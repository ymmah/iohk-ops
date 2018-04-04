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

#$(nix-build set-cluster.nix \
#    --argstr clusterName ${CLUSTERNAME} \
#    --argstr commit  ${COMMIT} \
#    )/bin/set-cluster.sh


$(nix-build run-bench.nix     \
    --argstr coreNodes     7      \
    --argstr startWaitTime 10     \
    --argstr time          6000    \
    --argstr conc          2      \
    --argstr delay         250    \
    --argstr sendMode send-random \
    --argstr cooldown      10     \
    --argstr addGenerators 6      \
    --argstr edgeNodes     10      \
    --arg walletsDeployment  \"edgenodes-cluster\" \
    )/bin/run-bench.sh

