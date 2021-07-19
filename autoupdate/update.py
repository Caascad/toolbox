#!/usr/bin/env python
import json
import os

import yaml
import subprocess
from graphqlclient import GraphQLClient
import re

sha = re.compile('(?<=got: {4}sha256:).*')

source_file = "nix/sources.json"


def writefile(nixpkgs):
    fileh = open(source_file, 'w')
    fileh.write(json.dumps(nixpkgs, indent=4, sort_keys=True, ensure_ascii=False))
    fileh.close()


def readfile(filename=source_file):
    filh = open(source_file)
    nixpkgsf = json.load(filh)
    filh.close()
    return nixpkgsf


fileh = open("autoupdate/autoupdates.yml")
conf = yaml.load(fileh, Loader=yaml.FullLoader)
fileh.close()

nixpkgs = readfile()

print('************PreFlight************\n'
      'Ensure all package build')
for cmd in [['-A', 'terraform-providers'], ['']]:
    dpkg = subprocess.run(['nix-build'] + cmd, check=False,
                          cwd=os.getcwd(), capture_output=True,
                          env={"GITHUB_TOKEN": os.getenv('GITHUB_TOKEN'), "PATH": os.getenv('PATH')})
    if dpkg.returncode != 0:
        print('PreFlight test failed, checks logs')
        print(dpkg.stderr)
        exit(1)

print('PreFlight test succeded, checking for upgrades')
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
client.inject_token('bearer ' + os.getenv('GITHUB_TOKEN'))
result = json.loads(client.execute(qr))
for pkg in pkgsq:
    if len(result['data'][pkgsq[pkg]['alias']]['releases']['nodes']) > 0:
        pkgsq[pkg]['c_version'] = result['data'][pkgsq[pkg]['alias']]['releases']['nodes'][0][
            'tagName'].replace('v',
                               '')
        if pkgsq[pkg]['c_version'] != pkgsq[pkg]['o_version']:
            print(
                "\033[97m" + pkg + "\033[0m Latest Version: \033[92m" + pkgsq[pkg][
                    'c_version'] + "\033[0m Version in source: \033[92m" + pkgsq[pkg]['o_version'] + "\033[0m")
            subprocess.run(['niv', 'update', pkg, '-v', pkgsq[pkg]['c_version']], cwd=os.getcwd(),
                           check=False,
                           env={"GITHUB_TOKEN": os.getenv('GITHUB_TOKEN'), "PATH": os.getenv('PATH')})
            if 'vendorSha256' in nixpkgs[pkg].keys():
                build_arg = pkg
                for nixbuild in conf['build_mappings']:
                    if pkg.startswith(nixbuild):
                        build_arg = conf['build_mappings'][nixbuild]
                nixpkgs = readfile()
                print('Need to update VendorSHA, launch build to fail ' + pkg)
                nixpkgs[pkg]['vendorSha256'] = '0000000000000000000000000a00000000000000000000000000'
                writefile(nixpkgs)
                fbuild = subprocess.run(['nix-build', '-A', build_arg], check=False,
                                        cwd=os.getcwd(), capture_output=True)
                nixpkgs[pkg]['vendorSha256'] = sha.search(fbuild.stderr.decode()).group()
                writefile(nixpkgs)
        else:
            print("\033[97m" + pkg + "\033[0m Up to date Version: \033[92m" + pkgsq[pkg]['o_version'] + "\033[0m")
