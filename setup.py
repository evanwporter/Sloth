from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np

extensions = [
    Extension(
        "pydataframe",
        sources=["dataframe.pyx", "dataframe.cpp"],
        include_dirs=[np.get_include()],
        language="c++",
    )
]

setup(
    name="pydataframe",
    ext_modules=cythonize(extensions),
    zip_safe=False,
)
