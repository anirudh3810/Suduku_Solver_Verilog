`timescale 1ns/1ps
`default_nettype none

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

    localparam [2:0] ST_IDLE     = 3'd0;
    localparam [2:0] ST_LOAD     = 3'd1;
    localparam [2:0] ST_VALIDATE = 3'd2;
    localparam [2:0] ST_SOLVE    = 3'd3;
    localparam [2:0] ST_DONE     = 3'd4;
    localparam [2:0] ST_FAIL     = 3'd5;

    reg [2:0] state;

    reg [3:0] board      [0:80];
    reg       fixed_cell [0:80];
    reg [6:0] empty_pos  [0:80];
    reg [3:0] next_digit [0:80];

    reg [6:0] empty_count;
    reg [6:0] sp;
    reg [6:0] load_idx;
    reg [6:0] check_idx;

    integer init_i;
    integer pack_i;

    function is_placement_valid;
        input [6:0] cell_index;
        input [3:0] digit;
        integer row;
        integer col;
        integer base_row;
        integer base_col;
        integer rr;
        integer cc;
        integer peer;
        begin
            is_placement_valid = 1'b1;

            if (digit == 4'd0) begin
                is_placement_valid = 1'b0;
            end else begin
                row = cell_index / 9;
                col = cell_index % 9;

                for (cc = 0; cc < 9; cc = cc + 1) begin
                    peer = (row * 9) + cc;
                    if ((peer != cell_index) && (board[peer] == digit)) begin
                        is_placement_valid = 1'b0;
                    end
                end

                for (rr = 0; rr < 9; rr = rr + 1) begin
                    peer = (rr * 9) + col;
                    if ((peer != cell_index) && (board[peer] == digit)) begin
                        is_placement_valid = 1'b0;
                    end
                end

                base_row = (row / 3) * 3;
                base_col = (col / 3) * 3;

                for (rr = 0; rr < 3; rr = rr + 1) begin
                    for (cc = 0; cc < 3; cc = cc + 1) begin
                        peer = ((base_row + rr) * 9) + (base_col + cc);
                        if ((peer != cell_index) && (board[peer] == digit)) begin
                            is_placement_valid = 1'b0;
                        end
                    end
                end
            end
        end
    endfunction

    always @(*) begin
        solution_flat = {324{1'b0}};
        for (pack_i = 0; pack_i < 81; pack_i = pack_i + 1) begin
            solution_flat[(pack_i * 4) +: 4] = board[pack_i];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= ST_IDLE;
            done       <= 1'b0;
            valid      <= 1'b0;
            busy       <= 1'b0;
            empty_count <= 7'd0;
            sp         <= 7'd0;
            load_idx   <= 7'd0;
            check_idx  <= 7'd0;

            for (init_i = 0; init_i < 81; init_i = init_i + 1) begin
                board[init_i]      <= 4'd0;
                fixed_cell[init_i] <= 1'b0;
                empty_pos[init_i]  <= 7'd0;
                next_digit[init_i] <= 4'd1;
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done  <= 1'b0;
                    valid <= 1'b0;
                    busy  <= 1'b0;

                    if (start) begin
                        done        <= 1'b0;
                        valid       <= 1'b1;
                        busy        <= 1'b1;
                        empty_count <= 7'd0;
                        sp          <= 7'd0;
                        load_idx    <= 7'd0;
                        check_idx   <= 7'd0;
                        state       <= ST_LOAD;

                        for (init_i = 0; init_i < 81; init_i = init_i + 1) begin
                            board[init_i]      <= 4'd0;
                            fixed_cell[init_i] <= 1'b0;
                            empty_pos[init_i]  <= 7'd0;
                            next_digit[init_i] <= 4'd1;
                        end
                    end
                end

                ST_LOAD: begin
                    board[load_idx]      <= puzzle_flat[(load_idx * 4) +: 4];
                    fixed_cell[load_idx] <= (puzzle_flat[(load_idx * 4) +: 4] != 4'd0);

                    if (puzzle_flat[(load_idx * 4) +: 4] == 4'd0) begin
                        empty_pos[empty_count]  <= load_idx;
                        next_digit[empty_count] <= 4'd1;
                        empty_count             <= empty_count + 7'd1;
                    end

                    if (load_idx == 7'd80) begin
                        check_idx <= 7'd0;
                        state     <= ST_VALIDATE;
                    end else begin
                        load_idx <= load_idx + 7'd1;
                    end
                end

                ST_VALIDATE: begin
                    if ((board[check_idx] != 4'd0) && !is_placement_valid(check_idx, board[check_idx])) begin
                        done  <= 1'b1;
                        valid <= 1'b0;
                        busy  <= 1'b0;
                        state <= ST_FAIL;
                    end else if (check_idx == 7'd80) begin
                        sp <= 7'd0;

                        if (empty_count == 7'd0) begin
                            done  <= 1'b1;
                            valid <= 1'b1;
                            busy  <= 1'b0;
                            state <= ST_DONE;
                        end else begin
                            state <= ST_SOLVE;
                        end
                    end else begin
                        check_idx <= check_idx + 7'd1;
                    end
                end

                ST_SOLVE: begin
                    if (sp >= empty_count) begin
                        done  <= 1'b1;
                        valid <= 1'b1;
                        busy  <= 1'b0;
                        state <= ST_DONE;
                    end else if (next_digit[sp] > 4'd9) begin
                        board[empty_pos[sp]] <= 4'd0;
                        next_digit[sp]       <= 4'd1;

                        if (sp == 7'd0) begin
                            done  <= 1'b1;
                            valid <= 1'b0;
                            busy  <= 1'b0;
                            state <= ST_FAIL;
                        end else begin
                            board[empty_pos[sp - 7'd1]] <= 4'd0;
                            next_digit[sp - 7'd1]       <= next_digit[sp - 7'd1] + 4'd1;
                            sp                          <= sp - 7'd1;
                        end
                    end else if (is_placement_valid(empty_pos[sp], next_digit[sp])) begin
                        board[empty_pos[sp]] <= next_digit[sp];

                        if (sp == (empty_count - 7'd1)) begin
                            done  <= 1'b1;
                            valid <= 1'b1;
                            busy  <= 1'b0;
                            state <= ST_DONE;
                        end else begin
                            sp                           <= sp + 7'd1;
                            board[empty_pos[sp + 7'd1]] <= 4'd0;
                            next_digit[sp + 7'd1]       <= 4'd1;
                        end
                    end else begin
                        next_digit[sp] <= next_digit[sp] + 4'd1;
                    end
                end

                ST_DONE: begin
                    done  <= 1'b1;
                    valid <= 1'b1;
                    busy  <= 1'b0;
                end

                ST_FAIL: begin
                    done  <= 1'b1;
                    valid <= 1'b0;
                    busy  <= 1'b0;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
