const DiaToken = artifacts.require("DiaNFT");
const Won = artifacts.require("Won");
const Market = artifacts.require("Market");
const Funds = artifacts.require("Funds");

module.exports = async function(deployer) {
  await deployer.deploy(DiaToken);
  await deployer.deploy(Won, 10000000000);
  await deployer.deploy(Funds, Won.address);
  await deployer.deploy(Market, Funds.address, Won.address, DiaToken.address);
};