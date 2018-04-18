pragma solidity ^0.4.19;

import "../zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../util/TokenTimelock.sol";


contract ABLGExchanger is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public wallet;

    ERC20 public ABL;
    ERC20 public ABLG;

    function ABLGExchanger(
        address _abl,
        address _ablg,
        address _wallet
        ) public {
        require(_abl != address(0));
        require(_ablg != address(0));
        require(_wallet != address(0));

        wallet = _wallet;
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

    function distribute() public onlyOwner onlyOnce {
        once = true;

        for(uint256 i = 0; i < keys.length; i++) {
            address key = keys[i];

            uint256 amount = ABLG.balanceOf(key);

            require(amount != 0);
            require(ABL.balanceOf(wallet).sub(amount) > 0);

            // Safe Amount
            uint256 samount = amount.div(29).mul(23);
            // Lock Amount
            uint256 lamount = amount.div(29).mul(6);

            // Send owner's ABL Tokens to msg.sender
            ABL.safeTransferFrom(wallet, key, samount);

            // Lock 30 percent of given bonus
            if(lockList[key] == address(0)) {
                TokenTimelock lockContract = new TokenTimelock(address(ABL), owner, key, 1 years);
                lockList[key] = address(lockContract);
            }

            ABL.safeTransferFrom(wallet, lockList[key], lamount);

            emit Distribute(wallet, msg.sender, amount);
        }
    }

    function bulkRelease() public onlyOwner onlyOnce {
        for(uint256 i = 0; i < keys.length; i++) {
            TokenTimelock lock = TokenTimelock(lockList[keys[i]]);
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

    function addHolder(address _holder, uint256 _amount) public onlyOwner {
        require(_holder != address(0));
        require(_amount > 0);

        holder[_holder] = _amount;
        keys.push(_holder);

        emit AddHolder(_holder, _amount);
    }

    function addHolders(address[] _holders, uint256[] _amounts) public onlyOwner {
        require(_holders.length == _amounts.length);

        for(uint256 i = 0; i < _holders.length; i++) {
            addHolder(_holders[i], _amounts[i]);
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

    event AddHolder(address indexed holder, uint256 amount);

    event RemoveHolder(address indexed holder, uint256 index);
}
