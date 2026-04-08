
# Abstract Generator

### 라우팅 스펙과 via 정의가 되어있지 않은 문제
이제 innovus 에서 PnR을 해야한다. 
그걸 위해서는 abstract view가 필요한데, 이걸 만들기 위해서는 tech파일을 수정해야한다. 

![[Pasted image 20260407180337.png]]

라우팅 스펙과 via 정의가 되어있지 않다는 에러다. 

tf 파일에 

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

해당 부분을 넣으니 문제가 해결됐다. 

이 블록은 Abstract Generator에게 "LEF를 만들 때 어떤 routing layer와 via를 쓰고, 배선 grid를 어떻게 잡을지" 알려주는 설정이다.

![[Pasted image 20260407184351.png]]

이제 Import Logical을 하면 된다. 
셀의 논리적 정보를 넣어주는건데 Abstract Generator는 레이아웃(physical)만 보면 각 도형이 어떤 net인지, 그리고 그 pin이 input인지 output인지 알 수 없다.

그래서 Import Logical을 통해 Verilog나 LIB를 넣어주면, Abstract가 "이 셀에는 A(input), Y(output)가 있다"는 걸 알게 되고, 레이아웃의 pin label과 매칭해서 LEF에 `PIN A DIRECTION INPUT`, `PIN Y DIRECTION OUTPUT` 이런 식으로 정확하게 써줄 수 있다.

![[Pasted image 20260407185158.png]]

여기에 .lib파일을 넣으면



- [ ] 라우팅 스펙과 via 정의가 되어있지 않다.
- [ ] lib가 잘 안나와서 Genus에서 합성했을 때 타이밍 정보가 안나왔다.
- [x] tech lef를 뽑을 때 PITCH가 안나온다.
	- [ ] tech lef를 뽑았을 때 PITCH가 2번 들어간다. 
