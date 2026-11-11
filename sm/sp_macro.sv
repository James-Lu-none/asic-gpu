// ASIC integration only: replace the SP implementation with its hardened view.
`timescale 1ns / 1ps
// Streaming Multiprocessor (SM) Compute Core - TRUE SIMT ARCHITECTURE
// Top-level module encapsulating the Warp Scheduler, Fetch/Decode, 
// Vector Register File, and Execution Pipeline.

import gpu_pkg::*;

module sub_partition (
    input wire clk,
    input wire rst_n,

    // Instruction Load Interface (From Hardware Engine)
    input wire iram_we,
    input wire [11:0] iram_waddr,
    input wire [31:0] iram_wdata,

    // Warp Launch Interface (From Warp Scheduler)
    warp_alloc_if.slave alloc,

    // L1 Cache Interface (To SM Global L1 Cache)
    output wire l1_req_valid,
    output wire [31:0] l1_req_addr,
    output wire [DATA_W-1:0] l1_req_wdata,
    output wire [7:0] l1_req_wstrb,
    output wire l1_req_we,
    input wire l1_req_ready,
    input wire l1_rsp_valid,
    input wire [DATA_W-1:0] l1_rsp_rdata
`ifdef ENABLE_GPU_DEBUG
    , input wire perf_clear,
    output wire [PERF_COUNT-1:0] perf_events
`endif
);

    sp_pd_top u_macro (
        .clk(clk), .rst_n(rst_n),
        .iram_we(iram_we), .iram_waddr(iram_waddr), .iram_wdata(iram_wdata),
        .alloc_valid(alloc.valid), .alloc_ready(alloc.ready),
        .alloc_available_slots(alloc.available_slots),
        .alloc_block_id(alloc.block_id),
        .alloc_block_idx_x(alloc.block_idx_x), .alloc_block_idx_y(alloc.block_idx_y),
        .alloc_thread_id_start(alloc.thread_id_start),
        .alloc_active_mask(alloc.active_mask),
        .l1_req_valid(l1_req_valid), .l1_req_addr(l1_req_addr),
        .l1_req_wdata(l1_req_wdata), .l1_req_wstrb(l1_req_wstrb),
        .l1_req_we(l1_req_we), .l1_req_ready(l1_req_ready),
        .l1_rsp_valid(l1_rsp_valid), .l1_rsp_rdata(l1_rsp_rdata)
`ifdef ENABLE_GPU_DEBUG
        , .perf_clear(perf_clear), .perf_events(perf_events)
`endif
    );
endmodule

(* blackbox *) module sp_pd_top (
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
endmodule
