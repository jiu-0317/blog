
현재 FPU를 포함한 전체 RTL 설계가 완료되었다.  
Cell Area는 다음과 같다:

![[Pasted image 20260526222652.png]]

![[Pasted image 20260526222719.png]]

너무너무 크다.  
설계를 최적화하는 정도가 아니라 잘라내야한다.  

RF부분이 역시 가장 크다.  

칩 크기가 1000x1000인데 Area가 160만이 나와버린다.  
거의 60만을 잘라내야한다.  
거기다 PnR하면 면적이 달라지니 더 넉넉하게 면적을 확보해야한다.  

적용할 수 있는 방법은 다음과 같다:  
1. RF에 latch 사용  
2. RF 재사용  
3. 예외처리 로직 제거

1번부터 시도해볼 예정이다. 

# 1. RF에 latch 사용

가장 큰 RF 부분의 면적을 줄이기 위해 RF에서 사용되는 DFF대신 latch를 사용하도록 코드를 수정하였다. 

```verilog
always @(i_clk) begin
    /*if (!i_rstn) begin
        w_all_set     <= 9'd0;
        i_all_set     <= 9'd0;
    end else */
    if (i_clear_valid) begin
        i_all_set <= 9'd0;
    end else if (i_w_wen) begin 
    . . .
```

이렇게 sensitive list에 posedge를 없애고 rst도 없앴다.  
이때 sensitive list에 edge trigger와 level trigger가 함께 들어가니 에러가 나서 rst는 삭제했다.  

이렇게 W_I_RF와 FPU_RF를 바꾸고 tb를 돌리니까 제대로 값이 나왔고, 다시 합성해보니 다음과 같이 면적이 나왔다.  

![[Pasted image 20260528144617.png]]

Cell이 약 500개가 줄었다.  

사용할 수 있는 칩의 면적이 1000x1000 으로 1,000,000n 인데, Cell 면적만 1,000,000n이 넘으니까 거의 30~40만을 줄여야할 것 같다.  

# 2. RF 재사용

FPU_RF를 없애고 FPU의 연산 결과를 W_I_RF의 input RF에 덮어 씌우도록 만들 것이다.  

재사용 전:  

![[Pasted image 20260528232047.png]]

재사용 후:  

![[Pasted image 20260528232126.png]]

더 늘었다.  
MUX 가 늘어났다.  

이때 latch를 사용하면서 negedge와 posedge 에서 각각 FPU의 연산 결과가 저장되는 문제가 있었는데 (2번째 결과는 쓰레기) fpu_written flag를 추가해서 해결했다.  

문제를 파악하기 위해 schematic을 보니  

![[Pasted image 20260528173450.png]]

이렇게 

![[Pasted image 20260528175628.png]]

![[Pasted image 20260528175852.png]]


1961

# 3. TCL
TCL에 옵션을 더 주니까 면적이 좀 줄었다. 

![[Pasted image 20260529183526.png]]

오른쪽이 수정한 버전이다. 


![[Pasted image 20260529185333.png]]

이건 level trigger logic 바꾼건데 면적이 더 늘었다.  



---

# 6. LUT 재사용

LUT에서 axb와 bxa를 같은 값으로 처리했더이 각 9개의 LUT의 크기가 거의 반토막이 나서 크기가 많이 줄었다. 

![[Pasted image 20260601115014.png]]


# 7. FPU 특수값 처리 묶기

inf와 nan을 묶어서 처리했다.  
그러니까 92만에서 90만으로 줄었다.

이전에 ACC 정확도 높이면서 87만에서 92만으로 면적이 늘었었다.

![[Pasted image 20260602225718.png]]

FPU 쪽에서는 안묶여있어서 이것도 묶으니까 이렇게 줄었다.

![[Pasted image 20260603000132.png]]

# 8. FPU 1개만 사용하기

최후의 수단으로 FPU를 1개만 넣어보았다. 
그러니까 면적이 많이 줄기는 하는데 기대만큼 줄지는 않았다. 

![[Pasted image 20260603182206.png]]

FPU 3개를 하니까 이렇게 나온다.  
fpu selec하는 로직이 크다.

![[Pasted image 20260603184320.png]]


이건 fpu셀렉을 상수로 고정해둔건데 역시 MUX가 많이 줄었다.

![[Pasted image 20260603185738.png]]


# 9. FPU 3개 사용하기

1개만 사용하는건 원래 목적이 너무 희석되니 절충안으로 3개의 FPU를 사용하기로 했다.  
합성 결과 면적은 이렇게 나왔다.  

![[Pasted image 20260604004350.png]]

이게 SPI CDC 문제 해결한 것 까지 적용해서 나온 면적이다.  
SPI 적용 안하면 75만정도 나온다.  

이제 좀 여유가 있으니까 이전에 제거했던 예외처리 로직을 살릴까 생각중이다.  

![[Pasted image 20260604011258.png]]

이게 예외처리로직 살린건데.. 크다
그냥 빼야겠다.  

saturation 관련 로직 수정하니까 소폭 늘었다.

![[Pasted image 20260604013039.png]]

이건 곱셈기버전이다. 다 동일한데 LUT 만 안 쓰는거

![[Pasted image 20260604142804.png]]

![[Pasted image 20260604182510.png]]

