`timescale 1ns / 1ps
// Scalar physical boundary for the shared SP's warp-allocation interface.
// This wrapper adds no state or scheduling logic; shared hardware is unchanged.
module sp_pd_top (
    input wire clk, rst_n,
    input wire iram_we,
    input wire [11:0] iram_waddr,
    input wire [31:0] iram_wdata,
    input wire alloc_valid,
    input wire [15:0] alloc_block_id, alloc_block_idx_x, alloc_block_idx_y,
    input wire [15:0] alloc_thread_id_start,
    input wire [31:0] alloc_active_mask,
    output wire alloc_ready,
    output wire [4:0] alloc_available_slots,
    output wire l1_req_valid,
    output wire [31:0] l1_req_addr,
    output wire [gpu_pkg::DATA_W-1:0] l1_req_wdata,
    output wire [7:0] l1_req_wstrb,
    output wire l1_req_we,
    input wire l1_req_ready, l1_rsp_valid,
    input wire [gpu_pkg::DATA_W-1:0] l1_rsp_rdata
`ifdef ENABLE_GPU_DEBUG
    , input wire perf_clear,
    output wire [gpu_pkg::PERF_COUNT-1:0] perf_events
`endif
);
    warp_alloc_if alloc();
    assign alloc.valid = alloc_valid;
    assign alloc.block_id = alloc_block_id;
    assign alloc.block_idx_x = alloc_block_idx_x;
    assign alloc.block_idx_y = alloc_block_idx_y;
    assign alloc.thread_id_start = alloc_thread_id_start;
    assign alloc.active_mask = alloc_active_mask;
    assign alloc_ready = alloc.ready;
    assign alloc_available_slots = alloc.available_slots;

    sub_partition u_sp (
        .clk(clk), .rst_n(rst_n),
        .iram_we(iram_we), .iram_waddr(iram_waddr), .iram_wdata(iram_wdata),
        .alloc(alloc),
        .l1_req_valid(l1_req_valid), .l1_req_addr(l1_req_addr),
        .l1_req_wdata(l1_req_wdata), .l1_req_wstrb(l1_req_wstrb),
        .l1_req_we(l1_req_we), .l1_req_ready(l1_req_ready),
        .l1_rsp_valid(l1_rsp_valid), .l1_rsp_rdata(l1_rsp_rdata)
`ifdef ENABLE_GPU_DEBUG
        , .perf_clear(perf_clear), .perf_events(perf_events)
`endif
    );
endmodule
