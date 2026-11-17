# Streaming-multiprocessor physical design

- `flat_auto_right` for automatic SRAM placement with all signal IO on the
right.
- `flat_fixed_right` retains fixed SRAM coordinates for comparison.
- `hard_sp_stack` assembles four SP abstracts.

- `hard_sp_stack` derives its height from the SP LEF and keeps the SP/L1 anchors fixed. `SM_RIGHT_SPACE` controls space to the right of L1 (default 80um).
- A wider comparison can use the same config with an independent result name:

```bash
make flow DESIGN=sm FLOW_VARIANT=hard_sp_stack_wide \
  DESIGN_CONFIG=sm/variants/hard_sp_stack.mk SM_RIGHT_SPACE=600 STAGE=finish JOBS=8
```

- `hard_sp_mirrored`：左右各兩個 SP，右列 MY 鏡像，IO 朝向中央

- `hard_sp_mirrored_bottom`：保留 SP 左右鏡像配置，將所有 SM 訊號 IO 放到底邊，維持 2um pin 間距。
  - 央通道 600um、獨立底邊 pin placement、hold repair target 0.08ns