#!/usr/bin/env python
import json
import os

import yaml
import subprocess
from graphqlclient import GraphQLClient
import re

config_file = 'autoupdate/config.yml'
source_file = 'nix/sources.json'

dummy_sha = '0000000000000000000000000a00000000000000000000000000'
re_sha = re.compile('(?<=got: {4}sha256:).*')

def get_nixpkgs_releases(token, pkgs):
    client = GraphQLClient('https://api.github.com/graphql')
    client.inject_token('bearer ' + token)

    query = '{'
    for pkg in pkgs:
        pkgs[pkg]['alias'] = pkg.replace('-', '')
        query += pkgs[pkg]['alias'] + ':repository(owner:"' + pkgs[pkg]['owner'] + '",name:"' + pkgs[pkg][
            'repo'] + '"){releases(last:1){nodes{tagName}}}'
    query += '}'

    return json.loads(client.execute(query))

def load_config(filename=config_file):
    fileh = open(filename)
    conf = yaml.load(fileh, Loader=yaml.FullLoader)
    fileh.close()
    return conf

def readfile(filename=source_file):
    filh = open(filename)
    nixpkgsf = json.load(filh)
    filh.close()
    return nixpkgsf 

def writefile(nixpkgs):
    fileh = open(source_file, 'w')
    fileh.write(json.dumps(nixpkgs, indent=4, sort_keys=True, ensure_ascii=False))
    fileh.close() 

def preflight_check(token):
    print('\033[1mRunning preflight check...')
    for cmd in [['-A', 'terraform-providers'], ['']]:
        dpkg = subprocess.run(['nix-build'] + cmd, check=False,
                            cwd=os.getcwd(), capture_output=True,
                            env={"GITHUB_TOKEN": token, "PATH": os.getenv('PATH')})
        if dpkg.returncode != 0:
            print('\033[93mPreFlight test failed, checks logs\033[0m')
            print(dpkg.stderr)
            exit(1)

    print('\033[1mPreFlight test succeeded !\n'
        'Checking for upgrades...\033[0m')

def update_pkg(token, pkg, version, pkgs):
    print(
        "\033[96m" + pkg + "\033[0m is upgradable from version \033[92m" + pkgs[pkg][
            'o_version'] + "\033[0m to version \033[92m" + pkgs[pkg]['c_version'] + "\033[0m")
                
    try:
        subprocess.run(['niv', 'update', pkg, '-v', version], cwd=os.getcwd(),
                    check=False,
                    env={"GITHUB_TOKEN": token, "PATH": os.getenv('PATH')})
    except subprocess.CalledProcessError as err:
        print('Error updating %s to version %s : %s', pkg, pkgs[pkg]['c_version'], err.output)
        exit(1)    


def main():
    conf = load_config()

    token = os.environ['GITHUB_TOKEN']

    preflight_check(token)

    nixpkgs = readfile()
    pkgsq = {}
    for pkg in nixpkgs:
        if pkg not in conf['blacklist']:
            if 'version' in nixpkgs[pkg].keys():
                pkgsq[pkg] = {}
                pkgsq[pkg]['owner'] = nixpkgs[pkg]['owner']
                pkgsq[pkg]['repo'] = nixpkgs[pkg]['repo']
                pkgsq[pkg]['o_version'] = nixpkgs[pkg]['version']

    result = get_nixpkgs_releases(token, pkgsq)

    for pkg in pkgsq:
        nodes = result['data'][pkgsq[pkg]['alias']]['releases']['nodes']
        if len(nodes) > 0:
            pkgsq[pkg]['c_version'] = nodes[0]['tagName'].replace('v', '')
            if pkgsq[pkg]['c_version'] != pkgsq[pkg]['o_version']:
                update_pkg(token, pkg, pkgsq[pkg]['c_version'], pkgsq)

                if 'vendorSha256' in nixpkgs[pkg].keys():
                    build_arg = pkg
                    for nixbuild in conf['build_mappings']:
                        if pkg.startswith(nixbuild):
                            build_arg = conf['build_mappings'][nixbuild]
                    nixpkgs = readfile()
                    o_nixpkgs = nixpkgs
                    nixpkgs[pkg]['vendorSha256'] = dummy_sha
                    writefile(nixpkgs)

                    fbuild = subprocess.run(['nix-build', '-A', build_arg], check=False,
                                            cwd=os.getcwd(), capture_output=True)
                    sha = re_sha.search(fbuild.stderr.decode())
                    if sha:
                        nixpkgs[pkg]['vendorSha256'] = sha.group()
                        writefile(nixpkgs)
                    else:
                        print('Error retrieving new vendor sha for package %s : %s', pkg, fbuild.stderr.decode())
                        writefile(o_nixpkgs)
                        exit(1)

            else:
                print("\033[96m" + pkg + "\033[0m is up to date. Current version: \033[92m" + pkgsq[pkg]['o_version'] + "\033[0m")


if __name__ == "__main__":
    main()