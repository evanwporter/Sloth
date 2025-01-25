from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import numpy as np


def get_extensions():
    return [
        Extension("Sloth.frame", ["src/Sloth/frame.c"]),
        Extension("Sloth.indexer", ["src/Sloth/indexer.c"]),
        Extension("Sloth.resample", ["src/Sloth/resample.c"]),
        Extension("Sloth.rolling", ["src/Sloth/rolling.c"]),
        Extension("Sloth.util", ["src/Sloth/util.c"]),
    ]


with open("requirements.txt") as fp:
    install_requires = fp.read().strip().split("\n")

with open("requirements-dev.txt") as fp:
    dev_requires = fp.read().strip().split("\n")

setup(
    name="Sloth",
    version="1.0.1b1",
    description="Sloth module",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="Evan Porter",
    author_email="evanwporter@gmail.com",
    url="https://github.com/evanwporter/Sloth",
    packages=find_packages(where="src"),  # Updated to use the src layout
    package_dir={"": "src"},  # Root directory for packages is src/
    ext_modules=get_extensions()
    + cythonize(
        ["src/Sloth/*.pyx"],  # Updated path to .pyx files in src
        compiler_directives={"language_level": "3", "profile": True},
    ),
    include_dirs=[np.get_include()],
    include_package_data=True,
    install_requires=install_requires,
    extras_require={"dev": dev_requires, "docs": ["sphinx", "furo"]},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.12",
    zip_safe=False,
)
