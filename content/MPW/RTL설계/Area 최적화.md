
# 문제 정의

큰일이다. 
Area가 너무 크다.
Mode select 인스턴스 1개로 합성하고 placement했을 때 면적을 8% 차지하고

![[Pasted image 20260506175905.png|310]]

![[Pasted image 20260506175916.png|376]]

Mode select 인스턴스 2개로 합성했을 때는 무려 21%를 차지한다...

![[Pasted image 20260506180110.png|308]]

![[Pasted image 20260506180121.png|389]]

이대로라면 SPI ACC 등등 이것들 넣기도 전에 FPU 9개도 다 못넣는다. 

그런데 단일 Mode와 Mode select를 비교해보니 면적이 거의 2배 넘게 차이난다. 

![[Pasted image 20260506180208.png|583]]

처음에는 곱셈기가 mode마다 1개씩 생성되어 그런 것인줄 알았는데 그건 아니고, 그냥 mode 의존도가 높은 코드가 많은 탓이었다. 
거기다 exp와 mantissa를 더 많은 비트 수 쪽에 맞추다 보니 곱셈기의 크기도 커졌다. 

이게 현재 FPU 코드이다. 

![[mode_select.v]]

모듈로 나누고 나서의 area는 다음과 같다

![[Pasted image 20260506180520.png]]

확실히 곱셈기가 크긴 한가보다. 

이제 Area를 줄이기 위해 적용할 수 있는 방안은 다음과 같다
1. 코드 최적화를 통한 면적 감소(mode의존도 줄이기, 곱셈기 사이즈 줄이기 등)
2. 만들어둔 gate모두 사용해서 합성(현재는 INV, NAND, NOR만 사용했다. HA나 FA가 더해지면 면적이 좀 줄어들거다.)
3. 합성 시 최적화 우선순위로 Area를 최상단에 두기
4. Macro cell (레이아웃 노가다를 다시 하면..)

먼저 1번부터 적용해보자.

# 해결 방안

## 1. 코드 최적화

### 곱셈기 크기 줄이기
코드 최적화에서 가장 먼저 시도할 방법은 곱셈기 크기 줄이기이다.

```verilog
    wire [3:0] full_mant_a = {1'b1, mant_a};
    wire [3:0] full_mant_b = {1'b1, mant_b};
    assign mant_product = full_mant_a * full_mant_b;
```

이렇게 MSB는 항상 1인걸 알 수 있다. 이걸 다시 쓰면
(8+ma)x(8+mb) --> 64+8(ma+mb)+(ma x mb)
이렇게 풀어헤칠 수 있다. 

이렇게 하면 4x4곱셈기가 3x3이 된다. 
이건 합성기가 원래 해줄 것 같기는 하지만 혹시 모르니까 적용해서 합성해보았다. 

![[Pasted image 20260506192049.png]]

역시 합성기가 먼저 잘 해뒀나보다.
변화가 없다.

### 삼항연산자 줄이기

모드 의존도를 줄인다는거다. 

기존의 코드는 exp와 mantissa를 큰 포맷에 맞추어 확장하고, 연산 후 다시 포맷을 맞춘다. 
이렇게 하면 아래와 같은 코드는 비트 폭을 맞춰서 넣어주는걸로 연산자를 간소화할 수 있다.

수정 전: MUX 4개

```verilog
    wire [2:0] mant_round_candidate = mode ? mant_normalized[6:4] : {1'b0, mant_normalized[6:5]};
    wire       guard  = mode ? mant_normalized[3] : mant_normalized[4];
    wire       round_ = mode ? mant_normalized[2] : mant_normalized[3];
    wire       sticky = mode ? (|mant_normalized[1:0]) : (|mant_normalized[2:0]);

    wire round_up = guard & (round_ | sticky | mant_round_candidate[0]);
```

수정 후: MUX 1개
```verilog
wire [2:0] mant_round_candidate = mant_normalized[6:4];
wire       guard  = mant_normalized[3];
wire       round_ = mant_normalized[2];
wire       sticky = |mant_normalized[1:0];

wire round_up_e4m3 = guard & (round_ | sticky | mant_round_candidate[0]);
wire round_up_e5m2 = mant_round_candidate[0] & (guard | round_ | sticky | mant_round_candidate[1]);
wire round_up = mode ? round_up_e4m3 : round_up_e5m2;
```

E5M2는 E4M3기준으로 정의한 flag들을 1비트 밀려서 정의해주면 된다. 

합성 결과는 다음과 같다.

![[Pasted image 20260506193944.png]]

우와 이게 뭘까..? 면적이 증가했다!
수정한 결과 코드가 셀이 1개 더 늘었고, 면적도 늘었다. 
수정할 때 or가 많이 들어간 것 때문에 그런가..

## 2. GATE 추가

만들어둔 게이트를 모두 적용해서 합성해보니 면적이 반토막이 났다!

![[Pasted image 20260507222525.png]]

이게 기존의 module 안쪼갠 FPU 면적

![[Pasted image 20260507222555.png]]

이게 게이트 다 사용한거

---

5/18
설계가 변경되어 mode가 필요 없어졌다. 
E5M3로 통일하고 합성하니까 셀이 40개정도 줄었다. 

![[Pasted image 20260518000547.png]]

![[fpu.v]]

클로드놈이 코드를 너무 못짜서 한땀한땀 직접 작성했다..