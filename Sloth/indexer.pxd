cimport numpy as np
from cpython cimport str
from .index cimport DateTimeIndex, ObjectIndex, _Index
from .frame cimport Frame, Series, DataFrame


cdef class Indexer:
    cdef:
        Frame frame
        _Index index, 
        np.ndarray values

        str reference
        ObjectIndex columns
        str name

    cdef slice combine_slices(self, slice mask, slice overlay, int length_a)

cdef class IntegerLocation(Indexer):
    cdef str x
    #     dict columns

cdef class Location(Indexer):
    cdef str x

    # cdef inline Frame _handle_slice(self, slice arg)

    # cdef inline Frame _handle_array(self, arg)