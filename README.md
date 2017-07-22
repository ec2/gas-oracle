# GAS ORACLES BABY
Okay guys, so hopefully I will have pushed this somehow from the middle of nowhere Malaga Spain.
Here's what you need to know:
1. Prediction market contracts are all in `/contracts/` folder
2. Throughout the repo, the gas oracle should be similar to `CentralizedOracle.sol` in implementation and deployment.
3. `GasOracle.sol` and `GasOracleFactory.sol` should go in `/contracts/oracles` and have implementation similar to `CentralizedOracle.sol`.
4. Edit `/migrations/2_deploy_gnosis_contracts.js` so that `GasOracleFactory.sol` is linked and deployed.
5. There is a javascript test in `/test/javascript/test_oracles.js` that goes through the exact steps to deploy a prediction market using the contracts deployed in the migration script in 4.
6. Sunny should know how to spin up a UI so that people can bet on gas prices, however, Tim just put up a tutorial called petshop in the truffleframework tutorials that will walk you through basics.

### times that Collin will be awake EST:
1AM EST Saturday - 4PM EST Saturday
1AM EST Sunday - 5AM EST Sunday  &  8PM+ EST Sunday (I will be back in berkeley)

### Setup:
```bash
testrpc (different terminal)
npm install
truffle compile
truffle migrate
```

### Example test:
`truffle test /test/javascript/test_oracles.js`

Gnosis Smart Contracts
======================

Collection of smart contracts for the Gnosis prediction market platform (https://www.gnosis.pm).
To interact with those contracts have a look at (https://github.com/gnosis/gnosis.js/).

Install
-------
### Install requirements with npm: (actually cloned the node modules so you shouldnt have to do this)

```bash
npm install
```

Original Repo
--------------------
https://github.com/gnosis/gnosis-contracts

Security and Liability
----------------------
All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

License
-------
All smart contracts are released under GPL v.3.

Contributors
------------
- Stefan George ([Georgi87](https://github.com/Georgi87))
- Martin Koeppelmann ([koeppelmann](https://github.com/koeppelmann))
- Alan Lu ([cag](https://github.com/cag))
- Roland Kofler ([rolandkofler](https://github.com/rolandkofler))
- Collin Chin ([collinc97](https://github.com/collinc97))
- Christopher Gewecke ([cgewecke](https://github.com/cgewecke))
