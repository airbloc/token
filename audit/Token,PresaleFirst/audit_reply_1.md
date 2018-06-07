# HAECHILABS 1차 프리세일 컨트랙트 감사 답변서

## Intro.

본 답변서는 HAECHI Labs의 감사 보고서에 대하여 취약점에 대한 대응방법을 설명하기 위해 작성되었습니다.

Audit Report에서 사용된 코드의 커밋해시는 `dd150e02317b29cfa07b04cf8f36766a34972076`이고,
현 답변서에서 참고할 코드의 커밋해시는 `0b5af3547b0a156222766a5ad5404fef4b338235`입니다.

## *Major Issues*

#### ABL 토큰의 발행량이 백서에 명시된 발행량과 다릅니다.

발행량에 Decimals를 곱하지 않은 문제로 인해 생긴 이슈입니다.

양을 산출해내는 공식을 추가함으로써 해결하였습니다.

```js
// Token Distribution Rate
uint256 public constant SUM = 400000000;   			// totalSupply
uint256 public constant DISTRIBUTION = 221450000; 	// distribution
uint256 public constant DEVELOPERS = 178550000;   	// developer

uint256 public totalSupply = SUM.mul(10 ** uint256(decimals));

balances[_dtb] = DISTRIBUTION.mul(10 ** uint256(decimals));
balances[_dev] = DEVELOPERS.mul(10 ** uint256(decimals));
```



#### PresaleFirst.sol에서 받은 이더를 ABL 토큰으로 교환하는 공식이 잘못됐습니다.

위와 같이 Decimals를 고려하지 않아 생긴 실수이므로 공식을 수정하여 해결하였습니다.

```js
// buy
uint256 tokenAmount = purchase.mul(rate);
```



## *Minor Issues*

#### ABL 토큰을 lock하는 구현은 제거하는 것이 좋습니다.

owner가 토큰의 transfer가능성을 마음대로 제어하는것은 옳지않다고 판단한 HAECHI Labs의 의견에 공감했습니다.

따라서, 토큰의 lock을 하되, 일회성으로 만듦으로써 해결하였습니다.

```js
// token is non-transferable until owner calls unlock()
// (to prevent OTC before the token to be listed on exchanges)
bool isTransferable = false;

function unlock() external onlyOwner {
    isTransferable = true;
}
```



#### PresaleFirst.sol의 Fallback function은 public보다 external이 적합합니다.

가스비 최적화에 관한 이슈입니다. Fallback function의 접근제어자 뿐만아니라 다른 함수들의 접근제어자도 용도에 맞게 최적화하였습니다.

```js
function () external payable
function release(address addr) public onlyOwner
function releaseMany(uint256 start, uint256 end) external onlyOwner
function refund(address addr) public onlyOwner
function refundMany(uint256 start, uint256 end) external onlyOwner
```



#### PresaleFirst.sol에서 `maxcap`을 줄이는 것은 초기 cap을 추적하기 어렵게 합니다.

투자자들에게 혼란을 줄 수 있을 여지가 있다고 판단하여 maxcap변수를 고정하고, 새로운 변수 weiRaised를 만들어 현재 모인 fund를 계산하였습니다.



#### 프리 세일의 토큰 세일 기간이 명시적이지 않습니다.

테스트를 위해 deploy script를 작성하는 과정에서 생긴 이슈입니다. 메인넷에 컨트랙트를 배포하기 전 수정하였습니다.



#### 프리 세일 도중에 모은 이더리움을 출금하면 의심을 받을 수 있습니다.

이 이슈는 인지하였지만, 컨트랙트에 문제가 생겼을 경우 (환불 함수까지도 문제가 생겼을 경우) 수동으로 환불을 해야되는 상황을 고려하여 제한을 넣지 않았습니다. 그리고, 1차 프리세일이 진행될때 이벤트를 추적해본 결과 세일 도중 팀원이 이더리움을 출금하는 상황이 벌어지지 않았기에 문제가 없다고 생각합니다. 1차 프리세일 이후 좀 더 나은 방법을 위해 고민하였고, 2차 프리세일 컨트랙트에서 다른 방법으로 해결하였습니다.



#### PresaleFirst.sol의 Buyer struct에 불필요한 데이터 저장으로 gas가 낭비됩니다.

buyer가 투자한 이더 총량과 그에 따라 받을 수 있는 토큰 총량을 따로 저장하여 생긴 이슈입니다. `TokenAmount = FundAmount * rate`를 적용하고, Buyer struct를 mapping(address => uint256)으로 바꾸어 최적화하였습니다.



#### PresaleFirst.sol의 getTokenAmount함수의 기능이 분리될 필요가 있습니다.

getTokenAmount의 기능을 2개의 함수로 분리하여 작성하였습니다.

```js
// 1. check over exceed
function checkOverExceed(address _buyer) private constant returns (uint256) {
    if(msg.value >= exceed) {
        return exceed;
    } else if(msg.value.add(buyers[_buyer]) >= exceed) {
        return exceed.sub(buyers[_buyer]);
    } else {
        return msg.value;
    }
}

// 2. check sale hardcap
function checkOverMaxcap(uint256 amount) private constant returns (uint256) {
    if((amount + weiRaised) >= maxcap) {
        return (maxcap.sub(weiRaised));
    } else {
        return amount;
    }
}
```

1차 프리세일 컨트랙트에서는 다음과 같은 로직을 사용하였지만, 2차 프리세일 컨트랙트에서는 좀 더 효율적인 로직을 사용하여 함수 하나로 처리하였습니다.

```js
function getPurchaseAmount(address _buyer, uint256 _amount)
    private
    view
    returns (uint256, uint256)
{
    uint256 d1 = maxcap.sub(weiRaised);
    uint256 d2 = exceed.sub(buyers[_buyer]);

    uint256 d = (d1 > d2) ? d2 : d1;

    return (_amount > d) ? (d, _amount.sub(d)) : (_amount, 0);
}
```



#### LogString Event 는 항상 발생하지 않습니다. 

테스트를 위한 이벤트이므로 삭제하였습니다.



#### PresaleFirst.sol 의 release 함수를 하기 전에 transfer lock 상태를 확인하기를 권장합니다. 

Token의 owner들만이 lock상태에서 transfer를 할 수 있게 만들고, 그 owner에 1차 프리세일 컨트랙트를 추가해놓음으로써 해결하였습니다.



#### PresaleFirst.sol 의 release 함수에서 token 을 전송하고 token 을 차감할 것을 권장합니다. 

큰 문제가 없었기에 1차 프리세일은 기존 코드 그대로 배포 후 진행하였지만, 안전한 코딩 패턴을 지향하기 위하여 2차 프리세일 컨트랙트에서는 [zeppelin의 권고](https://blog.zeppelin.solutions/onward-with-ethereum-smart-contract-security-97a827e47702)에 따라서 Conditions -> Effects -> Interaction으로 함수의 코드를 정리하였고, token을 transfer하기 전 mapping의 값을 0으로 만듦으로써 혹시있을 reentrancy를 방지하였습니다.

