from setuptools import setup, Extension
from pybind11.setup_helpers import Pybind11Extension, build_ext

ext_modules = [
    Pybind11Extension(
        "sloth",
        ["sloth.cpp"],
    ),
]

setup(
    name="sloth",
    version="0.0.1",
    description="DataFrame Python-C++ bindings",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
)
