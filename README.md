# gaussian

A visual Gaussian elimination tool for the browser, built with Gleam and Lustre.

🌐 **Live Demo**: [https://voneiden.github.io/gaussian](https://voneiden.github.io/gaussian)

> **Note**: This project is 100% vibe coded using GitHub Copilot CLI. It was created as a demonstration of AI-assisted software development, from initial planning through implementation, testing, and deployment setup.

## Features

- **Interactive Matrix Input**: Create augmented matrices (Ax = b format) with customizable dimensions
- **Row Operations**: 
  - **Swap**: Click a row to select it, then click another row to swap them
  - **Elimination**: Click a row to select it, then click a cell in another row to eliminate that column
- **Visual Feedback**: Hover previews show operation results before applying
- **Operation History**: View all operations performed on the matrix with undo support
- **Automatic Solution**: Detects upper triangular form and solves the system using back substitution
- **Dark Mode**: Automatic theme detection based on system preferences with manual toggle
- **Precision Control**: Adjustable decimal precision (0-10 decimal places)
- **Input Validation**: Real-time validation with helpful error messages

## Deployment to GitHub Pages

This project is configured for automatic deployment to GitHub Pages using GitHub Actions.

### Initial Setup

1. **Enable GitHub Pages** in your repository settings:
   - Go to Settings → Pages
   - Under "Build and deployment", set Source to "GitHub Actions"

2. **Push to main branch**: The workflow in `.github/workflows/deploy.yml` will automatically:
   - Build the Gleam project
   - Compile to minified JavaScript
   - Process Tailwind CSS
   - Deploy to GitHub Pages

### Manual Deployment

To publish a new version:

```sh
# Make your changes and commit
git add .
git commit -m "Your changes"
git push origin main
```

The GitHub Actions workflow will automatically build and deploy. Your site will be available at:
`https://<username>.github.io/gaussian/`

### Testing Production Build Locally

To test the production build before deploying:

```sh
# Build for production
gleam run -m lustre/dev build --minify --outdir=dist

# Serve locally
cd dist
python3 -m http.server 8000
# Visit http://localhost:8000
```

## Usage

### Development

Start the development server with hot-reload:

```sh
gleam run -m lustre/dev start
```

Then open http://localhost:1234 in your browser.

The project uses Tailwind CSS v4 for styling. The CSS entry point is at `src/gaussian.css`.

### How to Use the Tool

1. **Enter Matrix Size**: Specify the number of equations/unknowns (e.g., 3 for a 3×3 system)
2. **Enter Values**: Fill in the coefficient matrix A and the constant vector b
3. **Start Operating**: Begin performing row operations
4. **Select a Row**: Click on any row label to select it (highlighted in green)
5. **Perform Operations**:
   - **Swap**: Click another row label to swap positions
   - **Eliminate**: Click a cell to eliminate that column using the selected row
6. **View Previews**: Hover over cells to see what the result would be
7. **Undo**: Use the Undo button in the history panel to revert operations
8. **Solve**: Once in upper triangular form, click "Solve" to get the solution

### Row Elimination

When you select a source row and click a cell in a target row:
- The tool calculates the multiplier needed to eliminate that column
- Both the source cell and target cell must be non-zero
- The operation adds a multiple of the source row to the target row
- Formula: new_target = target + (-(target_cell / source_cell)) × source

## Project Structure

```
gaussian/
├── src/
│   ├── gaussian.gleam      # Main Lustre application (~1065 lines)
│   ├── gaussian.css        # Tailwind v4 configuration
│   ├── gaussian.ffi.mjs    # JavaScript FFI (theme, localStorage)
│   ├── gaussian_ffi.erl    # Erlang FFI stubs
│   └── matrix.gleam        # Matrix operations (~290 lines)
├── test/
│   ├── matrix_test.gleam   # Matrix operation tests (13 tests)
│   └── solve_test.gleam    # Solution detection tests (5 tests)
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions deployment workflow
└── gleam.toml              # Project configuration
```

## Development

### Running Locally

```sh
# Install dependencies
gleam deps download

# Start development server with hot-reload
gleam run -m lustre/dev start
# Visit http://localhost:1234
```

### Running Tests

```sh
gleam test  # Run all tests (18 tests)
gleam check # Check for warnings
gleam format src test  # Format code
```

## Building for Production

```sh
# Build minified production bundle
gleam run -m lustre/dev build --minify --outdir=dist
```

This generates optimized files in the `dist` directory:
- `index.html` - Entry point
- `gaussian.js` - Minified JavaScript bundle (~82KB)
- `gaussian.css` - Compiled Tailwind CSS (~20KB)

## Technical Details

- **Language**: Gleam (compiles to JavaScript)
- **UI Framework**: Lustre (Elm-inspired)
- **Styling**: Tailwind CSS v4
- **Tests**: 18 tests (gleeunit)
- **Zero compiler warnings**

### Key Implementation Notes

- Float parsing requires special handling on JS target (supports "1" and "1.0")
- Hover state tracked in model for precise visual control
- Dark mode uses FFI to manipulate document.documentElement classes
- Back substitution uses recursive algorithm with accumulator pattern
- All operations preserve full matrix state for reliable undo

## License

MIT
