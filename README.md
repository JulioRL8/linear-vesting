# Linear Vesting

A prefunded ETH grant that vests linearly for a single beneficiary.

## How it works

1. Deploy with a beneficiary, a start timestamp at or after deployment, a duration in seconds, and the ETH grant.
2. Read `vestedAt(timestamp)` to inspect the schedule. Fractional wei round down during vesting.
3. Anyone can call `release()` to send newly vested funds to the beneficiary. The grant becomes fully vested at `endsAt`.

The grant size is fixed at deployment. The beneficiary and schedule are immutable. The beneficiary's address must be able to accept ETH.

## Build and test

Install [Foundry](https://getfoundry.sh/) and run these commands from this directory. Forge selects Solidity 0.8.36 from `foundry.toml`. The project has no third-party Solidity dependencies.

```bash
forge build
forge test -vv
forge coverage --exclude-tests
```

## Local deployment

Start a fresh `anvil` node in a separate terminal. Deploy with the first unlocked account on that local node.

```bash
export RPC_URL=http://127.0.0.1:8545
export ANVIL_ACCOUNT=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
forge create src/LinearVesting.sol:LinearVesting --rpc-url "$RPC_URL" --from "$ANVIL_ACCOUNT" --unlocked --broadcast --value 1ether --constructor-args "$ANVIL_ACCOUNT" "$(($(date +%s) + 120))" 86400
```

## Local example

Set `CONTRACT` to the address printed by `forge create` and keep using the same terminal.

```bash
export ETH_RPC_URL="$RPC_URL"
CONTRACT=0x... # Replace with your deployed address.
cast call "$CONTRACT" 'startsAt()(uint256)'
cast rpc evm_increaseTime 86520
cast rpc evm_mine
cast send "$CONTRACT" 'release()' --from "$ANVIL_ACCOUNT" --unlocked
cast call "$CONTRACT" 'released()(uint256)'
```

## Test cases

Foundry reports 7 passing tests and 100% coverage on contract lines, statements, branches and functions.

- Prefunding and schedule validation.
- Pre-start, mid-schedule and fully vested balances, including repeated releases.
- Failed payments and fuzzed release amounts.
