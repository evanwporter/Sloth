# # import sloth as sl

# # def test_dataframe():
# #     # Create an ObjectIndex and ColumnIndex
# #     row_index = sl.ObjectIndex(
# #         {'row1': 0, 'row2': 1, 'row3': 2}, 
# #         ['row1', 'row2', 'row3']
# #     )
# #     col_index = sl.ColumnIndex(
# #         {'col1': 0, 'col2': 1}, 
# #         ['col1', 'col2']
# #     )

# #     # Create a DataFrame
# #     values = [
# #         [1.0, 2.0],
# #         [3.0, 4.0],
# #         [5.0, 6.0]
# #     ]
# #     df = sl.DataFrame(values, row_index, col_index)

# #     # Test DataFrame attributes
# #     print("DataFrame repr:")
# #     print(df.repr())
    
# #     print(f"DataFrame shape: {df.shape()}")
# #     # assert shape == (3, 2), f"Expected shape (3, 2), got {shape}"

# #     print("LENGTH")

# #     slice_ = sl.slice(0, 1, 1)

# #     # print(df.get_mask().get_step())

# #     print(df.loc["row1"])

# # if __name__ == "__main__":
# #     test_dataframe()
# import numpy as np
# from sloth import DataFrame, ObjectIndex, ColumnIndex, slice

# def test_dataframe():
#     values = [
#         [1.0, 2.0, 3.0],
#         [4.0, 5.0, 6.0],
#         [7.0, 8.0, 9.0]
#     ]

#     index = np.array(["row1", "row2", "row3"])
#     columns = np.array(["col1", "col2", "col3"])

#     df = DataFrame(values, index, columns)

#     print("DataFrame initialized:")
#     print(df.repr())

#     print("Accessing 'row1':")
#     print(df.loc["row1"])

# test_dataframe()


import numpy as np
from sloth import DataFrame

def test_dataframe():
    values = [
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, 9.0]
    ]

    index_np = np.array(["row1", "row2", "row3"])
    columns_np = np.array(["col1", "col2", "col3"])

    # Create DataFrame with NumPy arrays
    df_np = DataFrame(values, index_np, columns_np)

    print("DataFrame initialized with NumPy arrays:")
    print(df_np.repr())

    index_list = ["row1", "row2", "row3"]
    columns_list = ["col1", "col2", "col3"]

    # Create DataFrame with Python lists
    df_list = DataFrame(values, index_list, columns_list)

    print("DataFrame initialized with Python lists:")
    print(df_list.repr())

    print("Accessing 'row1' in NumPy DataFrame:")
    print(df_np.loc["row1"])

    print("Accessing 'row1' in List DataFrame:")
    print(df_list.loc["row1"])

    print(df_np.sum(1))

test_dataframe()
