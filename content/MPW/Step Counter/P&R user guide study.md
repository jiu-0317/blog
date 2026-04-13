
이제 import design에 성공했으니 본격적으로 P&R 을 할 차례다. 
먼저 innovus의 user guide를 읽고 공부한 내용을 정리한다. 
# Flat Implementation

![[Pasted image 20260412194029.png]]

전체 설계를 계층 분할 없이 하나의 덩어리로 place & route하는 방식입니다. 설계 전체가 단일 레벨에서 한 번에 처리됩니다.

장점: 계층 설정의 복잡성이 없고, 셋업이 단순합니다. 작은 설계에 적합합니다.

단점: 설계 규모가 수백만 인스턴스 이상으로 커지면 메모리 사용량과 런타임이 과도해져 비현실적이 됩니다.

Hierarchical flow는 설계를 여러 블록으로 분할(partition)해서 각 블록을 독립적으로, 병렬로 구현한 뒤 최종 조립(chip assembly)하는 방식입니다. 
대규모 SoC에서는 필수적이지만, 타이밍 클로저나 블록 간 인터페이스 관리가 복잡해집니다.

현재 설계는 테스트로 해보는 Step counter로 크기가 매우 작으니, Flat implementation이 적합하다. 

# Foundation Flow

Foundation Flow는 Cadence에서 제공하는 권장 PnR 스크립트 템플릿입니다.

쉽게 말하면, Innovus로 PnR을 할 때 필요한 명령어와 설정을 Cadence가 미리 검증된 순서와 옵션으로 짜놓은 레퍼런스 스크립트입니다. Flat, hierarchical, low-power(CPF) 설계 각각에 대한 버전이 있습니다.

왜 만들었느냐면, 사용자가 직접 flow 스크립트를 작성하고 유지보수하는 것이 시간이 많이 걸리고 실수가 발생하기 쉽기 때문입니다. 또한 Innovus 버전이 올라갈 때마다 권장 명령어와 옵션이 바뀌는데, 이를 매번 따라가기가 어렵습니다. Foundation Flow를 쓰면 각 릴리스에서 검증된 최신 권장 플로우를 바로 사용할 수 있습니다.

# Design Closure Flow

Design Closure Flow는 합성된 넷리스트를 받아서 물리적으로 완성된, 타이밍 위반 없는 칩을 만들어내는 전체 과정을 말합니다. 
"Closure"라는 단어는 모든 제약 조건(타이밍, 면적, 전력, DRC 등)이 수렴(converge)해서 더 이상 위반이 없는 상태에 도달한다는 뜻입니다.

타이밍 closure는 단순히 타이밍 최적화만이 아니라, placement, timing optimization, CTS, routing, SI fixing이 모두 수렴해야 하는 완전한 플로우이고, 각 단계가 목표치를 달성해야만 최종 closure가 가능하다고 합니다.

구체적인 단계는 순서대로 다음과 같다:
1. Data Preparation — LEF, .lib, .v, .sdc 등 입력 파일 준비
2. init_design — 데이터 import 및 검증
3. Floorplanning — 칩 영역 설정, 매크로 배치, 전원망 구성
4. place_opt_design (Pre-CTS Optimization) — 셀 배치 + 타이밍 최적화
5. CTS (Clock Tree Synthesis) — 클럭 트리 생성
6. Post-CTS Optimization — 클럭 삽입 후 setup/hold 최적화
7. Detailed Routing — 실제 배선
8. Post-Route Extraction — 기생 RC 추출
9. Post-Route Optimization — 배선 후 최종 타이밍 최적화
10. Chip Finishing — metal fill, filler cell 삽입, DRC 정리
11. Timing Signoff — 최종 타이밍 검증

# Data Preparation for Design Closure Flow

Design Closure Flow를 위해서는 다은과 같은 파일이 필요하다.

## **Timing Libraries** — `.lib`
liberate에서 제작한 .lib파일. 
모든 셀(standard cell, block, I/O pad)의 타이밍 정보를 담고 있다. 

