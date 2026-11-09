`timescale 1ns / 1ps
// ASIC cache storage: data and tag share address, enable and refill timing.
// Macro outputs are valid for capture at the next rising edge after a lookup;
// output values outside that read interval are not part of the interface.
module cache_line_ram #(
    parameter integer DATA_W = 256,
    parameter integer TAG_W = 21,
    parameter integer NUM_LINES = 64,
    parameter integer ADDR_W = $clog2(NUM_LINES)
)(
    input wire clk,
    input wire read_enable,
    input wire [ADDR_W-1:0] read_address,
    output wire [DATA_W-1:0] read_data,
    output wire [TAG_W-1:0] read_tag,
    input wire write_enable,
    input wire [ADDR_W-1:0] write_address,
    input wire [DATA_W-1:0] write_data,
    input wire [TAG_W-1:0] write_tag
);
    wire [DATA_W+TAG_W-1:0] read_line;
    wire [DATA_W+TAG_W-1:0] write_line = {write_tag, write_data};
    wire [ADDR_W-1:0] address = write_enable ? write_address : read_address;
    wire chip_select_n = !(read_enable || write_enable);
    assign {read_tag, read_data} = read_line;

`ifndef SYNTHESIS
    // A controller change requiring simultaneous accesses needs another port.
    always @(posedge clk)
        if (read_enable && write_enable)
            $fatal(1, "Single-port cache SRAM received both lookup and refill");
`endif
    generate
        if (DATA_W == 256 && TAG_W == 21 && NUM_LINES == 64 && ADDR_W == 6) begin : l1
            gpc_sram_1rw_64x277
`ifndef SYNTHESIS
                #(.VERBOSE(0))
`endif
            memory (
                .clk0(clk), .csb0(chip_select_n), .web0(!write_enable),
                .addr0(address), .din0(write_line), .dout0(read_line)
            );
        end else if (DATA_W == 256 && TAG_W == 18 && NUM_LINES == 512 && ADDR_W == 9) begin : l2
            gpc_sram_1rw_512x274
`ifndef SYNTHESIS
                #(.VERBOSE(0))
`endif
            memory (
                .clk0(clk), .csb0(chip_select_n), .web0(!write_enable),
                .addr0(address), .din0(write_line), .dout0(read_line)
            );
        end else begin : unsupported_shape
            initial $fatal(1, "Unsupported cache SRAM shape");
        end
    endgenerate
endmodule
