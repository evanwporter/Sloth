# cython: profile=True

cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from util cimport datetime64, indice

import pandas as pd

"""
Public Variables
(Displacement Compliant)
------------------------
  * keys
"""

cdef class _Index:
    @property
    def keys(self):
        return np.asarray(self.keys_)[self.mask]

    def fast_init(self, mask: slice):
        index = self.__new__(self.__class__)

        index.index = self.index
        index.keys_ = self.keys_

        index.mask = mask

        return index
    
    # def __setattr__(self, arg, value):
    #     if arg == "FD":
    #         raise AttributeError("Attribute 'FD' cannot be modified")
    #     if arg == "BD":
    #         raise AttributeError("Attribute 'BD' cannot be modified")
    #     setattr(self, arg, value)


    # def __iter__(self):
        # return 
#     def __getitem__(self, arg):
#         return self.index[arg]


cdef class ObjectIndex(_Index):
    def __init__(self, object index):
        # Makes the index a numpy array
        self.keys_ = np.asarray(index)
        self._initialize()
        self.reference = "object"
        self.mask = slice(0, len(self.keys_), 1)

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)

        # Because the index is a bunch of python objects
        # it will be stored in a python dictionary
        self.index = {}
        for i in range(length):
            self.index[self.keys_[i]] = i

    def get_item(self, arg):
        # Grabs the exact index location of arg
        try:
            ret = self.index[arg]
        except KeyError:
            raise KeyError("%s is not a member of the index." % arg)

        # TODO: Ensures that the user is unable to access date outside of the
        # current scope of the dataframe
        # if self.FD <= ret and ret <= self.BD:
        #     return ret
        # raise KeyError("Invalid key: %s" % arg)

    # def set_item(self, arg, value):
    def to_pandas(self):
        return pd.Index(data=self.keys)
    
    def __contains__(self, item):
        return item in self.keys


cdef class DateTimeIndex(_Index):
    def __init__(self, index):
        """
        Index must be of type np.ndarray. If coming from a pandas 
        DatetimeIndex you can do index._data._data.

        Parameters
        ----------
        index : np.ndarray
            Index array.
        """
        self.reference = "datetime"

        if isinstance(index, np.ndarray):
            self.keys_ = index.view(np.int64)
        else:
            self.keys_ = index
        self._initialize()
    
    def to_pandas(self):
        return pd.DatetimeIndex(data=self.keys)

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)

        mask = slice(0, length, 1)

        # Use int64
        self.index = Int64to64Map(number_of_elements_hint=length, for_int=True)
        for i in range(length):
            self.index.put_int64(self.keys_[i], i)
    
    def get_item(self, arg):
        # Makes sure DateTime64 objects are in int64 format
        if not isinstance(arg, np.int64):
            arg_int = arg.astype(np.int64)

        ret = self.index.get_int64(arg_int)
        return ret
        # if self.FD <= ret and ret <= self.BD:
        #     return ret
        # raise KeyError("Invalid key: %s" % arg)

    # @property
    # def keys(self):
    #     return super().keys.astype("datetime64[ns]")

cdef class RangeIndex(_Index):
    """
    Using the equation:
        x = (y - b) / m
        where:
            x: desired index location 
            y: index label (passed argument)
            b: starting index value (start)
            m: interval (step)
    We can figure out the index of the row without having to go through
    the lengthy process of looking up the key in a dictionary/hash table
    """

    def __init__(self, start=0, stop=1, step=1):
        """
        Parameters
        ----------
        start : int
        stop : int
            'stop' is not used at all. The only reason that it is a parameter is 
            for symbolic reasons 
        """
        self.start = start
        self.stop = stop
        self.step = step
        
        
    def get_item(self, arg):
        return (arg - self.start) / self.step

    def to_pandas(self):
        return pd.RangeIndex(start=self.start, step=self.step)

