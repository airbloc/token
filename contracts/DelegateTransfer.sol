pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";

contract DelegateTransfer is Whitelist {
    using SafeERC20 for ERC20;

    ERC20 public Token;

    constructor(address _token, address _allower) {
        require(_token != address(0));

        Token = ERC20(_token);
        addAddressToWhitelist(_allower);
    }

    function transfer(address _to, uint256 _amount) public {
        require(msg.sender == owner || whitelist(msg.sender));
        require(_amount < Token.balanceOf(address(this)));

        Token.safeTransfer(_to, _amount);
    }

    function end() public onlyOwner {
        selfdestruct(owner);
    }
}