## **Physical Libraries** — `.lef`
셀의 abstract(물리적 레이아웃 정보)를 정의하며, technology LEF와 cell LEF로 나뉜다. 
Cell lef를 뽑을 때 abstract view를 지정할 수 있다. 

## **Verilog Netlist** — `.v`
The netlist should be unique.
Use the init_design_uniquify global variable to 1.

여기서 init_design_uniquify는 뭐고 unique 해야한다는건 뭘까?

여기서 non-unique하다는건 넷리스트에서 같은 모듈이 여러 번 인스턴스화된 경우, 하나의 인스턴스만 수정할 수 없는 상태이다. 
모듈을 수정하면 세개의 인스턴스에 모두 영향이 간다. 

반대로 unique하다는건 하나의 인스턴스만 수정할 수 있는 상태이다. 내부적으로 각 안스턴스가 독립된 모듈 정의를 갖도록 한다. 

uniquify는 non-unique에서 unique로 바꾸는 것이다. 

init_design_uniquify 가 0이면 uniquify를 진행X 1이면 진행.

그러니 Use the init_design_uniquify global variable to 1. 라고 하는거다. 최적화하기 편하게.

## Timing Constraints — `.sdc`
Timing constraints in the form of SDCs are required. You should have an SDC file for each operational mode required for analysis.

## Multi-Mode Multi-Corner
Multi-mode multi-corner analysis uses a tiered approach to assemble the information necessary for timing analysis and optimization.

MMMC View Definition File은 보통 `viewDefinition.tcl`이라는 이름의 Tcl 스크립트로, Innovus가 타이밍 분석에 필요한 모든 객체를 한꺼번에 정의하는 파일이다.

이 파일에는 다음 항목들이 순서대로 들어간다:

1. **Library Set** — 타이밍 라이브러리(.lib) 파일 경로 (`create_library_set`)
2. **RC Corner** — 배선 기생 캐패시턴스/저항 조건 (`create_rc_corner`)
3. **Delay Corner** — Library Set + RC Corner + 동작 조건(PVT)을 묶은 것 (`create_delay_corner`)
4. **Constraint Mode** — SDC 타이밍 제약 파일 (`create_constraint_mode`)
5. **Analysis View** — Delay Corner + Constraint Mode를 조합 (`create_analysis_view`)
6. **Active View 설정** — setup/hold 분석에 사용할 view 지정 (`set_analysis_view`)

작성한 MMMC viewDefinition.tcl 스크립트는 다음과 같다:
```tcl
create_library_set -name my_libs \
  -timing [list /home/virtuoso2/liberate/test4/dff_stdcell_1.lib]

create_rc_corner -name my_rc

create_delay_corner -name my_dc \
  -library_set my_libs \
  -rc_corner my_rc

create_constraint_mode -name my_mode \
  -sdc_files [list /home/virtuoso2/genus/test5/outputs/saturation_step_counter.sdc]

create_analysis_view -name my_view \
  -constraint_mode my_mode \
  -delay_corner my_dc

set_analysis_view -setup my_view -hold my_view
```

각 명령어가 어떤 역할을 하는지 정리해보겠다. 

### create_library_set
여러 개의 라이브러리 파일(.lib)을 하나의 묶음으로 만들어 이름을 붙인 것이다. 

복잡한 설계에서는 하나의 .lib 파일로 모든 셀을 커버하지 못합니다. 예를 들어:

- Standard Cell용 .lib 1개
- 메모리(SRAM 등)용 .lib 1개
- I/O Pad용 .lib 1개

이렇게 3개의 .lib가 필요한데, 매번 3개를 따로따로 지정하면 번거롭습니다. 그래서 이것들을 **하나의 Library Set으로 묶어서 이름을 붙이면**, 나중에 Delay Corner 같은 상위 설정에서 그 이름 하나만 참조하면 됩니다.

### create_rc_corner
배선(wire)의 기생 저항(R)과 기생 캐패시턴스(C)를 추출하는 조건을 정의한 것입니다.

