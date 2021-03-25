# How to create poetry files

```sh
nix-shell -p python3Packages.virtualenv gcc poetry
virtualenv /tmp/venv
source /tmp/venv/bin/activate
pip install openstackclient python-octaviaclient otcextensions
poetry init -n
pip freeze | sed 's/ @.*$//' | sed '/poetry/d' | sed '/virtualenv/d' | sed '/keyring/d' | xargs poetry add
deactivate
rm -rf /tmp/venv
```
