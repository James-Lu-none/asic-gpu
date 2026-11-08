# mul32 history

## case 1

```
# create_clock -name core_clk -period 10.0 [get_ports clk]
create_clock -name core_clk -period 2.0 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks core_clk]
set_clock_transition 0.10 [get_clocks core_clk]
set_input_delay -max 1.0 -clock core_clk [get_ports {a* b*}]
set_input_delay -min 0.2 -clock core_clk [get_ports {a* b*}]
set_output_delay -max 1.0 -clock core_clk [get_ports {result*}]
set_output_delay -min 0.2 -clock core_clk [get_ports {result*}]
set_driving_cell -lib_cell BUF_X1 [get_ports {a* b*}]
set_load 5.0 [get_ports {result*}]
```

core_clk 10ns 時 wns 7.62ns
core_clk 2ns 時 wns -0.19ns

透過分析 6_finish.rpt

```log
==========================================================================
finish report_checks -path_delay max
--------------------------------------------------------------------------
Startpoint: b[6] (input port clocked by core_clk)
Endpoint: low_product[28]$_DFF_P_
          (rising edge-triggered flip-flop clocked by core_clk)
Path Group: core_clk
Path Type: max

Fanout     Cap    Slew   Delay    Time   Description
-----------------------------------------------------------------------------
                          0.00    0.00   clock core_clk (rise edge)
                          0.00    0.00   clock network delay (propagated)
                          1.00    1.00 v input external delay
     1    3.30    0.01    0.01    1.01 v b[6] (in)
                                         b[6] (net)
                  0.01    0.00    1.01 v input61/A (BUF_X4)
    11   19.30    0.01    0.03    1.03 v input61/Z (BUF_X4)
                                         net61 (net)
                  0.01    0.00    1.04 v place588/A (BUF_X2)
     2    2.04    0.00    0.02    1.06 v place588/Z (BUF_X2)
                                         net588 (net)
                  0.00    0.00    1.06 v _2968_/A2 (AND2_X1)
     1    4.04    0.01    0.03    1.09 v _2968_/ZN (AND2_X1)
                                         _0116_ (net)
                  0.01    0.00    1.09 v _3722_/A (FA_X1)
     1    4.22    0.02    0.10    1.20 v _3722_/S (FA_X1)
                                         _1690_ (net)
                  0.02    0.00    1.20 v _4004_/A (FA_X1)
     1    3.91    0.02    0.08    1.28 v _4004_/CO (FA_X1)
                                         _2198_ (net)
                  0.02    0.00    1.28 v _3942_/B (FA_X1)
     1    2.89    0.01    0.12    1.40 ^ _3942_/S (FA_X1)
                                         _2001_ (net)
                  0.01    0.00    1.40 ^ _3853_/CI (FA_X1)
     1    3.91    0.02    0.10    1.50 v _3853_/S (FA_X1)
                                         _1868_ (net)
                  0.02    0.00    1.50 v _3803_/A (FA_X1)
     1    2.88    0.01    0.12    1.62 ^ _3803_/S (FA_X1)
                                         _1864_ (net)
                  0.01    0.00    1.62 ^ _3802_/CI (FA_X1)
     1    3.50    0.02    0.09    1.71 v _3802_/S (FA_X1)
                                         _1866_ (net)
                  0.02    0.00    1.71 v _4097_/B (HA_X1)
     4   10.67    0.02    0.07    1.78 v _4097_/S (HA_X1)
                                         _0537_ (net)
                  0.02    0.00    1.78 v _2468_/B2 (AOI21_X4)
     2    4.54    0.02    0.03    1.82 ^ _2468_/ZN (AOI21_X4)
                                         _1243_ (net)
                  0.02    0.00    1.82 ^ _2491_/B1 (OAI21_X2)
     2    4.63    0.01    0.02    1.84 v _2491_/ZN (OAI21_X2)
                                         _1265_ (net)
                  0.01    0.00    1.84 v _2498_/B1 (OAI33_X1)
     2    3.64    0.07    0.08    1.92 ^ _2498_/ZN (OAI33_X1)
                                         _1272_ (net)
                  0.07    0.00    1.92 ^ rebuffer758/A (BUF_X2)
     1    6.60    0.01    0.04    1.95 ^ rebuffer758/Z (BUF_X2)
                                         net758 (net)
                  0.01    0.00    1.95 ^ _2761_/A2 (NOR3_X4)
     1    3.99    0.02    0.01    1.97 v _2761_/ZN (NOR3_X4)
                                         _0881_ (net)
                  0.02    0.00    1.97 v _2762_/B1 (OAI221_X2)
     2    8.30    0.05    0.06    2.03 ^ _2762_/ZN (OAI221_X2)
                                         _0882_ (net)
                  0.05    0.00    2.03 ^ _3127_/C1 (OAI221_X2)
     3    8.05    0.02    0.04    2.07 v _3127_/ZN (OAI221_X2)
                                         _1036_ (net)
                  0.02    0.00    2.07 v _3473_/B1 (OAI22_X2)
     1    2.36    0.03    0.04    2.11 ^ _3473_/ZN (OAI22_X2)
                                         _1183_ (net)
                  0.03    0.00    2.11 ^ _3474_/A (XNOR2_X1)
     1    1.47    0.02    0.04    2.16 ^ _3474_/ZN (XNOR2_X1)
                                         _0724_ (net)
                  0.02    0.00    2.16 ^ low_product[28]$_DFF_P_/D (DFF_X1)
                                  2.16   data arrival time

                          2.00    2.00   clock core_clk (rise edge)
                          0.00    2.00   clock source latency
     1    7.84    0.00    0.00    2.00 ^ clk (in)
                                         clk (net)
                  0.00    0.00    2.00 ^ clkbuf_0_clk/A (CLKBUF_X3)
     8   26.15    0.02    0.04    2.05 ^ clkbuf_0_clk/Z (CLKBUF_X3)
                                         clknet_0_clk (net)
                  0.02    0.00    2.05 ^ clkbuf_3_4__f_clk/A (CLKBUF_X3)
     9   20.31    0.02    0.05    2.10 ^ clkbuf_3_4__f_clk/Z (CLKBUF_X3)
                                         clknet_3_4__leaf_clk (net)
                  0.02    0.00    2.10 ^ low_product[28]$_DFF_P_/CK (DFF_X1)
                         -0.10    2.00   clock uncertainty
                          0.00    2.00   clock reconvergence pessimism
                         -0.03    1.96   library setup time
                                  1.96   data required time
-----------------------------------------------------------------------------
                                  1.96   data required time
                                 -2.16   data arrival time
-----------------------------------------------------------------------------
                                 -0.19   slack (VIOLATED)
```

