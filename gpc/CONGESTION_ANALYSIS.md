# hard_sm_pair 局部壅塞調查

分析資料：`results/5_1_grt-failed.odb`、`results/1_2_yosys.v`、`reports/congestion.rpt`、`logs/3_3_place_gp.log`、`reports/4_cts_final.rpt`。

## 定位結果

壅塞報告共 1025 個 region 記錄，其中 1000 個的左下角落在 x=2000–2100、y=2200–2400 µm

在 x=1850–2250、y=2200–2450 µm 的擴大觀察窗內：

- 共 6339 個非 macro instances，包含 buffers、clock cells、tap cells。
- L2 `u_l2_cache.u_cache.valid_ram` 的 512 個暫存器全部位於此窗。
- 合成網表由這 512 個暫存器 D 端回追，遇到暫存器或無法辨識的外部 driver 即停止，共 3682 個 combinational cells；其中 3149 個原始 instance 名稱仍位於觀察窗內。此 cone 包含共用上游控制，不等於每一個 cell 都只服務 valid 更新。
- 合成 cone 內有 512 MUX2、1025 AOI21、1033 NAND3、528 NAND2 等。後續 resizer/CTS 會改動部分 cells，不能把合成數量直接當 final 數量。

因此熱點主要與 L2 valid-bit 儲存及其讀寫／控制網路有關

## RTL 結構

`rtl/common/unified_cache.sv`：

- `valid_ram` 是 `reg [NUM_LINES-1:0]`，沒有放進 data/tag SRAM。
- `valid_ram[core_index]` 動態讀取，合成為多選一網路。
- `valid_ram[req_index_q]` 在不同 state 中動態寫入，形成地址選擇、保持舊值與更新控制。
- reset/flush 清除整組 valid bits，共用控制訊號需要廣播。

這使原本簡短的 RTL 形成數百個暫存器和大量互連，工具實際執行了多輪壅塞區 inflation：weighted congestion 4.9988 → 3.1033 → 3.5201 → 4.0672 → 4.1984，連續三次沒有改善後退回較佳配置。最後報告 routability weighted congestion 為 2.4920，仍超過 1.01 目標。

因此工具有嘗試分散，但這個 heuristic 在目前 wirelength/timing/density 的折衷與停止條件下沒有解決 routing congestion；它不是硬性保證可繞的最佳化。

