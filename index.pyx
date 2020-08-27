cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

cdef class _Index:
    @property
    def keys_(self):
        return np.asarray(self.keys)

    # def __iter__(self):
        # return 
#     def __getitem__(self, arg):
#         return self.index[arg]


cdef class ObjectIndex(_Index):
    def __init__(self, object index):
        self.keys = index
        self._initialize()
    
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef int i
        cdef int length = len(self.keys)

        # Use int64
        self.index = {}
        for i in range(length):
            self.index[self.keys[i]] = i

    cdef get_item(self, arg):
        return self.index[arg]

# ctypedef np.int64_t datetime64

cdef class DateTimeIndex(_Index):

    def __init__(self, index):
        """
        Index must be of type np.ndarray. If coming from pandas 
        DatetimeIndex you can do index._data._data.
        """
        if isinstance(index, np.ndarray):
            self.keys = index.view(np.int64)
        else:
            self.keys = index
        self._initialize()

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef int i
        cdef int length = len(self.keys)

        # Use int64
        self.index = Int64to64Map(number_of_elements_hint=length, for_int=True)
        for i in range(length):
            self.index.put_int64(self.keys[i], i)
    
    cdef int get_item(self, np.int64_t item):
        return self.index.get_int64(item)

    @property
    def keys_(self):
        return super().keys_.astype("datetime64[ns]")

