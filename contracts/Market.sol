pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./nft.sol";
import "./Pool.sol";

contract Market {
//    event Register(uint itemId, uint32 price);
//    event Deposit(uint itemId, uint32 price, bool success);

    enum Status {OffSale, OnSale, Rented, Sold}

    struct Item {
        address seller;
        address buyer;
        uint tokenId;
        uint256 price;

        Status status;
    }

    uint fee;

    uint private itemCnt;
    mapping (uint => Item) RegisteredDiaList;

    // linking with other contracts
    address public addrPool;
    address public addrWon;
    address public addrNFT;

    constructor (address Pool, address Won, address NFT) public {
        addrPool = Pool;
        addrWon = Won;
        addrNFT = NFT;
        itemCnt = 0;
        fee = 1;
    }

    function register(uint256 tokenId, uint256 price) public {
        DiaNFT nft = DiaNFT(addrNFT);
        nft.transferFrom(msg.sender, address(this), tokenId);

        RegisteredDiaList[itemCnt] = Item(msg.sender, address(0x0), tokenId, price, Status.OffSale);
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

    function getDiamonds(uint256 first, uint256 end) public view returns
            (uint[] memory, uint[] memory, Status[] memory) {
        // first, end limit 구현해야됨

        uint[] memory ids = new uint[] (end-first);
        uint[] memory price = new uint[](end-first);
        Status[] memory status = new Status[](end-first);

        //Item[] memory dias = new Item[](itemId);
        for (uint i = first; i < end ; i++) {
            Item storage dia = RegisteredDiaList[i];

            ids[i] = dia.tokenId;
            price[i] = dia.price;
            status[i] = dia.status;
        }
        return (ids, price, status);
    }

    function rentDiamond(uint256 itemId) public {
        require(RegisteredDiaList[itemId].status == Status.OnSale, "The item is not onSale..");
        RegisteredDiaList[itemId].buyer = msg.sender;
        RegisteredDiaList[itemId].status = Status.Rented;
    }

    function confirmPurchase(uint itemId) public {
        Item memory dia = RegisteredDiaList[itemId];
        require(msg.sender == dia.buyer, "only buyer can confirm purchase");
        Won won = Won(addrWon);
        won.transferFrom(msg.sender, address(this), (dia.price * fee)/100);
        won.transferFrom(msg.sender, dia.seller, dia.price);
        DiaNFT nft = DiaNFT(addrNFT);
        nft.transferFrom(address(this), msg.sender, dia.tokenId);
    }

    function returnDiamond(uint itemId) public {
        require(RegisteredDiaList[itemId].status == Status.Rented, "The item is not Rented..");
        require(msg.sender == RegisteredDiaList[itemId].buyer, "only buyer can return");
        RegisteredDiaList[itemId].buyer = address(0x0);
        RegisteredDiaList[itemId].status = Status.OnSale;
    }
}