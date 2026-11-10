`timescale 1ns/1ps

module tb;

    // Inputs
    reg [3:0] a;
    reg [3:0] b;
    reg [2:0] op;

    // Outputs
    wire [3:0] result;
    wire zero;
    wire carry;

    // Instantiate the ALU
    alu uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    // Variables for checking
    reg [3:0] exp_result;
    reg       exp_zero;
    reg       exp_carry;
    
    integer   error_count = 0;
    integer   test_count = 0;

    // Task to apply inputs, compute expected outputs, and verify
    task check_alu(input [3:0] in_a, input [3:0] in_b, input [2:0] in_op);
        reg [4:0] add_temp;
        begin
            a  = in_a;
            b  = in_b;
            op = in_op;
            
            // Wait for combinational propagation
            #1;

            // Compute expected values based on spec
            exp_carry = 1'b0;
            case (op)
                3'b000: begin // ADD
                    add_temp = a + b;
                    exp_result = add_temp[3:0];
                    exp_carry  = add_temp[4];
                end
                3'b001: begin // SUB
                    exp_result = a - b;
                    exp_carry  = (a < b) ? 1'b1 : 1'b0;
                end
                3'b010: exp_result = a & b;   // AND
                3'b011: exp_result = a | b;   // OR
                3'b100: exp_result = a ^ b;   // XOR
                3'b101: exp_result = ~a;      // NOT
                3'b110: exp_result = a << 1;  // SHL
                3'b111: exp_result = a >> 1;  // SHR
                default: exp_result = 4'b0000;
            endcase

            exp_zero = (exp_result == 4'b0000);

            test_count = test_count + 1;

            // Check against actual outputs
            if ((result !== exp_result) || (zero !== exp_zero) || (carry !== exp_carry)) begin
                $display("FAIL: op=%b, a=%0d, b=%0d | Expected: res=%0h, z=%0b, c=%0b | Got: res=%0h, z=%0b, c=%0b",
                         op, a, b, exp_result, exp_zero, exp_carry, result, zero, carry);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        // --- Corner Cases and Comprehensive Testing ---

        // 1. Zero cases
        check_alu(4'd0, 4'd0, 3'b000); // ADD: 0 + 0
        check_alu(4'd0, 4'd0, 3'b001); // SUB: 0 - 0
        check_alu(4'd0, 4'd0, 3'b010); // AND: 0 & 0
        check_alu(4'd0, 4'd0, 3'b011); // OR:  0 | 0
        check_alu(4'd0, 4'd0, 3'b100); // XOR: 0 ^ 0
        check_alu(4'd0, 4'd0, 3'b101); // NOT: ~0
        check_alu(4'd0, 4'd0, 3'b110); // SHL: 0 << 1
        check_alu(4'd0, 4'd0, 3'b111); // SHR: 0 >> 1

        // 2. Max value cases (a=15, b=15)
        check_alu(4'd15, 4'd15, 3'b000); // ADD: 15 + 15 (Carry & wrap)
        check_alu(4'd15, 4'd15, 3'b001); // SUB: 15 - 15
        check_alu(4'd15, 4'd15, 3'b010); // AND: 15 & 15
        check_alu(4'd15, 4'd15, 3'b011); // OR:  15 | 15
        check_alu(4'd15, 4'd15, 3'b100); // XOR: 15 ^ 15
        check_alu(4'd15, 4'd15, 3'b101); // NOT: ~15
        check_alu(4'd15, 4'd15, 3'b110); // SHL: 15 << 1
        check_alu(4'd15, 4'd15, 3'b111); // SHR: 15 >> 1

        // 3. Equality cases (a == b)
        check_alu(4'd5, 4'd5, 3'b000);
        check_alu(4'd5, 4'd5, 3'b001); // SUB results in 0, borrow=0
        check_alu(4'd7, 4'd7, 3'b100); // XOR results in 0

        // 4. SUB specific corner cases: a < b (borrow = 1) vs a >= b (borrow = 0)
        check_alu(4'd3, 4'd5, 3'b001); // 3 - 5 (a < b, borrow=1)
        check_alu(4'd5, 4'd3, 3'b001); // 5 - 3 (a > b, borrow=0)
        check_alu(4'd0, 4'd1, 3'b001); // 0 - 1 (borrow=1)

        // 5. Random/general cases across all operations
        check_alu(4'd9,  4'd6,  3'b000); // ADD with carry out (9+6=15, no carry), let's do 10+6
        check_alu(4'd10, 4'd6,  3'b000); // 10 + 6 = 16 -> res=0, carry=1
        check_alu(4'd12, 4'd3,  3'b001); // 12 - 3
        check_alu(4'd12, 4'd10, 3'b010); // 12 & 10
        check_alu(4'd12, 4'd10, 3'b011); // 12 | 10
        check_alu(4'd12, 4'd10, 3'b100); // 12 ^ 10
        check_alu(4'd11, 4'd0,  3'b101); // ~11
        check_alu(4'd9,  4'd0,  3'b110); // 9 << 1
        check_alu(4'd9,  4'd0,  3'b111); // 9 >> 1

        // Final Result Report
        if (error_count == 0) begin
            $display("PASS: All %0d test cases passed successfully.", test_count);
        end else begin
            $display("FAIL: %0d out of %0d test cases failed.", error_count, test_count);
        end

        $finish;
    end

endmodule
