
xcelium 유저가이드는 아래 파일에 있다.  

![[xceliumSCUG.tar.gz]]

![[glsug.tar.gz]]

하나씩 보면서 사용법을 익혀봐야겠다.  

PnR이 끝나고 spef를 tempus에서 sdf로 변환했다.  
sdf를 컴파일하기 전에, 먼저 넷리스트를 컴파일해야한다.  

유저가이드를 보면 

게이트 레벨 시뮬레이션(GLS)은 게이트 지연 유무에 관계없이 넷리스트를 시뮬레이션하는 것으로, RTL 코드 합성 후 또는 P&R(배치 및 라우팅) 후에 수행됩니다. RTL 시뮬레이션은 하나 이상의 HDL 언어로 작성된 소스 코드의 기능과 유효성을 검사하고 검증하기 위한 RTL 코드 시뮬레이션입니다.

게이트 레벨 시뮬레이션은 고수준 RTL에서 저수준 게이트 구현으로 변환하는 과정에서 원하는 기능이 손실되지 않는지 확인하고, 타이밍이 활성화되었을 때 타이밍 지연으로 인해 의도된 기능이 손상되지 않는지 확인하는 데 사용됩니다.

라고 한다.  


![[Pasted image 20260605225704.png]]

① 컴파일 (xmvlog) → HDL 소스를 내부 표현으로 변환 
② Elaboration (xmelab) → 설계 계층 구성, SDF 어노테이션 수행 
③ Simulation (xmsim) → 스냅샷 로드 후 시뮬레이션 실행

셀의 타이밍 정보를 담고있는 .v 파일이 없어서 만들었다.  

![[std_cell.v]]

먼저 각 파일을 컴파일한다. 

```
xmvlog -work worklib tb_TOP.v TOP.v std_cell.v
```

다음으로 sdf 커맨드를 써준다.  

![[top.sdf_cmd]]

```
SDF_FILE = "top.sdf",
SCOPE = tb_TOP.u_top,
LOG_FILE = "sdf.log",
MTM_CONTROL = "MAXIMUM";
```

다음으로 elaboration을 진행했다.  

```
xmelab -work worklib -sdf_cmd_file top.sdf_cmd worklib.tb_TOP
```

그러니까 이런 warning이 엄청 뜬다.  

`SDFNEP`:SDF에 `IOPATH R Q`, `IOPATH S Q`, `IOPATH D Q` 등의 path delay가 있는데, `std_cell.v`의 해당 셀 `specify` 블록에 대응하는 path가 없음

`SDFNET`: SDF에 `SETUPHOLD`, `RECREM`, `WIDTH` 등의 timing check가 있는데, `std_cell.v`의 해당 셀 `specify` 블록에 대응하는 timing check가 없음

이 워닝들은 해당 셀의 일부 타이밍이 어노테이션되지 않는다는 뜻이지, 시뮬레이션 자체가 불가능하다는 것은 아니니까 그대로 진행한다.  

---

그냥 xrun으로 했다. 

```tcl
xrun  tb_TOP.v TOP.v std_cell.v -sdf_file max:TOP:top.sdf -access +rwc -gui
```

이렇게 했는데 결과가 2pass 21fail이 나서 파형을 보니 result가 모두 X였다.  

![[Pasted image 20260606151810.png]]

보니까 clk는 잘 나오는데 ~clk가 X로 나오는 것을 확인했다.  
inv가 잘 동작하고있지 않은 것이다.  

## 문제:
합성된 표준 셀(`mychips_scl_0.0.1_tt_5.50v.v`)들이 전원핀(VDD/VSS)을 가진 power-aware 모델이다. 
넷리스트 `TOP.v`는 이 셀들을 VDD/VSS 연결 없이 인스턴스화했고, UPF도 없었으며, 전원을 자체 구동하는 `initial force VDD=1'b1`은 `` `ifdef no_power_gate `` 안에만 있었다. 
그런데 그 define 없이 시뮬을 돌리는 바람에 모든 셀의 전원이 X로 떠서 → 셀 출력이 전부 X → 데이터패스 전체가 X → `o_miso`가 처음부터 끝까지 X였다.

## 적용한 해결책:
컴파일 시 `+define+no_power_gate`를 추가했다. 
이 한 줄로 모든 셀이 VDD=1/VSS=0을 자체 구동해 정상 기능 동작을 하게 됐다.

## 문제를 찾은 과정:
문제의 핵심은 "X가 어디서 시작되는가"를 한 단계씩 좁혀간 것이었다.

1. 타이밍 위반 의심 → 배제: 처음엔 SDF max 어노테이션으로 인한 setup/hold violation → notifier X 전파를 의심했지만, `-notimingchecks`로도 X가 그대로여서 타이밍 문제가 아님을 확인했다.
2. VCD로 자극 vs 출력 분리: 파형을 보니 clk은 187,018회 토글, reset도 매 테스트 정상인데 `o_miso`는 935µs 내내 X 한 번만 찍히고 고착. 자극은 완벽한데 DUT 출력만 죽어 있다 → 내부 구조적 X 전파로 방향 전환.
3. 계층을 따라 X 추적: clk/reset은 DUT 내부까지 정상 도달하는데 결과 레지스터(`acc_r_data`, `u_spi_RBUF`)가 X. VCD scope에서 클럭 게이팅 셀(`u_spi_RC_CG_HIER_INST*`)을 발견 → 게이팅 클럭 `ck_out`이 X에 고착된 것을 확인.
4. 게이팅 enable force 시도 → 더 깊은 단서: enable을 1로 force해도 `ck_out`이 안 풀림. 더 안쪽을 찍어보니 인버터 출력 `n_0`이 입력 1에 X를 출력 → 게이팅이 아니라 셀 자체가 정상 입력에도 X를 내고 있다는 결정적 단서.
5. 라이브러리 grep으로 확정: 셀 정의를 grep하니 `pg_type` 전원핀과 `` `ifdef no_power_gate `` 안의 `initial force VDD/VSS`가 보였고, 네트리스트엔 전원핀 미연결 → 전원 X가 모든 X의 근원임을 확정.

최종 명령어:

```
xrun tb_TOP.v TOP.v mychips_scl_0.0.1_tt_5.50v.v \
+define+no_power_gate \
-sdf_verbose \
-access +rwc
```

+define+no_power_gate 이 핵심이다.  

![[Pasted image 20260606173729.png]]


## sdf back annotation
다음으로 sdf 백어노테이션을 했다.  
tb에 다음 구문을 넣으면 된다  

```
initial $sdf_annotate("./top.sdf", u_top, , , "MAXIMUM");
```

![[Pasted image 20260606173820.png]]

xrun 돌리면 log에 이렇게 백어노테이션이 얼마나 되었는지 결과가 나온다.  

결과를 보면 잘 나온다.  
타이밍 위반이 있기는 한데 latch 에 생기고 시뮬 초반에 생겨서 무시가 가능할 것 같다.  

타겟 주파수가 20M인데 40M로 높이자 결과가 깨져서 나왔다.  

