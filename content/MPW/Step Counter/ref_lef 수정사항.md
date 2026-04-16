
# tech lef

![[1. P&R import design#Core Site]]


## via 룰 추가

tech lef의 VIARULE 이전에 추가:

```
VIA M2_M1 DEFAULT
  LAYER metal1 ;
    RECT -1.050 -1.050 1.050 1.050 ;
  LAYER via1 ;
    RECT -0.450 -0.450 0.450 0.450 ;
  LAYER metal2 ;
    RECT -1.050 -1.050 1.050 1.050 ;
END M2_M1

VIA M3_M2 DEFAULT
  LAYER metal2 ;
    RECT -1.050 -1.050 1.050 1.050 ;
  LAYER via2 ;
    RECT -0.450 -0.450 0.450 0.450 ;
  LAYER metal3 ;
    RECT -1.050 -1.050 1.050 1.050 ;
END M3_M2
```
해당 값은 Etri의 tech lef와 같다.

# cell lef

![[debug_IMPREPO-513 — lef에 shape이 없음#참고!]]

