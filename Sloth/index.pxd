cimport numpy as np 
cimport cython
from cpython cimport dict, slice
from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from .util cimport datetime64, timedelta64, indice

cdef class _Index:
    cdef public:
        slice mask
        
cdef class ObjectIndex(_Index):
    cdef public:
        object keys_
        dict index
        reference

    cdef inline void _initialize(self)

    # cdef get_item(self, arg)

cdef class DateTimeIndex(_Index):
    cdef public:
        datetime64[:] keys_
        Int64to64Map index
        str reference

    cdef inline void _initialize(self)
        # cdef int i

    # cdef int get_item(self, item)

cdef class _RangeIndexMixin(_Index):
    cdef str x

cdef class RangeIndex(_RangeIndexMixin):
    cdef public int start, stop, step

cdef class PeriodIndex(_RangeIndexMixin):
    cdef public:
        datetime64 start, stop
        timedelta64 step