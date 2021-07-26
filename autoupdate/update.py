#!/usr/bin/env python
import json
import os
import re
import subprocess

from graphqlclient import GraphQLClient
import yaml

CONFIG_FILE = 'autoupdate/config.yml'
SOURCE_FILE = 'nix/sources.json'

DUMMY_SHA = '0000000000000000000000000a00000000000000000000000000'
REGEX_SHA = '(?<=got: {4}sha256:).*'

NO_VERSION = 'no_version'

def get_packages_releases(token, pkgs):
    client = GraphQLClient('https://api.github.com/graphql')
    client.inject_token('bearer ' + token)

    query = '{'
    for pkg in pkgs:
        pkgs[pkg]['alias'] = pkg.replace('-', '')
        query += pkgs[pkg]['alias'] + ':repository(owner:"' + pkgs[pkg]['owner'] + '",name:"' + pkgs[pkg][
            'repo'] + '"){releases(last:1){nodes{tagName}}}'
    query += '}'

    return json.loads(client.execute(query))

def load_config(file=CONFIG_FILE):
    f = open(file)
    config = yaml.load(f, Loader=yaml.FullLoader)
    f.close()
    return config

def read_source_file(file=SOURCE_FILE):
    f = open(file)
    source = json.load(f)
    f.close()
    return source

def write_source_file(pkgs, file=SOURCE_FILE):
    f = open(file, 'w')
    f.write(json.dumps(pkgs, indent=4, sort_keys=True, ensure_ascii=False))
    f.close() 

def preflight_check(token):
    print('\033[1mRunning preflight check...')
    for cmd in [['-A', 'terraform-providers'], ['']]:
        try:
            subprocess.run(['nix-build'] + cmd, check=True,
                                cwd=os.getcwd(), capture_output=True,
                                env={'GITHUB_TOKEN': token, 'PATH': os.getenv('PATH')})
        except subprocess.CalledProcessError as err:
            print('\033[91mPreFlight test failed :\n', err.stderr.decode(), '\033[0m')
            exit(1)

    print('\033[1mPreflight check succeeded !\nChecking for upgrades...\033[0m')

def update_package(token, pkgs, pkg, version):
    cmd = ['niv', 'update', pkg]

    if version == NO_VERSION:
        print('\033[1m\033[96m', pkg, '\033[0mwill be updated to the latest commit')
    else:
        cmd += ['-v', version]
        print(
            '\033[1m\033[96m', pkg, '\033[0mis upgradable from version\033[92m', pkgs[pkg][
                'o_version'], '\033[0mto version\033[92m', pkgs[pkg]['c_version'], '\033[0m')
    try:
        print('\033[1m Updating\033[96m', pkg + '...\033[0m')
        subprocess.run(cmd, cwd=os.getcwd(),
                    check=True, capture_output=True,
                    env={"GITHUB_TOKEN": token, "PATH": os.getenv('PATH')})
    except subprocess.CalledProcessError as err:
        print('\033[91mError updating %s to version :\n', pkg, err.stderr.decode(), '\033[0m')
        exit(1)

def main():
    token = os.environ['GITHUB_TOKEN']

    conf = load_config()
    
    preflight_check(token)

    nixpkgs = read_source_file()
    pkgs = {}
    for pkg in nixpkgs:
        if pkg not in conf['blacklist']:
            pkgs[pkg] = {}
            pkgs[pkg]['owner'] = nixpkgs[pkg]['owner']
            pkgs[pkg]['repo'] = nixpkgs[pkg]['repo']
            if 'version' in nixpkgs[pkg].keys():
                pkgs[pkg]['o_version'] = nixpkgs[pkg]['version']
            else:
                pkgs[pkg]['o_version'] = NO_VERSION

    result = get_packages_releases(token, pkgs)

    for pkg in pkgs:
        nodes = result['data'][pkgs[pkg]['alias']]['releases']['nodes']
        if len(nodes) > 0:
            pkgs[pkg]['c_version'] = nodes[0]['tagName'].replace('v', '')
            if pkgs[pkg]['c_version'] != pkgs[pkg]['o_version']:
                update_package(token, pkgs, pkg, pkgs[pkg]['c_version'])

                # Retrieve vendor sha by intentionally failing build to get the correct one
                if 'vendorSha256' in nixpkgs[pkg].keys():
                    build_arg = pkg
                    for nixbuild in conf['build_mappings']:
                        if pkg.startswith(nixbuild):
                            build_arg = conf['build_mappings'][nixbuild]

                    nixpkgs = read_source_file()
                    o_nixpkgs = nixpkgs
                    nixpkgs[pkg]['vendorSha256'] = DUMMY_SHA
                    write_source_file(nixpkgs)

                    fbuild = subprocess.run(['nix-build', '-A', build_arg], check=False,
                                            cwd=os.getcwd(), capture_output=True)
                    sha = re.compile(REGEX_SHA).search(fbuild.stderr.decode())
                    if sha:
                        nixpkgs[pkg]['vendorSha256'] = sha.group()
                        write_source_file(nixpkgs)
                    else:
                        print('\033[91mError retrieving vendor sha for package %s : %s', pkg, fbuild.stderr.decode(), '\033[0m')
                        write_source_file(o_nixpkgs)
                        exit(1)

            else:
                print('\033[1m\033[96m', pkg, '\033[0mis up to date. Current version:\033[92m', pkgs[pkg]['o_version'], '\033[0m')
        elif pkgs[pkg]['o_version'] == NO_VERSION:
            update_package(token, pkgs, pkg, pkgs[pkg]['o_version'])

if __name__ == "__main__":
    main()