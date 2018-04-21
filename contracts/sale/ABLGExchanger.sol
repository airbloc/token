pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../util/OwnedTokenTimelock.sol";


contract ABLGExchanger is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public ABL;
    ERC20 public ABLG;

    function ABLGExchanger(
        address _abl,
        address _ablg
        ) public {
        require(_abl != address(0));
        require(_ablg != address(0));

        ABL = ERC20(_abl);
        ABLG = ERC20(_ablg);
    }

//////////////////
//  once
//////////////////

    bool once = false;

    modifier onlyOnce() {
        require(!once);
        _;
    }

//////////////////
//  distribute
//////////////////

    function calcAmount(address key) private constant returns (uint256, uint256) {
        /* require(holder[key] != 0);
        require(ABL.balanceOf(this).sub(holder[key]) > 0); */

        return(holder[key].div(29).mul(23), holder[key].div(29).mul(6));
    }

    function distribute() public onlyOwner onlyOnce {
        /* require(ABL.balanceOf(this) > 0); */
        once = true;

        for(uint256 i = 0; i < keys.length; i++) {
            address key = keys[i];

            uint256 samount;
            uint256 lamount;

            (samount, lamount) = calcAmount(key);

            // Send owner's ABL Tokens to msg.sender
            ABL.safeTransfer(key, samount);

            // Lock 30 percent of given bonus
            OwnedTokenTimelock lockContract = new OwnedTokenTimelock(address(ABL), owner, key, 1 years);
            lockList[key] = address(lockContract);

            ABL.safeTransfer(key, lamount);

            emit Distribute(this, key, holder[key]);
        }
    }

    function bulkRelease() public onlyOwner onlyOnce {
        for(uint256 i = 0; i < keys.length; i++) {
            OwnedTokenTimelock lock = OwnedTokenTimelock(lockList[keys[i]]);
            lock.release();
        }
    }

    event Distribute(address indexed owner, address indexed beneficiary, uint256 amount);

    event BulkRelease(address indexed owner, address[] keys);

//////////////////
//  holder list
//////////////////

    mapping (address => address) public lockList;
    mapping (address => uint256) public holder;
    address[] public keys;

    function getKeys() public constant returns (address[]) {
        return keys;
    }

    function getHolderInfo(address _holder) public constant returns (address, uint256) {
        require(_holder != address(0));
        return (lockList[_holder], holder[_holder]);
    }

    function addHolder(address _holder) public onlyOwner {
        uint256 amount = ABLG.balanceOf(_holder);

        require(_holder != address(0));
        require(amount > 0);

        holder[_holder] = amount;
        keys.push(_holder);

        emit AddHolder(_holder, amount);
    }

    function addHolders(address[] _holders) public onlyOwner {
        require(_holders.length != 0);

        for(uint256 i = 0; i < _holders.length; i++) {
            addHolder(_holders[i]);
        }
    }

    function removeHolder(address _holder, uint256 _index) public onlyOwner {
        require(_holder != address(0));
        require(_index >= 0);

        delete holder[_holder];
        delete keys[_index];

        emit RemoveHolder(_holder, _index);
    }

    function removeHolders(address[] _holders, uint256[] _indexes) public onlyOwner {
        require(_holders.length == _indexes.length);

        for(uint256 i = 0; i < _holders.length; i++) {
            removeHolder(_holders[i], _indexes[i]);
        }
    }

//////////////////
//  events
//////////////////

    event AddHolder(address holder, uint256 amount);
    event RemoveHolder(address holder, uint256 index);
}
