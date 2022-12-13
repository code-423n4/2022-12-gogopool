# Justfiles are better Makefiles (Don't @ me)
# Install the `just` command from here https://github.com/casey/just
# or if you have rust: cargo install just
# https://cheatography.com/linux-china/cheat-sheets/justfile/

export HARDHAT_NETWORK := env_var_or_default("HARDHAT_NETWORK", "localhost")
export ETH_RPC_URL := env_var_or_default("ETH_RPC_URL", "http://127.0.0.1:8545")

# Autoload a .env if one exists
set dotenv-load

# Print out some help
default:
	@just --list --unsorted

# Install dependencies
install:
	yarn install

# Delete compilation artifacts
clean:
	npx hardhat clean
	forge clean
	rm -rf .openzeppelin

# Compile the project with hardhat
compile:
  npx hardhat compile

# Clean and compile the project
build: clean compile

# Deploy base contracts to HARDHAT_NETWORK
deploy-base: (_ping ETH_RPC_URL)
	npx hardhat run --network {{HARDHAT_NETWORK}} scripts/deploy-base.ts

# Deploy non-base contracts to HARDHAT_NETWORK
deploy contracts="": (_ping ETH_RPC_URL)
	DEPLOY_CONTRACTS="{{contracts}}" npx hardhat run --network {{HARDHAT_NETWORK}} scripts/deploy.ts

# Compile and Deploy contracts to a testnet and init actors and settings
setup-evm:
	just clean
	just deploy-base
	just deploy
	just task debug:setup
	just task debug:setup-dao

# HARDHAT_NETWORK should be "localhost" for tasks, but must be "hardhat" when starting the node
# Start a local hardhat EVM node
node:
	HARDHAT_NETWORK=hardhat npx hardhat node

# Run forge unit tests
test contract="." test="." *flags="":
	@# Using date here to give some randomness to tests that use block.timestamp
	forge test --allow-failure --block-timestamp `date '+%s'` --match-contract {{contract}} --match-test {{test}} {{flags}}

# Run forge unit tests whenever file changes occur
test-watch contract="." test="." *flags="":
	@# Using date here to give some randomness to tests that use block.timestamp
	forge test --allow-failure --block-timestamp `date '+%s'` --match-contract {{contract}} --match-test {{test}} {{flags}} --watch contracts test --watch-delay 1

# Run a hardhat task (or list all available tasks)
task *cmd:
	npx hardhat {{cmd}}

# just cast send MultisigManager "registerMultisig(address)" 0xf39f...
# Run cast command
cast cmd contractName sig *args:
	#!/usr/bin/env bash
	source -- "cache/deployed_addrs_${HARDHAT_NETWORK:-localhost}.bash"
	if ([ "{{cmd}}" == "send" ]); then legacy="--legacy"; else legacy=""; fi;
	cast {{cmd}} ${legacy} --private-key $PRIVATE_KEY ${addrs[{{contractName}}]} "{{sig}}" {{args}}

# Print signatures for all errors found in /artifacts
decoded-errors: compile
	#!/usr/bin/env bash
	join() { local d=$1 s=$2; shift 2 && printf %s "$s${@/#/$d}"; }
	shopt -s globstar # so /**/ works
	errors=$(cat artifacts/**/*.json | jq -r '.abi[]? | select(.type == "error") | .name' | sort | uniq)
	sigsArray=()
	for x in $errors;	do
		sigsArray+=("\"$(cast sig "${x}()")\":\"${x}()\"")
	done
	sigs=$(join ',' ${sigsArray[*]})
	echo "{${sigs}}" | jq

# Run solhint linter and output table of results
solhint:
	npx solhint -f table contracts/**/*.sol

# Run slither static analysis
slither:
	slither . \
		--filter-paths "(lib/|utils/|openzeppelin|ERC)"

