# CODE_GUIDE — 현재 파이썬 코드 전체 해설

> **읽는 사람**: 인공지능 이론은 알지만 프로그래밍은 처음. 하드웨어/Verilog/C 배경.
> **목적**: `D:\jiu\fpga\fp8_eval\` 의 코드를 남이 쓴 것이 아니라 **내 것으로** 만들기.
> **연구 맥락은** `HANDOFF.md` 를 볼 것. 이 문서는 오직 코드만 다룬다.

---

## 0. 이 문서를 쓰는 법

다음 세션에서 이 문서를 열어 두고, **§4의 순서대로 파일을 하나씩 읽으면서**
막히는 줄마다 물어보면 된다. §9에 "물어보면 좋을 질문" 목록을 미리 만들어 두었다.

한 번에 다 이해하려 하지 말 것. `fp8.py` 의 `quantize()` 함수 하나만 완전히
이해해도 나머지의 70%가 따라온다.

---

## 1. 전체 지도 — 파일이 서로를 어떻게 부르는가

```
                    ┌─────────────────────────────────┐
                    │  resnet9_best_mixed_fp8.pt      │  선배가 준 가중치 (데이터)
                    └───────────────┬─────────────────┘
                                    │ torch.load()
                                    ▼
   data.py  ────────────►  resnet9_senior.py  ◄────────  torchvision (CIFAR-10)
   (데이터 공급)              (모델 정의 + 평가)
                                    │
                                    │  model, x, y
                                    ▼
   fp8.py   ────────────►     eval_w.py                  실험 스크립트
   (양자화 도구)              (정확도 매트릭스)
                                    │
                                    ▼
                              화면에 표 출력

   [미사용] resnet9.py + train.py + data.py(0~1 로더)  ← 자체 학습용, 지금은 안 씀
   [보존]   inspect_pt.py                              ← .pt 파일 들여다보는 도구
```

**핵심은 셋이다.**

| 파일                  | 한 줄 정의                | Verilog로 치면  |
| ------------------- | --------------------- | ------------ |
| `fp8.py`            | FP8 숫자를 다루는 **도구 상자** | 재사용 모듈 라이브러리 |
| `resnet9_senior.py` | 신경망 **구조 정의 + 평가 함수** | 데이터패스 정의     |
| `eval_w.py`         | 실험을 **조립해서 돌리는 스크립트** | 테스트벤치        |

`import` 는 Verilog의 모듈 인스턴스화와 비슷하다.
`from fp8 import quantize` 는 "fp8.py 안의 quantize 를 여기서 쓰겠다"는 뜻이다.

---

## 2. 먼저 알아야 할 파이썬 문법 10가지

### 2.1 들여쓰기가 블록이다

C의 `{ }` 대신 **들여쓰기**로 블록을 구분한다. 콜론 `:` 다음 줄부터 들여쓴다.

```python
if x > 0:           # C의  if (x > 0) {
    y = 1           #          y = 1;
    z = 2           #          z = 2;
                    #      }
w = 3               # 들여쓰기가 풀리면 블록 밖
```

들여쓰기가 틀리면 **문법 에러**다. 공백 4칸이 관례.

### 2.2 타입 선언이 없다

```python
x = 5             # int
x = "hello"       # 같은 이름에 문자열을 넣어도 된다
```

`def quantize(x: torch.Tensor, fmt: FP8Format) -> torch.Tensor:` 에서
`: torch.Tensor` 와 `-> torch.Tensor` 는 **주석일 뿐**이고 강제되지 않는다
(type hint). 읽는 사람을 위한 것이다.

### 2.3 함수 — `def`, 기본값, 키워드 인자

```python
def pow2_scale(x, fmt, mode="max", shift=0):    # mode, shift 는 기본값이 있다
    ...

pow2_scale(w, E4M3)                  # mode="max", shift=0 으로 불린다
pow2_scale(w, E4M3, shift=2)         # 이름으로 지정 — 순서 상관없음
```

`**scale_kwargs` 는 "이름 붙은 인자를 통째로 받아서 그대로 넘긴다"는 뜻이다.

```python
def fake_quant(x, fmt, scale=None, **scale_kwargs):
    scale = pow2_scale(x, fmt, **scale_kwargs)   # 받은 걸 그대로 전달
