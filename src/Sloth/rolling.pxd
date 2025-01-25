cimport numpy as np 

from .frame cimport Frame, Series, DataFrame


cdef class Rolling:
    cdef public:
        Frame frame
        int window