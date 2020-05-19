pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DiaNFT is ERC721 {
  struct Dia {
    string Clarity;
    string Color;
    string Carat;
    string Cut;
    string GirdleCode;
    string Report;
    string etc;
  }

  Dia[] public dia;
  address public owner;

  constructor () ERC721("DiaToken", "DIA") public {
    owner = msg.sender;
  }

  function mintDia(
    string memory Clarity,
    string memory Color,
    string memory Carat,
    string memory Cut,
    string memory GirdleCode,
    string memory Report,
    string memory etc,
    address account
    ) public returns (uint256) {
    require(owner == msg.sender, "Sender not authorized");
    uint256 DiaID = dia.length;
    dia.push(Dia(Clarity, Color, Carat, Cut, GirdleCode, Report, etc));
    _mint(account, DiaID);
    return DiaID;
  }

  function getDia(uint256 index) public view
  returns (string memory Clarity, string memory Color, string memory Carat, string memory Cut, string memory GirdleCode, string memory Report, string memory etc)
  {
    return (dia[index].Clarity, dia[index].Color, dia[index].Carat, dia[index].Cut, dia[index].GirdleCode, dia[index].Report, dia[index].etc);
  }
}