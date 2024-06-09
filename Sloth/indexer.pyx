# cython: profile=True

cimport numpy as np
import numpy as np

from copy import copy

from .index cimport DateTimeIndex
from cpython cimport str
from .frame cimport Frame, Series, DataFrame

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
the table is queried, the solution is to simply adjust two properties: 
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
        """
        Initialize the Indexer with the given Frame.

        Parameters
        ----------
        frame : Frame
            The frame to index.

        Attributes
        ----------
        frame : Frame
            The frame to index.
        index : Any
            The index of the frame.
        reference : str
            The reference type of the frame.
        columns : Any
            The columns of the frame if reference is "D".
        name : Any
            The name of the frame if reference is not "D".
        """
        self.frame = frame
        self.index = frame.index
        
        self.reference = frame.reference
        
        if self.reference == "D":
            self.columns = frame.columns
        else:
            self.name = frame.name

    cdef slice combine_slices(self, slice mask, slice overlay, int length_mask):
        """
        Combine two slices into a single slice.

        Parameters
        ----------
        mask : slice
            The mask slice.
        overlay : slice
            The overlay slice.
        length_mask : int
            The length of the mask.

        Returns
        -------
        slice
            The combined slice.
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
        Calculate the final index for a single value.

        Parameters
        ----------
        mask : slice
            The mask slice.
        overlay : int
            The overlay value.

        Returns
        -------
        int
            The calculated index.
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
        Get item(s) from the frame using integer location.

        Parameters
        ----------
        arg : int or slice
            The integer or slice to index.

        Returns
        -------
        Series or DataFrame
            The indexed data.

        Examples
        --------
        >>> iloc[5]
        Series(...)

        >>> iloc[2:8]
        DataFrame(...)
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
        """
        Get item(s) from the frame using label-based location.

        Parameters
        ----------
        arg : int, slice, or str
            The label, slice, or array to index.

        Returns
        -------
        Series or DataFrame
            The indexed data.

        Examples
        --------
        >>> loc['row_label']
        Series(...)

        >>> loc['start_label':'end_label']
        DataFrame(...)
        """
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
        
cdef class iAT(Indexer):
    
    def __getitem__(self, arg):
        """
        Get item from the frame using integer-based indexing.

        Parameters
        ----------
        arg : tuple
            A tuple of two integers representing row and column indices.

        Returns
        -------
        Any
            The indexed value.

        Raises
        ------
        ValueError
            If the length of the argument tuple is not 2.

        Examples
        --------
        >>> iat[3, 5]
        42
        """
        if len(arg) != 2:
            raise ValueError("Must pass two values.")

        return self.values[arg[0], arg[1]]
