import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import matrix.{type Matrix}

// FFI function to set document class - only works in JavaScript
@external(javascript, "./gaussian.ffi.mjs", "setDocumentClass")
@external(erlang, "gaussian_ffi", "set_document_class")
fn set_document_class(class_name: String) -> Nil

// FFI function to get browser's preferred color scheme
@external(javascript, "./gaussian.ffi.mjs", "getPreferredColorScheme")
@external(erlang, "gaussian_ffi", "get_preferred_color_scheme")
fn get_preferred_color_scheme() -> String

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL

pub type Theme {
  Light
  Dark
}

pub type Settings {
  Settings(decimal_precision: Int)
}

pub type Model {
  Model(
    current_matrix: Matrix,
    selected_row: Option(Int),
    history: List(HistoryEntry),
    input_mode: InputMode,
    dimension_rows: String,
    dimension_cols: String,
    hovered_cell: Option(#(Int, Int)),
    preview_row: Option(#(Int, List(Float))),
    theme: Theme,
    settings: Settings,
    show_settings_modal: Bool,
  )
}

pub type HistoryEntry {
  HistoryEntry(matrix: Matrix, description: String)
}

pub type InputMode {
  SettingDimensions
  EditingMatrix(rows: Int, cols: Int, values: List(String))
  Operating
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  let preferred_scheme = get_preferred_color_scheme()
  let initial_theme = case preferred_scheme {
    "dark" -> Dark
    _ -> Light
  }
  let _ = set_document_class(preferred_scheme)
  
  #(
    Model(
      current_matrix: matrix.new(0, 0),
      selected_row: None,
      history: [],
      input_mode: SettingDimensions,
      dimension_rows: "3",
      dimension_cols: "4",
      hovered_cell: None,
      preview_row: None,
      theme: initial_theme,
      settings: Settings(decimal_precision: 3),
      show_settings_modal: False,
    ),
    effect.none(),
  )
}

// UPDATE

pub type Msg {
  UpdateDimensionRows(String)
  UpdateDimensionCols(String)
  CreateMatrix
  UpdateCell(index: Int, value: String)
  InitializeMatrix
  SelectRow(row: Int)
  PerformSwap(row: Int)
  PerformElimination(row: Int, col: Int)
  Undo
  Restart
  Deselect
  ToggleTheme
  ToggleSettingsModal
  SetDecimalPrecision(String)
  KeyPress(String)
  HoverCell(row: Int, col: Int)
  UnhoverCell
  NoOp
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UpdateDimensionRows(value) -> {
      #(Model(..model, dimension_rows: value), effect.none())
    }

    UpdateDimensionCols(value) -> {
      #(Model(..model, dimension_cols: value), effect.none())
    }

    CreateMatrix -> {
      let rows = case int.parse(model.dimension_rows) {
        Ok(r) if r > 0 && r <= 10 -> r
        _ -> 3
      }
      let cols = case int.parse(model.dimension_cols) {
        Ok(c) if c > 0 && c <= 10 -> c
        _ -> 4
      }
      let total = rows * cols
      #(
        Model(
          ..model,
          input_mode: EditingMatrix(rows, cols, list.repeat("0", total)),
        ),
        effect.none(),
      )
    }

    UpdateCell(index, value) -> {
      case model.input_mode {
        EditingMatrix(rows, cols, values) -> {
          let new_values = list.index_map(values, fn(v, i) {
            case i == index {
              True -> value
              False -> v
            }
          })
          #(
            Model(..model, input_mode: EditingMatrix(rows, cols, new_values)),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    InitializeMatrix -> {
      case model.input_mode {
        EditingMatrix(rows, cols, values) -> {
          // Parse values to floats - handles both "1" and "1.0"
          let float_values =
            values
            |> list.index_map(fn(v, idx) {
              case parse_number(v) {
                Ok(f) -> f
                Error(_) -> 0.0
              }
            })

          // Convert to matrix (list of lists)
          let matrix_data = chunk_list(float_values, cols)
          let new_matrix = matrix.from_lists(matrix_data)

          #(
            Model(
              ..model,
              current_matrix: new_matrix,
              input_mode: Operating,
              history: [],
              selected_row: None,
            ),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    SelectRow(row) -> {
      case model.selected_row {
        Some(r) if r == row ->
          #(Model(..model, selected_row: None), effect.none())
        _ -> #(Model(..model, selected_row: Some(row)), effect.none())
      }
    }

    PerformSwap(target_row) -> {
      case model.selected_row {
        Some(source_row) -> {
          case matrix.swap_rows(model.current_matrix, source_row, target_row) {
            Ok(new_matrix) -> {
              let description =
                "Swapped R" <> int.to_string(source_row) <> " ↔ R" <> int.to_string(target_row)
              #(
                Model(
                  ..model,
                  current_matrix: new_matrix,
                  selected_row: None,
                  history: [
                    HistoryEntry(model.current_matrix, description),
                    ..model.history
                  ],
                ),
                effect.none(),
              )
            }
            Error(_) -> #(model, effect.none())
          }
        }
        None -> #(model, effect.none())
      }
    }

    PerformElimination(target_row, col) -> {
      case model.selected_row {
        Some(source_row) -> {
          case
            matrix.eliminate_row(
              model.current_matrix,
              source_row,
              target_row,
              col,
            )
          {
            Ok(new_matrix) -> {
              let description =
                "Eliminated R"
                <> int.to_string(target_row)
                <> "["
                <> int.to_string(col)
                <> "] using R"
                <> int.to_string(source_row)
              #(
                Model(
                  ..model,
                  current_matrix: new_matrix,
                  selected_row: None,
                  history: [
                    HistoryEntry(model.current_matrix, description),
                    ..model.history
                  ],
                ),
                effect.none(),
              )
            }
            Error(_) -> #(model, effect.none())
          }
        }
        None -> #(model, effect.none())
      }
    }

    Undo -> {
      case model.history {
        [HistoryEntry(prev_matrix, _), ..rest] ->
          #(
            Model(
              ..model,
              current_matrix: prev_matrix,
              history: rest,
              selected_row: None,
            ),
            effect.none(),
          )
        [] -> #(model, effect.none())
      }
    }

    Restart -> {
      #(
        Model(
          current_matrix: matrix.new(0, 0),
          selected_row: None,
          history: [],
          input_mode: SettingDimensions,
          dimension_rows: "3",
          dimension_cols: "4",
          hovered_cell: None,
          preview_row: None,
          theme: model.theme,
          settings: model.settings,
          show_settings_modal: False,
        ),
        effect.none(),
      )
    }

    ToggleTheme -> {
      let new_theme = case model.theme {
        Light -> Dark
        Dark -> Light
      }
      let theme_class = case new_theme {
        Light -> "light"
        Dark -> "dark"
      }
      let _ = set_document_class(theme_class)
      #(Model(..model, theme: new_theme), effect.none())
    }
    
    ToggleSettingsModal -> {
      #(Model(..model, show_settings_modal: !model.show_settings_modal), effect.none())
    }
    
    SetDecimalPrecision(value) -> {
      let precision = case int.parse(value) {
        Ok(p) if p >= 0 && p <= 10 -> p
        _ -> model.settings.decimal_precision
      }
      #(Model(..model, settings: Settings(decimal_precision: precision)), effect.none())
    }

    Deselect -> {
      #(Model(..model, selected_row: None), effect.none())
    }

    KeyPress(key) -> {
      case key {
        "Escape" -> #(Model(..model, selected_row: None), effect.none())
        _ -> #(model, effect.none())
      }
    }

    HoverCell(row, col) -> {
      // Calculate preview if hovering over valid elimination target (not row label)
      let preview = case model.selected_row, col {
        Some(source_row), c if source_row != row && c >= 0 -> {
          case matrix.get_cell(model.current_matrix, source_row, col), 
               matrix.get_cell(model.current_matrix, row, col),
               matrix.get_row(model.current_matrix, source_row),
               matrix.get_row(model.current_matrix, row) {
            Ok(s), Ok(t), Ok(source_data), Ok(target_data) 
              if s != 0.0 && t != 0.0 -> {
              // Calculate preview
              let multiplier = 0.0 -. t /. s
              let preview_values = list.zip(target_data, source_data)
                |> list.map(fn(pair) {
                  let #(target_val, source_val) = pair
                  target_val +. multiplier *. source_val
                })
              Some(#(row, preview_values))
            }
            _, _, _, _ -> None
          }
        }
        _, _ -> None
      }
      
      #(
        Model(..model, hovered_cell: Some(#(row, col)), preview_row: preview),
        effect.none(),
      )
    }

    UnhoverCell -> {
      #(
        Model(..model, hovered_cell: None, preview_row: None),
        effect.none(),
      )
    }

    NoOp -> #(model, effect.none())
  }
}

// Helper to get guide text based on current state
fn get_guide_text(model: Model) -> String {
  case model.selected_row, model.hovered_cell {
    None, _ -> "💡 Click on a row to select it"
    Some(selected), None -> 
      "💡 Click another row to swap, or click a cell to eliminate its column"
    Some(selected), Some(#(hover_row, hover_col)) -> {
      case selected == hover_row {
        True -> "⚠️ Cannot perform operation on the same row"
        False -> {
          // Check if hovering over row label (col = -1) - this means swap
          case hover_col {
            -1 -> "✓ Click to swap R" <> int.to_string(selected) <> " ↔ R" <> int.to_string(hover_row)
            _ -> {
              // Check if elimination is possible
              let source_cell = matrix.get_cell(model.current_matrix, selected, hover_col)
              let target_cell = matrix.get_cell(model.current_matrix, hover_row, hover_col)
              
              case source_cell, target_cell {
                Ok(s), Ok(t) if s == 0.0 -> 
                  "⚠️ Cannot eliminate: source cell (R" <> int.to_string(selected) <> ") is zero"
                Ok(s), Ok(t) if t == 0.0 -> 
                  "⚠️ Cannot eliminate: target cell is already zero"
                Ok(_), Ok(_) -> 
                  "✓ Click to eliminate R" <> int.to_string(hover_row) <> "[" <> int.to_string(hover_col) <> "]"
                _, _ -> "⚠️ Invalid operation"
              }
            }
          }
        }
      }
    }
  }
}

// Helper to parse a string to float, handling both integers and floats
fn parse_number(s: String) -> Result(Float, Nil) {
  // First try parsing as float
  case float.parse(s) {
    Ok(f) -> Ok(f)
    Error(_) -> {
      // If that fails, try parsing as int and converting to float
      case int.parse(s) {
        Ok(i) -> Ok(int.to_float(i))
        Error(_) -> Error(Nil)
      }
    }
  }
}

// Format float with specified decimal precision
fn format_float(value: Float, precision: Int) -> String {
  let multiplier = case precision {
    0 -> 1.0
    1 -> 10.0
    2 -> 100.0
    3 -> 1000.0
    4 -> 10000.0
    5 -> 100000.0
    6 -> 1000000.0
    7 -> 10000000.0
    8 -> 100000000.0
    9 -> 1000000000.0
    _ -> 10000000000.0
  }
  
  let rounded = int.to_float(float.round(value *. multiplier)) /. multiplier
  let str = float.to_string(rounded)
  
  // Check if we're showing an approximation
  let original_str = float.to_string(value)
  case original_str == str {
    True -> str
    False -> "~" <> str
  }
}

// Helper function to chunk a list into sublists of given size
fn chunk_list(items: List(a), chunk_size: Int) -> List(List(a)) {
  case items {
    [] -> []
    _ -> {
      let chunk = list.take(items, chunk_size)
      let rest = list.drop(items, chunk_size)
      [chunk, ..chunk_list(rest, chunk_size)]
    }
  }
}

// VIEW

fn view_settings_modal(model: Model) -> Element(Msg) {
  html.div([
    attribute.class("fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"),
    event.on_click(ToggleSettingsModal),
  ], [
    html.div([
      attribute.class("bg-white dark:bg-gray-800 p-6 rounded-lg shadow-xl max-w-md w-full"),
      event.on_click(NoOp), // Prevent click from closing modal
    ], [
      html.h2([attribute.class("text-2xl font-bold text-gray-800 dark:text-gray-100 mb-4")], [
        element.text("Settings")
      ]),
      html.div([attribute.class("mb-4")], [
        html.label([
          attribute.class("block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"),
          attribute.for("precision-input")
        ], [
          element.text("Decimal Precision: " <> int.to_string(model.settings.decimal_precision))
        ]),
        html.input([
          attribute.id("precision-input"),
          attribute.type_("range"),
          attribute.min("0"),
          attribute.max("10"),
          attribute.value(int.to_string(model.settings.decimal_precision)),
          attribute.class("w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"),
          event.on_input(SetDecimalPrecision),
        ]),
        html.div([attribute.class("flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1")], [
          element.text("0 (integers)"),
          element.text("10 (max)")
        ])
      ]),
      html.div([attribute.class("text-sm text-gray-600 dark:text-gray-400 mb-4")], [
        element.text("Adjust how many decimal places are shown. Values with more decimals will be approximated with a ~ prefix.")
      ]),
      html.button([
        attribute.class("w-full px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors font-semibold"),
        event.on_click(ToggleSettingsModal),
      ], [
        element.text("Close")
      ])
    ])
  ])
}

fn view(model: Model) -> Element(Msg) {
  html.div([
    attribute.class("max-w-7xl mx-auto p-8 bg-gray-50 dark:bg-gray-900 min-h-screen transition-colors"),
    event.on_keydown(KeyPress),
    attribute.attribute("tabindex", "0"),
  ], [
    html.div([attribute.class("flex justify-between items-center mb-6")], [
      html.h1([attribute.class("text-3xl font-bold text-gray-800 dark:text-gray-100 border-b-4 border-green-500 pb-2")], [
        element.text("Gaussian Elimination Tool")
      ]),
      html.div([attribute.class("flex gap-2")], [
        html.button([
          attribute.class("px-3 py-2 rounded bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"),
          event.on_click(ToggleTheme),
          attribute.attribute("aria-label", "Toggle theme"),
        ], [
          element.text(case model.theme {
            Light -> "🌙"
            Dark -> "☀️"
          })
        ]),
        html.button([
          attribute.class("px-3 py-2 rounded bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"),
          event.on_click(ToggleSettingsModal),
          attribute.attribute("aria-label", "Settings"),
        ], [
          element.text("⚙️")
        ])
      ])
    ]),
    case model.show_settings_modal {
      True -> view_settings_modal(model)
      False -> element.none()
    },
    case model.input_mode {
      SettingDimensions -> view_dimension_input(model)
      EditingMatrix(rows, cols, values) -> view_matrix_input(rows, cols, values)
      Operating -> view_operating_mode(model)
    },
  ])
}

fn view_dimension_input(model: Model) -> Element(Msg) {
  html.div([attribute.class("bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md")], [
    html.h2([attribute.class("text-2xl font-semibold text-gray-700 dark:text-gray-200 mb-4")], [
      element.text("Enter Matrix Dimensions")
    ]),
    html.div([attribute.class("mb-4")], [
      html.p([attribute.class("text-gray-600 dark:text-gray-400 mb-2")], [element.text("Rows (1-10):")]),
      html.input([
        attribute.class("px-4 py-2 border-2 border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 rounded focus:border-green-500 focus:outline-none w-32 text-center"),
        attribute.type_("number"),
        attribute.value(model.dimension_rows),
        attribute.attribute("min", "1"),
        attribute.attribute("max", "10"),
        event.on_input(UpdateDimensionRows),
      ]),
    ]),
    html.div([attribute.class("mb-4")], [
      html.p([attribute.class("text-gray-600 dark:text-gray-400 mb-2")], [element.text("Columns (1-10):")]),
      html.input([
        attribute.class("px-4 py-2 border-2 border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 rounded focus:border-green-500 focus:outline-none w-32 text-center"),
        attribute.type_("number"),
        attribute.value(model.dimension_cols),
        attribute.attribute("min", "1"),
        attribute.attribute("max", "10"),
        event.on_input(UpdateDimensionCols),
      ]),
    ]),
    html.button(
      [
        attribute.class("bg-green-500 text-white px-6 py-3 rounded hover:bg-green-600 transition-colors font-medium"),
        event.on_click(CreateMatrix)
      ],
      [element.text("Create Matrix")],
    ),
  ])
}

fn view_matrix_input(rows: Int, cols: Int, values: List(String)) -> Element(Msg) {
  html.div([attribute.class("bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md")], [
    html.h2([attribute.class("text-2xl font-semibold text-gray-700 dark:text-gray-200 mb-4")], [
      element.text("Enter Matrix Values")
    ]),
    html.p([attribute.class("text-sm text-gray-500 dark:text-gray-400 mb-2")], [
      element.text("Debug: Total values = " <> int.to_string(list.length(values)) <> " | First value: " <> case list.first(values) {
        Ok(v) -> "\"" <> v <> "\""
        Error(_) -> "none"
      })
    ]),
    html.div([attribute.class("overflow-x-auto mb-4")], [
      html.table([attribute.class("border-collapse")], [
        html.tbody(
          [],
          list.range(0, rows - 1)
          |> list.map(fn(r) {
            html.tr(
              [],
              list.range(0, cols - 1)
              |> list.map(fn(c) {
                let index = r * cols + c
                let value = case list.drop(values, index) |> list.first {
                  Ok(v) -> v
                  Error(_) -> "?"
                }
                html.td([attribute.class("p-1")], [
                  html.input([
                    attribute.class("w-20 px-2 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 rounded text-center focus:border-green-500 focus:outline-none"),
                    attribute.type_("text"),
                    attribute.value(value),
                    event.on_input(fn(v) { UpdateCell(index, v) }),
                  ]),
                ])
              }),
            )
          }),
        ),
      ]),
    ]),
    html.button(
      [
        attribute.class("bg-green-500 text-white px-6 py-3 rounded hover:bg-green-600 transition-colors font-medium"),
        event.on_click(InitializeMatrix)
      ],
      [element.text("Start Operating")],
    ),
  ])
}

fn view_operating_mode(model: Model) -> Element(Msg) {
  let row_count = matrix.rows(model.current_matrix)
  let col_count = matrix.columns(model.current_matrix)
  
  html.div([attribute.class("grid grid-cols-1 lg:grid-cols-3 gap-6")], [
    html.div([attribute.class("lg:col-span-2")], [
      // Header with restart button
      html.div([attribute.class("flex justify-between items-center mb-4")], [
        html.h2([attribute.class("text-2xl font-semibold text-gray-700")], [
          element.text("Matrix Operations")
        ]),
        html.button(
          [
            attribute.class("bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600 transition-colors font-medium"),
            event.on_click(Restart)
          ],
          [element.text("↻ Restart")],
        ),
      ]),
      // Guide text
      html.div([attribute.class("bg-blue-50 dark:bg-blue-900 border-l-4 border-blue-500 dark:border-blue-400 p-4 mb-4 rounded")], [
        html.p([attribute.class("text-blue-900 dark:text-blue-100 font-medium")], [
          element.text(get_guide_text(model))
        ])
      ]),
      view_matrix_display(model),
    ]),
    html.div([], [
      view_history(model.history, model.settings.decimal_precision),
    ]),
  ])
}

fn view_matrix_display(model: Model) -> Element(Msg) {
  let row_count = matrix.rows(model.current_matrix)
  let col_count = matrix.columns(model.current_matrix)

  html.div([attribute.class("bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md")], [
    html.h2([attribute.class("text-2xl font-semibold text-gray-700 dark:text-gray-200 mb-4")], [
      element.text("Current Matrix")
    ]),
    html.div([attribute.class("overflow-x-auto mb-4")], [
      html.table([attribute.class("border-collapse text-lg")], [
        html.tbody(
          [],
          list.range(0, row_count - 1)
          |> list.map(fn(r) {
            let is_selected = case model.selected_row {
              Some(selected) -> selected == r
              None -> False
            }
            
            // Check if this row is being hovered (any cell in this row)
            let is_hovered = case model.hovered_cell {
              Some(#(hover_row, _)) -> hover_row == r
              None -> False
            }
            
            // Check if this row is being hovered as a target for elimination
            let is_hovered_target = case model.selected_row, model.hovered_cell {
              Some(selected), Some(#(hover_row, _)) -> selected != r && hover_row == r
              _, _ -> False
            }
            
            let row_class = case is_selected, is_hovered_target {
              True, _ -> "ring-4 ring-green-500 ring-inset"
              False, True -> "ring-2 ring-blue-400 ring-inset"
              False, False -> ""
            }

            html.tr([
              attribute.class(row_class <> " transition-colors"),
            ], [
              html.td([
                attribute.class(
                  "text-blue-700 dark:text-blue-200 font-bold px-4 py-3 border border-gray-300 dark:border-gray-600 cursor-pointer " <>
                  case is_selected, is_hovered {
                    True, True -> "bg-green-400 dark:bg-green-500"
                    True, False -> "bg-green-300 dark:bg-green-600"
                    False, True -> "bg-blue-200 dark:bg-blue-800"
                    False, False -> "bg-blue-100 dark:bg-blue-900"
                  }
                ),
                event.on_click(handle_row_click(model, r)),
                event.on_mouse_enter(HoverCell(r, -1)),
                event.on_mouse_leave(UnhoverCell),
              ], [
                element.text("R" <> int.to_string(r)),
              ]),
              ..list.range(0, col_count - 1)
              |> list.map(fn(c) {
                let value = case matrix.get_cell(model.current_matrix, r, c) {
                  Ok(v) -> format_float(v, model.settings.decimal_precision)
                  Error(_) -> "?"
                }
                
                // Check if we have a preview for this cell
                let preview_value = case model.preview_row {
                  Some(#(preview_row, preview_vals)) if preview_row == r -> {
                    case list.drop(preview_vals, c) |> list.first {
                      Ok(pv) -> Some(format_float(pv, model.settings.decimal_precision))
                      Error(_) -> None
                    }
                  }
                  _ -> None
                }
                
                let base_cell_class = case c == col_count - 1 {
                  True -> " border-l-4 border-l-gray-800"
                  False -> ""
                }
                
                // Base background color depends on selection state and hover
                let base_bg = case is_selected, is_hovered {
                  True, True -> " bg-green-300 dark:bg-green-600"
                  True, False -> " bg-green-200 dark:bg-green-700"
                  False, True -> " bg-gray-100 dark:bg-gray-600"
                  False, False -> " bg-white dark:bg-gray-700"
                }
                
                // Add general hover effect for cells (not used anymore, handled by base_bg)
                let general_hover = ""
                
                // Determine hover styling based on validity
                let hover_class = case model.selected_row, model.hovered_cell {
                  Some(selected), Some(#(hover_row, hover_col)) 
                    if selected != hover_row && hover_row == r && hover_col == c -> {
                    // Hovering over a different row for elimination
                    let source_cell = matrix.get_cell(model.current_matrix, selected, c)
                    let target_cell = matrix.get_cell(model.current_matrix, r, c)
                    case source_cell, target_cell {
                      Ok(s), Ok(t) if s == 0.0 || t == 0.0 -> 
                        " bg-red-100 dark:bg-red-900 border-red-500 border-4 cursor-not-allowed ring-2 ring-red-400"
                      Ok(_), Ok(_) -> " bg-green-100 dark:bg-green-800 border-green-500 border-4 cursor-pointer ring-2 ring-green-400 shadow-lg"
                      _, _ -> " cursor-pointer" <> general_hover
                    }
                  }
                  _, _ -> " cursor-pointer" <> general_hover
                }

                html.td(
                  [
                    attribute.class("px-4 py-3 border border-gray-300 dark:border-gray-600 dark:text-gray-100 text-center w-32 min-w-32 max-w-32 transition-colors" <> base_bg <> base_cell_class <> hover_class),
                    event.on_click(handle_cell_click(model, r, c)),
                    event.on_mouse_enter(HoverCell(r, c)),
                    event.on_mouse_leave(UnhoverCell),
                  ],
                  case preview_value {
                    Some(pv) -> [
                      html.div([attribute.class("font-bold")], [element.text(value)]),
                      html.div([attribute.class("text-xs text-gray-500 dark:text-gray-400 mt-1")], [
                        element.text("→ " <> pv)
                      ]),
                    ]
                    None -> [element.text(value)]
                  },
                )
              })
            ])
          }),
        ),
      ]),
    ]),
  ])
}

fn handle_row_click(model: Model, row: Int) -> Msg {
  case model.selected_row {
    Some(selected) if selected != row -> PerformSwap(row)
    Some(selected) if selected == row -> Deselect
    None -> SelectRow(row)
    _ -> NoOp
  }
}

fn handle_cell_click(model: Model, row: Int, col: Int) -> Msg {
  case model.selected_row {
    Some(selected) if selected != row -> PerformElimination(row, col)
    Some(selected) if selected == row -> Deselect
    None -> SelectRow(row)
    _ -> NoOp
  }
}

fn view_history(history: List(HistoryEntry), precision: Int) -> Element(Msg) {
  let has_history = !list.is_empty(history)
  
  html.div([attribute.class("bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md")], [
    html.div([attribute.class("flex justify-between items-center mb-4")], [
      html.h3([attribute.class("text-xl font-semibold text-gray-700 dark:text-gray-200")], [
        element.text("Operation History")
      ]),
      html.button(
        [
          attribute.class("bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors font-medium disabled:bg-gray-400 disabled:cursor-not-allowed text-sm"),
          event.on_click(Undo),
          attribute.disabled(!has_history)
        ],
        [element.text("↶ Undo")],
      ),
    ]),
    case has_history {
      True -> html.div(
        [attribute.class("space-y-4")],
        history
        |> list.reverse
        |> list.map(fn(entry: HistoryEntry) {
          html.div([attribute.class("border-l-4 border-green-500 bg-gray-50 dark:bg-gray-700 p-3 rounded")], [
            html.p([attribute.class("font-medium text-gray-700 dark:text-gray-200 mb-2")], [
              element.text(entry.description)
            ]),
            html.div([attribute.class("text-xs")], [
              view_compact_matrix(entry.matrix, precision)
            ])
          ])
        }),
      )
      False -> html.p([attribute.class("text-gray-500 dark:text-gray-400 italic")], [
        element.text("No operations yet")
      ])
    },
  ])
}

fn view_compact_matrix(mat: Matrix, precision: Int) -> Element(Msg) {
  let row_count = matrix.rows(mat)
  let col_count = matrix.columns(mat)
  
  html.table([attribute.class("border-collapse text-xs")], [
    html.tbody([], 
      list.range(0, row_count - 1)
      |> list.map(fn(r) {
        html.tr([], 
          list.range(0, col_count - 1)
          |> list.map(fn(c) {
            let value = case matrix.get_cell(mat, r, c) {
              Ok(v) -> format_float(v, precision)
              Error(_) -> "?"
            }
            let cell_class = case c == col_count - 1 {
              True -> "border-l-2 border-l-gray-600 dark:border-l-gray-400"
              False -> ""
            }
            html.td([attribute.class("px-2 py-1 border border-gray-300 dark:border-gray-600 text-center bg-white dark:bg-gray-600 dark:text-gray-100 " <> cell_class)], [
              element.text(value)
            ])
          })
        )
      })
    )
  ])
}

