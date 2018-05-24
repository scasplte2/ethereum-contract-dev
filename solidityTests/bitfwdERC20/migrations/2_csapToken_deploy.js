var csapToken = artifacts.require("./CsaplteToken.sol");

module.exports = function(deployer) {
  deployer.deploy(csapToken);
};