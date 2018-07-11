# Response for Security Audit Report of ABL

### Introduction

This document is written for explaining our responses and actions to the security audit report by [HAECHI Labs](https://medium.com/haechi-labs/ethereum-smart-contract-test-driven-development-5dedfcde19ba).

The commit hash referred from the audit report is `dd150e02317b29cfa07b04cf8f36766a34972076`,
and the commit hash referred from this document is `0b5af3547b0a156222766a5ad5404fef4b338235`.



## Major Issues

#### 1. The amount of ABL token issued is different from what is specified in the white paper.

This issue was caused because decimals are not multiplied to total distribution amount of ABL.

It was fixed by multiplying `10 ** uint256(decimals)` to the amount.

```js
// Token Distribution Rate
uint256 public constant SUM = 400000000;   			// totalSupply
uint256 public constant DISTRIBUTION = 221450000; 	// distribution
uint256 public constant DEVELOPERS = 178550000;   	// developer

uint256 public totalSupply = SUM.mul(10 ** uint256(decimals));

balances[_dtb] = DISTRIBUTION.mul(10 ** uint256(decimals));
balances[_dev] = DEVELOPERS.mul(10 ** uint256(decimals));
```



#### 2. The exchange formula of ETH received from PresaleFirst.sol to ABL token is incorrect. 

This issue was also caused because of decimals.

It was fixed by multiplying decimals to the amount.

```js
// buy
uint256 tokenAmount = purchase.mul(rate);
```



## *Minor Issues*

#### 1. The intention of implementing modifier locked could lead to a misunderstanding. 

We agreed to the analysis of HAECHI Labs that the ability of token owner can control the transferability could lead to a misunderstanding of our intentions. Therefore, we deleted re-lock function and made the lock one-time.

```js
// token is non-transferable until owner calls unlock()
// (to prevent OTC before the token to be listed on exchanges)
bool isTransferable = false;

function unlock() external onlyOwner {
    isTransferable = true;
}
```
