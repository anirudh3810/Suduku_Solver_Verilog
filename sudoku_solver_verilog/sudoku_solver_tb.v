`timescale 1ns/1ps
`default_nettype none

module sudoku_solver_tb;

    reg         clk;
    reg         rst;
    reg         start;
    reg [323:0] puzzle;

    wire [323:0] solution;
    wire         done;
    wire         valid;
    wire         busy;

    localparam [323:0] PUZZLE = 324'h970080000500914000082000060600020007100308004300060008060000890000591006000070035;
    localparam [323:0] EXPECTED_SOLUTION = 324'h971682543536914782482735169658429317197358624324167958765243891843591276219876435;

    integer cycles;
    integer errors;
    integer idx;

    sudoku_solver dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .puzzle_flat(puzzle),
        .solution_flat(solution),
        .done(done),
        .valid(valid),
        .busy(busy)
    );

    function [3:0] flat_cell;
        input [323:0] flat;
        input integer index;
        begin
            flat_cell = flat[(index * 4) +: 4];
        end
    endfunction

    task print_board;
        input [323:0] flat;
        integer row;
        integer col;
        integer cell_index;
        begin
            for (row = 0; row < 9; row = row + 1) begin
                $write("    ");
                for (col = 0; col < 9; col = col + 1) begin
                    cell_index = (row * 9) + col;
                    $write("%0d", flat_cell(flat, cell_index));
                    if (col != 8) begin
                        $write(" ");
                    end
                    if ((col == 2) || (col == 5)) begin
                        $write("| ");
                    end
                end
                $write("\n");
                if ((row == 2) || (row == 5)) begin
                    $display("    ---------------------");
                end
            end
        end
    endtask

    initial begin
        clk   = 1'b0;
        rst   = 1'b1;
        start = 1'b0;
        puzzle = PUZZLE;

        $display("Input Sudoku:");
        print_board(PUZZLE);

        #12 rst = 1'b0;
        #10 start = 1'b1;
        #10 start = 1'b0;

        cycles = 0;
        while (!done && (cycles < 500000)) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (!done) begin
            $display("TIMEOUT: solver did not finish after %0d cycles.", cycles);
            $finish_and_return(1);
        end

        if (!valid) begin
            $display("FAIL: solver reported that the puzzle is invalid or unsatisfiable.");
            $display("Partial board:");
            print_board(solution);
            $finish_and_return(1);
        end

        $display("Solved Sudoku after %0d cycles:", cycles);
        print_board(solution);

        errors = 0;
        for (idx = 0; idx < 81; idx = idx + 1) begin
            if (flat_cell(solution, idx) !== flat_cell(EXPECTED_SOLUTION, idx)) begin
                errors = errors + 1;
                $display(
                    "Mismatch at row %0d col %0d: got %0d expected %0d",
                    idx / 9,
                    idx % 9,
                    flat_cell(solution, idx),
                    flat_cell(EXPECTED_SOLUTION, idx)
                );
            end
        end

        if (errors == 0) begin
            $display("PASS: solution matches the expected Sudoku grid.");
        end else begin
            $display("FAIL: %0d mismatches detected.", errors);
            $finish_and_return(1);
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule

`default_nettype wire
