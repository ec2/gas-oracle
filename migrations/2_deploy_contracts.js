var Adoption = artifacts.require("./Adoption.sol");
var Gashole = artifacts.require("./Gashole.sol");

module.exports = function(deployer) {
  deployer.deploy(Adoption);
  deployer.deploy(Gashole);
};
