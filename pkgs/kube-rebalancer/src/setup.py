from setuptools import setup, find_packages

setup(
    name="kube-rebalancer",
    version="0.0.1",
    description="Used to move pod from a node to another",
    author="Yacine SAIBI",
    author_email="yacine.saibi@orange.com",
    packages=find_packages(),
    install_requires=["kubernetes", "quantiphy", "urllib3"],
    scripts=["bin/rebalancer-move-pods"]
)
