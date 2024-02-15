#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.pyyaml python3Packages.graphqlclient
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
SOURCE_FILTER = os.getenv('SOURCE_FILTER','.*')
DUMMY_SHA = '0000000000000000000000000000000000000000000000000000'
re_sha = re.compile('(?<=got: {4})(sha256:)?(.*)')

def get_package_latest_release(token, props, **kwargs):
    client = GraphQLClient('https://api.github.com/graphql')
    client.inject_token('bearer ' + token)

    query = r"""
        query GetRelease($owner: String!, $name: String!, $cursor: String) {
            repository(owner: $owner, name: $name) {
                releases(before: $cursor, last: 1, orderBy: {field: CREATED_AT, direction: ASC}) {
                    pageInfo {
                        hasPreviousPage
                        startCursor
                    }
                    nodes {
                        isPrerelease
                        ...OtherReleaseData
                    }
                }
            }
        }

        fragment OtherReleaseData on Release {
            tagName
        }
    """
    return json.loads(client.execute(query, variables={
        'owner': props.get('owner'),
        'name': props.get('repo'),
        'cursor': kwargs.get('cursor')
    }))


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
        print('\033[91mError updating', pkg, '\n', err.stderr.decode(), '\033[0m')
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

    # Note(JPB): no need to test the current build
    # preflight_check(token)

    nixpkgs = read_source_file()
    pkgs = {}
    for pkg, props in nixpkgs.items():
        if re.match(SOURCE_FILTER,pkg) and props.get('autoupdate', True):
            pkgs[pkg] = {
                'owner': props['owner'],
                'repo': props['repo'],
                'o_version': None,
            }
            if 'version' in nixpkgs[pkg].keys():
                pkgs[pkg]['o_version'] = props['version']

    for pkg, props in pkgs.items():
        # Not using a tagged release
        if props['o_version'] is None:
            update_package(token, pkg, props)
            # Retrieve vendor sha by intentionally failing build to get the correct one
            if 'vendorSha256' in nixpkgs[pkg]:
                update_vendor_sha(pkg, config)
            continue

        # Check for new releases
        cursor = None
        c_version = None
        while c_version is None:
            resp = get_package_latest_release(token, props, cursor=cursor)
            if 'errors' in resp:
                print('\033[91mError Fetching new release for', pkg,':', resp['errors'][0]['message'], '\033[0m')
                break

            releases = resp['data']['repository']['releases']
            nodes = releases.get('nodes', [])
            page_info = releases['pageInfo']
            if len(nodes) > 0:
                if not nodes[0]['isPrerelease']:
                    c_version = nodes[0]['tagName']
                elif page_info['hasPreviousPage']:
                    cursor = page_info['startCursor']
                else:
                    print('\033[91mNo stable release available for', pkg, '\033[0m')
                    break
            else:
                print('\033[91mCould not find any release for', pkg, '\033[0m')
                break

        if c_version is not None:
            props['c_version'] = c_version.replace('v', '')
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
    changesh.close()


if __name__ == "__main__":
    main()
