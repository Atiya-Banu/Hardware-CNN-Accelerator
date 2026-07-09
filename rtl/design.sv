// =============================================================================
// Module Name:  cnn_accelerator_top
// Description:  Hardware-accelerated 2D Convolution Engine implementing a 3x3 
//               Laplacian edge-detection filter for streaming pixel data.
// Architect:    [Atiya Banu]
// Date:         July 2026
// =============================================================================
module processing_element (
    input wire          clk,
    input wire          rst_n,
    input wire          en,
    input wire          clear, // Add this new input port
    input wire [7:0]    pixel_in,
    input wire [7:0]    weight_in,
    output reg [15:0]   accu_out
);

wire signed [15:0] product;
assign product = $signed(pixel_in) * $signed(weight_in);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        accu_out <= 16'd0;
    end else if (en) begin
        if (clear) begin 
            accu_out <= product; // Reset accumulator to the first product of the new window
        end else begin
            accu_out <= accu_out + product; // Keep accumulating
        end
    end
end

endmodule// Code your design here
module line_buffer #(
  parameter IMG_WIDTH = 8
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] pixel_in,
    output wire [7:0] row0_out,
    output wire [7:0] row1_out,
    output wire [7:0] row2_out
);

    // Memory arrays to store image rows (Shift Registers)
    reg [7:0] shift_reg0 [0:IMG_WIDTH-1];
    reg [7:0] shift_reg1 [0:IMG_WIDTH-1];
    
    integer i;

    // Row 0 is just the incoming live pixel data stream
    assign row0_out = pixel_in;
    // Row 1 gets the data coming out of the first shift register
    assign row1_out = shift_reg0[IMG_WIDTH-1];
    // Row 2 gets the data coming out of the second shift register
    assign row2_out = shift_reg1[IMG_WIDTH-1];

    // Sequential logic to shift pixels through memory
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                shift_reg0[i] <= 8'h00;
                shift_reg1[i] <= 8'h00;
            end
        end else if (en) begin
            // Shift register 0 logic
            shift_reg0[0] <= pixel_in;
            for (i = 1; i < IMG_WIDTH; i = i + 1) begin
                shift_reg0[i] <= shift_reg0[i-1];
            end
            // Shift register 1 logic (takes data from the end of register 0)
            shift_reg1[0] <= shift_reg0[IMG_WIDTH-1];
            for (i = 1; i < IMG_WIDTH; i = i + 1) begin
                shift_reg1[i] <= shift_reg1[i-1];
            end
        end
    end

endmodule 
module cnn_accelerator_top (
  input  wire          clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [7:0]  pixel_in,
    
    // 9 Kernel Weights for a 3x3 Filter matrix
    input  wire [7:0]  w00, input wire [7:0] w01, input wire [7:0] w02,
    input  wire [7:0]  w10, input wire [7:0] w11, input wire [7:0] w12,
    input  wire [7:0]  w20, input wire [7:0] w21, input wire [7:0] w22,
    
    output wire [15:0] conv_out // final accumulated multi-cycle sum
);

    // 1. Wires to connect the Line Buffer outputs
    wire [7:0] r0, r1, r2;

    // Instantiate the Line Buffer
  line_buffer #(.IMG_WIDTH(8)) buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .pixel_in(pixel_in),
        .row0_out(r0),
        .row1_out(r1),
        .row2_out(r2)
    );

    // 2. Create local spatial registers to simulate a 3x3 sliding window
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
        end else if (en) begin
            // Shift the pixels horizontally to form the 3x3 matrix window
            p00 <= r0;  p01 <= p00; p02 <= p01;
            p10 <= r1;  p11 <= p10; p12 <= p11;
            p20 <= r2;  p21 <= p20; p22 <= p21;
        end
    end
    // 3. Wires to get individual results from our 9 PEs
    wire [15:0] out00, out01, out02;
    wire [15:0] out10, out11, out12;
    wire [15:0] out20, out21, out22;
    wire clear_signal;

    // 4. Connect 9 instances of our Processing Element (MAC Unit)
  processing_element pe00 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p00), .weight_in(w00), .accu_out(out00));
  processing_element pe01 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p01), .weight_in(w01), .accu_out(out01));
  processing_element pe02 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p02), .weight_in(w02), .accu_out(out02));

  processing_element pe10 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p10), .weight_in(w10), .accu_out(out10));
  processing_element pe11 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal),  .pixel_in(p11), .weight_in(w11), .accu_out(out11));
  processing_element pe12 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p12), .weight_in(w12), .accu_out(out12));

  processing_element pe20 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p20), .weight_in(w20), .accu_out(out20));
  processing_element pe21 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p21), .weight_in(w21), .accu_out(out21));
  processing_element pe22 (.clk(clk), .rst_n(rst_n), .en(en), .clear(clear_signal), .pixel_in(p22), .weight_in(w22), .accu_out(out22));

    // 5. Final Output Adder tree combining the array values
    assign conv_out = out00 + out01 + out02 + 
                      out10 + out11 + out12 + 
                      out20 + out21 + out22;

endmodule