```

### 2.4 클래스 — `class`, `__init__`, `self`

```python
class ScaleCalibrator:
    def __init__(self, fmt, mode="max"):   # 생성자. 객체를 만들 때 한 번 불린다
        self.fmt = fmt                      # self = 자기 자신. C의 구조체 포인터
        self.mode = mode
        self._running_max = None            # 앞에 _ 는 "내부용" 이라는 관례

    def observe(self, x):                   # 메서드. 첫 인자는 항상 self
        ...

cal = ScaleCalibrator(E4M3)    # 객체 생성 -> __init__ 호출
cal.observe(활성)               # self 는 자동으로 cal 이 들어간다
```

`self` 는 명시적으로 쓴다는 점만 C++/Java와 다르다.

### 2.5 `@dataclass` — 구조체 만들기

```python
@dataclass(frozen=True)
class FP8Format:
    name: str
    mant_bits: int
    max_val: float
```

이렇게만 쓰면 `__init__` 이 자동으로 만들어진다. **C의 struct**라고 보면 된다.
`frozen=True` 는 "만든 뒤 못 고친다" — 상수 취급.

`@` 로 시작하는 것을 **데코레이터**라 하는데, "아래 정의를 이렇게 변형해라"는 표시다.

### 2.6 `@property` — 괄호 없이 부르는 메서드

```python
@property
def min_normal(self):
    return 2.0 ** self.e_min

E4M3.min_normal     # 괄호 없이 속성처럼 쓴다. 실제로는 함수가 돈다
```

`**` 는 거듭제곱이다 (`2.0 ** -6` = 2^-6).

### 2.7 리스트 / 딕셔너리 / 튜플

```python
a = [1, 2, 3]              # 리스트: 순서 있음, 고칠 수 있음
d = {"key": 1, "k2": 2}    # 딕셔너리: 이름->값. Verilog의 연관배열
t = (1, 2)                 # 튜플: 고칠 수 없는 리스트. 함수가 여러 값 돌려줄 때 씀

q, stats = quantize_stats(x, fmt)    # 튜플을 두 변수로 한 번에 받는다
```

`stats["flush_ratio"]` 로 딕셔너리 값을 꺼낸다.

### 2.8 반복문과 컴프리헨션

```python
for k, v in d.items():          # 딕셔너리를 이름/값 쌍으로 순회
    print(k, v)

for i in range(0, 10, 3):       # 0, 3, 6, 9
    ...

vals = [x * 2 for x in a]       # 리스트 컴프리헨션: [2, 4, 6]
```

마지막 것은 "a의 각 원소를 2배 해서 새 리스트를 만든다"는 뜻이다. 자주 나온다.

### 2.9 제너레이터 — `yield`

```python
def batches(x, y, batch_size):
    for i in range(0, N, batch_size):
        yield x[i:i+batch_size], y[i:i+batch_size]   # return 이 아니라 yield

for xb, yb in batches(x, y, 128):    # 필요할 때마다 하나씩 꺼내 준다
    ...
