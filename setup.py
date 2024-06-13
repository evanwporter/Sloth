from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
import sys
import setuptools

class get_pybind_include(object):
    """Helper class to determine the pybind11 include path"""

    def __init__(self, user=False):
        self.user = user

    def __str__(self):
        import pybind11
        return pybind11.get_include(self.user)

ext_modules = [
    Extension(
        'sloth',
        ['sloth.cpp'],
        include_dirs=[
            # Path to local Eigen directory
            './lib/Eigen',
            # Path to pybind11 headers
            get_pybind_include(),
            get_pybind_include(user=True)
        ],
        language='c++',
        extra_compile_args=['-std=c++14'],
    ),
]

setup(
    name='sloth',
    version='0.0.1',
    author='Author Name',
    author_email='author@example.com',
    description='Description of the package',
    ext_modules=ext_modules,
    install_requires=['pybind11>=2.5'],
    cmdclass={'build_ext': build_ext},
    zip_safe=False,
)
