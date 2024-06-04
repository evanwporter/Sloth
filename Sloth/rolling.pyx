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
        return bn.move_mean(self.frame.values, window=self.window, axis=0)

    def sum(self):
        return bn.move_sum(self.frame.values, window=self.window, axis=0)