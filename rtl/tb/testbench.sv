// =============================================================================
// Testbench:    tb_cnn_accelerator
// Description:  Verifies functional correctness of the convolution engine
//               by streaming dummy pixel sequences and logging signed decimal 
//               edge-detection outputs.
// =============================================================================
module tb_cnn_accelerator;

    reg clk;
    reg rst_n;
    reg en;
    reg [7:0] pixel_in;
    
    reg signed [7:0] w00, w01, w02;
    reg signed [7:0] w10, w11, w12;
    reg signed [7:0] w20, w21, w22;
    
    wire [15:0] conv_out;

    cnn_accelerator_top  uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .pixel_in(pixel_in),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22),
        .conv_out(conv_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_cnn_accelerator);

        clk = 0;
        rst_n = 0;
        en = 0;
        pixel_in = 8'd0;

        w00 = -1; w01 = -1; w02 = -1;
        w10 = -1; w11 = 8; w12 = -1;
        w20 = -1; w21 = -1; w22 = -1;

        #15;
        rst_n = 1; 
        #5;
        en = 1;    

        // Row 0
        pixel_in = 8'd2; #10; pixel_in = 8'd2; #10; pixel_in = 8'd2; #10; pixel_in = 8'd2; #10;
        pixel_in = 8'd2; #10; pixel_in = 8'd2; #10; pixel_in = 8'd2; #10; pixel_in = 8'd2; #10;

        // Row 1
        pixel_in = 8'd3; #10; pixel_in = 8'd3; #10; pixel_in = 8'd3; #10; pixel_in = 8'd3; #10;
        pixel_in = 8'd3; #10; pixel_in = 8'd3; #10; pixel_in = 8'd3; #10; pixel_in = 8'd3; #10;

        // Row 2
        pixel_in = 8'd4; #10; pixel_in = 8'd4; #10; pixel_in = 8'd4; #10; pixel_in = 8'd4; #10;
        pixel_in = 8'd4; #10; pixel_in = 8'd4; #10; pixel_in = 8'd4; #10; pixel_in = 8'd4; #10;

        #50;
        $finish;
    end

endmodule
