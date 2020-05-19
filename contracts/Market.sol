pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./nft.sol";
import "./Pool.sol";

contract Market {

    event Register(uint itemId, uint32 price);
    event Deposit(uint itemId, uint32 price, bool success);

    enum Status {OffSale, OnSale, Rented, Sold}

    struct Item {
        address buyer;
        uint itemId;
        uint32 price;

        Status status;
    }

    uint private itemCount;
    mapping (uint => Item) RegisteredDiaList;

    // linking with other contracts
    address public addrPool;
    address public addrWon;
    address public addrNFT;

    constructor (address Pool, address Won, address NFT) public {
        addrPool = Pool;
        addrWon = Won;
        addrNFT = NFT;
    }

    function register(uint256 ItemID, uint32 price) public {
        RegisteredDiaList[itemCount] = Item(ItemID, price, Status.OffSale);
        itemCount++;
        emit Register(itemCount-1, price);
    }
/*
    function getDiamonds () public view returns (Item[] memory) {
        Item[] memory dias = new Item[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            Item storage dia = RegisteredDiaList[i];
            dias[i] = dia;
        }
        return dias;
    }
*/
    function getDiamond(uint itemId) public view returns(Item memory) {
        for(uint i = 0 ; i < itemCount ; i++) {
            Item storage dia = RegisteredDiaList[i];
            if (dia.itemId == itemId) {
                return dia;
            }
        }
    }

    function getDiamonds () public view returns
            (uint[] memory, uint[] memory, Status[] memory) {

        uint[] memory ids = new uint[] (itemCount);
        uint[] memory price = new uint[](itemCount);
        Status[] memory status = new Status[](itemCount);

        //Item[] memory dias = new Item[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            Item storage dia = RegisteredDiaList[i];

            ids[i] = dia.itemId;
            price[i] = dia.price;
            status[i] = dia.status;
        }
        return (ids, price, status);
    }

    function transitStatus (uint itemId, Status newStatus) public {
        RegisteredDiaList[itemId].status = newStatus;
    }

    function rentDiamond(uint itemId) public view returns (bool) {
        require(RegisteredDiaList[itemId].status == Status.OnSale, "The item is not onsale..");
        return true;
    }

    function confirmPurchase(uint itemId) public {
      require()
    }

    function returnDiamond(uint itemId) public view returns (bool) {
        require(RegisteredDiaList[itemId].status == Status.OnSale, "The item is not onsale..");
        return true;
    }



/*
    function stateTransition(   bytes32 targetHashedDia, Status toStatus,
                                bytes32 _anchor, // Merkle Root of NFT Tree..
                                uint[8] memory points) public returns (bool) {
        
    }

    // Temp for compiling the contract.... will be removed when verifier.sol is created by zokrates.
    function verifyTx (uint[2] memory a, uint[2][2] memory b, uint[2] memory c,
                        uint[5] memory input) public returns (bool) {
        return true;
    }

    function verify (bytes32 targetHash, uint[8] memory points) public {
        
    }
*/

}