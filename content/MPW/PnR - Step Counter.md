
# Abstract Generator

PnR을 하기 위해 파일을 import하는 과정에서 다음과 같은 문제들이 발견되었다.
이 글에서는 해당 문제들을 해결하는 내용을 작성한다. 

- [x] 라우팅 스펙과 via 정의가 되어있지 않다.
- [x] tech lef를 뽑을 때 PITCH가 안나온다.
- [x] constraints 부족 문제
- [ ] lib가 잘 안나와서 Genus에서 합성했을 때 타이밍 정보가 안나왔다.

## 라우팅 스펙과 via 정의가 되어있지 않은 문제
이제 innovus 에서 PnR을 해야한다. 
그걸 위해서는 abstract view가 필요한데, 이걸 만들기 위해서는 tech파일을 수정해야한다. 

![[Pasted image 20260407180337.png]]

라우팅 스펙과 via 정의가 되어있지 않다는 에러다. 

tf 파일에 

```c
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

그리고 원래 tech.lef에는 
``` c
LAYER MET1
  TYPE ROUTING ;
  DIRECTION HORIZONTAL ;
  WIDTH 0.8 ;
  SPACING 0.8 ;
  SPACING 0.8 SAMENET ;
END MET1

```

이렇게 Pitch와 offset이 없었는데 위 내용을 tf파일에 추가하면 

```c
LAYER MET1
  TYPE ROUTING ;
  DIRECTION HORIZONTAL ;
  PITCH 1.6 1.6 ;
  WIDTH 0.8 ;
  OFFSET 0.8 0.8 ;
  SPACING 0.8 ;
  SPACING 0.8 SAMENET ;
END MET1
```

추가된다. 

값이 2개씩 나오는건 각 X, Y방향의 값이다. 

참고로 lef파일은 tf 파일으로부터 직접적으로 영향을 받는다.

---

![[Pasted image 20260407184351.png]]

이제 Import Logical을 하면 된다. 
셀의 논리적 정보를 넣어주는건데 Abstract Generator는 레이아웃(physical)만 보면 각 도형이 어떤 net인지, 그리고 그 pin이 input인지 output인지 알 수 없다.

그래서 Import Logical을 통해 Verilog나 LIB를 넣어주면, Abstract가 "이 셀에는 A(input), Y(output)가 있다"는 걸 알게 되고, 레이아웃의 pin label과 매칭해서 LEF에 `PIN A DIRECTION INPUT`, `PIN Y DIRECTION OUTPUT` 이런 식으로 정확하게 써줄 수 있다.

![[Pasted image 20260407185158.png|452]]

여기에 .lib파일을 넣으면 된다.

![[Pasted image 20260408143134.png|459]]

다음으로 핀을 설정해준다.
핀의 이름은 레이아웃을 할 때 설정한 이름으로 작성해야한다. 

![[Pasted image 20260408143235.png|472]]

다음으로 Extract와 Abstract는 그냥 돌리면 된다. 

Abstract 만드는 순서가 logical --> pins --> extract --> abstract 인데

1. **Logical** 셀의 논리적 인터페이스를 정의하는 단계. Schematic(또는 CDL 넷리스트)에서 셀이 어떤 핀을 가지고 있는지, 각 핀의 방향(input/output/inout)이 뭔지를 가져온다. 쉽게 말해 "이 셀은 A, B, Y, VDD, VSS라는 핀이 있다"는 정보를 확립하는 것.

2. **Pins Logical**에서 정의된 각 핀이 레이아웃의 어느 레이어, 어느 위치에 있는지 매핑하는 단계이다. 예를 들어 "핀 Y는 MET1 레이어의 이 사각형 영역이다"라고 지정한다. 이게 나중에 LEF에서 `PIN ... PORT ... RECT` 구문이 되는 것이다.

3. **Extract** 레이아웃의 메탈/비아 geometry를 스캔해서 net connectivity를 파악한다. Pins 단계에서 핀 위치를 잡았으니, 나머지 메탈 geometry가 어떤 net에 속하는지, 어디가 연결되고 어디가 안 되는지를 분석한다. 이 결과로 핀에 속하지 않는 내부 배선은 OBS(obstruction)로 분류된다.

4. **Abstract** 앞 3단계의 결과를 종합해서 최종 LEF용 추상 뷰를 생성하는 단계. 여기서 셀의 boundary(SIZE), 핀 geometry, OBS가 합쳐져서 P&R 툴(Innovus 등)이 읽을 수 있는 abstract view가 만들어진다.

![[Pasted image 20260408144544.png]]

이제 virtuoso에서 열어보면,

![[Pasted image 20260408144725.png]]

이렇게 잘 나오는걸 볼 수 있다. 

이제 이 abstract view를 사용해서 cell lef를 뽑으면 된다. 

![[Pasted image 20260408150850.png]]

이게 각 tech, cell lef이다. 
![[no_tech.lef]]

![[tech 2.lef]]


---

## constraints 부족 문제

이제 TechDB Check를 돌려보면 
![[Pasted image 20260408153058.png]]

![[Pasted image 20260408153104.png]]

필요한 constraints와 발견된 constraints가 나온다. 
PVS는 Physical Verification System. Cadence의 물리적 검증 툴이다.

여기서 PVS를 눌러보면 
![[Pasted image 20260408153824.png]]

Act와 nwell의 spacing이 없다고 나온다. 
이건 sky130 pdk를 참고해서 이렇게 넣으면 된다.

![[Pasted image 20260408153927.png]]

항상 tf 파일을 손대면 load와 savr를 하는 것을 잊지 말자. 

![[Pasted image 20260408154053.png]]

이제 모든 constraints가 맞춰졌다. 

---

## Genus에서 합성했을 때 면적과 타이밍 정보가 안 나오는 문제

### 면적
원래 liberate로 만든 lib에는 area가 없었다..
그래서 virtuoso에서 prBoundary의 면적을 재서 직접 넣어줬다. 

![[Pasted image 20260409155711.png]]

이렇게 하니까 면적 report가 잘 나왔다. 

![[Pasted image 20260409155753.png]]

### 타이밍
