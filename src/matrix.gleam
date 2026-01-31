import gleam/list
import gleam/result

pub type Matrix =
  List(List(Float))

pub type RowOperation {
  Swap(row1: Int, row2: Int)
  Eliminate(source_row: Int, target_row: Int, column: Int)
}

pub type OperationError {
  RowOutOfBounds
  ColumnOutOfBounds
  ZeroValueError
  SameRowError
}

pub fn new(rows: Int, cols: Int) -> Matrix {
  list.repeat(list.repeat(0.0, cols), rows)
}

pub fn from_lists(data: List(List(Float))) -> Matrix {
  data
}

pub fn rows(matrix: Matrix) -> Int {
  list.length(matrix)
}

pub fn columns(matrix: Matrix) -> Int {
  matrix
  |> list.first
  |> result.map(list.length)
  |> result.unwrap(0)
}

pub fn get_cell(matrix: Matrix, row: Int, col: Int) -> Result(Float, Nil) {
  matrix
  |> list.drop(row)
  |> list.first
  |> result.try(fn(row_data) {
    row_data
    |> list.drop(col)
    |> list.first
  })
}

pub fn set_cell(
  matrix: Matrix,
  row: Int,
  col: Int,
  value: Float,
) -> Result(Matrix, Nil) {
  matrix
  |> list.index_map(fn(row_data, row_idx) {
    case row_idx == row {
      True ->
        row_data
        |> list.index_map(fn(cell, col_idx) {
          case col_idx == col {
            True -> value
            False -> cell
          }
        })
      False -> row_data
    }
  })
  |> Ok
}

pub fn get_row(matrix: Matrix, row: Int) -> Result(List(Float), Nil) {
  matrix
  |> list.drop(row)
  |> list.first
}

pub fn set_row(matrix: Matrix, row: Int, row_data: List(Float)) -> Matrix {
  matrix
  |> list.index_map(fn(r, idx) {
    case idx == row {
      True -> row_data
      False -> r
    }
  })
}

pub fn swap_rows(
  matrix: Matrix,
  row1: Int,
  row2: Int,
) -> Result(Matrix, OperationError) {
  case row1 == row2 {
    True -> Error(SameRowError)
    False -> {
      let row_count = rows(matrix)
      case row1 >= 0 && row1 < row_count && row2 >= 0 && row2 < row_count {
        True -> {
          use r1 <- result.try(
            get_row(matrix, row1) |> result.replace_error(RowOutOfBounds),
          )
          use r2 <- result.try(
            get_row(matrix, row2) |> result.replace_error(RowOutOfBounds),
          )

          matrix
          |> set_row(row1, r2)
          |> set_row(row2, r1)
          |> Ok
        }
        False -> Error(RowOutOfBounds)
      }
    }
  }
}

pub fn eliminate_row(
  matrix: Matrix,
  source_row: Int,
  target_row: Int,
  column: Int,
) -> Result(Matrix, OperationError) {
  case source_row == target_row {
    True -> Error(SameRowError)
    False -> {
      let row_count = rows(matrix)
      let col_count = columns(matrix)

      case
        source_row >= 0
        && source_row < row_count
        && target_row >= 0
        && target_row < row_count
        && column >= 0
        && column < col_count
      {
        True -> {
          use source_cell <- result.try(
            get_cell(matrix, source_row, column)
            |> result.replace_error(RowOutOfBounds),
          )
          use target_cell <- result.try(
            get_cell(matrix, target_row, column)
            |> result.replace_error(RowOutOfBounds),
          )

          case source_cell == 0.0 || target_cell == 0.0 {
            True -> Error(ZeroValueError)
            False -> {
              let multiplier = 0.0 -. target_cell /. source_cell

              use source_data <- result.try(
                get_row(matrix, source_row)
                |> result.replace_error(RowOutOfBounds),
              )
              use target_data <- result.try(
                get_row(matrix, target_row)
                |> result.replace_error(RowOutOfBounds),
              )

              let new_target_row =
                list.zip(target_data, source_data)
                |> list.map(fn(pair) {
                  let #(target_val, source_val) = pair
                  target_val +. multiplier *. source_val
                })

              matrix
              |> set_row(target_row, new_target_row)
              |> Ok
            }
          }
        }
        False -> Error(RowOutOfBounds)
      }
    }
  }
}
