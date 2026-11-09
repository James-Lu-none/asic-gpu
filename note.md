# ORFS RTL-to-GDS-II note

## 1. Synthesis: 邏輯合成

```sh
make flow DESIGN=gpc STAGE=synth
```

config.mk 提供主要設定

- do-binary-libs: 將文字 Liberty 轉成供 OpenROAD 快速載入的 binary cache
- do-yosys-canonicalize: 把 SystemVerilog 轉成 Yosys 的中間表示 `1_1_yosys_canonicalize.rtlil`
- do-yosys: 最佳化 RTLIL 並映射成 `*.lib` 中定義的 library cells，輸出 Verilog netlist `1_2_yosys.v`; SRAM 則保留為已提供模型的 macro instances, see `synth_stat.txt` and `1_2_yosys.log`
- do-1_synth: 將 mapped netlist、LEF、Liberty 與 SDC 連結成設計資料庫 `1_synth.odb`，並寫出供後續階段使用的時序約束 `1_synth.sdc`

## 2. Floorplan: 平面與供電規劃

```sh
make flow DESIGN=gpc STAGE=do-floorplan
```

- do-2_1_floorplan: 讀取 `1_synth.odb`／`1_synth.sdc` 與平台／macro 模型，依 `config.mk` 建立 die、core、rows 與 routing tracks，輸出 `2_1_floorplan.odb`、`2_1_floorplan.sdc`
- do-2_2_floorplan_macro: 放置 macros，輸出 `2_2_floorplan_macro.odb`；GPC 在此固定 21 顆 SRAM 的位置
- do-2_3_floorplan_tapcell: 依 macro halo 切開 rows，插入 tap／endcap cells，輸出 `2_3_floorplan_tapcell.odb`
- do-2_4_floorplan_pdn: 建立 VDD／VSS rails、stripes 與 vias，連接 SRAM supply rings，輸出 `2_4_floorplan_pdn.odb`
- do-2_floorplan、do-2_floorplan.sdc: 將上述結果複製成 `2_floorplan.odb`、`2_floorplan.sdc`，供 placement 使用

## 3. Placement: 標準元件放置

```sh
make flow DESIGN=gpc STAGE=do-place
```

- do-3_1_place_gp_skip_io: 讀取 `2_floorplan.odb`／`2_floorplan.sdc`，依 `PLACE_DENSITY` 等設定初步安排 cells，輸出 `3_1_place_gp_skip_io.odb`
- do-3_2_place_iop: 依 cells 位置與 `IO_CONSTRAINTS` 放置邊界接腳，輸出 `3_2_place_iop.odb`
- do-3_3_place_gp: 納入 IO 位置，依時序與可繞性最佳化 cells 分布，輸出 `3_3_place_gp.odb`
- do-3_4_place_resized: 以估計 RC 做 cell sizing／buffer insertion，修復負載與時序問題，輸出 `3_4_place_resized.odb`
- do-3_5_place_dp: 消除重疊並對齊 rows／sites，輸出 `3_5_place_dp.odb`、`3_place.sdc`，see `3_detailed_place.rpt`
- do-3_place: 將結果複製成 `3_place.odb`，供 CTS 使用

## 4. CTS: 時脈樹合成

```sh
make flow DESIGN=gpc STAGE=do-cts
```

- do-4_1_cts: TritonCTS 讀取 `3_place.odb`／`3_place.sdc`，插入 library clock cells 建立 clock tree、控制 latency／skew，再修復 setup／hold 並 legalization，輸出 `4_1_cts.odb`、`4_cts.sdc`
    - Timing 改用 propagated clock 與估計 RC，see `4_cts_final.rpt`
- do-4_cts: 將結果複製成 `4_cts.odb`，供 routing 使用

## 5. Routing: 繞線

```sh
make flow DESIGN=gpc STAGE=do-route
```

- do-5_1_grt: 讀取 `4_cts.odb`／`4_cts.sdc`，依平台 routing 設定檢查 pin access、規劃 guides，再以 routing RC 修復負載與時序，輸出 `5_1_grt.odb`、`5_1_grt.sdc`、`route.guide`
    - See `5_global_route.rpt`；congestion overflow 為 0 不代表 detailed routing 無 DRC
