# Rocket Pool rETH Exchange Rate Oracle for Polygon

This repository contains 2 main contracts. `RocketPolygonPriceMessenger` which can be called by anyone to submit the current
rETH exchange rate (as reported by `RocketNetworkBalances`) to the `RocketPolygonPriceOracle` contract which is deployed on
Polygon.

## Notice

Rocket Pool provides this exchange rate oracle as-is for convenience and offers no guarantee about its accuracy or the
freshness of the data. These contracts have not been formally audited for security or correctness.

## Usage

Calling `rate()` on `RocketPolgyonPriceOracle` will return the latest rETH exchange rate reported. This value is in the form
of the ETH value of 1 rETH. e.g. If 1 rETH is worth 1.5 ETH `rate()` will return 1.5e18. `lastUpdated()` can be called to
retrieve the timestamp that the rate was last updated.

## Deployments

Rocket Pool maintains a Goerli testnet instance of the protocol alongside our mainnet deployment which can be used for 
integration testing before promotion to mainnet.

| Chain | RocketPolygonPriceMessenger (EVM) | RocketPolygonPriceOracle (Polygon) | RocketBalancerRateProvider (Polygon) |
| -- | -- | -- | -- |
| Mainnet | [0xb1029Ac2Be4e08516697093e2AFeC435057f3511](https://etherscan.io/address/0xb1029Ac2Be4e08516697093e2AFeC435057f3511) | [0x594Fb75D3dc2DFa0150Ad03F99F97817747dd4E1](https://polygonscan.com/address/0x594Fb75D3dc2DFa0150Ad03F99F97817747dd4E1) | [0xA73ec45Fe405B5BFCdC0bF4cbc9014Bb32a01cd2](https://polygonscan.com/address/0xa73ec45fe405b5bfcdc0bf4cbc9014bb32a01cd2) |
| Goerli | [0x6D736da1dC2562DBeA9998385A0A27d8c2B2793e](https://goerli.etherscan.io/address/0x6D736da1dC2562DBeA9998385A0A27d8c2B2793e) | [0xA73ec45Fe405B5BFCdC0bF4cbc9014Bb32a01cd2](https://mumbai.polygonscan.com/address/0xa73ec45fe405b5bfcdc0bf4cbc9014bb32a01cd2) | tba |

## Deploying and Submitting

There is a simple deploy script (`deploy.js`) that can be run with `node deploy.js`. You will need to create a suitable 
`.env` file first. Example `.env` file is available for Goerli and Mainnet.
