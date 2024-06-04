# cython: profile=True

cimport numpy as np
import numpy as np

from .frame cimport Frame, Series, DataFrame

# bottleneck is faster than a pure numpy implementation
import bottleneck as bn


cdef class Rolling:
    def __init__(self, Frame frame, int window):
        self.frame = frame
        self.window = window

    def __repr__(self):
        return "Rolling[window={}]".format(self.window)

    def mean(self):
        return DataFrame(values=bn.move_mean(self.frame.values, window=self.window, axis=0), index=self.frame.index, columns=self.frame.columns)

    def sum(self):
        # Note floting points may happen
        return DataFrame(values=bn.move_sum(self.frame.values, window=self.window, axis=0), index=self.frame.index, columns=self.frame.columns)
