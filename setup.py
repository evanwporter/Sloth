from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import numpy as np

setup(
    name='Sloth',
    install_requires=[
        "numpy",
        "cython"
    ],
    ext_modules=cythonize(
        ["Sloth/*.pyx"],
        compiler_directives={'language_level': "3"}
    ),
    include_dirs=[np.get_include()],
    packages=['Sloth'],
    zip_safe=False,
    author="Evan Porter",
    url="https://github.com/evanwporter/Sloth",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",

)

"""
python setup.py build_ext --inplace
"""