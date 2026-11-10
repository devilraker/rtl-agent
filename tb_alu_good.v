`timescale 1ns/1ns

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

    // Task to check outputs
    task check_results(
        input [3:0] exp_result,
        input       exp_zero,
        input       exp_carry
    );
        begin
            #1; // Small delay for combinational propagation
            if (result !== exp_result || zero !== exp_zero || carry !== exp_carry) begin
                $display("FAIL: op=%b, a=%d, b=%d | Expected: res=%d, zero=%b, carry=%b | Got: res=%d, zero=%b, carry=%b",
                         op, a, b, exp_result, exp_zero, exp_carry, result, zero, carry);
                $finish;
            end
        end
    endtask

    // Expected value calculation functions for self-checking
    function [4:0] compute_expected(input [2:0] operation, input [3:0] op_a, input [3:0] op_b);
        reg [4:0] full_res;
        begin
            full_res = 5'b0;
            case (operation)
                3'b000: full_res = op_a + op_b;                               // ADD: {carry, result}
                3'b001: full_res = { (op_a < op_b), (op_a - op_b) & 4'hF };   // SUB: {borrow, result}
                3'b010: full_res = {1'b0, op_a & op_b};                       // AND
                3'b011: full_res = {1'b0, op_a | op_b};                       // OR
                3'b100: full_res = {1'b0, op_a ^ op_b};                       // XOR
                3'b101: full_res = {1'b0, ~op_a};                              // NOT
                3'b110: full_res = {1'b0, op_a << 1};                         // SHL
                3'b111: full_res = {1'b0, op_a >> 1};                         // SHR
                default: full_res = 5'b0;
            endcase
            compute_expected = full_res;
        end
    endfunction

    // Test stimulus
    integer i_op, i_a, i_b;
    reg [4:0] exp;

    initial begin
        // Exhaustive or comprehensive corner-case testing
        // Test all operations across a variety of inputs including corner cases (0, 15, a=b, a<b)
        for (i_op = 0; i_op < 8; i_op = i_op + 1) begin
            for (i_a = 0; i_a < 16; i_a = i_a + 1) begin
                for (i_b = 0; i_b < 16; i_b = i_b + 1) begin
                    op = i_op[2:0];
                    a  = i_a[3:0];
                    b  = i_b[3:0];

                    exp = compute_expected(op, a, b);
                    check_results(exp[3:0], (exp[3:0] == 4'b0), exp[4]);
                end
            end
        end

        $display("PASS");
        $finish;
    end

endmodule
