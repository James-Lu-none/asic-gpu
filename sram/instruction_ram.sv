`timescale 1ns / 1ps
// ASIC instruction storage, preserving the shared synchronous RAM boundary.
module instruction_ram #(
    parameter integer DEPTH = gpu_pkg::IRAM_DEPTH,
    parameter integer ADDR_W = 12
)(
    input wire clk,
    input wire write_enable,
    input wire [ADDR_W-1:0] write_address,
    input wire [31:0] write_data,
    input wire [ADDR_W-1:0] read_address,
    output wire [31:0] read_data
);
    generate
        if (DEPTH != 1024 || ADDR_W != 12) begin : unsupported_shape
            initial $fatal(1, "OpenRAM IRAM requires DEPTH=1024 and ADDR_W=12");
        end
    endgenerate
    // Reject writes outside the array; high PC bits must not alias valid code.
    wire read_in_range = (read_address < 12'd1024);
    wire write_in_range = (write_address < 12'd1024);
    reg pending_write;
    reg [9:0] pending_address;
    reg [31:0] pending_data;
    wire forward_pending = pending_write && read_in_range &&
                           (read_address[9:0] == pending_address);
    reg read_in_range_q, forward_q;
    reg [31:0] forward_data_q;
    wire [31:0] macro_read_data;

    // No reset: accepted loader writes continue committing during control reset.
    always @(posedge clk) begin
        pending_write <= write_enable && write_in_range;
        pending_address <= write_address[9:0];
        pending_data <= write_data;
        read_in_range_q <= read_in_range;
        forward_q <= forward_pending;
        forward_data_q <= pending_data;
    end
    // Out-of-range inferred-array reads are undefined, rather than wrapping.
    assign read_data = !read_in_range_q ? 32'bx :
                       forward_q ? forward_data_q : macro_read_data;

    gpc_sram_1rw1r_1024x32
`ifndef SYNTHESIS
        #(.VERBOSE(0))
`endif
    memory (
        .clk0(clk), .csb0(!pending_write), .web0(1'b0),
        .addr0(pending_address), .din0(pending_data), .dout0(),
        .clk1(clk), .csb1(!read_in_range || forward_pending),
        .addr1(read_address[9:0]), .dout1(macro_read_data)
    );
endmodule
