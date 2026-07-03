$ErrorActionPreference = "Stop"

$iverilog = Get-Command iverilog -ErrorAction SilentlyContinue
if (-not $iverilog) {
    if (Test-Path "C:\iverilog\bin\iverilog.exe") {
        $iverilogPath = "C:\iverilog\bin\iverilog.exe"
    } else {
        throw "iverilog was not found. Install Icarus Verilog or update the script path."
    }
} else {
    $iverilogPath = $iverilog.Source
}

$vvp = Get-Command vvp -ErrorAction SilentlyContinue
if (-not $vvp) {
    if (Test-Path "C:\iverilog\bin\vvp.exe") {
        $vvpPath = "C:\iverilog\bin\vvp.exe"
    } else {
        throw "vvp was not found. Install Icarus Verilog or update the script path."
    }
} else {
    $vvpPath = $vvp.Source
}

& $iverilogPath -g2012 -o .\sudoku_sim .\sudoku_solver.v .\sudoku_solver_tb.v
& $vvpPath .\sudoku_sim
