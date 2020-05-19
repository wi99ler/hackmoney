pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Won is ERC20 {
  address public owner;

  constructor (uint256 InitialSupply) ERC20("WonHwa", "WON") public {
    owner = msg.sender;
    _mint(msg.sender, InitialSupply);
  }

  function Mint(uint256 Amount) public {
    require(owner == msg.sender, "Sender not authorized");

    _mint(msg.sender, Amount);
  }

  function Burn(uint256 Amount) public {
    require(owner == msg.sender, "Sender not authorized");

    _burn(msg.sender, Amount);
  }
}