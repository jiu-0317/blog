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