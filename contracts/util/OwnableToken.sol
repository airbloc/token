pragma solidity ^0.4.19;


contract OwnableToken {
    mapping (address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        if(!owners[msg.sender]) {
            delete owners[msg.sender];
            revert();
        }
        _;
    }

    function OwnableToken() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        delete owners[msg.sender];
        owners[newOwner] = true;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}
