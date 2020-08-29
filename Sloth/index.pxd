cimport numpy as np 
cimport cython
from cpython cimport dict
from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from util cimport datetime64, indice

cdef class _Index:
    cdef public:
        indice FD, BD
cdef class ObjectIndex(_Index):
    cdef public:
        object keys
        dict index
        reference

    cdef inline void _initialize(self)

    # cdef get_item(self, arg)

cdef class DateTimeIndex(_Index):
    cdef public:
        datetime64[:] keys
        Int64to64Map index
        str reference

    cdef inline void _initialize(self)
        # cdef int i

    # cdef int get_item(self, item)