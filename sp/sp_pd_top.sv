`timescale 1ns / 1ps
`include "gpu_defines.vh"
// Scalar physical boundary; no added state or memory protocol conversion.
module sp_pd_top (
    input wire clk,
    input wire rst_n,

    // Instruction Load Interface (From Hardware Engine)
    input wire iram_we,
    input wire [11:0] iram_waddr,
    input wire [31:0] iram_wdata,

    // Warp Launch Interface (From Warp Scheduler)
    input wire alloc_valid,
    input wire [15:0] alloc_block_id, alloc_block_idx_x, alloc_block_idx_y,
    input wire [15:0] alloc_thread_id_start,
    input wire [31:0] alloc_active_mask,
    output wire alloc_ready,
    output wire [4:0] alloc_available_slots,
    input wire [15:0] block_dim_x,

    // Memory Interface (To SM-Level Dynamic Coalescing Engine)
    output wire                          mem_req_valid,
    output wire                          mem_req_is_load,
    output wire [$clog2(`MAX_WARPS)-1:0] mem_req_warp_id,
    output wire [4:0]                    mem_req_rd,
    output wire [11:0]                   mem_req_pc,
    output wire [`NUM_LANES-1:0]         mem_req_mask,
    output wire [`WARP_DATA_W-1:0]       mem_req_addr,
    output wire [`WARP_DATA_W-1:0]       mem_req_wdata,
    input  wire                          mem_req_ready,

    input  wire                          mem_rsp_valid,
    input  wire [$clog2(`MAX_WARPS)-1:0] mem_rsp_warp_id,
    input  wire [4:0]                    mem_rsp_rd,
    input  wire [11:0]                   mem_rsp_pc,
    input  wire [`NUM_LANES-1:0]         mem_rsp_mask,
    input  wire                          mem_rsp_is_load,
    input  wire [`WARP_DATA_W-1:0]       mem_rsp_rdata
`ifdef ENABLE_GPU_DEBUG
    , input wire perf_clear,
    output wire [`PERF_COUNT-1:0] perf_events
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
        .alloc(alloc),
        .clk(clk),
        .rst_n(rst_n),
        .iram_we(iram_we),
        .iram_waddr(iram_waddr),
        .iram_wdata(iram_wdata),
        .block_dim_x(block_dim_x),
        .mem_req_valid(mem_req_valid),
        .mem_req_is_load(mem_req_is_load),
        .mem_req_warp_id(mem_req_warp_id),
        .mem_req_rd(mem_req_rd),
        .mem_req_pc(mem_req_pc),
        .mem_req_mask(mem_req_mask),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),
        .mem_req_ready(mem_req_ready),
        .mem_rsp_valid(mem_rsp_valid),
        .mem_rsp_warp_id(mem_rsp_warp_id),
        .mem_rsp_rd(mem_rsp_rd),
        .mem_rsp_pc(mem_rsp_pc),
        .mem_rsp_mask(mem_rsp_mask),
        .mem_rsp_is_load(mem_rsp_is_load),
        .mem_rsp_rdata(mem_rsp_rdata)
`ifdef ENABLE_GPU_DEBUG
        , .perf_clear(perf_clear), .perf_events(perf_events)
`endif
    );
endmodule