看起來 wire delay (net) 目前都是 0，然後六個 FA_X1 (full adder with Drive Strength 1) 貢獻了 1.71-1.09 = 0.62 的 latency, 扣掉 1ns 的 input delay, 佔全部的 53%,  所以可能的做法是把 FA_X1 改快一點的？

- 嘗試改寫 default mapping

ADDER_MAP_FILE changed to none, disables both FA and HA mapping

Default mapping:

- Synthesis area 3870.566 um^2; 356 FA_X1, 232 HA_X1 and 96 DFFs.
- Final standard-cell area 4376.76 um^2, excluding filler cells.
- Setup worst slack -0.192218 ns; setup TNS -3.38341 ns.
- Hold worst slack +0.0000368039 ns; hold TNS 0.
- Worst setup path: b[6] to low_product[28].

No dedicated adder mapping:

- Synthesis area 4958.506 um^2; no FA_X1/HA_X1; 96 DFFs.
- More XOR/XNOR, AOI/OAI and other standard cells, not a different macro.
- Final standard-cell area 6709.58 um^2 (+53.3%).
- Setup worst slack -0.203846 ns; setup TNS -1.63421 ns.
- Hold worst slack +0.00301929 ns; hold TNS 0.
- Worst setup path: b[9] to low_product[30].

TNS improved, but worst slack worsened by about 11.6 ps with a substantial area cost, hence keep default mapping for now
