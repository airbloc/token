pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Whitelist is Ownable {
    mapping (address => bool) public whitelist;

    modifier isWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    function register(address _buyer) public onlyOwner {
        require(_buyer != 0x0);
        whitelist[_buyer] = true;
    }

    function unregister(address _buyer) public onlyOwner {
        require(_buyer != 0x0);
        whitelist[_buyer] = false;
    }
}
