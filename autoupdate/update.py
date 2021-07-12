#!/usr/bin/env python
import json
import os

import yaml
import subprocess
from graphqlclient import GraphQLClient
from dotenv import load_dotenv
import re

sha = re.compile('(?<=got: {4}sha256:).*')

load_dotenv()
source_file = "../nix/sources.json"


def writefile(nixpkgs):
    fileh = open(source_file, 'w')
    fileh.write(json.dumps(nixpkgs, indent=4, sort_keys=True, ensure_ascii=False))
    fileh.close()


def readfile(filename=source_file):
    filh = open(source_file)
    nixpkgsf = json.load(filh)
    filh.close()
    return nixpkgsf


fileh = open("autoupdates.yml")
conf = yaml.load(fileh, Loader=yaml.FullLoader)
fileh.close()
pkgsq = {}

nixpkgs = readfile()

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
            subprocess.run(['niv', 'update', pkg, '-v', pkgsq[pkg]['c_version']], cwd=os.getcwd() + '/../', check=False,
                           env={"GITHUB_TOKEN": os.getenv('GH_TOKEN'), "PATH": os.getenv('PATH')})
            if 'vendorSha256' in nixpkgs[pkg].keys():
                if pkg.startswith('terraform-provider'):
                    build_arg = 'terraform-providers'
                else:
                    build_arg = pkg
                nixpkgs = readfile()
                print('Need to update VendorSHA, launch build to fail ' + pkg)
                nixpkgs[pkg]['vendorSha256'] = '0000000000000000000000000a00000000000000000000000000'
                writefile(nixpkgs)
                fbuild = subprocess.run(['nix-build', '-A', build_arg], check=False,
                                        cwd=os.getcwd() + '/../', capture_output=True)
                print(sha.search(fbuild.stderr.decode()).group())
                nixpkgs[pkg]['vendorSha256'] = sha.search(fbuild.stderr.decode()).group()
                writefile(nixpkgs)
        else:
            print(pkg + " Up to date Version: " + pkgsq[pkg]['o_version'])
