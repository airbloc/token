pragma solidity ^0.4.19;

import "../zeppelin/token/ERC20/TokenTimelock.sol";
import "../zeppelin/token/ERC20/SafeERC20.sol";
import "../zeppelin/token/ERC20/ERC20Basic.sol";
import "../zeppelin/ownership/Ownable.sol";


contract OwnedTokenTimelock is Ownable, TokenTimelock {

    function OwnedTokenTimelock(
        address _token,
        address _owner,
        address _buyer,
        uint256 _after
        ) public TokenTimelock(
            ERC20Basic(_token),
            _buyer,
            block.timestamp + _after
        ){
        transferOwnership(_owner);
    }

    function release() public {
        super.release();
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
