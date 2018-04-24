#!/bin/sh

CLUSTERNAME=benchmarks110experiments
COMMIT=5693299345465aa3569c55561c1e76a4c4609b21

set -e        # exit on error
set -o xtrace # print commands

export TZ=UTC
export TEMPDIR=/tmp/
export TMPDIR=/tmp/
export TEMP=/tmp/
export TMP=/tmp/

$(nix-build ./scripts/run-bench.nix \
    --argstr coreNodes     7        \
    --argstr startWaitTime 10       \
    --argstr txsPerThread  6000     \
    --argstr conc          2        \
    --argstr delay         250      \
    --argstr cooldown      10       \
    --argstr addGenerators 6        \
    --argstr edgeNodes     10       \
    --argstr walletsDeployment edgenodes-cluster \
    )/bin/run-bench.sh