```

`return` 은 함수를 끝내지만 `yield` 는 **값을 하나 내주고 멈췄다가 다음에 이어서**
돈다. 전체를 메모리에 만들지 않아도 되므로 큰 데이터에 유리하다.
하드웨어로 치면 한꺼번에 다 뱉는 대신 **스트리밍**하는 것이다.

### 2.10 f-string — 문자열 안에 값 넣기

```python
print(f"정확도 {acc * 100:.2f}%")     # acc=0.9382 -> "정확도 93.82%"
```

`f"..."` 안의 `{ }` 에 식을 넣는다. `:.2f` 는 소수점 2자리, `:6.2f` 는 너비 6칸.
C의 `printf("%6.2f")` 와 같다.

---

## 3. PyTorch 개념 8가지

### 3.1 텐서(Tensor) = 다차원 배열

```python
x = torch.randn(64, 3, 32, 32)    # 4차원 배열
x.shape                            # torch.Size([64, 3, 32, 32])
x.dim()                            # 4
x.numel()                          # 원소 총 개수 = 64*3*32*32
x.dtype                            # torch.float32
x.device                           # cuda:0 (GPU 위에 있다)
```

신경망에서 이미지 배치는 관례적으로 **(N, C, H, W)** 순서다:
장 수(batch), 채널, 높이, 너비.

### 3.2 GPU에 올린다 = `.to(device)`

```python
x = x.to("cuda")       # GPU 메모리로 복사
```

GPU에 있는 텐서끼리만 연산할 수 있다. CPU 텐서와 섞으면 에러가 난다.
이 프로젝트는 CIFAR-10 전체(50000장)를 통째로 GPU에 올려 두고 쓴다 — 작아서 가능하다.

### 3.3 ★ 벡터화 — for문을 쓰지 않는다

**이게 파이썬 수치 코드에서 가장 중요한 개념이다.**

```python
# 나쁨: 원소마다 파이썬 for문 -> 512번 CPU-GPU 왕복, 매우 느림
result = []
for i in range(512):
    result.append(x[i].max())

# 좋음: 한 줄로 512개를 동시에 -> GPU가 병렬로 처리
result = x.max(dim=1).values
```

Verilog로 치면 **순차 FSM으로 512사이클 도는 것 vs 512개 회로를 병렬로 놓는 것**의
차이다. GPU는 후자를 위한 하드웨어다.

`fp8.py` 수정에서 실제로 고친 버그가 이것이다 — `_reference_magnitude` 가
채널마다 파이썬 루프를 돌았는데 텐서 연산 한 줄로 바꿨다.

### 3.4 브로드캐스팅 — 모양이 달라도 자동으로 맞춘다

```python
x = torch.randn(64, 512, 8, 8)    # (N, C, H, W)
s = torch.randn(1, 512, 1, 1)     # 채널별 스케일
y = x / s                          # 알아서 (64,512,8,8) 로 늘려서 나눈다
```

크기가 1인 축은 **자동으로 복제**된다. Verilog의 replicate `{N{signal}}` 과 비슷하다.

그래서 `pow2_scale(..., dim=0)` 이 마지막에 모양을 `(C,1,1,1)` 로 되돌린다:

```python
shape = [1] * x.dim()     # [1, 1, 1, 1]
shape[dim] = -1           # [-1, 1, 1, 1]   -1 = "나머지 알아서"
s = s.reshape(shape)
```

### 3.5 인덱싱과 불린 마스크

```python
x[0]              # 첫 번째
x[0:10]           # 0~9 (슬라이싱)
x[:, 5]           # 모든 N에 대해 채널 5만.  ':' = 전부
x[:, 5] = 0.0     # 그 자리에 대입도 된다

mask = x > 0                # 같은 모양의 True/False 배열
x[mask]                     # True 인 자리만 뽑아 1차원으로
x[~mask]                    # ~ 는 반전 (NOT)
(mask & other).sum()        # & 는 AND. True 개수를 센다
```

`eval_w.py` 에서 선배 마스크를 이렇게 쓴다:
```python
q[~mask] = quantize(w[~mask], E4M3)    # mask 가 False 인 원소만 E4M3 로
q[mask]  = quantize(w[mask],  E5M2)
```

### 3.6 `nn.Module` — 신경망의 부품

```python
class ConvBN(nn.Module):
    def __init__(self, c_in, c_out):
        super().__init__()                 # 부모 클래스 초기화. 반드시 먼저
        self.conv = nn.Conv2d(c_in, c_out, 3, padding=1, bias=False)
        self.bn = nn.BatchNorm2d(c_out)

    def forward(self, x):                  # 순전파. 데이터가 흐르는 경로
        return F.relu(self.bn(self.conv(x)))
