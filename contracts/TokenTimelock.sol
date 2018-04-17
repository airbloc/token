pragma solidity ^0.4.19;

import "./zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";


contract TokenTimelock is Ownable {
    using SafeERC20 for ERC20Basic;

    ERC20Basic public token;
    address public buyer;
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _owner, address _buyer, uint256 _releaseTime) public {
        require(_releaseTime > block.timestamp);
        token = _token;
        buyer = _buyer;
        transferOwnership(_owner);
        releaseTime = _releaseTime;
    }

    function release() public {
        require(block.timestamp >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(buyer, amount);
    }

    function changeReleaseTime(uint256 _time) public onlyOwner {
        releaseTime = _time;
    }

    function withdraw() public onlyOwner {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(owner, amount);
    }
}
