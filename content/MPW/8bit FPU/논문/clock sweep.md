
FPU_LUT를 clock을 sweep해서 20MHz 부터 100MHz 까지 Area와 WNS의 변화를 관찰했다. 

![[Pasted image 20260618233141.png]]

그 결과 90M 까지는 slack이 넉넉해서 clk freq가 증가할 수록 wns가 선형적으로 감소한다. 
그러나 100M 에서는 slack이 충분하지 않기 때문에 툴이 critical path를 빠르게 하기 위해서 면적도 늘어나고 그 결과 slack도 늘어난다. 

![[Pasted image 20260618233701.png]]

그러면 100M 이후로 clk이 높아질 수록 면적이 증가하는, 원하는 모습을 볼 수 있으니 20M부터 500M 까지 sweep 해봤다. 

면적 곡선  
![[Pasted image 20260619001719.png]]

wns 곡선  
![[Pasted image 20260619001734.png]]

base와 lut 결과 비교

![[Pasted image 20260619001755.png]]

![[Pasted image 20260619001808.png]]

100M 부터 230M 까지 좀 더 촘촘하게 