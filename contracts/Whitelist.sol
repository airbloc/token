pragma solidity ^0.4.19;


contract Whitelist {
    mapping (address => bool) public whitelist;

    modifier isWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    function register(address _buyer) public {
        whitelist[_buyer] = true;
    }

    function unregister(address _buyer) public {
        whitelist[_buyer] = false;
    }
}
