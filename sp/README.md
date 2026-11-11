## Hold-repair follow-up

`ar1_hold100` keeps the same design and SDC, targets +0.05 ns hold slack and
allows up to 100% hold buffers. Both POST_CTS_TCL and POST_GLOBAL_ROUTE_TCL
source `scripts/repair_hold.tcl`; the global-route pass also reroutes added buffers.
The same file sets upper-layer routing capacity reservation to 10% before
global routing; this variant uses 300 congestion iterations and seed 1.

```sh
make flow DESIGN=sp FLOW_VARIANT=ar1_hold100
```

Post-hook reports are `4_cts_hold_repaired.rpt` and
`5_global_route_hold_repaired.rpt`. Use `6_finish.rpt` for final extracted timing.

Completed `ar1_hold100`: final extracted setup +3.73182 ns, hold +0.0215132 ns,
zero setup/hold violations, router DRC 0 and final netlist LEC passed.
Max slew/capacitance violations and the static-power activity warning remain.
See `ar1_hold100/reports/hold_repair_comparison.md` for the comparison.

To reuse this completed SP as a hard macro in SM:

```sh
make abstract DESIGN=sp FLOW_VARIANT=ar1_hold100
make flow DESIGN=sm
```

The exporter writes `sp_pd_top.lef` and `sp_pd_top_typ.lib` beside the final
GDS/netlist.
