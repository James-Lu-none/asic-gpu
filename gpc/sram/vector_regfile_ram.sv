`timescale 1ns / 1ps
// One ASIC odd/even bank per lane, allowing concurrent operand read/write.
module vector_regfile_ram #(
    parameter integer DEPTH = 128,
    parameter integer ADDR_W = $clog2(DEPTH)
)(
    input wire clk,
    input wire write_enable,
    input wire [ADDR_W-1:0] write_address,
    input wire [31:0] write_data,
    input wire [ADDR_W-1:0] read_address,
    output wire [31:0] read_data
);
    generate
        if (DEPTH != 128 || ADDR_W != 7) begin : unsupported_shape
            initial $fatal(1, "OpenRAM VRF bank requires DEPTH=128 and ADDR_W=7");
        end
    endgenerate
    // Buffer writes and forward older pending data to define read-during-write
    // semantics. A same-edge read observes data from before that edge's write.
    // No storage reset: accepted writes still commit while the parent resets.
    reg pending_write;
    reg [6:0] pending_address;
    reg [31:0] pending_data;
    wire forward_pending = pending_write && (read_address == pending_address);
    reg forward_q;
    reg [31:0] forward_data_q;
    wire [31:0] macro_read_data;
    always @(posedge clk) begin
        pending_write <= write_enable;
        pending_address <= write_address;
        pending_data <= write_data;
        forward_q <= forward_pending;
        forward_data_q <= pending_data;
    end
    assign read_data = forward_q ? forward_data_q : macro_read_data;

    gpc_sram_1rw1r_128x32
`ifndef SYNTHESIS
        #(.VERBOSE(0))
`endif
    memory (
        .clk0(clk), .csb0(!pending_write), .web0(1'b0),
        .addr0(pending_address), .din0(pending_data), .dout0(),
        .clk1(clk), .csb1(forward_pending),
        .addr1(read_address), .dout1(macro_read_data)
    );
endmodule
