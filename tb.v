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

    // Instantiate the Unit Under Test (UUT)
    alu uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    // Variables for self-checking and test tracking
    reg [3:0] expected_result;
    reg expected_carry;
    reg expected_zero;
    integer error_count = 0;
    integer test_count = 0;

    // Task to apply inputs, compute expected values via behavioral model, check, and report
    task check_alu(input [3:0] test_a, input [3:0] test_b, input [2:0] test_op);
        begin
            a = test_a;
            b = test_b;
            op = test_op;
            
            #1; // Wait for combinational propagation

            // Compute expected values according to spec
            case (test_op)
                3'b000: begin // ADD
                    {expected_carry, expected_result} = test_a + test_b;
                end
                3'b001: begin // SUB
                    expected_result = test_a - test_b;
                    expected_carry = (test_a < test_b) ? 1'b1 : 1'b0;
                end
                3'b010: begin // AND
                    expected_result = test_a & test_b;
                    expected_carry = 1'b0;
                end
                3'b011: begin // OR
                    expected_result = test_a | test_b;
                    expected_carry = 1'b0;
                end
                3'b100: begin // XOR
                    expected_result = test_a ^ test_b;
                    expected_carry = 1'b0;
                end
                3'b101: begin // NOT
                    expected_result = ~test_a;
                    expected_carry = 1'b0;
                end
                3'b110: begin // SHL
                    expected_result = test_a << 1;
                    expected_carry = 1'b0;
                end
                3'b111: begin // SHR
                    expected_result = test_a >> 1;
                    expected_carry = 1'b0;
                end
                default: begin
                    expected_result = 4'b0;
                    expected_carry = 1'b0;
                end
            endcase

            expected_zero = (expected_result == 4'b0000) ? 1'b1 : 1'b0;
            test_count = test_count + 1;

            // Verify outputs
            if ((result !== expected_result) || (carry !== expected_carry) || (zero !== expected_zero)) begin
                $display("FAIL: op=%b, a=%d, b=%d | Got: result=%b (carry=%b, zero=%b) | Expected: result=%b (carry=%b, zero=%b)",
                         test_op, test_a, test_b, result, carry, zero, expected_result, expected_carry, expected_zero);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        // --- Operation 3'b000: ADD (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b000); // Corner case: a=0, b=0
        check_alu(4'd15, 4'd15, 3'b000); // Corner case: a=15, b=15 (carry & wrap)
        check_alu(4'd5,  4'd5,  3'b000); // Corner case: a=b
        check_alu(4'd3,  4'd7,  3'b000); // Corner case: a<b
        check_alu(4'd10, 4'd2,  3'b000); // Standard case
        check_alu(4'd12, 4'd4,  3'b000); // Corner case: results in zero with carry

        // --- Operation 3'b001: SUB (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b001); // Corner case: a=0, b=0 (zero=1)
        check_alu(4'd15, 4'd15, 3'b001); // Corner case: a=15, b=15 (zero=1)
        check_alu(4'd5,  4'd5,  3'b001); // Corner case: a=b (zero=1)
        check_alu(4'd3,  4'd7,  3'b001); // Corner case: a<b (borrow=1)
        check_alu(4'd10, 4'd2,  3'b001); // Corner case: a>b (borrow=0)
        check_alu(4'd0,  4'd5,  3'b001); // Corner case: a=0, b>0 (borrow=1)

        // --- Operation 3'b010: AND (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b010); // Corner case: a=0, b=0
        check_alu(4'd15, 4'd15, 3'b010); // Corner case: a=15, b=15
        check_alu(4'd5,  4'd5,  3'b010); // Corner case: a=b
        check_alu(4'd3,  4'd7,  3'b010); // Corner case: a<b
        check_alu(4'd10, 4'd5,  3'b010); // Standard case (result 0)
        check_alu(4'd12, 4'd6,  3'b010); // Standard case

        // --- Operation 3'b011: OR (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b011); // Corner case: a=0, b=0
        check_alu(4'd15, 4'd15, 3'b011); // Corner case: a=15, b=15
        check_alu(4'd5,  4'd5,  3'b011); // Corner case: a=b
        check_alu(4'd3,  4'd7,  3'b011); // Corner case: a<b
        check_alu(4'd0,  4'd8,  3'b011); // Corner case: a=0, b!=0
        check_alu(4'd10, 4'd5,  3'b011); // Standard case

        // --- Operation 3'b100: XOR (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b100); // Corner case: a=0, b=0
        check_alu(4'd15, 4'd15, 3'b100); // Corner case: a=15, b=15 (zero=1)
        check_alu(4'd5,  4'd5,  3'b100); // Corner case: a=b (zero=1)
        check_alu(4'd3,  4'd7,  3'b100); // Corner case: a<b
        check_alu(4'd15, 4'd0,  3'b100); // Corner case: b=0
        check_alu(4'd10, 4'd5,  3'b100); // Standard case

        // --- Operation 3'b101: NOT (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b101); // Corner case: a=0 (result=15)
        check_alu(4'd15, 4'd15, 3'b101); // Corner case: a=15 (result=0, zero=1)
        check_alu(4'd5,  4'd0,  3'b101); // Corner case: a=5
        check_alu(4'd3,  4'd12, 3'b101); // Corner case: a=3
        check_alu(4'd10, 4'd2,  3'b101); // Standard case
        check_alu(4'd1,  4'd9,  3'b101); // Standard case

        // --- Operation 3'b110: SHL (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b110); // Corner case: a=0 (zero=1)
        check_alu(4'd15, 4'd0,  3'b110); // Corner case: a=15 (result=14)
        check_alu(4'd5,  4'd0,  3'b110); // Corner case: a=5
        check_alu(4'd8,  4'd0,  3'b110); // Corner case: a=8 (result=0, zero=1)
        check_alu(4'd1,  4'd0,  3'b110); // Standard case
        check_alu(4'd7,  4'd0,  3'b110); // Standard case

        // --- Operation 3'b111: SHR (at least 6 vectors including corner cases) ---
        check_alu(4'd0,  4'd0,  3'b111); // Corner case: a=0 (zero=1)
        check_alu(4'd15, 4'd0,  3'b111); // Corner case: a=15 (result=7)
        check_alu(4'd5,  4'd0,  3'b111); // Corner case: a=5 (result=2)
        check_alu(4'd1,  4'd0,  3'b111); // Corner case: a=1 (result=0, zero=1)
        check_alu(4'd8,  4'd0,  3'b111); // Standard case
        check_alu(4'd4,  4'd0,  3'b111); // Standard case

        // Final result reporting
        if (error_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d / %0d tests failed.", error_count, test_count);
        end

        $finish;
    end

endmodule
