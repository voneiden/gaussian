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

pub type SolveError {
  NotUpperTriangular
  ZeroDiagonal
  InconsistentSystem
  WrongDimensions
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

// Check if matrix is in upper triangular form (row echelon form)
// For an augmented matrix (n×(n+1)), checks if:
// - Each row i has zeros in columns 0..i-1
// - Diagonal element at column i is non-zero
pub fn is_upper_triangular(matrix: Matrix) -> Bool {
  let row_count = rows(matrix)
  let col_count = columns(matrix)
  
  // Must be n×(n+1) augmented matrix
  case col_count == row_count + 1 {
    False -> False
    True -> {
      list.range(0, row_count - 1)
      |> list.all(fn(i) {
        // Check that columns 0..i-1 are zero
        let zeros_ok = case i {
          0 -> True  // No columns to check for row 0
          _ -> {
            list.range(0, i - 1)
            |> list.all(fn(j) {
              case get_cell(matrix, i, j) {
                Ok(val) -> val == 0.0
                Error(_) -> False
              }
            })
          }
        }
        
        // Check that diagonal element is non-zero
        let diagonal_ok = case get_cell(matrix, i, i) {
          Ok(val) -> val != 0.0
          Error(_) -> False
        }
        
        zeros_ok && diagonal_ok
      })
    }
  }
}

// Solve an upper triangular augmented matrix using back substitution
// Returns the solution vector x where Ax = b
pub fn solve_upper_triangular(matrix: Matrix) -> Result(List(Float), SolveError) {
  let row_count = rows(matrix)
  let col_count = columns(matrix)
  
  // Verify dimensions
  case col_count == row_count + 1 {
    False -> Error(WrongDimensions)
    True -> {
      // Verify it's upper triangular
      case is_upper_triangular(matrix) {
        False -> Error(NotUpperTriangular)
        True -> {
          // Perform back substitution
          // Start from the last row and work upward
          do_back_substitution(matrix, row_count - 1, [])
        }
      }
    }
  }
}

// Helper for back substitution - recursive
fn do_back_substitution(
  matrix: Matrix,
  row: Int,
  acc: List(Float),
) -> Result(List(Float), SolveError) {
  case row < 0 {
    True -> Ok(acc)
    False -> {
      // Get the row
      case get_row(matrix, row) {
        Error(_) -> Error(WrongDimensions)
        Ok(row_data) -> {
          let col_count = columns(matrix)
          let n = col_count - 1  // Number of variables
          
          // Get diagonal element
          case list.drop(row_data, row) |> list.first {
            Error(_) -> Error(ZeroDiagonal)
            Ok(diagonal) -> {
              case diagonal == 0.0 {
                True -> Error(ZeroDiagonal)
                False -> {
                  // Get b value (last column)
                  case list.drop(row_data, n) |> list.first {
                    Error(_) -> Error(WrongDimensions)
                    Ok(b) -> {
                      // Calculate: x_i = (b_i - sum(A_ij * x_j)) / A_ii
                      // We need to subtract the contribution of already-solved variables
                      let sum = list.index_fold(acc, 0.0, fn(s, x_j, j) {
                        let col_index = row + 1 + j
                        case list.drop(row_data, col_index) |> list.first {
                          Ok(a_ij) -> s +. a_ij *. x_j
                          Error(_) -> s
                        }
                      })
                      
                      let x_i = { b -. sum } /. diagonal
                      do_back_substitution(matrix, row - 1, [x_i, ..acc])
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
