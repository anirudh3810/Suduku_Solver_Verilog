`timescale 1ns / 1ps

// Sequential 9x9 Sudoku solver.
//
// Input encoding:
//   puzzle_in[cell*4 +: 4] holds one cell, where cell = row*9 + column.
//   0 means blank, 1..9 are fixed givens. Values 10..15 are rejected.
//
// Output encoding:
//   solution_out uses the same packing after done=1 and solved=1.
//
// The core uses deterministic depth-first backtracking. It is intentionally
// compact and easy to integrate: pulse start high for one clock, then wait for
// done. If the puzzle is valid and solvable, solved will be high.
module sudoku_solver #(
    parameter MAX_CYCLES = 32'd10000000
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [323:0] puzzle_in,
    output reg         done,
    output reg         solved,
    output reg         invalid,
    output reg  [323:0] solution_out,
    output reg  [31:0] cycles
);

    localparam S_IDLE           = 4'd0;
    localparam S_CHECK_INPUT    = 4'd1;
    localparam S_VALIDATE       = 4'd2;
    localparam S_SOLVE          = 4'd3;
    localparam S_TRY_VALUE      = 4'd4;
    localparam S_BACKTRACK      = 4'd5;
    localparam S_BACKTRACK_SKIP = 4'd6;
    localparam S_PACK_OUTPUT    = 4'd7;
    localparam S_DONE           = 4'd8;

    reg [3:0] grid [0:80];
    reg       fixed_cell [0:80];

    reg [3:0] state;
    reg [6:0] idx;
    reg [6:0] validate_idx;
    reg [3:0] try_value;
    reg       input_bad;

    integer i;

    function is_legal;
        input [6:0] pos;
        input [3:0] value;
        integer row;
        integer col;
        integer box_row;
        integer box_col;
        integer j;
        integer check_pos;
        begin
            is_legal = 1'b1;

            if (value < 4'd1 || value > 4'd9) begin
                is_legal = 1'b0;
            end else begin
                row = pos / 9;
                col = pos % 9;

                for (j = 0; j < 9; j = j + 1) begin
                    check_pos = row * 9 + j;
                    if (check_pos != pos && grid[check_pos] == value) begin
                        is_legal = 1'b0;
                    end
                end

                for (j = 0; j < 9; j = j + 1) begin
                    check_pos = j * 9 + col;
                    if (check_pos != pos && grid[check_pos] == value) begin
                        is_legal = 1'b0;
                    end
                end

                box_row = (row / 3) * 3;
                box_col = (col / 3) * 3;
                for (j = 0; j < 9; j = j + 1) begin
                    check_pos = (box_row + (j / 3)) * 9 + box_col + (j % 3);
                    if (check_pos != pos && grid[check_pos] == value) begin
                        is_legal = 1'b0;
                    end
                end
            end
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= S_IDLE;
            done         <= 1'b0;
            solved       <= 1'b0;
            invalid      <= 1'b0;
            solution_out <= 324'd0;
            cycles       <= 32'd0;
            idx          <= 7'd0;
            validate_idx <= 7'd0;
            try_value    <= 4'd0;
            input_bad    <= 1'b0;

            for (i = 0; i < 81; i = i + 1) begin
                grid[i]       <= 4'd0;
                fixed_cell[i] <= 1'b0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        done         <= 1'b0;
                        solved       <= 1'b0;
                        invalid      <= 1'b0;
                        solution_out <= 324'd0;
                        cycles       <= 32'd0;
                        idx          <= 7'd0;
                        validate_idx <= 7'd0;
                        try_value    <= 4'd0;
                        input_bad    <= 1'b0;

                        for (i = 0; i < 81; i = i + 1) begin
                            grid[i]       <= puzzle_in[i*4 +: 4];
                            fixed_cell[i] <= (puzzle_in[i*4 +: 4] != 4'd0);
                            if (puzzle_in[i*4 +: 4] > 4'd9) begin
                                input_bad <= 1'b1;
                            end
                        end

                        state <= S_CHECK_INPUT;
                    end
                end

                S_CHECK_INPUT: begin
                    cycles <= cycles + 32'd1;
                    if (input_bad) begin
                        invalid <= 1'b1;
                        solved  <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_DONE;
                    end else begin
                        state <= S_VALIDATE;
                    end
                end

                S_VALIDATE: begin
                    cycles <= cycles + 32'd1;
                    if (grid[validate_idx] != 4'd0 &&
                        !is_legal(validate_idx, grid[validate_idx])) begin
                        invalid <= 1'b1;
                        solved  <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_DONE;
                    end else if (validate_idx == 7'd80) begin
                        idx   <= 7'd0;
                        state <= S_SOLVE;
                    end else begin
                        validate_idx <= validate_idx + 7'd1;
                    end
                end

                S_SOLVE: begin
                    cycles <= cycles + 32'd1;

                    if (cycles >= MAX_CYCLES) begin
                        invalid <= 1'b0;
                        solved  <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_DONE;
                    end else if (idx == 7'd81) begin
                        solved <= 1'b1;
                        state  <= S_PACK_OUTPUT;
                    end else if (fixed_cell[idx]) begin
                        idx <= idx + 7'd1;
                    end else begin
                        try_value <= grid[idx] + 4'd1;
                        state     <= S_TRY_VALUE;
                    end
                end

                S_TRY_VALUE: begin
                    cycles <= cycles + 32'd1;

                    if (cycles >= MAX_CYCLES) begin
                        invalid <= 1'b0;
                        solved  <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_DONE;
                    end else if (try_value <= 4'd9) begin
                        if (is_legal(idx, try_value)) begin
                            grid[idx] <= try_value;
                            idx       <= idx + 7'd1;
                            state     <= S_SOLVE;
                        end else begin
                            try_value <= try_value + 4'd1;
                        end
                    end else begin
                        grid[idx] <= 4'd0;
                        state     <= S_BACKTRACK;
                    end
                end

                S_BACKTRACK: begin
                    cycles <= cycles + 32'd1;

                    if (idx == 7'd0) begin
                        invalid <= 1'b0;
                        solved  <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_DONE;
                    end else begin
                        idx   <= idx - 7'd1;
                        state <= S_BACKTRACK_SKIP;
                    end
                end

                S_BACKTRACK_SKIP: begin
                    cycles <= cycles + 32'd1;

                    if (fixed_cell[idx]) begin
                        if (idx == 7'd0) begin
                            invalid <= 1'b0;
                            solved  <= 1'b0;
                            done    <= 1'b1;
                            state   <= S_DONE;
                        end else begin
                            idx <= idx - 7'd1;
                        end
                    end else begin
                        state <= S_SOLVE;
                    end
                end

                S_PACK_OUTPUT: begin
                    cycles <= cycles + 32'd1;

                    for (i = 0; i < 81; i = i + 1) begin
                        solution_out[i*4 +: 4] <= grid[i];
                    end

                    done  <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
