# distutils: language = c++
# distutils: sources = DataFrame.cpp

from libcpp.vector cimport vector
from libc.stdlib cimport malloc, free

cdef extern from "DataFrame.h":
    cdef cppclass DataFrame:
        DataFrame(const vector[vector[double]]& values)
        vector[vector[double]] getValues() const
        size_t rows() const
        size_t cols() const

cimport numpy as np
import numpy as np

cdef class PyDataFrame:
    cdef DataFrame* c_df

    def __cinit__(self, np.ndarray[np.double_t, ndim=2] values):
        cdef vector[vector[double]] cpp_values = self._convert_to_cpp(values)
        self.c_df = new DataFrame(cpp_values)

    def __dealloc__(self):
        del self.c_df

    cdef vector[vector[double]] _convert_to_cpp(self, np.ndarray[np.double_t, ndim=2] values):
        cdef vector[vector[double]] cpp_values
        cdef vector[double] row

        for i in range(values.shape[0]):
            for j in range(values.shape[1]):
                row.push_back(values[i, j])
            cpp_values.push_back(row)
        return cpp_values

    def get_values(self):
        """
        Convert the C++ DataFrame values to a NumPy array.
        """
        cdef vector[vector[double]] cpp_values = self.c_df.getValues()
        cdef int rows = self.c_df.rows()
        cdef int cols = self.c_df.cols()
        cdef np.ndarray[np.double_t, ndim=2] np_values = np.empty((rows, cols), dtype=np.double)

        for i in range(rows):
            for j in range(cols):
                np_values[i, j] = cpp_values[i][j]

        return np_values