```

`nn.Module` 을 상속하면 **파라미터를 자동으로 추적**해 준다.
`model(x)` 라고 쓰면 내부적으로 `forward(x)` 가 불린다.

Verilog로 치면 `nn.Module` = 모듈 정의, `self.conv = ...` = 하위 모듈 인스턴스화,
`forward` = 배선(wiring) 이다.

### 3.7 `state_dict` — 가중치 덤프

```python
sd = model.state_dict()     # {"prep.conv.weight": 텐서, "prep.bn.bias": 텐서, ...}
model.load_state_dict(sd, strict=True)
```

**이름 → 텐서** 딕셔너리다. `.pt` 파일에 저장되는 게 이것이다.
`strict=True` 면 이름이 하나라도 안 맞으면 에러 — `resnet9_senior.py` 는 이걸로
**구조 복원이 맞는지 검사**한다.

### 3.8 `@torch.no_grad()` — 학습이 아님을 알림

```python
@torch.no_grad()
def accuracy(model, x, y):
    ...
```

PyTorch는 기본적으로 역전파를 위해 모든 연산을 기록한다(메모리·시간 소모).
평가만 할 때는 이 데코레이터로 "기록하지 마"라고 알려 준다.

`model.eval()` 은 다른 것이다 — BatchNorm/Dropout을 **추론 모드**로 바꾼다
(저장된 통계를 쓴다). 둘 다 필요하다.

---

## 4. 파일별 해설 — 이 순서로 읽을 것

### 4.1 `fp8.py` ★ 가장 중요

#### 구조

```
1. 포맷 정의       FP8Format 구조체 + 상수 5개 (E4M3, E4M3_OUT, E5M2, E5M3, E5M7)
2. 양자화 본체     quantize(), quantize_stats()          ← 심장
3. 2^k 스케일      pow2_scale(), fake_quant()
4. 활성 캘리브레이션 ScaleCalibrator 클래스
5. 코드북          codebook()  — 검증용
6. 셀프테스트      _test_*()   — python fp8.py 로 실행되는 부분
```

#### ★ `quantize()` — 이 함수 하나만 이해하면 된다

"실수를 FP8 격자 위의 가장 가까운 값으로 옮긴다." 세 단계다.

```python
_, exponent = torch.frexp(x)        # (1) 지수 뽑기
e = exponent.to(torch.int32) - 1
e = torch.clamp(e, min=fmt.e_min)

step = torch.exp2((e - fmt.mant_bits).float())   # (2) 격자 간격
q = torch.round(x / step) * step                 #     반올림

