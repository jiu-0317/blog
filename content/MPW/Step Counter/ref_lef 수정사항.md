
# tech lef

![[1. P&R import design#Core Site]]


## via 룰 추가

tech lef의 VIARULE 이전에 추가:

```
VIA M2_M1 DEFAULT
  LAYER MET1 ;
    RECT -1.050 -1.050 1.050 1.050 ;
  LAYER via1 ;
    RECT -0.450 -0.450 0.450 0.450 ;
  LAYER MET2 ;
    RECT -1.050 -1.050 1.050 1.050 ;
END M2_M1

VIA M3_M2 DEFAULT
  LAYER MET2 ;
    RECT -1.050 -1.050 1.050 1.050 ;
  LAYER via2 ;
    RECT -0.450 -0.450 0.450 0.450 ;
  LAYER MET3 ;
    RECT -1.050 -1.050 1.050 1.050 ;
END M3_M2
```
해당 값은 Etri의 tech lef와 같다.

주의해야할 부분은 Etri의 lef는 metal# 을 하용하지만 내 lef는 MET#를 사용한다. 
이름을 맞추어서 작성해야한다.

# cell lef

![[debug_IMPREPO-513 — lef에 shape이 없음#참고!]]

