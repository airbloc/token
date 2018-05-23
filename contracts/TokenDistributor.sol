pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Tokenlock.sol";


contract TokenDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public x;
    uint256 public y;
    ERC20 public Token;
    ERC20 public Genesis;
    Tokenlock public Lock;

    constructor(
        uint256 _ratioX, // *x*/y
        uint256 _ratioY, // x/*y*
        address _token,
        address _genesis,
        address _tokenLock
    ) public {
        require(_ratioY > _ratioX);    // x = y -> x/y = 1
        require(_ratioY > 0);
        require(_token != address(0));
        require(_genesis != address(0));
        require(_tokenLock != address(0));

        x = _ratioX;
        y = _ratioY;
        Token = ERC20(_token);
        Genesis = ERC20(_genesis);
        Lock = Tokenlock(_tokenLock);
    }

    event Release(address indexed _to, uint256 _safeAmount, uint256 _lockAmount);

    function release(address _addr) public onlyOwner {
        uint256 locked = Lock.getBalance(_addr);
        uint256 amount = Genesis.balanceOf(_addr);

        require(_addr != address(0));
        require(locked == 0);   // check already locked
        require(amount > 0);    // check genesis amount is not 0

        uint256 samount = amount.div(y).mul(x);
        uint256 lamount = amount.div(y).mul(y.sub(x));

        Token.safeTransfer(address(Lock), lamount);
        Lock.lock(_addr, lamount);
        Token.safeTransfer(_addr, samount);

        emit Release(_addr, samount, lamount);
    }

    function releaseMany(address[] _addrs) external onlyOwner {
        require(_addrs.length < 30);

        for(uint256 i = 0; i < _addrs.length; i++) {
            release(_addrs[i]);
        }
    }
}