# Generate Go code interface for contracts to /gen
gen: compile
	#!/bin/bash
	CORETH=0.8.16
	echo "Generating GO code with Coreth v${CORETH}"
	THATDIR=$PWD
	mkdir -p $THATDIR/gen
	cd $GOPATH/pkg/mod/github.com/ava-labs/coreth@v${CORETH}
	cat $THATDIR/artifacts/contracts/contract/MinipoolManager.sol/MinipoolManager.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg minipool_manager --out $THATDIR/gen/minipool_manager.go
	cat $THATDIR/artifacts/contracts/contract/Staking.sol/Staking.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg staking --out $THATDIR/gen/staking.go
	cat $THATDIR/artifacts/contracts/contract/RewardsPool.sol/RewardsPool.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg rewards_pool --out $THATDIR/gen/rewards_pool.go
	cat $THATDIR/artifacts/contracts/contract/ClaimNodeOp.sol/ClaimNodeOp.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg claim_node_op --out $THATDIR/gen/claim_node_op.go
	cat $THATDIR/artifacts/contracts/contract/Oracle.sol/Oracle.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg oracle --out $THATDIR/gen/oracle.go
	cat $THATDIR/artifacts/contracts/contract/Storage.sol/Storage.json | jq '.abi' | go run cmd/abigen/main.go --abi - --pkg storage --out $THATDIR/gen/storage.go
	echo "Complete! Copying to rialto repo..."
	mkdir -p $THATDIR/../rialto/pkg/contracts/minipool_manager
	mkdir -p $THATDIR/../rialto/pkg/contracts/staking
	mkdir -p $THATDIR/../rialto/pkg/contracts/rewards_pool
	mkdir -p $THATDIR/../rialto/pkg/contracts/claim_node_op
	mkdir -p $THATDIR/../rialto/pkg/contracts/oracle
	mkdir -p $THATDIR/../rialto/pkg/contracts/storage
	cp $THATDIR/gen/minipool_manager.go $THATDIR/../rialto/pkg/contracts/minipool_manager/
	cp $THATDIR/gen/staking.go $THATDIR/../rialto/pkg/contracts/staking/
	cp $THATDIR/gen/rewards_pool.go $THATDIR/../rialto/pkg/contracts/rewards_pool/
	cp $THATDIR/gen/claim_node_op.go $THATDIR/../rialto/pkg/contracts/claim_node_op/
	cp $THATDIR/gen/oracle.go $THATDIR/../rialto/pkg/contracts/oracle/
	cp $THATDIR/gen/storage.go $THATDIR/../rialto/pkg/contracts/storage/

# Print a tab-separated list of all settings usage in contracts
review-settings:
	#!/usr/bin/env ruby
	lines = []
	Dir.glob('./contracts/**/*.sol').each do |file|
		next if file =~ /(Storage|BaseAbstract).sol/
		File.readlines(file).each do |line|
			if line =~ /(etInt|etUint|etBool|etAddress|etBytes|etString)/
				line = line[/^.*?([gs]et[^;]*);.*$/,1]
				next unless line
				line = line + "\t[#{file}]"
				lines << line
			end
		end
	end
	puts lines.sort.uniq

# Update foundry binaries to the nightly version
update-foundry:
	foundryup --version nightly

# Update git submodules
update-submodules:
	git submodule update --recursive --remote

# Diagnose any obvious setup issues for new folks
doctor:
	#!/usr/bin/env bash
	set -euo pipefail

	# check if yarn is installed
	if ! yarn --version > /dev/null 2>&1; then
		echo "yarn is not installed"
		echo "You can install it via npm with 'npm install -g yarn'"
		exit 1
	fi
	echo "yarn ok"

	if [ ! -e $HOME/.foundry/bin/forge ]; then
		echo "Install forge from https://book.getfoundry.sh/getting-started/installation.html"
		echo "(Make sure it gets installed to $HOME/.foundry/bin not $HOME/.cargo/bin if you want foundryup to work)"
		exit 1
	fi
	echo "forge ok"

# Im a recipie that doesnt show up in the default list
# Check if there is an http(s) server lisening on [url]
_ping url:
	@if ! curl -k --silent --connect-timeout 2 {{url}} >/dev/null 2>&1; then echo 'No server at {{url}}!' && exit 1; fi
