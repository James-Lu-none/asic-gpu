#!/usr/bin/env bash
# Integrate frozen qualified SM IP; do not rebuild changed SP/SM RTL here.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
jobs=${JOBS:-8}
stage=${GPC_STAGE:-floorplan}
results=artifacts/asic/sm/hard_sp_mirrored_bottom_c600_freepins_h80/results
for file in streaming_multiprocessor.lef streaming_multiprocessor_typ.lib 6_final.gds; do
    test -s "$results/$file" || { echo "Missing SM IP: $file; see gpc/README.md" >&2; exit 1; }
done
rg -q 'SYMMETRY X Y' "$results/streaming_multiprocessor.lef" || {
    echo 'SM LEF needs X/Y symmetry; see export command in gpc/README.md' >&2
    exit 1
}
printf 'Using frozen SM IP; latest SP RTL changes are not included.\n'
make flow DESIGN=gpc FLOW_VARIANT=hard_sm_pair "STAGE=$stage" "JOBS=$jobs"
image_stage=2_floorplan
if [[ "$stage" == finish ]]; then image_stage=6_final; fi
make images DESIGN=gpc FLOW_VARIANT=hard_sm_pair "IMAGE_STAGE=$image_stage" "JOBS=$jobs"
printf '\nFull flow: GPC_STAGE=finish bash temp.sh\n'
