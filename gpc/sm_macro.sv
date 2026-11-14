`timescale 1ns / 1ps
`include "gpu_defines.vh"
// Physical SM boundary; interface mirrors the qualified SM top.
(* blackbox *) module streaming_multiprocessor (
    input wire clk,
    input wire rst_n,
    input wire flush,

    // TBS Dispatch Interface (From GPC)
    input wire block_issue_valid,
    input wire [15:0] block_idx_x,
    input wire [15:0] block_idx_y,
    input wire [9:0] warps_per_block,
    input wire [15:0] threads_per_block,
    input wire [15:0] block_dim_x,

    output wire block_accepted,
    output wire [4:0] available_warp_slots,
    output wire sm_idle,

    // Global Config & I-RAM Interface (From GPC)
    input wire [31:0] dma_src_addr,
    input wire [31:0] dma_dst_addr,
    input wire iram_we,
    input wire [11:0] iram_waddr,
    input wire [31:0] iram_wdata,

    // L1 to L2 Cache Interface
    output wire l1_req_valid,
    output wire [31:0] l1_req_addr,
    output wire [255:0]l1_req_wdata,
    output wire [31:0] l1_req_wstrb,
    output wire l1_req_we,
    input wire l1_req_ready,
    input wire l1_rsp_valid,
    input wire [255:0]l1_rsp_rdata
`ifdef ENABLE_GPU_DEBUG
    , input wire perf_clear,
    output reg [31:0] perf_increments [0:`PERF_COUNT-1]
`endif
);
endmodule
