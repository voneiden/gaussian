# gaussian

[![Package Version](https://img.shields.io/hexpm/v/gaussian)](https://hex.pm/packages/gaussian)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gaussian/)

A visual Gaussian elimination tool for the browser, built with Gleam and Lustre.

## Features

- **Interactive Matrix Input**: Create augmented matrices of any size (up to 10×10)
- **Row Operations**: 
  - **Swap**: Click a row to select it, then click another row to swap them
  - **Elimination**: Click a row to select it, then click a cell in another row to eliminate that column
- **Operation History**: View all operations performed on the matrix
- **Undo Support**: Step backwards through your operations
- **Visual Feedback**: Selected rows are highlighted, augmented column is visually separated

## Usage

### Development

Start the development server with hot-reload:

```sh
gleam run -m lustre/dev start
```

Then open http://localhost:1234 in your browser.

The project uses Tailwind CSS v4 for styling. The CSS entry point is at `src/gaussian.css`.

### How to Use the Tool

1. **Enter Dimensions**: Specify the number of rows and columns for your augmented matrix
2. **Enter Values**: Fill in the matrix values (supports decimals)
3. **Start Operating**: Begin performing row operations
4. **Select a Row**: Click on any row to select it (highlighted in green)
5. **Perform Operations**:
   - **Swap**: Click another row to swap positions
   - **Eliminate**: Click a cell in another row to eliminate that column using the selected row
6. **Undo**: Use the Undo button to revert operations
7. **View History**: See all operations performed in the history panel

### Row Elimination

When you select a source row and click a cell in a target row:
- The tool calculates the multiplier needed to eliminate that column
- Both the source cell and target cell must be non-zero
- The operation adds a multiple of the source row to the target row

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam format src test  # Format code
```

## Building for Production

```sh
gleam run -m lustre/dev build --outdir=dist
```

This generates the compiled JavaScript and HTML in the `dist` directory.

