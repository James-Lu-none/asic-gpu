# tcl scripts

- `common/audit.tcl`：執行 placement／final 的電源檢查與報表輸出。
- `common/check_floorplan.tcl`：記錄 macro 位置並檢查 floorplan 電源連接。
- `common/check_power.tcl`：重新連接電源並檢查 VDD／VSS 連通性。
- `common/pdn_sram.tcl`：建立 standard cells 與 SRAM 電源網格，支援原生及旋轉方向。
- `common/pre_cts.tcl`：設定 CTS 前的 repair buffer 預算與 legalization 範圍。
- `common/repair_budget.tcl`：調整 timing repair 的 buffer 預算與繞線前設定。
- `common/repair_hold.tcl`：修復 hold timing，重新合法化擺放並視需要更新繞線。
- `common/tapcell.tcl`：插入 tap cells 與 endcaps。
- `flow/detail_view.tcl`：展開 hard macro 內部幾何，供 GUI 檢視。
- `flow/export_macro.tcl`：匯出 hard macro 的 timing model 與 LEF abstract。
- `reports/area.tcl`：輸出面積、buffer 與可擺放區域利用率報表。
- `reports/module_view.tcl`：依模組分組顯示元件並輸出視覺化報表。
- `sp/`: SP IO, SRAM bands, right-side row exclusions and region validation
- `sm/`: SM IO, automatic/fixed SRAM integration and right-side pin validation
- `sram/`: OpenRAM technology integration and physical pin-access validation
- `gpc/`: GPC-specific IO grouping
