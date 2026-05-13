
만들어둔 셀을 사용하기 위해서는 Characterization이 필요하다. 
이걸 Liberate로 할 수 있다. 

.scs와 .sp가 필요하다. 

먼저 DRC와 LVS가 마무리되면, Assura-Quantus로 spice 추출을 한다.

![[Pasted image 20260507183000.png]]

![[Pasted image 20260507184915.png]]

simulator lang=spectre
include "05cmos_model_241213.scs" section=mos
simulator lang=spice


![[Pasted image 20260507222222.png]]

