from setuptools import setup, find_packages, Extension
import os

def get_extensions():
    return [
        Extension("Sloth.frame", ["Sloth/frame.c"]),
        Extension("Sloth.indexer", ["Sloth/indexer.c"]),
        Extension("Sloth.resample", ["Sloth/resample.c"]),
        Extension("Sloth.rolling", ["Sloth/rolling.c"]),
        Extension("Sloth.util", ["Sloth/util.c"]),
    ]

# https://github.com/FedericoStra/cython-package-example/blob/master/setup.py
with open("requirements.txt") as fp:
    install_requires = fp.read().strip().split("\n")

with open("requirements-dev.txt") as fp:
    dev_requires = fp.read().strip().split("\n")

setup(
    name="Sloth",
    version="1.0.0-beta.1",
    description="Sloth module",
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    author="Evan Porter",
    author_email="evanwporter@gmail.com",
    url="https://github.com/evanwporter/Sloth",
    packages=['Sloth'],
    ext_modules=get_extensions(),
    include_package_data=True,
    install_requires=install_requires,
    extras_require={
        "dev": dev_requires,
        "docs": ["sphinx", "furo"]
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    zip_safe=False,

)

"""
python setup.py sdist bdist_wheel
pip install .
"""