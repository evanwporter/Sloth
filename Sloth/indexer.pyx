# cython: profile=True

cimport numpy as np
import numpy as np

from copy import copy

from .index cimport DateTimeIndex
from cpython cimport str
from .frame cimport Frame, Series, DataFrame

# from util cimport _normalize_slice

"""
Front Displacement (FD) & Back Displacement (BD)

When a DF user indexes a portion of a df. Say on a 10x10 df, the user 
wants row 3 through row 7. Obviously a new df must be created to show 
the user. There are two ways of going about this. The first way is to 
create an entirely new df, this means that the index hashmap will need 
to be redone. This is a quick process when the size of the hashmap is 
smaller, however as the index grows bigger, the number of values to hash
increases thus it becomes slower over time.

Instead of adjusting the values, the index and the columns every time 
the table is queried, the solution is to siimply adjust two properties: 
the Front Displacement (FD) and the Back Displacement (BD). Let's say we
have a 10x10 table, and we want to query rows 2-8. 
Current Index Hash Map:
    {"Row 1": 0, "Row 2": 1: "Row 3": 2, ... "Row 10": 9}
Instead of creating a new index/hash map for each row:
    {"Row 2": 1: "Row 3": 2, ... " Row 8": 7}
All we need to do is adjust the FD to 1, and the BD to 7. Then when
something happens that requires the queried table, such as view table,
then a renderer table is shown with values[FD:BD] and index[FD:BD]
"""

cdef class Indexer:
    
    def __init__(self, Frame frame):
        self.frame = frame
        self.index = frame.index
        
        self.reference = frame.reference
        
        if self.reference == "D":
            self.columns = frame.columns
        else:
            self.name = frame.name

    cdef slice combine_slices(self, slice mask, slice overlay, int length_mask):
        """
        This function is for handling slices.
        """
        # Normalize mask and overlay
        cdef int mask_start = 0 if mask.start is None else mask.start
        cdef int mask_stop = length_mask if mask.stop is None else mask.stop
        cdef int mask_step = 1 if mask.step is None else mask.step

        mask = slice(mask_start, mask_stop, mask_step)
        length_overlay = (mask.stop - mask.start + (mask.step - 1)) // mask.step

        cdef int overlay_start = 0 if overlay.start is None else overlay.start
        cdef int overlay_stop = length_overlay if overlay.stop is None else overlay.stop
        cdef int overlay_step = 1 if overlay.step is None else overlay.step

        overlay = slice(overlay_start, overlay_stop, overlay_step)
        
        # Calculate the start, stop, and step for the final slice
        cdef int start, stop, step
        start = mask.start + (overlay.start * mask.step)
        stop = mask.start + (overlay.stop * mask.step)
        step = mask.step * overlay.step
        
        return slice(start, stop, step)


    def calculate_index(self, mask, overlay):
        """
        This function is for handling single values ie: strings or ints.
        """
        # Normalize the slice to ensure it has start, stop, and step
        start = mask.start if mask.start is not None else 0
        step = mask.step if mask.step is not None else 1

        # Calculate the final index
        index = start + (overlay * step)

        return index
        
cdef class IntegerLocation(Indexer):
    
    def __getitem__(self, arg):
        """
        There are two (maybe 3) possible values of arg:
         (1) single integer
         (2) slice
        """
        cdef int displacement
        cdef int start
        cdef int stop

        if isinstance(arg, int):
            arg = self.calculate_index(self.frame.mask, arg)
            return Series(self.frame.values_[arg], index=self.frame.columns.keys_, name=self.index.keys_[arg])    
        if isinstance(arg, slice):
            arg = self.combine_slices(self.frame.mask, arg, len(self.index.keys_))
            return self.frame._fast_init(arg)
            
cdef class Location(Indexer):

    def __getitem__(self, arg):
        # if isinstance(arg, np.ndarray):
        #     return self._handle_array(arg)
        
        if isinstance(arg, slice):
            arg = slice(
                self.index.get_item(arg.start), 
                self.index.get_item(arg.stop) if arg.stop is not None else self.index.size, 
                arg.step
            )
            arg = self.combine_slices(self.frame.mask, arg, len(self.index.keys_))
            return self.frame._fast_init(arg) 
        else: # single value
            arg = self.calculate_index(self.frame.mask, self.index.get_item(arg))
            return Series(self.frame.values_[arg], index=self.frame.columns.keys_, name=self.index.keys_[arg])         
        
        # else:
        #     return Series(
        #         values=self.frame.values_[self.index.get_item(arg) - self.index.FD], 
        #         index=self.columns, 
        #         name=arg
        #     )
    
    # cdef inline Frame _handle_slice(self, slice arg):
    #     A = arg.start
    #     B = arg.stop

    #     print(A, B)
    #     FD = self.index.get_item(A)
    #     BD = self.index.get_item(B) + 1

    #     x = FD - self.index.FD
    #     y = BD - self.index.FD

    #     if arg.start is not None:
    #         start = self.index.get_item(arg.start) - self.index.FD
    #     if arg.stop is not None:
    #         stop = self.index.get_item(arg.stop) - self.index.FD
        
    #     return self.frame._fast_init("I", displacement=(start, stop), coordinates=(x, y))

    # cdef inline Frame _handle_array(self, arg):
    #     cdef str i
    #     cdef np.int64_t[:] args = np.zeros_like(arg, dtype=np.int64)
    #     for i in arg:
    #         args[i] = self.index.get_item(i)
    #     return DataFrame(self.values[args], columns=self.columns, index=arg)

cdef class iAT(Indexer):
    
    def __getitem__(self, arg):
   
        if len(arg) != 2:
            raise ValueError("Must pass two values.")

        return self.values[arg[0], arg[1]]