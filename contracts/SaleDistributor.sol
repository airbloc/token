pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./PresaleSecond.sol";


contract SaleDistributor is Ownable {
    PresaleSecond public Sale;

    constructor(address _sale) public {
        require(_sale != address(0));
        Sale = PresaleSecond(_sale);
    }

    function setSaleAddress(address _addr) external onlyOwner {
        require(_addr != address(0));
        Sale = PresaleSecond(_addr);
    }

    function releaseMany(address[] _addrs) external onlyOwner {
        require(_addrs.length < 30);

        for(uint256 i = 0; i < _addrs.length; i++) {
            Sale.release(_addrs[i]);
        }
    }
}
