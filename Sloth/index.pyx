# cython: profile=True

cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from util cimport datetime64, indice

cdef class _Index:
    @property
    def keys_(self):
        return np.asarray(self.keys)

    def fast_init(self, displacement):
        index = self.__new__(self.__class__)
        index.keys = self.keys
        index.reference = self.reference
        index.index = self.index
        index.FD = displacement[0]
        index.BD = displacement[1]

        return index

    # def __iter__(self):
        # return 
#     def __getitem__(self, arg):
#         return self.index[arg]


cdef class ObjectIndex(_Index):
    def __init__(self, object index):
        self.keys = index
        self._initialize()
        self.reference = "object"

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys)
        
        self.FD = 0
        self.BD = length

        # Use int64
        self.index = {}
        for i in range(length):
            self.index[self.keys[i]] = i

    def get_item(self, arg):
        ret = self.index[arg]
        if self.FD <= ret and ret <= self.BD:
            return ret
        raise KeyError("Invalid key: %s" % arg)

cdef class DateTimeIndex(_Index):
    def __init__(self, index):
        """
        Index must be of type np.ndarray. If coming from pandas 
        DatetimeIndex you can do index._data._data.
        """
        self.reference = "datetime"

        if isinstance(index, np.ndarray):
            self.keys = index.view(np.int64)
        else:
            self.keys = index
        self._initialize()

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys)

        self.FD = 0
        self.BD = length

        # Use int64
        self.index = Int64to64Map(number_of_elements_hint=length, for_int=True)
        for i in range(length):
            self.index.put_int64(self.keys[i], i)
    
    def get_item(self, arg):
        if not isinstance(arg, np.int64):
            arg = arg.astype(np.int64)

        ret = self.index[arg]
        if self.FD <= ret and ret <= self.BD:
            return ret
        raise KeyError("Invalid key: %s" % arg)

    @property
    def keys_(self):
        return super().keys_[self.FD: self.BD].astype("datetime64[ns]")

