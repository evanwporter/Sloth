cimport numpy as np
from cpython cimport list, dict, str
from index cimport DateTimeIndex, ObjectIndex, _Index
from frame cimport Frame, Series, DataFrame


cdef class Indexer:
    cdef:
        _Index index, 
        np.ndarray values

        str reference
        ObjectIndex columns
        str name

cdef class IntegerLocation(Indexer):
    cdef str x
    #     dict columns

cdef class Location(Indexer):
    cdef Series _handle_str(self, arg, int column)

    cdef Frame _handle_slice(self, slice arg)
