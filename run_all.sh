#!/usr/bin/env bash
# Rebuild current RTL: SP -> exported SP IP -> SM -> exported SM IP -> dual-SM GPC.
# Run from any directory: JOBS=8 bash /path/to/asic-gpu/run_all.sh
# Requires effective ASIC dimensions 2 SMs, 4 SPs, 16 lanes (config/asic_defines.mk).
# Example: FLOW_TIMEOUT=6h MAX_RETRIES=1 JOBS=8 bash run_all.sh
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

jobs=${JOBS:-8}
hardware_root=${HARDWARE_ROOT:-"$PWD/../fpga-gpu-hardware"}
sp_variant=${SP_VARIANT:-free_right_io_large}
sm_variant=${SM_VARIANT:-hard_sp_mirrored_bottom_sp15}
gpc_variant=${GPC_VARIANT:-hard_sm_pair_sp15}
defines="$hardware_root/rtl/common/gpu_defines.vh"

[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo 'JOBS must be a positive integer.' >&2; exit 1; }
for variant in "$sp_variant" "$sm_variant" "$gpc_variant"; do
    [[ "$variant" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid variant: $variant" >&2; exit 1; }
done
[[ -f "$defines" ]] || { echo "Missing RTL header: $defines" >&2; exit 1; }
architecture=$(make --no-print-directory -s DESIGN=sp \
    DESIGN_CONFIG=sp/variants/free_right_io_large.mk \
    "HARDWARE_ROOT=$hardware_root" print-architecture)
if [[ "$architecture" != 2:4:16 ]]; then
    printf 'This flow requires ASIC architecture 2:4:16; got %s. Check config/asic_defines.mk\n' "$architecture" >&2
    exit 1
fi

# SRAM views are reused; generate them separately if they were also deleted.
sram_root=${SRAM_ROOT:-/work/artifacts/asic-gpc-audit/openram}
case "$sram_root" in
    /work/*) sram_host="$PWD/${sram_root#/work/}" ;;
    *) echo 'SRAM_ROOT must be a /work/... path visible inside the flow container.' >&2; exit 1 ;;
esac
for macro in \
    vrf_128x32/gpc_sram_1rw1r_128x32 \
    iram_1024x32/gpc_sram_1rw1r_1024x32 \
    cache_l1_64x70/gpc_sram_1rw_64x70 \
    cache_l2_512x69/gpc_sram_1rw_512x69; do
    for suffix in .lef .gds _TT_1p1V_25C.lib; do
        [[ -s "$sram_host/$macro$suffix" ]] || {
            echo "Missing SRAM view: $sram_host/$macro$suffix" >&2
            exit 1
        }
    done
done

# Retry controls: 0 disables retries/timeouts respectively. Timeout is per flow
# attempt (not an inactivity detector). Each retry starts in a separate directory.
max_retries=${MAX_RETRIES:-1}
flow_timeout=${FLOW_TIMEOUT:-8h}
retry_orfs_args=${RETRY_ORFS_ARGS:-'PLACE_DENSITY=0.45'}
retry_grt_args=${RETRY_GRT_ARGS:-'-congestion_iterations 600 -verbose'}
retry_run_id="$(date +%Y%m%d_%H%M%S)_$$"
[[ "$max_retries" =~ ^[0-9]+$ ]] || { echo 'MAX_RETRIES must be nonnegative.' >&2; exit 1; }
command -v timeout >/dev/null || { echo 'GNU timeout is required.' >&2; exit 1; }
retry_logs="$PWD/artifacts/asic/run_all"
mkdir -p "$retry_logs"
active_cid=''
cleanup_attempt() {
    if [[ -n "$active_cid" && -s "$active_cid" ]]; then
        docker rm -f "$(cat "$active_cid")" >/dev/null 2>&1 || true
    fi
}
trap cleanup_attempt EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

run_flow() {
    local -n selected_args=$1
    local item design='' base='' base_orfs='' attempt variant log status retry_reason=''
    local cid_dir
    local -a base_args=() attempt_args=()
    for item in "${selected_args[@]}"; do
        case "$item" in
            DESIGN=*) design=${item#*=} ;;
            FLOW_VARIANT=*) base=${item#*=} ;;
            ORFS_ARGS=*) base_orfs=${item#*=}; continue ;;
        esac
        base_args+=("$item")
    done
    for ((attempt=0; attempt<=max_retries; attempt++)); do
        variant=$base
        attempt_args=("${base_args[@]}")
        if ((attempt)); then
            variant="${base}_retry${attempt}_${retry_run_id}"
            attempt_args+=("ORFS_ARGS=$base_orfs $retry_orfs_args GRT_SEED=$((attempt+1))")
            if [[ "$retry_reason" == congestion ]]; then
                attempt_args+=("ORFS_ARGS=$base_orfs $retry_orfs_args GRT_SEED=$((attempt+1)) GLOBAL_ROUTE_ARGS=\"$retry_grt_args\"")
            fi
        else
            attempt_args+=("ORFS_ARGS=$base_orfs")
        fi
        attempt_args+=("FLOW_VARIANT=$variant")
        log="$retry_logs/${design}_${variant}_$(date +%Y%m%d_%H%M%S)_$$.log"
        cid_dir=$(mktemp -d)
        active_cid="$cid_dir/container.cid"
        printf '\nFlow %s/%s, attempt %d/%d, timeout %s; log: %s\n' \
            "$design" "$variant" "$((attempt+1))" "$((max_retries+1))" "$flow_timeout" "$log"
        if timeout --signal=TERM --kill-after=30s "$flow_timeout" \
            make flow "${attempt_args[@]}" STAGE=finish "DOCKER_ARGS=--cidfile $active_cid" 2>&1 | tee "$log"; then
            status=0
        else
            status=${PIPESTATUS[0]}
            # A failed log write must not be treated as a successful flow.
            if ((status == 0)); then status=1; fi
        fi
        # Killing the Docker CLI alone can leave the actual flow container running.
        cleanup_attempt
        rm -rf -- "$cid_dir"
        active_cid=''
        if ((status == 0)); then
            selected_args=("${attempt_args[@]}")
            return 0
        fi
        if ((attempt == max_retries)); then
            printf 'Flow failed (exit %s); retry limit reached. See %s\n' "$status" "$log" >&2
            return "$status"
        fi
        if ((status == 124)); then
            retry_reason=timeout
        elif ((status == 137)); then
            retry_reason='forced termination (timeout kill or resource limit)'
        elif grep -q 'GRT-0116' "$log"; then
            retry_reason=congestion
        else
            printf 'Not retrying an unclassified error (exit %s). See %s\n' "$status" "$log" >&2
            return "$status"
        fi
        printf 'Retrying after %s with lower density and a different seed.\n' "$retry_reason"
    done
}

common=("JOBS=$jobs" "HARDWARE_ROOT=$hardware_root" "SRAM_ROOT=$sram_root")
sp=("${common[@]}" DESIGN=sp "FLOW_VARIANT=$sp_variant"
    DESIGN_CONFIG=sp/variants/free_right_io_large.mk)

printf '\n[1/3] Build SP from current RTL and export SP IP\n'
make elaborate "${sp[@]}"
run_flow sp
for item in "${sp[@]}"; do
    if [[ "$item" == FLOW_VARIANT=* ]]; then sp_variant=${item#*=}; fi
done
# Physical leaf cells/SRAMs must support the declared mirror axes.
make abstract "${sp[@]}" 'ORFS_ARGS=MACRO_SYMMETRY="X Y"'
make images "${sp[@]}" IMAGE_STAGE=6_final

sm=("${common[@]}" DESIGN=sm "FLOW_VARIANT=$sm_variant"
    DESIGN_CONFIG=sm/variants/hard_sp_mirrored_bottom.mk
    "SP_MACRO_DIR=/work/artifacts/asic/sp/$sp_variant/results"
    "SM_CENTER_SPACE=${SM_CENTER_SPACE:-600}" SM_BOTTOM_GROUP=0
    'ORFS_ARGS=HOLD_SLACK_MARGIN=0.08')

printf '\n[2/3] Build SM with the new SP IP and export SM IP\n'
make elaborate "${sm[@]}"
run_flow sm
for item in "${sm[@]}"; do
    if [[ "$item" == FLOW_VARIANT=* ]]; then sm_variant=${item#*=}; fi
done
make abstract "${sm[@]}" 'ORFS_ARGS=HOLD_SLACK_MARGIN=0.08 MACRO_SYMMETRY="X Y"'
make images "${sm[@]}" IMAGE_STAGE=6_final

gpc=("${common[@]}" DESIGN=gpc "FLOW_VARIANT=$gpc_variant"
    DESIGN_CONFIG=gpc/variants/hard_sm_pair.mk
    "SM_MACRO_DIR=/work/artifacts/asic/sm/$sm_variant/results"
    "GPC_CHANNEL=${GPC_CHANNEL:-1000}"
    "GPC_SIDE_MARGIN=${GPC_SIDE_MARGIN:-200}" "GPC_EDGE=${GPC_EDGE:-40}")

printf '\n[3/3] Build dual-SM GPC with the new SM IP\n'
make elaborate "${gpc[@]}"
run_flow gpc
for item in "${gpc[@]}"; do
    if [[ "$item" == FLOW_VARIANT=* ]]; then gpc_variant=${item#*=}; fi
done
make images "${gpc[@]}" IMAGE_STAGE=6_final

printf '\nCompleted GPC RTL-to-GDS flow: %s/artifacts/asic/gpc/%s/results/6_final.gds\n' "$PWD" "$gpc_variant"
printf 'This completes the implementation flow; separate DRC/LVS signoff is not run here.\n'
printf 'Open GUI:\n'
printf '%q ' make gui-web "${gpc[@]}" WEB_TARGET=web_6_final.odb
printf '\n'
