import time
import random
import concurrent.futures as cf
import urllib3
from kubernetes import client, config

urllib3.disable_warnings()

def COREv1():
    config.load_kube_config()
    return client.CoreV1Api()

def APIv1():
    config.load_kube_config()
    return client.AppsV1Api()

def CUSTOM_API():
    config.load_kube_config()
    return client.CustomObjectsApi()

RDSIDE = "required_during_scheduling_ignored_during_execution"

def dict_parser(dico, key, value=None):
    """ Finds nested dict
    params:
    dico: (dict) base dict to parse
    key: (string) the key to match
    value: (string) the corresponding value (optional)

    returns: dict
    """

    for k, v in dico.items():
        if k == key:
            if value and value == v:
                return dico
            else:
                return v
        elif isinstance(v, dict):
            result = dict_parser(v, key, value)
            if result is not None:
                return result
        elif isinstance(v, list):
            for elt in v:
                if isinstance(elt, dict):
                    return dict_parser(elt, key, value)

    return None


def check_and_update_pod_status(pod, timeout):
    """ Check the status of a pod and update corresponding instance
    params:
    pod: (Pod) the pod to check/update status

    returns: None
    """
    replicas = 1
    current_replicas = 0
    available_replicas = 0
    elapsed_time = 0
    if pod.get_owner()["kind"] == "ReplicaSet":
        while replicas != available_replicas \
                and elapsed_time < timeout:
            status = APIv1().read_namespaced_replica_set(
                pod.get_owner()["name"],
                pod.get_namespace()
            ).to_dict()["status"]
            replicas = status["replicas"]
            available_replicas = status["available_replicas"]
            pod.set_status(status)
            time.sleep(1)
            elapsed_time += 1

    elif pod.get_owner()["kind"] == "StatefulSet":
        while replicas != current_replicas \
                and elapsed_time < timeout:
            status = APIv1().read_namespaced_stateful_set(
                pod.get_owner()["name"],
                pod.get_namespace()
            ).to_dict()["status"]
            replicas = status["replicas"]
            current_replicas = status["current_replicas"]
            pod.set_status(status)
            time.sleep(1)
            elapsed_time += 1


def count_nodes():
    """ returns number of node"""
    return len(CUSTOM_API().list_cluster_custom_object(
        "metrics.k8s.io", "v1beta1", "nodes")["items"])


def describe_pods(name, namespace, containers):
    number_of_nodes = count_nodes()

    desc_pod = COREv1().read_namespaced_pod(
        name,
        namespace).to_dict()

    owner_kind = desc_pod["metadata"]["owner_references"][0]["kind"]
    owner_name = desc_pod["metadata"]["owner_references"][0]["name"]

    if owner_kind == "ReplicaSet":
        status = APIv1().read_namespaced_replica_set(
            owner_name,
            namespace
        ).to_dict()["status"]

        return Pod(
                name,
                namespace,
                desc_pod["spec"]["node_name"],
                desc_pod["metadata"]["labels"],
                containers,
                desc_pod["metadata"]["owner_references"][0],
                desc_pod["spec"]["affinity"],
                status
        )


def get_all_pods():
    """ List all pods
    returns:
    pods: (List(Pod)) the list of all pods
    """
    pods = []
    results = []
    # List pods and make a describe on each pod
    with cf.ProcessPoolExecutor() as executor:
        for pod in CUSTOM_API().list_cluster_custom_object(
                "metrics.k8s.io", "v1beta1", "pods")["items"]:
            results.append(
                executor.submit(
                    describe_pods,
                    pod["metadata"]["name"],
                    pod["metadata"]["namespace"],
                    pod["containers"],
                )
            )
        for f in cf.as_completed(results):
            if isinstance(f.result(), Pod):
                pods.append(f.result())

    return pods


def get_all_nodes():
    """ List all nodes
    returns:
    nodes: (list(Node)) List of all nodes
    """
    pods = get_all_pods()
    nodes = []
    # list nodes and get usage
    top_node = sorted(
        CUSTOM_API().list_cluster_custom_object(
            "metrics.k8s.io", "v1beta1", "nodes")["items"],
        key=lambda n: n["metadata"]["name"]
    )
    ls_node = sorted(
        COREv1().list_node().to_dict()["items"],
        key=lambda n: n["metadata"]["name"]
    )

    for top, ls in zip(top_node, ls_node):
        node_pods = []
        for pod in pods:
            if pod.get_node_name() == top["metadata"]["name"]:
                node_pods.append(pod)

        nodes.append(
            Node(top["metadata"]["name"],
                    ls["status"]["allocatable"]["cpu"],
                    ls["status"]["allocatable"]["memory"],
                    top["usage"]["cpu"],
                    top["usage"]["memory"],
                    ls["spec"]["unschedulable"],
                    ls["spec"]["taints"],
                    node_pods)
        )
    return nodes


