
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

# **Timing Constraints** — `.sdc`
Timing constraints in the form of SDCs are required. You should have an SDC file for each operational mode required for analysis.

