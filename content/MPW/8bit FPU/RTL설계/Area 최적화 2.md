
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

