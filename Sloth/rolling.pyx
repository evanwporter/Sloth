cimport numpy as np
import numpy as np

from .frame cimport Frame, Series, DataFrame

# bottleneck is faster than a pure numpy implementation
import bottleneck as bn


cdef class Rolling:
    """
    Rolling window calculations on a DataFrame.

    Parameters
    ----------
    frame : Frame
        The DataFrame on which to perform rolling calculations.
    window : int
        The size of the moving window.

    Attributes
    ----------
    frame : Frame
        The DataFrame to perform operations on.
    window : int
        The window size for rolling calculations.

    Examples
    --------
    >>> import numpy as np
    >>> from frame import Frame, DataFrame
    >>> data = np.random.randn(10, 3)
    >>> index = list(range(10))
    >>> columns = ['A', 'B', 'C']
    >>> df = DataFrame(values=data, index=index, columns=columns)
    >>> rolling = Rolling(df, window=3)

    >>> # Calculate rolling mean
    >>> rolling.mean()
    
    >>> # Calculate rolling sum
    >>> rolling.sum()
    """
    def __init__(self, Frame frame, int window):
        self.frame = frame
        self.window = window

    def __repr__(self):
        """
        Return a string representation of the Rolling object.
        
        Returns
        -------
        str
            A string representation of the Rolling object with the window size.
        """
        return "Rolling[window={}]".format(self.window)

    def mean(self):
        """
        Calculate the rolling mean of the DataFrame.

        Returns
        -------
        DataFrame
            A DataFrame containing the rolling mean values.

        Examples
        --------
        >>> rolling = Rolling(df, window=3)
        >>> rolling.mean()
        """
        return DataFrame(values=bn.move_mean(self.frame.values, window=self.window, axis=0), index=self.frame.index, columns=self.frame.columns)

    def sum(self):
        """
        Calculate the rolling sum of the DataFrame.

        Returns
        -------
        DataFrame
            A DataFrame containing the rolling sum values.

        Examples
        --------
        >>> rolling = Rolling(df, window=3)
        >>> rolling.sum()
        """
        return DataFrame(values=bn.move_sum(self.frame.values, window=self.window, axis=0), index=self.frame.index, columns=self.frame.columns)
