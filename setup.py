from setuptools import setup, Extension
from pybind11.setup_helpers import Pybind11Extension, build_ext

ext_modules = [
    Pybind11Extension(
        "dataframe",
        ["dataframe.cpp"],
    ),
]

setup(
    name="dataframe",
    version="0.0.1",
    description="DataFrame Python-C++ bindings",
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
)
