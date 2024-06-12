import dataframe as sl

def test_dataframe():
    # Create an ObjectIndex and ColumnIndex
    row_index = sl.ObjectIndex(
        {'row1': 0, 'row2': 1, 'row3': 2}, 
        ['row1', 'row2', 'row3']
    )
    col_index = sl.ColumnIndex(
        {'col1': 0, 'col2': 1}, 
        ['col1', 'col2']
    )

    # Create a DataFrame
    values = [
        [1.0, 2.0],
        [3.0, 4.0],
        [5.0, 6.0]
    ]
    df = sl.DataFrame(values, row_index, col_index)

    # Test DataFrame attributes
    print("DataFrame repr:")
    print(df.repr())
    
    print(f"DataFrame shape: {df.shape()}")
    # assert shape == (3, 2), f"Expected shape (3, 2), got {shape}"

    print("LENGTH")

    slice_ = sl.slice(0, 1, 1)

    print(type(dataframe.values()))

if __name__ == "__main__":
    test_dataframe()
