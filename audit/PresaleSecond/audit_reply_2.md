# HAECHILABS 2차 프리세일 컨트랙트 감사 답변서

## Intro.

본 답변서는 HAECHI Labs의 감사 보고서에 대하여 취약점에 대한 대응방법을 설명하기 위해 작성되었습니다.

Audit Report에서 사용된 코드의 커밋해시는 `d47404005f6596af955350a9e38ce01133c452be`이고,
현 답변서에서 참고할 코드의 커밋해시는 `0b5af3547b0a156222766a5ad5404fef4b338235`입니다.

## *Major Issues*

#### 토큰 세일기간이 명확하지 않습니다. 

1차 프리세일때 블록넘버로 진행한 결과 예정 시간보다 너무 큰 오차가 나 곤란함을 겪었던적이 있었습니다. 따라서, 정확한 시간에 세일을 시작하고자 수동으로 세일을 시작할 수 있게 하였습니다. 충분히 의심받을 수 있었던 상황이였긴 합니다만, 세일 종료 후 트랜잭션 로그를 살펴보면 ignite함수가 호출된것은 단 한번뿐이라는것을 확인하실수 있습니다.



#### getPurchaseAmount 에서 refund 계산 과정이 올바르지 않습니다. 

uint256에 음수값을 넣으려다가 SafeMath에 의해 revert되는 이슈였습니다. 기존 음수의 계산결과가 나오던 로직을 좀 더 최적화하여 바로 계산할 수 있도록 만들었습니다.

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



## *Minor Issues*

#### 라이브러리로 import 된 MintableToken 이 사용되지 않습니다. 

테스트를 위해 import된 컨트랙트였습니다. 메인넷에 배포하기 전 제거하였습니다.



#### keys 자료구조는 불필요합니다.

1차 프리세일 컨트랙트에서 releaseMany함수의 기능을 위해 만들어졌던 keys 자료구조가 불필요해지면서 생긴 이슈입니다.

해당 자료구조를 제거함으로써 해결하였습니다.



#### 프리 세일 도중에 모은 이더리움/토큰을 출금하면 의심을 받을 수 있습니다. 

withdrawToken과 withdrawEther 함수에 세일이 끝나야만 출금을 할 수 있는 조건문을 달아 해결하였습니다.

```js
event WithdrawToken(address indexed _from, uint256 _amount);
event WithdrawEther(address indexed _from, uint256 _amount);

function withdrawToken() public onlyOwner {
    require(!ignited);
    Token.safeTransfer(wallet, Token.balanceOf(address(this)));
    emit WithdrawToken(wallet, Token.balanceOf(address(this)));
}

function withdrawEther() public onlyOwner {
    require(!ignited);
    wallet.transfer(address(this).balance);
    emit WithdrawEther(wallet, address(this).balance);
}
```



#### refund 함수가 언제 호출 될 수 있는지 명확하지 않습니다. 

refund함수는 컨트랙트에 문제가 생겼을 경우 환불절차를 위한 함수입니다.

혹시라도 코드를 읽어보다 의도에 대해 궁금해 할 투자자 분들을 위해 컨트랙트에 주석으로 설명을 달았습니다.