`timescale 1ns / 1ps
// ASIC implementation of the shared RAM boundary. Select this file instead
// of hardware/rtl/sm/sp/vector_regfile_ram.sv; the FPGA source is unchanged.
module vector_regfile_ram #(
    parameter integer DEPTH = 256,
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
        if (DEPTH != 256 || ADDR_W != 8) begin : unsupported_shape
            initial $fatal(1, "OpenRAM VRF bank requires DEPTH=256 and ADDR_W=8");
        end
    endgenerate
    reg pending_write;
    reg [7:0] pending_address;
    reg [31:0] pending_data;
    wire forward_pending = pending_write && (read_address == pending_address);
    reg forward_q;
    reg [31:0] forward_data_q;
    wire [31:0] macro_read_data;

    // Like the inferred bank, this storage path has no reset. Accepted writes
    // must still commit while the parent resets its valid/control pipeline.
    // Power-up contents are undefined; consumers must initialize before use.
    always @(posedge clk) begin
        pending_write <= write_enable;
        forward_q <= forward_pending;
        pending_address <= write_address;
        pending_data <= write_data;
        forward_data_q <= pending_data;
    end

    assign read_data = forward_q ? forward_data_q : macro_read_data;

    gpc_sram_1rw1r_256x32
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
