# GPC hard-SM 組裝

`hard_sm_pair` 使用兩個已驗證的 SM hard macro；每個 SM 包含四個 16-lane SP。

- 下方 SM0 使用 MX，上方 SM1 使用 R0，兩者的訊號 pins 面向中央通道。
- 中央放置四個 L2 SRAM slices，以 2×2 排列；它們共同構成 L2 的資料寬度。
- 控制介面、clock、reset 與狀態放在中央通道左端；global-memory AXI 放在右端。
- 預設 die 為 3951 × 5296 µm，中央通道高 1000 µm，左右各預留 200 µm。
- SM 電源從 M9 接到 GPC M10；L2 電源經 M4–M7 接入。SM 內部已使用 M10

GPC 內部細節可用以下指令查看；展開支援 R0／MY／MX／R180，並保留原本的 implementation ODB：

```bash
# integrate
make flow DESIGN=gpc FLOW_VARIANT=hard_sm_pair_l2_valid_regions_compact

# inspect
make details DESIGN=gpc FLOW_VARIANT=hard_sm_pair_l2_valid_regions_compact
make gui-web-detail DESIGN=gpc FLOW_VARIANT=hard_sm_pair_l2_valid_regions_compact
make images DESIGN=gpc FLOW_VARIANT=hard_sm_pair_l2_valid_regions_compact IMAGE_STAGE=6_final_detailed
```
