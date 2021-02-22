# cython: profile=True

cimport numpy as np
import numpy as np

from copy import copy

from index cimport DateTimeIndex
from cpython cimport  str
from frame cimport Frame, Series, DataFrame

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
        self.values = frame.values
        
        self.reference = frame.reference
        
        if self.reference == "D":
            self.columns = frame.columns
        else:
            self.name = frame.name

cdef class IntegerLocation(Indexer):
    
    def __getitem__(self, arg):
        cdef int displacement
        cdef int start
        cdef int stop

        if isinstance(arg, int):
            if arg >= 0:
                displacement = self.index.FD
            else:
                displacement = self.index.BD

            # Apply the displacement
            arg = displacement + arg
            return Series(self.values[arg], index=self.columns, name=self.index.keys[arg])          

        length = len(self.values)

        y1 = arg.start
        y2 = arg.stop

        if arg.start >= arg.stop: 
            raise ValueError("%d cannot be greater than %d" % (y1, y2))

        # Less than zero
        if arg.start < 0: y1 = length - arg.start
        if arg.stop < 0: y2 = length - arg.start

        currentFD = self.index.FD
        newFD = currentFD + y1
        newBD = currentFD + y2 + 1

        # If its not an integer, then it assumes that it is a slice

        # TODO: Allow arg.step to be used
        return self.frame.fast_init(
            location="I", 
            displacement=(newFD, newBD), 
            coordinates=(y1, y2)
        )

        # if isinstance(arg, int):
            
        #     # 1d
        #     values = self.values[arg]
        #     if isinstance(values, np.ndarray):
        #         return Series(values, index=self.columns, name=list(self.index)[arg])
        #     else:
        #         # Value
        #         return values
                
        # if isinstance(arg, slice):
        #     values = self.values[arg]
        #     index = list(self.index)[arg]
            
        #     if self.values.shape[0] == 1:
        #         return Series(values=values, index=index, name=self.name)
        #     else:
        #         return DataFrame(values=values, columns=self.columns, index=index)

cdef class Location(Indexer):

    def __getitem__(self, arg):
        # if isinstance(arg, np.ndarray):
        #     return self._handle_array(arg)
            
        if isinstance(arg, slice):
            print("get")
            return self._handle_slice(arg)
        else:
            return Series(
                values=self.values[self.index.get_item(arg) - self.index.FD], 
                index=self.columns, 
                name=arg
            )
    
    cdef inline Frame _handle_slice(self, slice arg):
        A = arg.start
        B = arg.stop

        print(A, B)
        FD = self.index.get_item(A)
        BD = self.index.get_item(B) + 1

        x = FD - self.index.FD
        y = BD - self.index.FD

        if arg.start is not None:
            start = self.index.get_item(arg.start) - self.index.FD
        if arg.stop is not None:
            stop = self.index.get_item(arg.stop) - self.index.FD
        
        return self.frame.fast_init("I", displacement=(start, stop), coordinates=(x, y))

    # cdef inline Frame _handle_array(self, arg):
    #     cdef str i
    #     cdef np.int64_t[:] args = np.zeros_like(arg, dtype=np.int64)
    #     for i in arg:
    #         args[i] = self.index.get_item(i)
    #     return DataFrame(self.values[args], columns=self.columns, index=arg)
