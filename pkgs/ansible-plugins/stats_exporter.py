# Make coding more python3-ish, this is required for contributions to Ansible
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
  callback: stats_exporter
  callback_type: aggregate
  requirements:
    - whitelist in configuration
  short_description: Export stats at the end of ansible execution.
  version_added: "2.9"
  description:
    - Export stats at the end of ansible execution.
  options: []
'''

import json
import os

from ansible.plugins.callback import CallbackBase
from ansible.parsing.ajson import AnsibleJSONEncoder


class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'aggregate'
    CALLBACK_NAME = 'namespace.collection_name.stats_exporter'

    # only needed if you ship it and don't want to enable by default
    CALLBACK_NEEDS_WHITELIST = True

    def __init__(self):
        super(CallbackModule, self).__init__()

    def v2_playbook_on_stats(self, stats):
        '''Write playbook stats in a json file.'''

        hosts = stats.processed.keys()

        summary = dict()
        for h in hosts:
            s = stats.summarize(h)
            for status in s.keys():
                summary[status] = summary.get(status, 0) + s[status]

        path = os.getenv('ANSIBLE_STATS_EXPORTER_PATH', 'ansible-stats.json')
        with open(path, 'w+') as f:
            json.dump(summary, f, indent=4, sort_keys=True)
