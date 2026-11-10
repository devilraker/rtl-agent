`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    reg en;
    wire [3:0] q;

    // Instantiate the counter
    counter uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .q(q)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Expected value model
    reg [3:0] expected_q;
    reg error_found;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        en = 0;
        expected_q = 4'd0;
        error_found = 0;

        // Apply reset
        @(posedge clk);
        #1;
        rst = 1;
        expected_q = 4'd0;
        
        @(posedge clk);
        #1;
        if (q !== expected_q) begin
            $display("FAIL: Reset failed. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
            error_found = 1;
        end

        // Release reset, keep en low (hold value)
        rst = 0;
        @(posedge clk);
        #1;
        if (q !== expected_q) begin
            $display("FAIL: Hold failed when en=0. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
            error_found = 1;
        end

        // Enable counting for a few cycles
        en = 1;
        repeat (5) begin
            @(posedge clk);
            expected_q = expected_q + 4'd1;
            #1;
            if (q !== expected_q) begin
                $display("FAIL: Count failed when en=1. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
                error_found = 1;
            end
        end

        // Disable counting (hold value)
        en = 0;
        repeat (3) begin
            @(posedge clk);
            #1;
            if (q !== expected_q) begin
                $display("FAIL: Hold failed after counting. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
                error_found = 1;
            end
        end

        // Enable counting to test wrap-around (15 -> 0)
        en = 1;
        // Current expected_q is 5, we need it to reach 15 (10 more increments)
        repeat (11) begin
            @(posedge clk);
            expected_q = expected_q + 4'd1;
            #1;
            if (q !== expected_q) begin
                $display("FAIL: Count/Wrap failed. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
                error_found = 1;
            end
        end

        // Test synchronous reset while counting
        rst = 1;
        expected_q = 4'd0;
        @(posedge clk);
        #1;
        if (q !== expected_q) begin
            $display("FAIL: Mid-count synchronous reset failed. Expected: %0d, Got: %0d at time %0t", expected_q, q, $time);
            error_found = 1;
        end

        rst = 0;
        @(posedge clk);

        // Final result evaluation
        if (!error_found) begin
            $display("PASS");
        end

        $finish;
    end

endmodule
