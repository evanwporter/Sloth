# cython: profile=True

cimport numpy as np
import numpy as np

from frame cimport Frame, Series, DataFrame

cdef class Rolling:
    def __init__(self, Frame frame, int window):
        self.frame = frame
        self.window = window

    def __repr__(self):
        return "Rolling[window={}]".format(self.window)