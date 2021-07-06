#!/usr/bin/env python
import json
import os

import yaml
import subprocess
from graphqlclient import GraphQLClient
from dotenv import load_dotenv

load_dotenv()

filh = open("../nix/sources.json")
nixpkgs = json.load(filh)
filh.close()
fileh = open("autoupdates.yml")
conf = yaml.load(fileh, Loader=yaml.FullLoader)
fileh.close()
pkgsq = {}
for pkg in nixpkgs:
    if pkg not in conf['blacklist']:
        if 'version' in nixpkgs[pkg].keys():
            pkgsq[pkg] = {}
            pkgsq[pkg]['owner'] = nixpkgs[pkg]['owner']
            pkgsq[pkg]['repo'] = nixpkgs[pkg]['repo']
            pkgsq[pkg]['o_version'] = nixpkgs[pkg]['version']

qr = '{'
for pkg in pkgsq:
    pkgsq[pkg]['alias'] = pkg.replace('-', '')
    qr += pkgsq[pkg]['alias'] + ':repository(owner:"' + pkgsq[pkg]['owner'] + '",name:"' + pkgsq[pkg][
        'repo'] + '"){releases(last:1){nodes{tagName}}}'
qr += '}'

client = GraphQLClient('https://api.github.com/graphql')
client.inject_token('bearer ' + os.getenv('GH_TOKEN'))
result = json.loads(client.execute(qr))
for pkg in pkgsq:
    if len(result['data'][pkgsq[pkg]['alias']]['releases']['nodes']) > 0:
        pkgsq[pkg]['c_version'] = result['data'][pkgsq[pkg]['alias']]['releases']['nodes'][0]['tagName'].replace('v',
                                                                                                                 '')
        if pkgsq[pkg]['c_version'] != pkgsq[pkg]['o_version']:
            print(
                pkg + " Latest Version: " + pkgsq[pkg]['c_version'] + " Version in source: " + pkgsq[pkg]['o_version'])
            subprocess.run(['niv', 'update', pkg, '-v', pkgsq[pkg]['c_version']], cwd=os.getcwd() + '/../', check=False)
        else:
            print(pkg + " Up to date Version: " + pkgsq[pkg]['o_version'])
