#!/bin/bash -l
set -euo pipefail


forge script --rpc-url=https://anr.fly.dev/ext/bc/C/rpc --private-key=${PRIVATE_KEY} --broadcast scripts/finalize-minipools.s.sol
