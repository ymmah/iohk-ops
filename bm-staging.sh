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
    --argstr time          25000    \
    --argstr conc          1      \
    --argstr delay         500    \
    --argstr sendMode send-random \
    --argstr cooldown      10     \
    --argstr addGenerators 1      \
    --argstr edgeNodes     0      \
    --arg walletsDeployment  \"\" \
    )/bin/run-bench.sh

