![[tech.lef]]


## 테크놀로지 LEF

공정(fabrication) 수준의 물리적 규칙을 담고 있다.

- **UNITS** — 거리, 저항, 커패시턴스 등의 단위 정의
- **LAYER 정의** — 각 레이어(poly, metal1, via1 등)의 타입, 방향(DIRECTION), 피치(PITCH), 최소 폭(WIDTH), 최소 간격(SPACING) 같은 디자인 룰
- **VIA 정의** — via의 구조 (어떤 레이어를 연결하고, cut 크기와 enclosure이 어떻게 되는지)
- **VIARULE GENERATE** — via를 자동 생성할 때의 규칙
- **SITE 정의** — 셀 배치의 기본 격자 단위 (폭, 높이)
- **PROPERTYDEFINITIONS** — 위에서 본 확장 속성 선언

## 셀 라이브러리 LEF

개별 스탠다드 셀의 물리적 추상 정보를 담고 있어요.

- **MACRO** — 각 셀(INV, NAND, NOR, DFF 등)의 정의
    - **SIZE** — 셀의 가로×세로 크기
    - **CLASS** — 셀 종류 (CORE, PAD 등)
    - **SYMMETRY** — 배치 시 허용되는 대칭 (X, Y, R90 등)
    - **SITE** — 이 셀이 어떤 SITE 격자에 놓이는지
    - **PIN** — 각 핀(A, B, Y, VDD, VSS 등)의 방향(INPUT/OUTPUT/INOUT), 용도(SIGNAL/POWER/GROUND), 그리고 **PORT 도형** (어떤 레이어의 어떤 좌표에 핀이 있는지)
    - **OBS** — obstruction, 라우터가 피해야 할 영역

```
PROPERTYDEFINITIONS
  MACRO CatenaDesignType STRING ;
  LAYER LEF58_TYPE STRING ;
  LAYER LEF58_ENCLOSURE STRING ;
  LAYER LEF58_SPACING STRING ;
  LAYER LEF58_WIDTH STRING ;
END PROPERTYDEFINITIONS
```
사용자 정의 속성(custom properties)을 선언하는 부분.
