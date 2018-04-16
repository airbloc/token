pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Whitelist.sol";
import "./TokenTimelock.sol";
import "./ABL.sol";


contract GenesisSwapContract is Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    mapping (address => address) lockList;

    // Define ABGL origin address, target is 100% rate
    address private origin;

    // Define genesis and target token
    ERC20 public atoken;
    ERC20 public gtoken;

    function GenesisSwapContract(ERC20 _atoken, ERC20 _gtoken, address _origin) public {
        /* require(_gtoken != 0x0); */
        require(_origin != 0x0);

        origin = _origin;
        atoken = _atoken;
        gtoken = _gtoken;
    }

    function swap() public isWhitelisted returns(address) {
        uint256 amount = gtoken.balanceOf(msg.sender);

        require(amount != 0);
        require(gtoken.balanceOf(owner) - amount > 0);

        // Safe Amount
        uint256 samount = amount.div(29).mul(23);
        // Lock Amount
        uint256 lamount = amount.div(29).mul(6);

        // Send owner's ABL Tokens to msg.sender
        atoken.safeTransferFrom(owner, msg.sender, samount);

        // Lock 30 percent of given bonus
        if(lockList[msg.sender] == 0x0) {
            TokenTimelock lockContract = new TokenTimelock(ABL(atoken), owner, msg.sender, block.timestamp + 1 seconds);
            lockList[msg.sender] = address(lockContract);
        }

        atoken.safeTransferFrom(owner, lockList[msg.sender], lamount);

        // Send sedner's ABGL Tokens to origin
        gtoken.safeTransferFrom(msg.sender, origin, amount);

        return lockList[msg.sender];
    }
}
