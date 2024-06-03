from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import numpy as np

setup(
    name='Sloth',
    ext_modules=cythonize(
        ["Sloth/*.pyx"],
        compiler_directives={'language_level': "3"}
    ),
    include_dirs=[np.get_include()],
    packages=['Sloth'],
    zip_safe=False
)

"""
python setup.py build_ext --inplace
"""