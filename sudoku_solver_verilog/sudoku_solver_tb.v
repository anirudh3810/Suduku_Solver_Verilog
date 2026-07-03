`timescale 1ns / 1ps

module sudoku_solver_tb;
    reg clk;
    reg reset;
    reg start;
    reg [323:0] puzzle;
    reg [323:0] expected;

    wire done;
    wire solved;
    wire invalid;
    wire [323:0] solution;
    wire [31:0] cycles;

    integer errors;
    integer timeout;

    sudoku_solver #(
        .MAX_CYCLES(32'd10000000)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .puzzle_in(puzzle),
        .done(done),
        .solved(solved),
        .invalid(invalid),
        .solution_out(solution),
        .cycles(cycles)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task set_cell;
        input integer cell_index;
        input [3:0] value;
        begin
            puzzle[cell_index*4 +: 4] = value;
        end
    endtask

    task set_expected_cell;
        input integer cell_index;
        input [3:0] value;
        begin
            expected[cell_index*4 +: 4] = value;
        end
    endtask

    task print_board;
        input [323:0] board;
        integer row;
        integer col;
        integer cell_index;
        begin
            for (row = 0; row < 9; row = row + 1) begin
                $write("  ");
                for (col = 0; col < 9; col = col + 1) begin
                    cell_index = row * 9 + col;
                    $write("%0d", board[cell_index*4 +: 4]);
                    if (col == 2 || col == 5) begin
                        $write(" | ");
                    end else if (col != 8) begin
                        $write(" ");
                    end
                end
                $write("\n");
                if (row == 2 || row == 5) begin
                    $write("  ------+-------+------\n");
                end
            end
        end
    endtask

    task clear_vectors;
        begin
            puzzle   = 324'd0;
            expected = 324'd0;
        end
    endtask

    task load_standard_puzzle;
        begin
            clear_vectors;

            // Puzzle:
            // 530070000
            // 600195000
            // 098000060
            // 800060003
            // 400803001
            // 700020006
            // 060000280
            // 000419005
            // 000080079
            set_cell(0, 5);  set_cell(1, 3);  set_cell(4, 7);
            set_cell(9, 6);  set_cell(12, 1); set_cell(13, 9); set_cell(14, 5);
            set_cell(19, 9); set_cell(20, 8); set_cell(25, 6);
            set_cell(27, 8); set_cell(31, 6); set_cell(35, 3);
            set_cell(36, 4); set_cell(39, 8); set_cell(41, 3); set_cell(44, 1);
            set_cell(45, 7); set_cell(49, 2); set_cell(53, 6);
            set_cell(55, 6); set_cell(60, 2); set_cell(61, 8);
            set_cell(66, 4); set_cell(67, 1); set_cell(68, 9); set_cell(71, 5);
            set_cell(76, 8); set_cell(79, 7); set_cell(80, 9);

            // Solution:
            // 534678912
            // 672195348
            // 198342567
            // 859761423
            // 426853791
            // 713924856
            // 961537284
            // 287419635
            // 345286179
            set_expected_cell(0, 5);  set_expected_cell(1, 3);  set_expected_cell(2, 4);
            set_expected_cell(3, 6);  set_expected_cell(4, 7);  set_expected_cell(5, 8);
            set_expected_cell(6, 9);  set_expected_cell(7, 1);  set_expected_cell(8, 2);
            set_expected_cell(9, 6);  set_expected_cell(10, 7); set_expected_cell(11, 2);
            set_expected_cell(12, 1); set_expected_cell(13, 9); set_expected_cell(14, 5);
            set_expected_cell(15, 3); set_expected_cell(16, 4); set_expected_cell(17, 8);
            set_expected_cell(18, 1); set_expected_cell(19, 9); set_expected_cell(20, 8);
            set_expected_cell(21, 3); set_expected_cell(22, 4); set_expected_cell(23, 2);
            set_expected_cell(24, 5); set_expected_cell(25, 6); set_expected_cell(26, 7);
            set_expected_cell(27, 8); set_expected_cell(28, 5); set_expected_cell(29, 9);
            set_expected_cell(30, 7); set_expected_cell(31, 6); set_expected_cell(32, 1);
            set_expected_cell(33, 4); set_expected_cell(34, 2); set_expected_cell(35, 3);
            set_expected_cell(36, 4); set_expected_cell(37, 2); set_expected_cell(38, 6);
            set_expected_cell(39, 8); set_expected_cell(40, 5); set_expected_cell(41, 3);
            set_expected_cell(42, 7); set_expected_cell(43, 9); set_expected_cell(44, 1);
            set_expected_cell(45, 7); set_expected_cell(46, 1); set_expected_cell(47, 3);
            set_expected_cell(48, 9); set_expected_cell(49, 2); set_expected_cell(50, 4);
            set_expected_cell(51, 8); set_expected_cell(52, 5); set_expected_cell(53, 6);
            set_expected_cell(54, 9); set_expected_cell(55, 6); set_expected_cell(56, 1);
            set_expected_cell(57, 5); set_expected_cell(58, 3); set_expected_cell(59, 7);
            set_expected_cell(60, 2); set_expected_cell(61, 8); set_expected_cell(62, 4);
            set_expected_cell(63, 2); set_expected_cell(64, 8); set_expected_cell(65, 7);
            set_expected_cell(66, 4); set_expected_cell(67, 1); set_expected_cell(68, 9);
            set_expected_cell(69, 6); set_expected_cell(70, 3); set_expected_cell(71, 5);
            set_expected_cell(72, 3); set_expected_cell(73, 4); set_expected_cell(74, 5);
            set_expected_cell(75, 2); set_expected_cell(76, 8); set_expected_cell(77, 6);
            set_expected_cell(78, 1); set_expected_cell(79, 7); set_expected_cell(80, 9);
        end
    endtask

    task load_hard_puzzle;
        begin
            clear_vectors;

            // A sparse 17-clue puzzle often used for backtracking tests:
            // 800000000
            // 003600000
            // 070090200
            // 050007000
            // 000045700
            // 000100030
            // 001000068
            // 008500010
            // 090000400
            set_cell(0, 8);
            set_cell(11, 3); set_cell(12, 6);
            set_cell(19, 7); set_cell(22, 9); set_cell(24, 2);
            set_cell(28, 5); set_cell(32, 7);
            set_cell(40, 4); set_cell(41, 5); set_cell(42, 7);
            set_cell(48, 1); set_cell(52, 3);
            set_cell(56, 1); set_cell(61, 6); set_cell(62, 8);
            set_cell(65, 8); set_cell(66, 5); set_cell(70, 1);
            set_cell(73, 9); set_cell(78, 4);

            // Solution:
            // 812753649
            // 943682175
            // 675491283
            // 154237896
            // 369845721
            // 287169534
            // 521974368
            // 438526917
            // 796318452
            set_expected_cell(0, 8);  set_expected_cell(1, 1);  set_expected_cell(2, 2);
            set_expected_cell(3, 7);  set_expected_cell(4, 5);  set_expected_cell(5, 3);
            set_expected_cell(6, 6);  set_expected_cell(7, 4);  set_expected_cell(8, 9);
            set_expected_cell(9, 9);  set_expected_cell(10, 4); set_expected_cell(11, 3);
            set_expected_cell(12, 6); set_expected_cell(13, 8); set_expected_cell(14, 2);
            set_expected_cell(15, 1); set_expected_cell(16, 7); set_expected_cell(17, 5);
            set_expected_cell(18, 6); set_expected_cell(19, 7); set_expected_cell(20, 5);
            set_expected_cell(21, 4); set_expected_cell(22, 9); set_expected_cell(23, 1);
            set_expected_cell(24, 2); set_expected_cell(25, 8); set_expected_cell(26, 3);
            set_expected_cell(27, 1); set_expected_cell(28, 5); set_expected_cell(29, 4);
            set_expected_cell(30, 2); set_expected_cell(31, 3); set_expected_cell(32, 7);
            set_expected_cell(33, 8); set_expected_cell(34, 9); set_expected_cell(35, 6);
            set_expected_cell(36, 3); set_expected_cell(37, 6); set_expected_cell(38, 9);
            set_expected_cell(39, 8); set_expected_cell(40, 4); set_expected_cell(41, 5);
            set_expected_cell(42, 7); set_expected_cell(43, 2); set_expected_cell(44, 1);
            set_expected_cell(45, 2); set_expected_cell(46, 8); set_expected_cell(47, 7);
            set_expected_cell(48, 1); set_expected_cell(49, 6); set_expected_cell(50, 9);
            set_expected_cell(51, 5); set_expected_cell(52, 3); set_expected_cell(53, 4);
            set_expected_cell(54, 5); set_expected_cell(55, 2); set_expected_cell(56, 1);
            set_expected_cell(57, 9); set_expected_cell(58, 7); set_expected_cell(59, 4);
            set_expected_cell(60, 3); set_expected_cell(61, 6); set_expected_cell(62, 8);
            set_expected_cell(63, 4); set_expected_cell(64, 3); set_expected_cell(65, 8);
            set_expected_cell(66, 5); set_expected_cell(67, 2); set_expected_cell(68, 6);
            set_expected_cell(69, 9); set_expected_cell(70, 1); set_expected_cell(71, 7);
            set_expected_cell(72, 7); set_expected_cell(73, 9); set_expected_cell(74, 6);
            set_expected_cell(75, 3); set_expected_cell(76, 1); set_expected_cell(77, 8);
            set_expected_cell(78, 4); set_expected_cell(79, 5); set_expected_cell(80, 2);
        end
    endtask

    task run_case;
        input [8*32-1:0] name;
        begin
            $display("\n=== %0s ===", name);
            $display("Input puzzle:");
            print_board(puzzle);

            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            timeout = 0;
            while (!done && timeout < 20000000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                $display("FAIL: solver did not finish before testbench timeout");
                errors = errors + 1;
            end else if (!solved || invalid) begin
                $display("FAIL: solved=%0d invalid=%0d cycles=%0d", solved, invalid, cycles);
                errors = errors + 1;
            end else if (solution !== expected) begin
                $display("FAIL: solution does not match expected board, cycles=%0d", cycles);
                $display("Actual solution:");
                print_board(solution);
                $display("Expected solution:");
                print_board(expected);
                errors = errors + 1;
            end else begin
                $display("PASS: solved in %0d cycles", cycles);
                $display("Solved board:");
                print_board(solution);
            end

            repeat (3) @(posedge clk);
        end
    endtask

    initial begin
        errors = 0;
        reset = 1'b1;
        start = 1'b0;
        clear_vectors;

        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        load_standard_puzzle;
        run_case("standard puzzle");

        load_hard_puzzle;
        run_case("hard backtracking puzzle");

        if (errors == 0) begin
            $display("\nAll Sudoku solver tests passed.");
            $finish;
        end else begin
            $display("\n%0d Sudoku solver test(s) failed.", errors);
            $fatal;
        end
    end
endmodule
