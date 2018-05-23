pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Tokenlock is Ownable {
    using SafeERC20 for ERC20;

    mapping (address => uint256) public buyers;

    ERC20 public Token;
    address public locker;
    address public distributor;

    bool public started = false;
    uint256 public releaseTime;

    constructor(
        address _token,
        address _distributor
    ) public {
        require(_token != address(0));
        require(_distributor != address(0));

        Token = ERC20(_token);
        locker = msg.sender;
        distributor = msg.sender;
    }

    function getBalance(address _buyer) external view returns (uint256) {
        return buyers[_buyer];
    }

    //// only owner
    // setter
    function setLocker(address _addr)
        external
        onlyOwner
    {
        require(_addr != address(0));
        locker = _addr;
    }

    function setDistributor(address _addr)
        external
        onlyOwner
    {
        require(_addr != address(0));
        distributor = _addr;
    }

    // start timer
    function start()
        external
        onlyOwner
    {
        require(started == false);
        started = true;
        releaseTime = block.timestamp + 90 days;
    }

    //// others
    // add lock
    function lock(address _buyer, uint256 _amount) external {
        require(msg.sender == locker);
        require(_buyer != address(0));
        buyers[_buyer] = _amount;
    }

    // release locked tokens
    function release(address _buyer) external {
        require(msg.sender == distributor);
        require(block.timestamp >= releaseTime);

        uint256 amount = buyers[_buyer];
        buyers[_buyer] = 0;

        Token.safeTransfer(_buyer, amount);
    }
}
