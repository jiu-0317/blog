
# 문제점

자 핀을 연결하니 다음과 같은 문제가 발생한다. 

```
innovus 5> globalNetConnect VDD -type pgpin -pin VDD -all
innovus 6> globalNetConnect VSS -type pgpin -pin VSS -all
innovus 7> checkDesign -netlist -physicalLibrary -timingLibrary -powerGround -outDir RPT
Creating directory RPT.
############################################################################
# Innovus Netlist Design Rule Check
# Tue Apr 14 18:21:05 2026
############################################################################
Design: saturation_step_counter

------ Design Summary:
Total Standard Cell Number   (cells) : 180
Total Block Cell Number      (cells) : 0
Total I/O Pad Cell Number    (cells) : 0
Total Standard Cell Area     ( um^2) : 66261.17
Total Block Cell Area        ( um^2) : 0.00
Total I/O Pad Cell Area      ( um^2) : 0.00

------ Design Statistics:

Number of Instances            : 180
Number of Non-uniquified Insts : 180
Number of Nets                 : 192
Average number of Pins per Net : 2.78
Maximum number of Pins in Net  : 11

------ I/O Port summary

Number of Primary I/O Ports    : 18
Number of Input Ports          : 10
Number of Output Ports         : 8
Number of Bidirectional Ports  : 0
Number of Power/Ground Ports   : 0
Number of Floating Ports                     *: 0
Number of Ports Connected to Multiple Pads   *: 0
Number of Ports Connected to Core Instances   : 18
**WARN: (IMPREPO-202):  There are 18 Ports connected to core instances.

------ Design Rule Checking:

Number of Output Pins connect to Power/Ground *: 0
Number of Insts with Input Pins tied together ?: 0
Number of TieHi/Lo term nets not connected to instance's PG terms ?: 0
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'state_reg[1]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'state_reg[0]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[7]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[6]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[5]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[4]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[3]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[2]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[1]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[0]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[0] connected to net sum[0] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[0] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[0] connected to net n_166 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[0] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[1] connected to net sum[1] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[1] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[1] connected to net n_170 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[1] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[2] connected to net sum[2] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[2] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[2] connected to net n_172 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[2] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[3] connected to net sum[3] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[3] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[3] connected to net n_168 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[3] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[4] connected to net sum[4] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[4] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[4] connected to net n_167 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[4] connected to net reset but this pin has no shape.
**WARN: (EMS-27):       Message (IMPREPO-513) has exceeded the current message display limit of 20.
To increase the message display limit, refer to the product command reference manual.
Number of Input/InOut Floating Pins            : 10
Number of Output Floating Pins                 : 0
Number of Output Term Marked TieHi/Lo         *: 0

**WARN: (IMPREPO-218):  There are 10 Floating Instance terminals.
**WARN: (IMPREPO-514):  There are 508 pin connect with net but term has no shape.
Number of nets with tri-state drivers          : 0
Number of nets with parallel drivers           : 0
Number of nets with multiple drivers           : 0
Number of nets with no driver (No FanIn)       : 0
Number of Output Floating nets (No FanOut)     : 0
Number of High Fanout nets (>50)               : 0
Design check done.
Report saved in file RPT/saturation_step_counter.main.htm.ascii

*** Summary of all messages that are not suppressed in this session:
Severity  ID               Count  Summary
WARNING   IMPDB-2136          10  %s term '%s' of %s instance '%s' does no...
WARNING   IMPREPO-513        508  Pin %s of inst %s connected to net %s bu...
WARNING   IMPREPO-514          1  There are %d pin connect with net but te...
WARNING   IMPREPO-202          1  There are %d Ports connected to core ins...
WARNING   IMPREPO-218          1  There are %d Floating Instance terminals...
*** Message Summary: 521 warning(s), 0 error(s)

0

```

먼저 globalNetConnect는 스탠다드 셀 내부의 VDD/VSS 핀을 설계의 전원/그라운드에 논리적으로 연결해주는 것이다. 

![[Pasted image 20260414184114.png]]
user guide 1998p

잘 연결되었는지 다음 명령어로 확인할 수 있다. 
`checkDesign -netlist -physicalLibrary -timingLibrary -powerGround -outDir RPT`

![[Pasted image 20260414184525.png]]

![[saturation_step_counter.main.htm]]

다음 리포트를 보면
![[Pasted image 20260414184713.png]]

Pin without shape이 508개가 잡힌다. 
그리고 Floating Instance terminals도 10개가 잡힌다. 

각 부분의 warning을 자세히 보면

Pin without shape: 
```
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[0] connected to net sum[0] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[0] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[0] connected to net n_166 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[0] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[1] connected to net sum[1] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[1] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[1] connected to net n_170 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[1] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[2] connected to net sum[2] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[2] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[2] connected to net n_172 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[2] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[3] connected to net sum[3] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[3] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[3] connected to net n_168 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[3] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[4] connected to net sum[4] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[4] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[4] connected to net n_167 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[4] connected to net reset but this pin has no shape.
**WARN: (EMS-27):       Message (IMPREPO-513) has exceeded the current message display limit of 20.
```

다 shape이 없다고 뜬다. 
shape이 뭘까?

etri050_stdcells.lef 를 참고해보자. 

![[etri050_stdcells (2).lef]]

이건 내꺼
![[assets/no_tech.lef]]


내가 만든 lef와 비교해보면

