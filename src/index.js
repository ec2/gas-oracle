const contracts = require('../deploy/environments.json').rinkeby;
const Eth = require('ethjs');
const HttpProvider = require('ethjs-provider-http');
//const eth = new Eth(new HttpProvider('http://localhost:8545'));
const eth = new Eth(new HttpProvider('https://rinkeby.infura.io'));


const ContractDataC = contracts["../contracts/C.sol:C"];

const ContractInstance = eth.contract(JSON.parse(ContractDataC.interface)).at(ContractDataC.address);

ContractInstance.a().then(console.log)
ContractInstance.blah(new Eth.BN(3)).then(console.log)
