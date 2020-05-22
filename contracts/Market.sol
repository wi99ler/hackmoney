pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./nft.sol";
import "./Funds.sol";

contract Market {
//    event Register(uint itemId, uint32 price);
//    event Deposit(uint itemId, uint32 price, bool success);

    enum Status {OffSale, OnSale, Rented, Sold, Disabled}

    struct Item {
        address seller;
        address buyer;
        uint tokenId;
        uint256 price;
        uint rentAt;

        Status status;
    }

    uint public fee;

    uint private itemCnt;
    mapping (uint => Item) RegisteredDiaList;

    // linking with other contracts
    address public addrFunds;
    address public addrWon;
    address public addrNFT;

    constructor (address Funds, address Won, address NFT) public {
        addrFunds = Funds;
        addrWon = Won;
        addrNFT = NFT;
        itemCnt = 0;
        fee = 1;
    }

    function getFee() public returns (uint) {
        return fee;
    }

    function register(uint256 tokenId, uint256 price) public {
        DiaNFT nft = DiaNFT(addrNFT);
        nft.transferFrom(msg.sender, address(this), tokenId);

        RegisteredDiaList[itemCnt] = Item(msg.sender, address(0x0), tokenId, price, 0, Status.OffSale);
        itemCnt++;
    }

    function transitStatus (uint itemId, Status newStatus) public {
        Item memory item = RegisteredDiaList[itemId];
        require(item.seller == msg.sender, "not owner of this token");
        RegisteredDiaList[itemId].status = newStatus;
    }

    function getDiamondByTokenId(uint256 tokenId) public view returns(Item memory) {
        for(uint i = 0 ; i < itemCnt ; i++) {
            Item storage dia = RegisteredDiaList[i];
            if (dia.tokenId == tokenId) {
                return dia;
            }
        }
    }

    function changePrice(uint256 itemId, uint256 price) public {
        require(RegisteredDiaList[itemId].seller == msg.sender, "not owner of this token");
        RegisteredDiaList[itemId].price = price;
    }

    function getDiamond(uint256 itemId) public view returns(Item memory) {
        return RegisteredDiaList[itemId];
    }

    function getDiaMarket(uint256 first, uint256 cnt, Status _status) public view returns
            (uint[] memory, uint[] memory, uint[] memory, Status[] memory) {
        // first, end limit 구현해야됨

        uint[] memory ids = new uint[] (cnt);
        uint[] memory price = new uint[](cnt);
        uint[] memory rentAt = new uint[](cnt);
        Status[] memory status = new Status[](cnt);

        //Item[] memory dias = new Item[](itemId);
        uint Cnt = 0;
        for (uint i = 0 ; i < itemCnt && Cnt <= cnt ; i++ ) {
            Item storage dia = RegisteredDiaList[i+first];

            if (dia.status == _status) {
                ids[i] = dia.tokenId;
                price[i] = dia.price;
                rentAt[i] = dia.rentAt;
                status[i] = dia.status;
                Cnt++;
            }
        }
        return (ids, price, rentAt, status);
    }

    function getDiamonds(uint256 first, uint256 end) public view returns
            (uint[] memory, uint[] memory, uint[] memory, Status[] memory) {
        // first, end limit 구현해야됨

        uint[] memory ids = new uint[] (end-first);
        uint[] memory price = new uint[](end-first);
        uint[] memory rentAt = new uint[](end-first);
        Status[] memory status = new Status[](end-first);

        //Item[] memory dias = new Item[](itemId);
        for (uint i = 0; i < end-first ; i++) {
            ids[i] = RegisteredDiaList[i+first].tokenId;
            price[i] = RegisteredDiaList[i+first].price;
            rentAt[i] = RegisteredDiaList[i+first].rentAt;
            status[i] = RegisteredDiaList[i+first].status;
        }
        return (ids, price, rentAt, status);
    }

    function rentDiamond(uint256 itemId) public {
        require(RegisteredDiaList[itemId].status == Status.OnSale, "The item is not onSale..");
        RegisteredDiaList[itemId].buyer = msg.sender;
        RegisteredDiaList[itemId].rentAt = now;
        RegisteredDiaList[itemId].status = Status.Rented;

        Funds funds = Funds(addrFunds);
//        Won won = Won(addrWon);

        funds.requestDeposit(itemId, RegisteredDiaList[itemId].price);
    }

//    function claim4ExpiredDia(uint itemId) public {
//        require(RegisteredDiaList[itemId].seller == msg.sender, "only seller can call claim");
//    }

    function confirmPurchase(uint itemId) public {
        Item memory dia = RegisteredDiaList[itemId];
        require(msg.sender == dia.buyer, "only buyer can confirm purchase");
        Won won = Won(addrWon);
        won.transferFrom(msg.sender, address(this), (dia.price * fee)/100);
        won.transferFrom(msg.sender, dia.seller, dia.price);
        Funds funds = Funds(addrFunds);
        won.approve(addrFunds, (dia.price * (100+fee))/100);
        funds.cancelIOU(itemId, fee);
        DiaNFT nft = DiaNFT(addrNFT);
        nft.transferFrom(address(this), msg.sender, dia.tokenId);
    }

    function returnDiamond(uint itemId) public {
        require(RegisteredDiaList[itemId].status == Status.Rented, "The item is not Rented..");
        require(msg.sender == RegisteredDiaList[itemId].buyer, "only buyer can return");
        RegisteredDiaList[itemId].buyer = address(0x0);
        RegisteredDiaList[itemId].status = Status.OnSale;
    }

    function returnNFT(uint itemId) public {
        require(RegisteredDiaList[itemId].seller == msg.sender, "Only owner can return NFT");

        DiaNFT nft = DiaNFT(addrNFT);
        nft.transferFrom(address(this), msg.sender, RegisteredDiaList[itemId].tokenId);

        RegisteredDiaList[itemId].seller = address(0x0);
        RegisteredDiaList[itemId].price = 0;
        RegisteredDiaList[itemId].rentAt = 0;
        RegisteredDiaList[itemId].status = Status.Disabled;
    }
}