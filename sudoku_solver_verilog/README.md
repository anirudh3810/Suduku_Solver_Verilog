# Verilog Sudoku Solver

This project implements a working 9x9 Sudoku solver in Verilog. The design follows the same broad direction as the reference proposal: a testbench loads a puzzle, the solver validates the clues, and a stack-based search engine fills the empty cells until the solved board is produced.

## Files

- `sudoku_solver.v`: main solver module
- `sudoku_solver_tb.v`: self-checking testbench with a sample Sudoku
- `run_test.ps1`: Windows helper script that compiles and runs the testbench

## Solver architecture

The solver uses a compact and simulation-friendly hardware structure:

1. The input puzzle is flattened into `81 x 4-bit` cells.
2. Every zero-valued cell is recorded in an `empty_pos` stack.
3. The initial board is checked to make sure the clues do not violate Sudoku rules.
4. The solver walks through the empty cells one by one.
5. For each empty cell, it tries digits `1` through `9`.
6. If a digit is legal in its row, column, and 3x3 box, the digit is written and the solver advances.
7. If no digit works, the solver backtracks to the previous empty cell and increments the previous guess.

This is an iterative depth-first search with explicit state stored in registers, so it behaves like a hardware state machine rather than a recursive software function.

## Module interface

```verilog
module sudoku_solver (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [323:0] puzzle_flat,
    output reg  [323:0] solution_flat,
    output reg          done,
    output reg          valid,
    output reg          busy
);
```

### Signals

- `puzzle_flat`: 81 cells packed as 4-bit nibbles, row-major order
- `solution_flat`: solved board in the same packed format
- `start`: pulse high for one cycle to begin solving
- `busy`: high while the solver is working
- `done`: high when the solver has finished
- `valid`: high if the puzzle was solved successfully, low if the clues were invalid or no solution was found

## Included sample puzzle

The testbench uses this Sudoku:

```text
5 3 0 | 0 7 0 | 0 0 0
6 0 0 | 1 9 5 | 0 0 0
0 9 8 | 0 0 0 | 0 6 0
---------------------
8 0 0 | 0 6 0 | 0 0 3
4 0 0 | 8 0 3 | 0 0 1
7 0 0 | 0 2 0 | 0 0 6
---------------------
0 6 0 | 0 0 0 | 2 8 0
0 0 0 | 4 1 9 | 0 0 5
0 0 0 | 0 8 0 | 0 7 9
```

Expected solution:

```text
5 3 4 | 6 7 8 | 9 1 2
6 7 2 | 1 9 5 | 3 4 8
1 9 8 | 3 4 2 | 5 6 7
---------------------
8 5 9 | 7 6 1 | 4 2 3
4 2 6 | 8 5 3 | 7 9 1
7 1 3 | 9 2 4 | 8 5 6
---------------------
9 6 1 | 5 3 7 | 2 8 4
2 8 7 | 4 1 9 | 6 3 5
3 4 5 | 2 8 6 | 1 7 9
```

## How to run

If you have Icarus Verilog installed:

```powershell
iverilog -g2012 -o sudoku_sim sudoku_solver.v sudoku_solver_tb.v
vvp sudoku_sim
```

On Windows, you can also run:

```powershell
.\run_test.ps1
```

The testbench prints the input puzzle, prints the solved board, and checks the result against the expected solution. If everything is correct, it ends with:

```text
PASS: solution matches the expected Sudoku grid.
```

## Notes

- The implementation is written to be easy to understand and verify in simulation.
- It is a complete Sudoku solver for standard 9x9 puzzles, not just a single-position filler.
- The project can be extended later with candidate masks, naked pairs, hidden pairs, or display/input logic if you want to move closer to the full FPGA proposal.
