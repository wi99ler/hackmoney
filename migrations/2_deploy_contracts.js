const DiaToken = artifacts.require("DiaNFT");
const Won = artifacts.require("Won");
const Market = artifacts.require("Market");

module.exports = function(deployer) {
  deployer.deploy(DiaToken);
  deployer.deploy(Won, 10000000000);
  deployer.deploy(Market, "0xFEC78CE97e2eD26d501dB74F13fFC7747d75cEab");
};