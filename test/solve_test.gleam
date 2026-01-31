import gleeunit
import gleeunit/should
import matrix

pub fn main() {
  gleeunit.main()
}

// Test 2x3 upper triangular matrix
// [2  1 | 5]
// [0  3 | 9]
// Solution: x2 = 3, x1 = 1
pub fn solve_2x3_test() {
  let data = [[2.0, 1.0, 5.0], [0.0, 3.0, 9.0]]
  let m = matrix.from_lists(data)
  
  let result = matrix.solve_upper_triangular(m)
  should.be_ok(result)
  
  case result {
    Ok([x1, x2]) -> {
      should.equal(x2, 3.0)
      should.equal(x1, 1.0)
    }
    _ -> should.fail()
  }
}

// Test 3x4 upper triangular matrix
// [1  2  1 | 8]
// [0  1  3 | 11]
// [0  0  2 | 4]
// Solution: x3 = 2, x2 = 5, x1 = -4
pub fn solve_3x4_test() {
  let data = [
    [1.0, 2.0, 1.0, 8.0],
    [0.0, 1.0, 3.0, 11.0],
    [0.0, 0.0, 2.0, 4.0]
  ]
  let m = matrix.from_lists(data)
  
  let result = matrix.solve_upper_triangular(m)
  should.be_ok(result)
  
  case result {
    Ok([x1, x2, x3]) -> {
      should.equal(x3, 2.0)
      should.equal(x2, 5.0)
      should.equal(x1, -4.0)
    }
    _ -> should.fail()
  }
}

// Test is_upper_triangular detection
pub fn is_upper_triangular_test() {
  let tri = [[2.0, 1.0, 5.0], [0.0, 3.0, 9.0]]
  let m_tri = matrix.from_lists(tri)
  should.be_true(matrix.is_upper_triangular(m_tri))
  
  let not_tri = [[2.0, 1.0, 5.0], [1.0, 3.0, 9.0]]
  let m_not = matrix.from_lists(not_tri)
  should.be_false(matrix.is_upper_triangular(m_not))
}

// Test error when matrix has zero diagonal
pub fn solve_zero_diagonal_test() {
  let data = [[2.0, 1.0, 5.0], [0.0, 0.0, 9.0]]
  let m = matrix.from_lists(data)
  
  let result = matrix.solve_upper_triangular(m)
  should.be_error(result)
}

// Test error when not upper triangular
pub fn solve_not_upper_triangular_test() {
  let data = [[2.0, 1.0, 5.0], [1.0, 3.0, 9.0]]
  let m = matrix.from_lists(data)
  
  let result = matrix.solve_upper_triangular(m)
  should.be_error(result)
}