def select_overloaded_nodes(nodes, percent, limit):
    """ List overloaded nodes
    params:
    nodes: (List(Nodes)) List of nodes
    percent: (float) Usage percentage limit (mem/cpu)
    limit: (int) Max number of node to return

    returns:
    overloaded_nodes: (dict(Node)) List of overloaded nodes
    """
    # We sort nodes by needed resources
    overloaded_nodes = {
        "need_memory": [],
        "need_cpu": [],
        #"need_cpu_and_memory": []
    }
    for node in nodes:
        node.get_cpu_percent()
        node.get_memory_percent()
        #if node.get_cpu_percent() > float(percent) and \
        #        node.get_memory_percent() > float(percent):
        #    overloaded_nodes["need_cpu_and_memory"].append(
        #        node
        #    )
        if node.get_memory_percent() > float(percent):
            overloaded_nodes["need_memory"].append(
                node
            )
        elif node.get_cpu_percent() > float(percent):
            overloaded_nodes["need_cpu"].append(
                node
            )
    # Sorting node based on percentage usage
    for key, value in overloaded_nodes.items():
        if key == "need_cpu":
            overloaded_nodes[key] = sorted(
                value,
                key=lambda n: n.get_cpu_percent(),
                reverse=True
            )[:limit]
        elif key == "need_memory":
            overloaded_nodes[key] = sorted(
                value,
                key=lambda n: n.get_memory_percent(),
                reverse=True
            )[:limit]
    return overloaded_nodes


def select_destination_nodes(nodes, percent, limit):
    """ List of node that have resources
    params:
    nodes: (List(Nodes)) List of nodes
    percent: (float) Usage percentage limit (mem/cpu)
    limit: (int) Max number of node to return

    returns:
    destination_nodes: (list(Node)) List of node to move pods on
    """
    destination_nodes = {
        "has_memory": [],
        "has_cpu": [],
        "has_cpu_and_memory": []
    }
    for node in nodes:
        if node.get_cpu_percent() < float(percent) and \
                node.get_memory_percent() < float(percent):
            destination_nodes["has_cpu_and_memory"].append(
                node
            )
        if node.get_cpu_percent() < float(percent):
            destination_nodes["has_cpu"].append(
                node
            )
        if node.get_memory_percent() < float(percent):
            destination_nodes["has_memory"].append(
                node
            )
    # Sorting node based on percentage usage (reversed)
    for key, value in destination_nodes.items():
        if key == "has_cpu":
            destination_nodes[key] = sorted(
                value,
                key=lambda n: n.get_cpu_percent(),
            )[:limit]
        elif key == "has_memory":
            destination_nodes[key] = sorted(
                value,
                key=lambda n: n.get_memory_percent(),
            )[:limit]
    return destination_nodes


def have_enough_resources(node, pod, percent):
    """ Check node has enough resources
    params:
    node: (Node) Node to move 'pod' on
    pod: (Pod) Pod to move
    percent: (float) Usage percentage limit

    returns: (Boolean)
    """
    mem_percent_after_move = \
        (node.get_used_memory() + pod.get_memory()) / \
        node.get_total_memory() * 100

    cpu_percent_after_move = \
        (node.get_used_cpu() + pod.get_cpu()) / \
        node.get_total_cpu() * 100

    if mem_percent_after_move < percent and \
            cpu_percent_after_move < percent:
        return True
    return False


def is_taints_compatible(node, pod):
    """ Check taints compatibility
    params:
    node: (Node) Node to move 'pod' on
    pod: (Pod) Pod to move

    returns: (Boolean)
    """
    for taint in node.get_taints():
        if taint["effect"] == "NoSchedule":
            if taint["key"] not in pod.get_labels().keys() or \
                    pod.get_labels()[taint["key"]] != taint["value"]:
                return False
    return True


def has_no_anti_affinity(node, pod):
    """ Check affinity
        params:
        node: (Node) Node to move 'pod' on
        pod: (Pod) Pod to move

        returns: (Boolean)
        """
    affinity = pod.get_affinity()
    for key, value in affinity.items():
        if value is not None:
            if key == "node_affinity":
                nst = dict_parser(value, "node_selector_terms")
                for selector in nst:
                    if selector["match_expressions"] is not None:
                        pass
                    if selector["match_fields"] is not None:
                        for field in selector["match_fields"]:
                            if field["operator"] == "In" and \
                                    node.get_name() not in field["values"]:
                                return False

            elif key == "pod_affinity":
                pass
            elif key == "pod_anti_affinity":
                ls = dict_parser(value, "label_selector")
                if ls["match_expressions"] is not None:
                    pass
                if ls["match_labels"] is not None:
                    label_size = len(ls["match_labels"])
                    passed_labels = 0
                    for k, v in ls["match_labels"].items():
                        for pod in node.get_pods():
                            labels = pod.get_labels()
                            if k in labels.keys() and \
                                    labels[k] == v:
                                passed_labels += 1
                    if passed_labels == label_size:
                        return False
    return True


