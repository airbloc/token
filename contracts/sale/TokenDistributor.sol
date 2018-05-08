pragma solidity 0.4.23

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract TokenDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;

    /* Constructor */
    constructor(address _token) public {
        require(_token != address(0), "address of _token cannot be empty");

        token = ERC20(_token);
    }

    /* External Functions */
    function withdraw() onlyOwner external {
        token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    function bulkDistribute(
        address[] buyers,
        uint256[] amounts
    )
        external onlyOwner
    {
        require(buyers.length == amount.length, "mismatching buyers and amounts array");

        for(uint256 i = 0; i < buyers.length; i++) {
            require(validation(buyers[i]), "invalid buyer");
            distribute(buyers[i], amounts[i], true);
        }
    }
}
