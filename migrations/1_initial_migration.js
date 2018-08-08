var traceability = artifacts.require("./traceability.sol");

module.exports = function(deployer) {
  deployer.deploy(traceability);
};
