
![[Pasted image 20260416140454.png]]

왜 라우팅이 잘 안될까?

일단 로그에서 가장 먼저 눈에 띄는건

![[Pasted image 20260416142429.png]]

setNanoRouteMode -routeTopRoutingLayer 를 3으로 설정하라고 한다. 

이렇게 했더니 

![[Pasted image 20260416142516.png]]

setDesignMode -topRoutingLayer 를 쓰라고 한다. 


![[Pasted image 20260416142613.png]]

![[Pasted image 20260416142819.png]]

![[Pasted image 20260416142556.png]]

![[routeDesign2.txt]]

그러니 이렇게 로그가 나온다. 
이전의 warning은 사라졌지만 

![[Pasted image 20260416143837.png]]

![[Pasted image 20260416143808.png]]

여전히 라우팅은 잘 되지 않았다.

로그를 뜯어보니

![[Pasted image 20260416144218.png]]

DRC violation이 있다. 

이게 무슨 violation인지 알아보니

![[Pasted image 20260416144325.png]]

![[Pasted image 20260416144450.png]]

![[Pasted image 20260416144459.png]]

이런 문제가 발생하는데, 왜 발생하는지 찾아보니까 로그에 이런 내용이 있다. 
```
#WARNING (NRAG-41) The M1 user tracks are removed and regenerated from M3.
# MET1         H   Track-Pitch = 2.4000    Line-2-Via Pitch = 2.2000
# MET2         V   Track-Pitch = 2.0000    Line-2-Via Pitch = 2.5000
#WARNING (NRAG-44) Track pitch is too small compared with line-2-via pitch.
# MET3         H   Track-Pitch = 2.4000    Line-2-Via Pitch = 2.6000
#WARNING (NRAG-44) Track pitch is too small compared with line-2-via pitch.
```

The M1 user tracks are removed and regenerated from M3 라고 한다.
라우터가 M1의 라우팅 스펙 정의를 무시하고 자체적으로 재생성했다는 것 같다. 

tech.lef를 보면 

![[Pasted image 20260416150244.png]]

pitch 가 1.6으로 설정되어있는데 이게 재생성되면서 2.4로 바뀐 것 같다. 
참고로 이건 이젠에 [[1. P&R import design]] 에서 생성한 .tf 파일 내용에서 영향을 받아 작성된 것이다. 

```
  ( "LEFDefaultRouteSpec"  nil  "LEFDefaultRouteSpec"

    interconnect(
     ( validLayers   (MET1  MET2  MET3) )
     ( validVias     (M1_POLY1  M2_M1  M3_M2) )
    ) ;interconnect

    routingGrids(
     ( horizontalPitch    "MET1"  1.6 )
     ( verticalPitch      "MET1"  1.6 )
     ( horizontalOffset   "MET1"  0.8 )
     ( verticalOffset     "MET1"  0.8 )
     ( horizontalPitch    "MET2"  2.0 )
     ( verticalPitch      "MET2"  2.0 )
     ( horizontalOffset   "MET2"  1.0 )
     ( verticalOffset     "MET2"  1.0 )
     ( horizontalPitch    "MET3"  2.4 )
     ( verticalPitch      "MET3"  2.4 )
     ( horizontalOffset   "MET3"  1.2 )
     ( verticalOffset     "MET3"  1.2 )
    ) ;routingGrids
  ) ;LEFDefaultRouteSpec
```

.tf 파일에는 이렇게 작성되어있다. 

Etri에서 제공하는 tech를 일단 살펴보고 수정할 수 있으면 .tf를 수정해서 lef를 다시 뽑아야할 것 같다. 

```
LAYER metal1
  TYPE		ROUTING ;
  DIRECTION	HORIZONTAL ;
  PITCH		3.0 ;
  OFFSET	1.5 ;
  WIDTH	    0.9 ;   # ETRI050 Rule: WIDTH=0.8
  SPACING	0.9 ;   # ETRI050 Rule: SPACING=0.8(1.0 for Width >10um)
  RESISTANCE	RPERSQ 0.09 ;
  CAPACITANCE	CPERSQDIST 3.2e-05 ;
END metal1

LAYER via1
  TYPE	CUT ;
  SPACING	0.9 ;
END via1

LAYER metal2
  TYPE		ROUTING ;
  DIRECTION	VERTICAL ;
  PITCH		3.0 ;
  OFFSET	1.5 ;
  WIDTH		1.05 ;  # ETRI050 Rule: WIDTH=1.0
  SPACING	0.9 ;   # ETRI050 Rule: SPACING=1.0(1.2 for Width >10um)
  RESISTANCE	RPERSQ 0.09 ;
  CAPACITANCE	CPERSQDIST 1.6e-05 ;
END metal2

LAYER via2
  TYPE	CUT ;
  SPACING	0.9 ;
END via2

LAYER metal3
  TYPE		ROUTING ;
  DIRECTION	HORIZONTAL ;
  PITCH		3.0 ;
  OFFSET	1.5 ;
  WIDTH		1.2 ;   # ETRI050 Rule: WIDTH=1.2
  SPACING	0.9 ;   # ETRI050 Rule: SPACING=1.0(1.2 for Width >10um)
  RESISTANCE	RPERSQ 0.05 ;
  CAPACITANCE	CPERSQDIST 1e-05 ;
END metal3
```

Etri 에서는 pitch를 모두 3.0으로 세팅했다.
좀 넉넉하게 준 것 같다. 
그러면 나도 3.0으로 pitch를 세팅하고 다시 돌려봐야겠다.

```
( "LEFDefaultRouteSpec"  nil  "LEFDefaultRouteSpec"

    interconnect(
     ( validLayers   (MET1  MET2  MET3) )
     ( validVias     (M1_POLY1  M2_M1  M3_M2) )
    ) ;interconnect

    routingGrids(
     ( horizontalPitch    "MET1"  3.0 )
     ( verticalPitch      "MET1"  3.0 )
     ( horizontalOffset   "MET1"  1.5 )
     ( verticalOffset     "MET1"  1.5 )
     ( horizontalPitch    "MET2"  3.0 )
     ( verticalPitch      "MET2"  3.0 )
     ( horizontalOffset   "MET2"  1.5 )
     ( verticalOffset     "MET2"  1.5 )
     ( horizontalPitch    "MET3"  3.0 )
     ( verticalPitch      "MET3"  3.0 )
     ( horizontalOffset   "MET3"  1.5 )
     ( verticalOffset     "MET3"  1.5 )
    ) ;routingGrids
  ) ;LEFDefaultRouteSpec
```

이렇게 세팅했다.

추가적으로 via크기 세팅도 조금 달라서 이건 lef를 뽑고 추가해야겠다.

lef에 추가한 내용은 따로 이 파일에서 정리한다.

[[ref_lef 수정사항]]

이제 tech.lef를 모두 수정했으니 floorplan부터 다시 해보면 

![[Pasted image 20260416174936.png]]

이렇게 해도 라우팅이 잘 안되었다. 

![[Pasted image 20260416180217.png]]

그래서 abstract view를 확인해보니.....

![[Pasted image 20260416180328.png]]

![[Pasted image 20260416180351.png]]

분명 잘 나왔었던 abstract가 이상하게 나와있는 것을 확인했다..

![[Pasted image 20260416192215.png]]

![[Pasted image 20260416192227.png]]

이렇게 옵션을 주고 뽑으니 잘 뽑힌다. 

![[Pasted image 20260416192259.png]]

이제 cell lef를 뽑고

![[abstract2.lef]]

없던 라인들이 생기니 violation이 거의 10배가 되었다..