q = torch.where(q.abs() < fmt.min_normal, 0, q)  # (3) 하드웨어 규칙
q = torch.clamp(q, -fmt.max_val, fmt.max_val)
```

**(1) 지수 뽑기.** `frexp` 는 `x = m × 2^exponent` (단 0.5 ≤ |m| < 1) 로 쪼갠다.
즉 `2^(exponent-1) ≤ |x| < 2^exponent` 이므로 우리가 쓰는 지수는 `exponent - 1` 이다.
`log2` 를 쓰지 않는 이유는 **부동소수 오차 없이 지수 비트를 직접 읽기** 때문이다.

`clamp(e, min=e_min)` 가 중요하다. subnormal 구간도 격자 간격은 `e_min` 구간과
같으므로, e 를 더 내려가지 못하게 막아야 `min_normal` 바로 밑의 값이 제대로
`min_normal` 로 올라간다. **§6.4의 14.00% vs 15.41% 차이를 만든 지점이 바로 이 한 줄이다.**

**(2) 반올림.** E4M3에서 `e=0` 이면 `step = 2^(0-3) = 0.125`. 그 구간의 격자 간격이다.
`x/step` 을 정수로 반올림하고 다시 `step` 을 곱하면 격자 위로 올라간다.
`torch.round` 는 **round half to even** 이라 하드웨어의 RNE와 정확히 같다
(`torch.round(0.5) = 0`, `torch.round(1.5) = 2`).

**(3) 하드웨어 규칙.** `min_normal` 미만은 0(subnormal flush), `max_val` 초과는 포화.
`torch.where(조건, A, B)` 는 원소별 3항 연산자 — Verilog의 `cond ? a : b` 가
배열 전체에 적용되는 것이다.

**돌려주는 값은 float32다.** 실제로 8비트로 담지 않는다. 값만 FP8 격자 위로 옮겨
"8비트로 담았다면 이 값이 된다"를 보장한다. 이걸 **fake quantization** 이라 하고,
양자화 실험의 표준 방식이다.

**직접 해 볼 것**:
```python
>>> from fp8 import E4M3, quantize
>>> import torch
>>> quantize(torch.tensor([0.1, 0.13, 500.0, 0.001]), E4M3)
```
각 값이 왜 그렇게 나오는지 손으로 따라가 보면 확실히 이해된다.

#### `pow2_scale()` — 창 맞추기

텐서를 포맷의 표현 범위 안에 넣기 위한 스케일 `s` 를 고른다. 쓰는 법은
`q = quantize(x / s, fmt)` 이고 복원은 `q * s` 다.

```python
k = torch.ceil(torch.log2(ref / fmt.max_val)) - shift
s = torch.exp2(k)
```

`ref` 는 "이 텐서에서 큰 쪽 대표값"(최대값 또는 99.9 퍼센타일)이다.
`ref / s ≤ max_val` 이 되는 가장 작은 2의 거듭제곱을 고른다.

**왜 2의 거듭제곱만 쓰는가**: 부동소수에서 2^k 곱셈은 지수 필드에 정수를 더하는
것뿐이라 **가수가 전혀 안 변한다**. 하드웨어에 `x/s` 를 넣고 결과에 `s` 를 도로
곱해도 비트가 안 깨진다. 셀프테스트 [4]가 이걸 검사한다:
```python
assert torch.equal((w / s) * s, w)     # 비트 단위로 완전히 같아야 한다
```

`assert 조건` 은 "조건이 거짓이면 에러를 내고 멈춰라"는 뜻이다.

**0 방어**가 들어 있다:
```python
ref = torch.where(torch.isfinite(ref) & (ref > 0), ref, torch.full_like(ref, fmt.max_val))
```
`ref=0` 이면 `log2(0) = -inf` → `s=0` → 0으로 나누기 → NaN 이 된다.
ReLU 뒤에는 전부 0인 채널이 흔하므로 반드시 필요하다.

#### `ScaleCalibrator` — 활성 스케일 고정하기

가중치는 고정값이라 스케일을 한 번 계산하면 끝이다. 그런데 **활성은 입력 이미지마다
달라진다.** 배치마다 스케일을 새로 잡으면 하드웨어에서 재현할 수 없다 — 실제 칩은
미리 정해진 고정 스케일로 돈다.

그래서 학습 데이터 일부로 미리 관찰해 값을 굳혀 둔다. 이게 **정적 양자화**다.

```python
cal = ScaleCalibrator(E4M3, mode="percentile", percentile=99.9)
for xb in calibration_batches(train_x):
    cal.observe(어떤_레이어의_활성)     # 여러 번 호출해 누적
s = cal.scale()                          # 확정. 이후 평가 내내 이 값 고정
```

`mode="max"` 는 지금까지 본 최대값을 갱신하고, `mode="percentile"` 은 배치마다
일부를 샘플로 모아 뒀다가 마지막에 분위수를 낸다.

#### 셀프테스트 (`python fp8.py`)

파일 맨 아래 이 관용구가 있다:
```python
if __name__ == "__main__":
    main()
```
"이 파일을 직접 실행할 때만 main()을 돌려라. 다른 파일이 import 할 때는 돌리지 마라."
Windows에서 특히 중요한 관용구다.

테스트 6개가 각각 무엇을 보는지는 §5 참고.

---

### 4.2 `resnet9_senior.py` — 모델 정의

선배 체크포인트에는 **숫자만** 있고 모델 코드가 없다. `state_dict` 의 `_metadata` 에
남은 모듈 계층으로 구조를 복원한 것이 이 파일이다.

```python
class ResNet9Senior(nn.Module):
    def __init__(self, num_classes=10, global_pool="max4"):
        super().__init__()
        self.register_buffer("data_mean", torch.zeros(1, 3, 1, 1))
        ...
        self.prep = ConvBN(3, 64)
        self.layer1_conv = ConvBN(64, 128, pool=True)
        ...