- do-5_2_route: 決定實際金屬線段與 vias，修復 router DRC，輸出 `5_2_route.odb`
- do-5_3_fillcell: 在 rows 空隙插入 filler cells，延續電源軌等結構，輸出 `5_3_fillcell.odb`
- do-5_route、do-5_route.sdc: 將結果複製成 `5_route.odb`、`5_route.sdc`，供 finishing 使用

## 6. Finishing: 最終資料產出

```sh
make flow DESIGN=gpc STAGE=do-finish
make flow DESIGN=gpc STAGE=do-gds
```

- do-6_1_fill: 讀取 `5_route.odb`／`5_route.sdc`，依平台設定加入 metal density fill，未啟用則複製 route database，輸出 `6_1_fill.odb`
- do-6_1_fill.sdc: 複製 `5_route.sdc` 為 `6_1_fill.sdc`
- do-6_report: 依平台 RCX 規則從走線萃取寄生 RC，產生 `6_final.spef` 並執行 final STA／static IR，寫出 `6_final.{odb,def,v,sdc}`，see `6_finish.rpt`
- do-gds: 依 GDS layer mapping 將 final DEF 與 standard-cell／macro GDS 合併成 `6_final.gds`；此步不包含在 `do-finish` 中

## 7. Signoff: 四項最終檢查

```sh
make signoff DESIGN=gpc
```

使用既有 final 資料，重新執行 STA／static IR、DRC、LVS。GPC 的 SRAM characterization、macro DRC／LVS 與完整 LVS reference views 尚待補齊。

### 7.1 STA: 靜態時序分析

- do-6_report: 讀取 final database、SDC、Liberty 與 extracted SPEF，以實作 clock tree 分析 setup／hold、WNS／TNS、slew／capacitance，see `reports/6_finish.rpt`
- 與第 7 節、static IR 共用同一次分析，不需分別重跑

### 7.2 DRC: 版圖幾何規則檢查

- `make drc DESIGN=gpc`: 以 KLayout 的 `drc/FreePDK45.lydrc` 檢查 `6_final.gds` 的線寬、間距、包覆等規則，輸出 `reports/6_drc.lyrdb`、`reports/6_drc_count.rpt`
- 非零違規數回傳失敗；GDS DRC 與 router DRC 的檢查範圍不同

### 7.3 LVS: 版圖與參考電路比對

- `make lvs DESIGN=mul32`: 將 `6_final.v` 轉成 `6_final.cdl`，附上 `NangateOpenCellLibrary.cdl`，形成 `objects/6_final_concat.cdl`
- 以 `lvs/lvs_freepdk45.lylvs` 從 `6_final.gds` 萃取電晶體與連線，與 reference 比對連接及 W／L 等參數，輸出 `6_lvs.lvsdb`、`6_lvs_extracted.cir`
- 此 deck 使用隱含 well／supply 連接；GPC 另需整合 SRAM SPICE／CDL 與對應 deck 設定

### 7.4 IR: 靜態供電壓降分析

- do-6_report: 原生 `final_outputs.tcl` 呼叫 `analyze_power_grid`，依 final PDN、Liberty 功耗、平台 RC 與供電來源設定，分析 VDD 壓降與 VSS 電位上升，see `logs/6_report.log`
- 與 STA 共用同一次分析；結果依活動率與功耗模型估計，並非 workload 的 dynamic IR

## 參考資料

- [LVS deck 來源與本地修改](lvs/SOURCE.md)
- [ORFS tutorial](https://openroad-flow-scripts.readthedocs.io/en/latest/tutorials/FlowTutorial.html)
- [ORFS variables](https://openroad-flow-scripts.readthedocs.io/en/latest/user/FlowVariables.html)
- [Nangate45 platform](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts/tree/master/flow/platforms/nangate45)
- [OpenSTA](https://github.com/The-OpenROAD-Project/OpenSTA)