왜 필요한가?
칩 내부에서 셀과 셀을 연결하는 금속 배선에는 원치 않는 저항(R)과 캐패시턴스(C)가 생깁니다. 이 기생 성분은 신호 지연에 직접 영향을 주기 때문에, 정확한 타이밍 분석을 하려면 이 값을 추출해야 합니다.

그런데 온도, 공정 편차 등에 따라 R과 C 값이 달라집니다. 그래서 어떤 조건에서 RC를 추출할 것인지를 RC Corner로 정의합니다.


### create_delay_corner
lib와 rc를 합쳐서 delay corner를 만든다. 

### create_constraint_mode
**Constraint Mode란?**
설계의 "동작 모드"별 타이밍 제약(SDC 파일)을 묶어서 이름을 붙인 것입니다.

**왜 필요한가?**
하나의 칩이 여러 모드로 동작할 수 있습니다:

- Functional 모드 — 정상 동작
- Test 모드 — 스캔 테스트 동작
- DVFS 모드 — 주파수/전압을 바꿔서 동작

각 모드마다 클럭 주파수, I/O 타이밍, 예외 경로 등이 다르기 때문에 SDC 파일도 다릅니다. 이 SDC 파일들을 모드별로 묶어놓은 것이 Constraint Mode입니다.

![[Pasted image 20260413180458.png]]

다음 그림은 3개의 .sdc 파일을 missionSetup 이라는 constraint mode로 묶은 것아다. 
이번 디자인은 단일 모드(기능모드)이므로, sdc파일 1개만 넣으면 된다. 

### create_analysis_view
Analysis View란?
Delay Corner + Constraint Mode를 합쳐서 "하나의 분석 조건"으로 만든 것입니다. Innovus가 타이밍을 분석할 때 사용하는 최종 단위이다.

이 디자인에서는 setup과 hold time 이 동일한 analysis view를 사용한다. 


# Floorplanning

이제 floorplan을 하면 된다..
![[Pasted image 20260413190701.png|357]]

![[Pasted image 20260413190634.png]]

명령어를 입력하니 이렇게 나왔다:
```c
innovus 3> floorPlan -site CoreSite -d {1000 1000 100 100 100 100}
**WARN: (IMPFP-4026):   Adjusting core to 'Bottom' to 99.200000 due to track/row misalignment. To force the value, specify the -noSnapToGrid option or use fpiSetSnapRule command to specify the die/core to different grid.
**WARN: (IMPFP-4026):   Adjusting core to 'Top' to 99.200000 due to track/row misalignment. To force the value, specify the -noSnapToGrid option or use fpiSetSnapRule command to specify the die/core to different grid.
**WARN: (IMPFP-3961):   The techSite 'CoreSite' has no related standard cells in the LEF/OA library. The calculations for this site type cannot be made unless standard cell models of this type exist in the LEF/OA library. Ignore this warning if the SITE is not used by the library. Alternatively, remove the SITE definition for the LEF/OA library to avoid this message.
Type 'man IMPFP-3961' for more detail.
**WARN: (IMPFP-3961):   The techSite 'CoreSite' has no related standard cells in the LEF/OA library. The calculations for this site type cannot be made unless standard cell models of this type exist in the LEF/OA library. Ignore this warning if the SITE is not used by the library. Alternatively, remove the SITE definition for the LEF/OA library to avoid this message.
Type 'man IMPFP-3961' for more detail.
Start create_tracks
Generated pitch 2 in MET3 is different from 2.4 defined in technology file in unpreferred direction.
Generated pitch 1.6 in MET2 is different from 2 defined in technology file in unpreferred direction.
Generated pitch 2 in MET1 is different from 1.6 defined in technology file in unpreferred direction.
**WARN: (IMPFP-325):    Floorplan of the design is resized. All current floorplan objects are automatically derived based on specified new floorplan. This may change blocks, fixed standard cells, existing routes and blockages.
```

