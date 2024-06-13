import numpy as np
from sloth import DataFrame

# Define numpy arrays for values, index, and columns
values_np = np.array([[1.0, 2.0, 3.0],
                        [4.0, 5.0, 6.0],
                        [7.0, 8.0, 9.0]])
index_np = np.array(['row1', 'row2', 'row3'])
columns_np = np.array(['col1', 'col2', 'col3'])

# Create the DataFrame using numpy arrays
df = DataFrame(values_np, index_np, columns_np)
print("DataFrame with numpy arrays:")
print(df)

# Create the DataFrame using Python lists (list of lists)
values_list = [[1.0, 2.0, 3.0],
                [4.0, 5.0, 6.0],
                [7.0, 8.0, 9.0]]
index_list = ['row1', 'row2', 'row3']
columns_list = ['col1', 'col2', 'col3']

df_list = DataFrame(values_list, index_list, columns_list)
print("DataFrame with Python lists:")
print(df_list)

print(dir(slice(1,5)))
print(slice(1,5).indices(1))
d = df.iloc[1:]
print(d.values)

print(d.mask)

print(df.sum(1))