class Rebalancer:
    """ Class that balance the cluster's load
    """

    def __init__(self,
                 resource_percent=90,
                 pod_limit=3,
                 node_limit=100,
                 timeout=120):
        self.pod_limit = pod_limit
        self.node_limit = node_limit
        self.timeout = timeout
        self.resource_percent = resource_percent
        self.pods = get_all_pods()
        self.nodes = get_all_nodes()
        self.overloaded_nodes = select_overloaded_nodes(
            self.nodes,
            self.resource_percent,
            self.node_limit
        )
        self.destination_nodes = select_destination_nodes(
            self.nodes,
            self.resource_percent,
            self.node_limit
        )

    # Getters
    def get_nodes(self):
        return self.nodes

    def get_node(self, name):
        for node in self.nodes:
            if name == node.get_name():
                return node

    def get_pods(self):
        return self.pods

    def get_pod(self, name):
        for pod in self.pods:
            if name == pod.get_name():
                return pod

    def get_overloaded_nodes(self):
        return self.overloaded_nodes

    def get_destination_nodes(self):
        return self.destination_nodes

    def update_pods(self):
        self.pods = get_all_pods()

    def update_nodes(self):
        self.nodes = get_all_nodes()

    def update_overloaded_nodes(self):
        self.update_nodes()
        self.overloaded_nodes = select_overloaded_nodes(
            self.nodes,
            self.resource_percent,
            self.node_limit
        )

    def update_destination_nodes(self):
        self.update_nodes()
        self.destination_nodes = select_destination_nodes(
            self.nodes,
            self.resource_percent,
            self.node_limit
        )

    def move(self, pod, node):
        cordon_body = [{'op': 'add',
                        'path': '/spec/unschedulable',
                        'value': True}]
        uncordon_body = [{'op': 'add',
                          'path': '/spec/unschedulable',
                          'value': None}]
        cordoned = []
        dst_nodes = self.destination_nodes

        if have_enough_resources(node,
                                 pod,
                                 self.resource_percent) \
                and is_taints_compatible(node, pod) and \
                has_no_anti_affinity(node, pod):
            try:
                for n in self.nodes:
                    name = n.get_name()
                    if name != node.get_name():
                        COREv1().patch_node(name, cordon_body)
                        cordoned.append(name)

                print("Moving pod {0} to node {1}...".format(
                    pod.get_name(),
                    node.get_name()
                    )
                )

                COREv1().delete_namespaced_pod(
                    pod.get_name(),
                    pod.get_namespace()
                )
                check_and_update_pod_status(pod, self.timeout)
                dst_nodes.update(self.destination_nodes)
                for n in cordoned:
                    COREv1().patch_node(n, uncordon_body)
                cordoned.clear()
            except (RuntimeError, TypeError, AttributeError, ValueError):
                for node in cordoned:
                    COREv1().patch_node(node, uncordon_body)
                cordoned.clear()

    def move_pods(self, pod_name=None, dst_node=None):
        if pod_name:
            pod = self.get_pod(pod_name)
            if pod:
                if dst_node:
                    node = self.get_node(dst_node)
                    self.move(pod, node)
                else:
                    node_list = [node for node in self.nodes
                                 if node.get_name() != pod.get_node_name()]
                    index = random.randrange(0, len(node_list) - 1, 1)
                    self.move(pod, node_list[index])
            else:
                raise ValueError("Pod not found.") 

        else:
            self.update_overloaded_nodes()
            self.update_destination_nodes()
            for key, value in self.overloaded_nodes.items():
                if key == "need_memory":
                    for no in value:
                        pods = no.get_pods()
                        high_mem = sorted(
                            pods,
                            key=lambda p: p.get_memory(),
                            reverse=True
                        )[:self.pod_limit]
                        dst_nodes = self.destination_nodes
                        for node in dst_nodes["has_memory"]:
                            for pod in high_mem:
                                self.move(pod, node)

                if key == "need_cpu":
                    for no in value:
                        pods = no.get_pods()
                        high_cpu = sorted(
                            pods,
                            key=lambda p: p.get_cpu(),
                            reverse=True
                        )[:self.pod_limit]
                        dst_nodes = self.destination_nodes
                        for node in dst_nodes["has_cpu"]:
                            for pod in high_cpu:
                                self.move(pod, node)
