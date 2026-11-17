# tcl scripts

- `common/io_right.tcl`：將 SP／SM 所有訊號 pins 放在右側，不依賴記憶體介面名稱。
- `common/audit.tcl`：執行 placement／final 的電源檢查與報表輸出。
- `common/check_floorplan.tcl`：記錄 macro 位置並檢查 floorplan 電源連接。
- `common/check_power.tcl`：重新連接電源並檢查 VDD／VSS 連通性。
- `common/pdn_sram.tcl`：建立 standard cells 與 SRAM 電源網格，支援原生及旋轉方向。
- `common/pre_cts.tcl`：設定 CTS 前的 repair buffer 預算與 legalization 範圍。
- `common/repair_budget.tcl`：調整 timing repair 的 buffer 預算與繞線前設定。
- `common/repair_hold.tcl`：修復 hold timing，重新合法化擺放並視需要更新繞線。
- `common/tapcell.tcl`：插入 tap cells 與 endcaps。
- `flow/detail_view.tcl`：展開 R0／MY／MX／R180 hard macro 的元件、走線與電源幾何，供 GUI 檢視。
- `flow/export_macro.tcl`：匯出 hard macro 的 timing model 與 LEF abstract。
- `reports/area.tcl`：輸出面積、buffer 與可擺放區域利用率報表。
- `reports/module_view.tcl`：依模組分組顯示元件並輸出視覺化報表。
- `sp/`: SP IO, SRAM bands, right-side row exclusions and region validation
- `sm/`: SM IO, automatic/fixed SRAM integration and right-side pin validation
- `sram/`: OpenRAM technology integration and physical pin-access validation
- `gpc/`: GPC-specific IO grouping

- `flow/stack_dimensions.py`：依 SP／L1 LEF 計算四個 SP 堆疊的高度，並依右側預留空間計算寬度。
- `sm/place_hard_sp_mirrored.tcl`：將四個 hard SP 排成兩列，右列鏡像，並檢查中央 L1 與 macro 邊界。

- `common/io_bottom.tcl`：將 SM 全部訊號 IO 放到底邊，可選擇逐 pin 最佳化。
- `sm/check_io.tcl`：依設定檢查 SM 訊號 pins 位於右側或底邊。

- `flow/gpc_dimensions.py`：依 SM／L2 LEF 與通道尺寸計算 GPC die 大小。
- `gpc/place_hard_sm_pair.tcl`：放置上下鏡像的兩個 hard SM 與中央 L2，檢查邊界及重疊。
- `gpc/io_channel.tcl`：將 GPC 控制與記憶體 IO 分別放在中央通道左右端。
- `gpc/pdn_hard_sm.tcl`：建立 GPC 電源網格並連接 SM 與 L2 電源。
- `gpc/region_l2_valid.tcl`：依 valid-bit 索引與更新邏輯連線建立四個擺放區域，共用邏輯保留自由擺放。
- `gpc/check_l2_regions.tcl`：合法化後逐顆檢查四組 cells 是否位於指定區域。
