#!/usr/bin/env -S=2 python -u
import json
import os
import re
import subprocess
import yaml
import sys
from datetime import date

from graphqlclient import GraphQLClient

CONFIG_FILE = 'autoupdate/config.yml'
SOURCE_FILE = 'nix/sources.json'
CHANGES_FILE = 'changes.md'

DUMMY_SHA = '0000000000000000000000000a00000000000000000000000000'
re_sha = re.compile('(?<=got: {4}sha256:).*')


def get_packages_latest_release(token, pkgs):
    client = GraphQLClient('https://api.github.com/graphql')
    client.inject_token('bearer ' + token)

    query = '{'
    for pkg, props in pkgs.items():
        props['alias'] = pkg.replace('-', '')
        query += '%s:repository(owner:"%s",name:"%s"){releases(last:1){nodes{tagName}}}' % (
            props['alias'], props['owner'], props[
                'repo'])
    query += '}'

    return json.loads(client.execute(query))


def load_config(file=CONFIG_FILE):
    with open(file) as cfileh:
        config = yaml.load(cfileh, Loader=yaml.FullLoader)
    return config


def read_source_file(file=SOURCE_FILE):
    with open(file) as sfileh:
        source = json.load(sfileh)
    return source


def write_source_file(pkgs, file=SOURCE_FILE):
    with open(file, 'w') as f:
        f.write(json.dumps(pkgs, indent=4, sort_keys=True, ensure_ascii=False))


def preflight_check(token):
    print('\033[1mRunning preflight check...')
    for cmd in [['-A', 'terraform-providers'], ['']]:
        try:
            subprocess.run(['nix-build'] + cmd, check=True,
                           cwd=os.getcwd(), capture_output=True,
                           env={'GITHUB_TOKEN': token, 'PATH': os.getenv('PATH')})
        except subprocess.CalledProcessError as err:
            print('\033[91mPreFlight test failed :\n', err.stderr.decode(), '\033[0m')
            sys.exit(1)

    print('\033[1mPreflight check succeeded !\nChecking for upgrades...\033[0m')


def update_package(token, pkg, props):
    cmd = ['niv', 'update', pkg]

    if 'c_version' not in props:
        print('\033[1m\033[96m', pkg, '\033[0mwill be updated to the latest commit')
    else:
        cmd += ['-v', props['c_version']]
        print(
            '\033[1m\033[96m', pkg, '\033[0mis upgradable from version\033[92m', props[
                'o_version'], '\033[0mto version\033[92m', props['c_version'], '\033[0m')
    try:
        print('\033[1m Updating\033[96m', pkg + '...\033[0m')
        subprocess.run(cmd, cwd=os.getcwd(),
                       check=True, capture_output=True,
                       env={"GITHUB_TOKEN": token, "PATH": os.getenv('PATH')})
    except subprocess.CalledProcessError as err:
        print('\033[91mError updating ', pkg, '\n', err.stderr.decode(), '\033[0m')
        sys.exit(1)


def update_vendor_sha(pkg, config):
    build_arg = pkg
    nixpkgs = read_source_file()
    nixpkgs[pkg]['vendorSha256'] = DUMMY_SHA
    write_source_file(nixpkgs)
    for arg in config['build_mappings']:
        if pkg.startswith(arg):
            build_arg = config['build_mappings'][arg]

    fbuild = subprocess.run(['nix-build', '-A', build_arg], check=False,
                            cwd=os.getcwd(), capture_output=True)
    sha = re_sha.search(fbuild.stderr.decode())
    if sha:
        nixpkgs[pkg]['vendorSha256'] = sha.group()
        write_source_file(nixpkgs)
    else:
        print('\033[91mError retrieving vendor sha for package ', pkg, '\n', fbuild.stderr.decode(),
              '\033[0m')
        sys.exit(1)


def main():
    token = os.getenv('GITHUB_TOKEN')
    if token is None:
        print('\033[91mGITHUB_TOKEN env variable is mandatory\033[0m\n')
        sys.exit(1)

    changesh = open(CHANGES_FILE, 'w')
    changesh.write('Autoupdate ' + date.today().strftime('%d-%m-%y') + '\n\nThe following packages will be updated\n\n')

    config = load_config()

    preflight_check(token)

    nixpkgs = read_source_file()
    pkgs = {}
    for pkg, props in nixpkgs.items():
        if pkg not in config['blacklist']:
            pkgs[pkg] = {
                'owner': props['owner'],
                'repo': props['repo']}
            if 'version' in nixpkgs[pkg].keys():
                pkgs[pkg]['o_version'] = props['version']

    result = get_packages_latest_release(token, pkgs)

    for pkg, props in pkgs.items():
        nodes = result['data'][props['alias']]['releases']['nodes']
        if len(nodes) > 0:
            props['c_version'] = nodes[0]['tagName'].replace('v', '')
            if props['c_version'] != props['o_version']:
                changesh.write(
                    '* `' + pkg + '` : **' + props['o_version'] + '** -> **' + props['c_version'] + '**\n')
                update_package(token, pkg, props)

                # Retrieve vendor sha by intentionally failing build to get the correct one
                if 'vendorSha256' in nixpkgs[pkg]:
                    update_vendor_sha(pkg, config)
            else:
                print('\033[1m\033[96m', pkg, '\033[0mis up to date. Current version:\033[92m', props['o_version'],
                      '\033[0m')
        elif 'o_version' not in props:
            update_package(token, pkg, props)
    changesh.close()


if __name__ == "__main__":
    main()
