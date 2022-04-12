##########################################################
#
# This module contains class that represent k8s resources
#
##########################################################
from quantiphy import Quantity


class Node:

    def __init__(self, name, total_cpu, total_memory, used_cpu,
                 used_memory, cordoned, taints, pods):
        self.name = name
        self.pods = pods
        self.total_cpu = Quantity(total_cpu)
        self.total_memory = Quantity(total_memory)
        self.used_cpu = Quantity(used_cpu)
        self.used_memory = Quantity(used_memory)
        self.cordoned = cordoned
        self.taints = taints if taints is not None else []
        self.cpu_percent = round(
            self.used_cpu / self.total_cpu * 100, 2
        )
        self.memory_percent = round(
            self.used_memory / self.total_memory * 100, 2
        )
    def __repr__(self):
        return "%s(%r)" % (self.__class__, self.__dict__)

    def __str__(self):
        return "Node: (name: {0}, \npods: {1}, \ntotal_cpu: {2}, \
        \ntotal_memory: {3}, \nused_cpu: {4}, \nused_memory: {5}, \
        \ncordoned: {6}, \ntaints: {7}, \ncpu_percent: {8}, \
        \nmemory_percent: {9})".format(
            self.name,
            [pod.__str__() for pod in self.pods],
            self.total_cpu,
            self.total_memory,
            self.used_cpu,
            self.used_memory,
            self.cordoned,
            self.taints,
            self.cpu_percent,
            self.memory_percent
        )

    # Getters
    def get_name(self):
        return self.name

    def get_pods(self):
        return self.pods

    def get_total_memory(self):
        return self.total_memory

    def get_total_cpu(self):
        return self.total_cpu

    def get_used_memory(self):
        return self.used_memory

    def get_used_cpu(self):
        return self.used_cpu

    def get_cordoned(self):
        return self.cordoned

    def get_taints(self):
        return self.taints

    def get_cpu_percent(self):
        return self.cpu_percent

    def get_memory_percent(self):
        return self.memory_percent

    # Setters
    def set_pods(self, pods):
        self.pods = pods

    def set_used_memory(self, memory):
        self.used_memory = Quantity(memory)

    def set_user_cpu(self, cpu):
        self.used_cpu = Quantity(cpu)

    def set_cordoned(self, cordoned):
        self.cordoned = cordoned

    def set_taints(self, taints):
        self.taints = taints

    def set_cpu_percent(self):
        self.cpu_percent = self.used_cpu / self.total_cpu * 100

    def set_memory_percent(self):
        self.memory_percent = self.used_memory / self.total_memory * 100

    # Other methods
    def add_pod(self, pod):
        self.pods.append(pod)

    def delete_pod(self, pod):
        self.pods.remove(pod)


class Pod:

    def __init__(self, name, namespace, node_name, labels,
                 containers, owner, affinity, status):

        self.name = name
        self.namespace = namespace
        self.node_name = node_name
        self.labels = labels
        self.containers = containers
        self.owner = owner
        self.affinity = affinity if affinity is not None else {}
        self.status = status
        self.memory = Quantity(
            sum(
                [Quantity(c["usage"]["memory"]) for c in self.containers]
            )
        )
        self.cpu = Quantity(
            sum(
                [Quantity(c["usage"]["cpu"]) for c in self.containers]
            )
        )

    def __repr__(self):
        return "%s(%r)" % (self.__class__, self.__dict__)

    def __str__(self):
        return "Pod: (name: {0},\nnamespace: {1},\nnode_name: {2}, \
        \nlabels: {3}, \ncontainers: {4}, \nowner: {5}, \naffinity: {6}, \nstatus: {7} \
        \nmemory: {8} , \ncpu: {9})".format(
            self.name,
            self.namespace,
            self.node_name,
            self.labels,
            self.containers,
            self.owner,
            self.affinity,
            self.status,
            self.memory,
            self.cpu)

    # Getters
    def get_name(self):
        return self.name

    def get_namespace(self):
        return self.namespace

    def get_node_name(self):
        return self.node_name

    def get_memory(self):
        return self.memory

    def get_cpu(self):
        return self.cpu

    def get_labels(self):
        return self.labels

    def get_containers(self):
        return self.containers

    def get_owner(self):
        return self.owner

    def get_affinity(self):
        return self.affinity

    def get_status(self):
        return self.status

    # Setters
    def set_node_name(self, name):
        self.node_name = name

    def set_memory(self, memory):
        self.memory = memory

    def set_cpu(self, cpu):
        self.cpu = cpu

    def set_labels(self, labels):
        self.labels = labels

    def set_container(self, containers):
        self.containers = containers

    def set_status(self, status):
        self.status = status
