"""
A Sphinx example and cheat sheet.

Documenting Python Code
#######################

For documenting Python code, see ``module/__init__.py`` or the code example below:

.. code-block:: python

    class AClass:
        \"\"\"
        Class docstring, with reference to the :mod:`module`, or another class
        :class:`module.AnotherClass` and its function :func:`module.AnotherClass.foo`.
        \"\"\"
    
    class AnotherClass:
        \"\"\"
        Another class' docstring.
        \"\"\"
        
        def foo(arg1, arg2):
            \"\"\"
            A method's docstring with parameters and return value.
            
            Use all the cool Sphinx capabilities in this description, e.g. to give
            usage examples ...
            
            :Example:
    
            >>> another_class.foo('', AClass())        
            
            :param arg1: first argument
            :type arg1: string
            :param arg2: second argument
            :type arg2: :class:`module.AClass`
            :return: something
            :rtype: string
            :raises: TypeError
            \"\"\"
            
            return '' + 1
"""

from .frame import DataFrame, Series

from .index import RangeIndex, ObjectIndex, PeriodIndex, DateTimeIndex
