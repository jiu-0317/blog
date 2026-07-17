
$p(y = c \mid \boldsymbol{x}) = \frac{p(y = c,\, \boldsymbol{x})}{p(\boldsymbol{x})} = \frac{p(\boldsymbol{x} \mid y = c)\, p(y = c)}{p(\boldsymbol{x})}$

**수학 모드 감싸기**  
`\[ ... \]`는 디스플레이(별행) 수학 모드입니다. 수식을 한 줄 가운데에 크게 띄워서 보여줍니다.

**분수** — `\frac{분자}{분모}`

**볼드 기호** — `\boldsymbol{x}`

**조건부 막대 — `\mid`**  
조건부 확률의 세로 막대 `|` 입니다. 그냥 `|`를 써도 막대는 나오지만 양옆 간격이 좁습니다.

**얇은 공백 — `\,`**  
가장 좁은 수동 간격입니다.

$\hat{c} = \operatorname* {argmax}_{c'} P(y = c' \mid x)$

**모자 기호** — `\hat{c}`

**argmax와 아래첨자 위치 — `\operatorname*{argmax}_{c'}`**  
핵심 포인트입니다. argmax는 함수 이름이라 정자체로 나와야 하므로 `\operatorname{}`으로 감쌉니다. 여기서 별표 `*`가 중요한데, `\operatorname*`로 쓰면 디스플레이 모드에서 아래첨자 `_{c'}`가 글자 **바로 아래**로 내려갑니다(이미지처럼). 별표 없이 `\operatorname{argmax}_{c'}`로 쓰면 `c'`가 오른쪽 옆에 작게 붙습니다.

**프라임** — `c'`

`\mathrm{}` — 로만체(정자체)

`\sum_{k}` — 합 기호와 첨자

**`\left( \right)` — 자동 크기 조절 괄호**  
그냥 `(`와 `)`는 항상 고정된 작은 크기입니다. 그래서 안에 분수나 큰 시그마가 들어가면 괄호가 내용물보다 작아서 어색해집니다. `\left(` 와 `\right)`로 감싸면 LaTeX가 **내용물 높이에 맞춰 괄호 크기를 자동으로 키웁니다.**

$\log p(D \mid \theta) = \sum_{i=1}^{N} \log p(x_i \mid \theta)$

`\log` — 로그 함수입니다. LaTeX 내장 함수라서 정자체로 나오고 뒤에 적절한 간격이 자동으로 붙습니다.

`\theta` — 그리스 문자 세타 θ\theta θ입니다. 파라미터를 나타낼 때 자주 쓰죠. 대문자 Θ는 `\Theta`

`\sum_{i=1}^{N}` — 합 기호입니다. 아래첨자 `_{i=1}`은 시작값, 위첨자 `^{N}`은 끝값

`x_i` — xx x의 아래첨자 ii i입니다. ii i가 한 글자라 중괄호 없이 `x_i`로 충분합니다. 만약 두 글자 이상이면 `x_{ij}`처럼 묶어야 합니다.

\epsilon

**`\cdot` — 가운뎃점 (가장 많이 씀)**a⋅ba \cdot b a⋅b 처럼 가운데 점으로 곱을 나타냅니다. 수식에서 변수끼리의 곱을 명시할 때 가장 흔하게 쓰입니다. 앞서 ReLU 수식의 `w[k] \cdot i[k]`에서 쓴 게 이겁니다.

**`\times` — 곱셈 엑스 기호**a×ba \times b a×b 처럼 ✕ 모양입니다. 숫자 곱셈(2×32 \times 3 2×3), 행렬·벡터 크기 표기(3×33 \times 3 3×3 행렬), 외적(cross product)에 씁니다.

**`\prod` — 총곱 (시그마의 곱 버전)**∏i=1Nxi\prod_{i=1}^{N} x_i ∏i=1N​xi​ 처럼 여러 항을 모두 곱할 때 씁니다. `\sum`과 사용법이 완전히 똑같고, 앞서 본 로그 가능도 식의 원래 형태 ∏i=1Np(xi∣θ)\prod_{i=1}^{N} p(x_i \mid \theta) ∏i=1N​p(xi​∣θ)가 바로 이겁니다.

비례 기호는 `\propto`

$\kappa(\mathbf{x}, \mathbf{x}') = \tanh(\gamma \mathbf{x}^T \mathbf{x}' + r)$

\gamma

$\mathbb{R}^n$
\mathbb --> 집합기호/차원 나타내는 기호

$\nabla$
\nabla

$\mu$
\mu

$\geq$
\geq

$\leq$
\leq

$\neq$
\neq

$\xi$
\xi 크사이


