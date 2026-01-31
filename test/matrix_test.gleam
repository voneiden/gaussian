import gleeunit/should
import matrix

pub fn new_matrix_test() {
  let mat = matrix.new(3, 4)
  matrix.rows(mat) |> should.equal(3)
  matrix.columns(mat) |> should.equal(4)
}

pub fn from_lists_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0, 3.0],
      [4.0, 5.0, 6.0],
    ])
  matrix.rows(mat) |> should.equal(2)
  matrix.columns(mat) |> should.equal(3)
}

pub fn get_cell_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0, 3.0],
      [4.0, 5.0, 6.0],
    ])

  matrix.get_cell(mat, 0, 0) |> should.equal(Ok(1.0))
  matrix.get_cell(mat, 0, 2) |> should.equal(Ok(3.0))
  matrix.get_cell(mat, 1, 1) |> should.equal(Ok(5.0))
  matrix.get_cell(mat, 2, 0) |> should.equal(Error(Nil))
}

pub fn set_cell_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0],
      [3.0, 4.0],
    ])

  let result = matrix.set_cell(mat, 1, 1, 99.0)
  result
  |> should.be_ok
  |> matrix.get_cell(1, 1)
  |> should.equal(Ok(99.0))
}

pub fn swap_rows_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0, 3.0],
      [4.0, 5.0, 6.0],
      [7.0, 8.0, 9.0],
    ])

  let result = matrix.swap_rows(mat, 0, 2)
  result |> should.be_ok

  let swapped = result |> should.be_ok
  matrix.get_row(swapped, 0) |> should.equal(Ok([7.0, 8.0, 9.0]))
  matrix.get_row(swapped, 2) |> should.equal(Ok([1.0, 2.0, 3.0]))
  matrix.get_row(swapped, 1) |> should.equal(Ok([4.0, 5.0, 6.0]))
}

pub fn swap_rows_same_row_error_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0],
      [3.0, 4.0],
    ])

  matrix.swap_rows(mat, 1, 1) |> should.equal(Error(matrix.SameRowError))
}

pub fn swap_rows_out_of_bounds_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0],
      [3.0, 4.0],
    ])

  matrix.swap_rows(mat, 0, 5) |> should.equal(Error(matrix.RowOutOfBounds))
}

pub fn eliminate_row_test() {
  // Test case: eliminate R1[0] using R0
  // R0 = [2.0, 4.0, 6.0]
  // R1 = [1.0, 2.0, 3.0]
  // multiplier = -(1.0 / 2.0) = -0.5
  // new R1 = [1.0, 2.0, 3.0] + (-0.5) * [2.0, 4.0, 6.0]
  //        = [1.0 - 1.0, 2.0 - 2.0, 3.0 - 3.0]
  //        = [0.0, 0.0, 0.0]
  let mat =
    matrix.from_lists([
      [2.0, 4.0, 6.0],
      [1.0, 2.0, 3.0],
    ])

  let result = matrix.eliminate_row(mat, 0, 1, 0)
  result |> should.be_ok

  let eliminated = result |> should.be_ok
  matrix.get_row(eliminated, 1) |> should.equal(Ok([0.0, 0.0, 0.0]))
  matrix.get_row(eliminated, 0) |> should.equal(Ok([2.0, 4.0, 6.0]))
}

pub fn eliminate_row_different_column_test() {
  // Test case: eliminate R1[1] using R0
  // R0 = [1.0, 3.0, 5.0]
  // R1 = [2.0, 6.0, 10.0]
  // At column 1:
  // multiplier = -(6.0 / 3.0) = -2.0
  // new R1 = [2.0, 6.0, 10.0] + (-2.0) * [1.0, 3.0, 5.0]
  //        = [2.0 - 2.0, 6.0 - 6.0, 10.0 - 10.0]
  //        = [0.0, 0.0, 0.0]
  let mat =
    matrix.from_lists([
      [1.0, 3.0, 5.0],
      [2.0, 6.0, 10.0],
    ])

  let result = matrix.eliminate_row(mat, 0, 1, 1)
  result |> should.be_ok

  let eliminated = result |> should.be_ok
  matrix.get_row(eliminated, 1) |> should.equal(Ok([0.0, 0.0, 0.0]))
}

pub fn eliminate_row_zero_source_test() {
  let mat =
    matrix.from_lists([
      [0.0, 2.0, 3.0],
      [1.0, 4.0, 5.0],
    ])

  matrix.eliminate_row(mat, 0, 1, 0)
  |> should.equal(Error(matrix.ZeroValueError))
}

pub fn eliminate_row_zero_target_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0, 3.0],
      [0.0, 4.0, 5.0],
    ])

  matrix.eliminate_row(mat, 0, 1, 0)
  |> should.equal(Error(matrix.ZeroValueError))
}

pub fn eliminate_row_same_row_error_test() {
  let mat =
    matrix.from_lists([
      [1.0, 2.0],
      [3.0, 4.0],
    ])

  matrix.eliminate_row(mat, 1, 1, 0)
  |> should.equal(Error(matrix.SameRowError))
}