```

**`register_buffer`** 는 "학습되지 않지만 모델과 함께 저장/이동되는 텐서"를 등록한다.
여기서는 정규화 상수다. 파라미터(`nn.Parameter`)와 구분된다.

**`forward`** 가 데이터 흐름이다:
```python
def forward(self, x):
    x = (x - self.data_mean) / self.data_std   # 0~255 원본을 모델이 직접 정규화
    x = self.prep(x)
    x = self.layer1_res(self.layer1_conv(x))
    ...
```
**입력이 0~255 원본**이라는 점이 중요하다 — 그래서 `data.py` 에 로더가 두 개다.

**`global_pool` 판별**: 파라미터가 없는 모듈이라 체크포인트만으로는 종류를 알 수 없었다.
후보 3개를 다 돌려 정확도로 판별했고 `MaxPool2d(4)` 로 확정됐다 (93.88%).

**이 파일은 아직 수정하지 않았다.** BN fold와 학습셋 로더가 없어서 다음 단계에
확장이 필요하다.

---

### 4.3 `eval_w.py` — 실험 스크립트

"가중치만 FP8로 바꾸면 정확도가 얼마나 떨어지나"를 22가지 설정으로 잰다.

#### `_apply()` — 공통 뼈대

```python
def _apply(model, fn, include_classifier=True):
    m2 = copy.deepcopy(model)          # 모델을 통째로 복사
    with torch.no_grad():
        for name, mod in weight_modules(m2, include_classifier):
            w = mod.weight.data
            q = fn(name, w)            # fn 은 "어떻게 양자화할지" 함수
            mod.weight.data = q
    return m2, stats
```

**`copy.deepcopy`** 로 복사하는 이유: 원본을 건드리면 다음 설정을 잴 때 이미 망가져 있다.

**`fn` 이 함수 인자**라는 점이 핵심이다. 파이썬에서는 함수를 변수처럼 넘길 수 있다.
설정마다 다른 `fn` 을 넘겨서 같은 뼈대를 재사용한다.

```python
def eval_scaled(model, x, y, fmt, shift=0, per_channel=False, ...):
    def fn(name, w):                   # 함수 안에 함수를 정의 (클로저)
        s = pow2_scale(w, fmt, shift=shift, dim=dim)
        return quantize(w / s, fmt) * s
    m2, st = _apply(model, fn)         # 정의한 함수를 넘긴다
```

안쪽 `fn` 이 바깥의 `fmt`, `shift` 를 그대로 쓸 수 있는 것을 **클로저**라 한다.

**`with torch.no_grad():`** 는 블록 전체에 "미분 기록 끄기"를 적용한다.
`with` 는 "블록을 벗어나면 자동으로 정리"하는 구문이다 (C++의 RAII와 비슷).

#### `weight_modules()` — 모델을 훑어 conv/linear 찾기

```python
for name, m in model.named_modules():
    if isinstance(m, nn.Conv2d):
        out.append((name, m))