etri
```
PIN gnd
    DIRECTION INOUT ;
    USE GROUND ;
    SHAPE ABUTMENT ;
    PORT
      LAYER metal1 ;
        RECT -0.900 -1.200 15.900 1.200 ;
    END
  END gnd
```

```
PIN A
    DIRECTION INPUT ;
    USE SIGNAL ;
    PORT
      LAYER metal2 ;
        RECT 0.450 15.450 2.550 17.550 ;
    END
  END A
```


내꺼
```
PIN VSS
    DIRECTION INOUT ;
    USE GROUND ;
  END VSS
```

```
PIN Q
    DIRECTION OUTPUT ;
    USE SIGNAL ;
  END Q
```

전원 핀은 SHAPE과 PORT 부분이 빠져있고 일반 핀은 PORT가 빠져있다. 

각 부분을 살펴보면 

**SHAPE ABUTMENT**
etri lef의 gnd핀에 있는 이 부분은, 해당 핀의 shape이 인접 셀과 맞닿아 연결되는 구조라는 뜻이다. 
std cell을 한 줄로 나란히 놓으면 세로 길이가 같으니까 쭉 이어지는 것이 이 속성으로 알 수 있다. 

**PORT**
이 핀에 와이어를 연결하면 된다고 알려준다. 라우터가 물리적으로 접근할 수 있는 금속 영역의 시작을 선언한다. 

**RECT -0.900 -1.200 15.900 1.200**
이 핀이 어디있는지 나타낸다. 
순서대로 왼쪽아래x, 왼쪽아래y, 오른쪽위x, 오른쪽아래y 좌표이다. 

이 정보가 없으면 routing이 정상적으로 실행되지 않을 것 같으니 문제를 해결해보자..


# Pin without shape 해결방안

abstract 으로 다시 lef를 뽑아봐도 문제는 동일했다. 
그러니 layout을 열고 핀을 확인해보니

## 문제 1

![[Pasted image 20260414192828.png]]
문제: 핀이 MET1TXT drawing 레이어에 있다. 
MET1 drawing 레이어에 있어야한다. 

-->
![[Pasted image 20260414193004.png]]


## 문제 2

![[Pasted image 20260414192836.png]]
문제: 핀의 타입이 signal로 되어있다. 
이게 아니라 power로 되어있어야 한다. 

-->
![[Pasted image 20260414193341.png]]

다른 셀도 모두 수정 사항을 적용해주면 된다. 

수정하고 abstract에서 다시 추출하고 lef를 export해주면,
![[abstract.lef]]

```
PIN VSS
    DIRECTION INOUT ;
    USE GROUND ;
    PORT
      LAYER MET1 ;
        RECT 6.4 6.7 86.2 8.5 ;
        RECT 84.35 14.01 86.15 15.81 ;
        RECT 84.85 6.7 85.65 15.81 ;
        RECT 81.75 14.01 83.55 15.81 ;
        RECT 82.25 6.7 83.05 15.81 ;
        RECT 76.55 14.01 78.35 15.81 ;
        RECT 77.05 6.7 77.85 15.81 ;
        RECT 71.35 14.01 73.15 15.81 ;
        RECT 71.85 6.7 72.65 15.81 ;
        RECT 56.18 14.01 57.98 15.81 ;
        RECT 56.68 6.7 57.48 15.81 ;
        RECT 46.69 14.01 48.49 15.81 ;
        RECT 47.32 6.7 48.12 15.81 ;
        RECT 36.95 14.01 38.75 15.81 ;
        RECT 37.45 6.7 38.25 15.81 ;
        RECT 31.75 14.01 33.55 15.81 ;
        RECT 32.25 6.7 33.05 15.81 ;
        RECT 29.15 14.01 30.95 15.81 ;
        RECT 29.65 6.7 30.45 15.81 ;
        RECT 23.95 14.01 25.75 15.81 ;
        RECT 24.45 6.7 25.25 15.81 ;
        RECT 6.5 14.01 8.3 15.81 ;
        RECT 7 6.7 7.8 15.81 ;
    END
  END VSS
```

이렇게 PORT가 생긴 것을 알 수 있다!

### 참고!
Tool 오류인지 몰라도 DFF의 SET 신호가 layout에서 signal로 설정해줘도 analog로 export되는 문제가 있다. 
해당 문제는 직접 lef를 수정하여 해결했다. 

![[Pasted image 20260414200021.png]]

## Floating Instance terminals 해결방안

이 문제는 합성된 넷리스트에서 DFF셀의 10개 SET 핀이 floating상태인 것이다. 
RTL에서 해당 기능을 사용하지 않았기 때문에 연결되어있지 않은거다. 

![[Pasted image 20260414201032.png]]

해당 명령어를 통해 해결할 수 있다. 

이 명령의 의미를 분해하면:
- **`VSS`** — 연결할 대상 글로벌 넷
- **`-type tielo`** — "tie-low가 필요한 핀"을 대상으로 한다
- **`-all`** — 설계 내 모든 인스턴스에 적용

즉 설계 전체에서 로직 0으로 고정해야하는 핀을 찾아서 VSS에 연결하라는거다. 

내 DFF의 SET은 active high니까, VSS에 묶이는게 맞다. 

`globalNetConnect VSS -type tielo -all`

이렇게 적용하고 다시 확인해보면,

![[Pasted image 20260414201220.png]]

모든 문제가 해결되었다!!

