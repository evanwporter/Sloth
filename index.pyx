# cython: profile=True

cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from .util cimport datetime64, timedelta64, indice, in_slice, interval_time_frame_to_timedelta

import pandas as pd

cdef class _Index:
    @property
    def keys(self):
        """
        Returns the keys of the index.

        Returns
        -------
        np.ndarray
            Array of keys.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.keys
        array(['a', 'b', 'c'], dtype='<U1')
        """
        return np.asarray(self.keys_)[self.mask]

    def _fast_init(self, mask: slice):
        """
        Quickly initializes an _Index object with a given mask.

        Parameters
        ----------
        mask : slice
            The mask to apply to the index.

        Returns
        -------
        _Index
            A new _Index object with the mask applied.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> new_idx = idx._fast_init(slice(1, 3))
        >>> new_idx.keys
        array(['b', 'c'], dtype='<U1')
        """
        index = self.__new__(self.__class__)

        index.index = self.index
        index.keys_ = self.keys_

        index.mask = mask

        return index

    @property
    def size(self):
        """
        Returns the size of the index.

        Returns
        -------
        int
            The size of the index.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.size
        3
        """
        return self.keys.size


cdef class ObjectIndex(_Index):
    """
    Initializes an ObjectIndex with the given index.

    Parameters
    ----------
    index : list
        List of objects to be indexed.

    Examples
    --------
    >>> idx = ObjectIndex(['a', 'b', 'c'])
    >>> idx.keys
    array(['a', 'b', 'c'], dtype='<U1')
    """
    def __init__(self, object index):
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
        """
        Retrieves the exact index location of the given argument.

        Parameters
        ----------
        arg : object
            The key to retrieve the index for.

        Returns
        -------
        int
            The index of the key.

        Raises
        ------
        KeyError
            If the key is not found or invalid.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.get_item('b')
        1
        >>> idx.get_item('d')
        KeyError: 'd is not a member of the index.'
        """
        try:
            ret = self.index[arg]
        except KeyError:
            raise KeyError("%s is not a member of the index." % arg)

        if in_slice(ret, self.mask.start, self.mask.stop, self.mask.step):
            return ret
        raise KeyError("Invalid key: %s" % arg)

    def __contains__(self, item):
        """
        Checks if the item is in the index.

        Parameters
        ----------
        item : object
            The item to check.

        Returns
        -------
        bool
            True if the item is in the index, False otherwise.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> 'b' in idx
        True
        >>> 'd' in idx
        False
        """
        return item in self.keys

    def __repr__(self):
        """
        Returns the string representation of the ObjectIndex.

        Returns
        -------
        str
            The string representation of the ObjectIndex.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> repr(idx)
        "ObjectIndex(array(['a', 'b', 'c'], dtype='<U1'))"
        """
        return f"ObjectIndex{repr(self.keys)[5:]}"

cdef class _RangeIndexMixin(_Index):

    def get_item(self, arg):
        """
        Retrieves an item based on its index.

        Parameters
        ----------
        arg : int
            The item to retrieve.

        Returns
        -------
        int
            The index of the item.

        Raises
        ------
        KeyError
            If the item is not in the slice.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.get_item(4)
        2
        >>> idx.get_item(5)
        KeyError: '5 not in slice'
        """
        if not in_slice(arg, self.start, self.stop, self.step):
            raise KeyError("{} not in slice".format(arg))
        return int((arg - self.start) / self.step)

    @property
    def keys_(self):
        """
        Returns the keys of the range index.

        Returns
        -------
        np.ndarray
            Array of keys.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.keys_
        array([0, 2, 4, 6, 8])
        """
        return np.arange(self.start, self.stop, self.step)

    @property
    def size(self):
        """
        Returns the size of the range index.

        Returns
        -------
        int
            The size of the index.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.size
        10
        """
        return self.stop - self.start

    def _fast_init(self, mask: slice):
        """
        Quickly initializes a RangeIndex object with a given mask.

        Parameters
        ----------
        mask : slice
            The mask to apply to the index.

        Returns
        -------
        _RangeIndexMixin
            A new _RangeIndexMixin object with the mask applied.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> new_idx = idx._fast_init(slice(2, 8, 2))
        >>> new_idx.keys_
        array([2, 4, 6])
        """
        index = self.__new__(self.__class__)

        index.start = mask.start
        index.stop = mask.stop
        index.step = mask.step

        return index

cdef class RangeIndex(_RangeIndexMixin):
    """
    Index that is roughly equivalent to numpy.arange().

    Parameters
    ----------
    start : int
        Beginning position.
    stop : int
        End position.
    step : int
        How much to increase the range every step. Must be positive.

    Examples
    --------
    >>> idx = RangeIndex(0, 10, 2)
    >>> idx.keys_
    array([0, 2, 4, 6, 8])
    >>> idx.size
    10
    """

    def __init__(self, start=0, stop=1, step=1):

        self.start = start
        self.stop = stop
        self.step = step