```
`named_modules()` 는 모델 안의 모든 하위 모듈을 (이름, 객체) 로 준다.
`isinstance(m, A)` 는 "m 이 A 타입인가".

---

### 4.4 `data.py` — 데이터 공급

**로더가 두 개인 이유가 핵심이다.**

| 함수 | 출력 | 쓰는 모델 |
|---|---|---|
| `load_cifar10_raw()` | **0~255 원본** | `resnet9_senior` (모델이 내부에서 정규화) |
| `load_cifar10()` | 0~1 정규화 | `resnet9.py` + `train.py` (미사용) |

**섞어 쓰면 입력 스케일이 255배 어긋나 결과가 무의미해진다.**

`calibration_batches()` 는 제너레이터(§2.9)다. **학습셋**에서 뽑는다 —
테스트셋으로 스케일을 정하면 평가 데이터를 미리 본 게 되어 결과를 믿을 수 없다.

`augment()` 는 학습용 데이터 증강(좌우반전 + 랜덤 크롭)인데, 지금은 안 쓴다.
고급 인덱싱을 쓴 부분이 어려우니 필요할 때 물어볼 것.

---

## 5. 셀프테스트가 무엇을 보장하는가

`python fp8.py` 로 도는 6개 테스트다. **이게 통과한다는 건 무슨 뜻인가**를 아는 게
테스트 코드 자체를 읽는 것보다 중요하다.

| # | 검사 | 통과하면 |
|---|---|---|
| 1 | 코드북 정합성 | `quantize` 결과가 **표현 가능한 값 집합 안에만** 있고, 항상 **최근접** 값이다 |
| 2 | 하드웨어 규칙 | subnormal flush, 480/448 포화, 경계값이 손으로 계산한 값과 일치 |
| 3 | torch 내장 FP8 교차검증 | 정규 구간 34만 개에서 **불일치 0개** → 반올림 로직이 표준과 동일 |
| 4 | 스케일 왕복 / 0 방어 | `(x/s)*s == x` 비트 동일, 0 텐서·0 채널에서 NaN 안 남 |
| 5 | 캘리브레이터 | max/percentile 모드 동작, percentile ≤ max |
| 6 | 선배 체크포인트 | flush 14.00% 재현 (§6.4 검증) |

**[3]이 가장 강력한 근거다.** torch가 내장한 FP8 구현과 34만 개에서 한 개도 안 틀렸다면,
반올림 로직에 실수가 있을 가능성은 사실상 없다.

---

## 6. 실행 흐름 — `python eval_w.py` 를 치면 무슨 일이 일어나나

```
1. import 문 실행
   → fp8.py, resnet9_senior.py 가 통째로 읽히고 그 안의 def/class 가 정의된다
   → 이때 E4M3 등 상수도 만들어진다

2. if __name__ == "__main__":  →  main() 호출

3. load_senior()
   → torch.load 로 33MB 읽기
   → ResNet9Senior 객체 생성 → load_state_dict(strict=True) 로 검사
   → .to("cuda") 로 GPU 이동, .eval() 로 추론 모드

4. load_cifar10_test_raw()
   → torchvision 이 ./data 에서 CIFAR-10 읽기 → GPU 로

5. accuracy(model, x, y)  →  FP32 베이스라인 93.88%

6. 설정 22개 반복:
   copy.deepcopy(model) → 가중치 양자화 → accuracy() → 표에 기록

