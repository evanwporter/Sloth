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
        compiler_directives={'language_level': "3", "profile": True}
    ),
    include_dirs=[np.get_include()],
)

"""
python cythonize.py build_ext --inplace
"""