7. 표 출력
```

**중요**: `import` 는 파일을 **처음부터 끝까지 실행**한다. 그래서 실행되면 안 되는
코드를 `if __name__ == "__main__":` 안에 넣는 것이다.

---

## 7. 자주 만날 에러와 뜻

| 에러 | 뜻 | 흔한 원인 |
|---|---|---|
| `ModuleNotFoundError` | import 할 파일/패키지가 없다 | venv 미활성화, 오타 |
| `AttributeError: 'X' object has no attribute 'y'` | 그 타입에 그런 메서드가 없다 | `numpy` 배열에 `.bool()` 을 부른 것이 실제 사례 |
| `RuntimeError: Expected all tensors on the same device` | CPU 텐서와 GPU 텐서를 섞었다 | `.to(device)` 누락 |
| `RuntimeError: shape mismatch` | 텐서 모양이 안 맞는다 | 브로드캐스팅 실패 |
| `CUDA out of memory` | GPU 메모리 부족 | 배치 크기를 줄일 것 |
| `IndentationError` | 들여쓰기가 틀렸다 | 탭/공백 혼용 |
| `assert` 실패 | 테스트가 깨졌다 | 코드 수정이 뭔가를 망가뜨림 |

에러 메시지는 **아래에서 위로** 읽는다. 맨 아래가 실제 에러, 그 위가 "어디서 불렸나"다.

---

## 8. 다음에 만들 코드 미리보기 — `quant_conv.py`

이해가 끝나면 만들 것이다. 개념만 미리 적어 둔다.

**왜 `F.conv2d` 를 못 쓰나**: cuDNN이 부분합을 내부에서 FP32로 누적해 버려서
중간에 개입할 수 없다. 부분합을 FP8로 자르려면 **직접 만들어야** 한다.

```python
x_unf = F.unfold(x, 3, padding=1).view(N, Cin, 9, L)      # 3x3 창을 펼친다
partial = torch.einsum('nckl,ock->nocl', x_unf, w.view(Cout, Cin, 9))
partial = quantize(partial / s, E4M3_OUT) * s              # ← 목적
out = partial.sum(dim=2)
```

**`unfold`** 는 슬라이딩 윈도우를 펼쳐 행렬곱으로 바꾸는 연산이다 (im2col).
**`einsum`** 은 아인슈타인 표기법으로 텐서 축을 곱하고 더한다 —
`'nckl,ock->nocl'` 은 "k 축(9항)에 대해 곱해서 더하고 나머지 축은 유지"라는 뜻이다.

**문제는 메모리다.** `partial` 이 `N × Cout × Cin × L` 이라
`layer3_res.conv1`(512×512×16)은 배치 32에서 **537MB**다. 그래서 청크로 끊는다:

```python
acc = 0
for ic0 in range(0, Cin, 64):          # 입력 채널을 64씩
    p = einsum(...)                     # (N, Cout, 64, L) 만 만든다
    acc = acc + (quantize(p / s, fmt) * s).sum(dim=2)
```

메모리가 `64/Cin` 배로 줄고 결과는 완전히 동일하다.

---

## 9. 다음 세션에서 물어보면 좋을 질문

### 반드시 짚을 것
1. `quantize()` 를 실제 숫자 몇 개로 손으로 따라가 주세요 (0.1, 500, 0.001 등)
2. `torch.frexp` 가 정확히 뭘 돌려주나요? `log2` 대신 쓰는 이유는?
3. `clamp(e, min=e_min)` 이 없으면 어떤 값이 어떻게 달라지나요?
4. 브로드캐스팅이 실제로 어떤 모양들 사이에서 일어나는지 예를 들어 주세요
5. `(x/s)*s == x` 가 왜 2의 거듭제곱에서만 성립하나요?

### 구조 이해
6. `_apply(model, fn)` 에서 함수를 인자로 넘기는 게 왜 편한가요? 클로저란?
7. `nn.Module` / `state_dict` / `register_buffer` 의 관계를 정리해 주세요
8. `model.eval()` 과 `torch.no_grad()` 는 뭐가 다른가요?
9. `import` 할 때 파일 전체가 실행된다는 게 무슨 뜻인가요?

### 직접 해보기
10. `fp8.py` 셀프테스트 중 하나를 일부러 깨뜨려서 어떤 에러가 나는지 보고 싶어요
11. `eval_w.py` 에 새 설정 한 줄(예: percentile 모드)을 추가하려면 어디를 고치나요?
12. 파이썬 대화형 셸(`python` 만 치고 들어가는 것)에서 텐서를 직접 만져 보고 싶어요

### 다음 단계 대비
13. `F.unfold` 와 `einsum` 을 작은 예제로 보여 주세요
14. BN fold 를 코드로 어떻게 구현하나요? (수식 → 코드)
15. `quant_conv.py` 를 같이 한 줄씩 만들어 보고 싶어요

---

## 10. 요약 — 딱 세 가지만 기억한다면

1. **`quantize()` 3단계**: 지수 뽑기(frexp) → 격자에 반올림(round) → 하드웨어 규칙(flush/포화)
2. **벡터화**: for문 대신 텐서 연산 한 줄. GPU를 병렬 회로처럼 쓰는 것
3. **fake quantization**: 8비트로 실제로 담지 않고 값만 FP8 격자 위로 옮긴다.
   float32로 계산하되 "8비트였다면 이 값"이 정확히 보장된다
