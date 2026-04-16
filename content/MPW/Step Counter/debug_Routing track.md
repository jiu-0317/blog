
![[Pasted image 20260416140454.png]]

왜 라우팅이 잘 안될까?

일단 로그에서 가장 먼저 눈에 띄는건

![[Pasted image 20260416142429.png]]

setNanoRouteMode -routeTopRoutingLayer 를 3으로 설정하라고 한다. 

이렇게 했더니 

![[Pasted image 20260416142516.png]]

setDesignMode -topRoutingLayer 를 쓰라고 한다. 


![[Pasted image 20260416142613.png]]

![[Pasted image 20260416142819.png]]

![[Pasted image 20260416142556.png]]

![[routeDesign2.txt]]

그러니 이렇게 로그가 나온다. 
이전의 warning은 사라졌지만 

![[Pasted image 20260416143837.png]]

![[Pasted image 20260416143808.png]]

여전히 라우팅은 잘 되지 않았다.

로그를 뜯어보니

![[Pasted image 20260416144218.png]]

DRC violation이 있다. 

이게 무슨 violation인지 알아보니

![[Pasted image 20260416144325.png]]

![[Pasted image 20260416144450.png]]

![[Pasted image 20260416144459.png]]

이런 문제가 발생하는데, 왜 발생하는지 찾아보니까 로그에 이런 내용이 있다. 
```
#WARNING (NRAG-41) The M1 user tracks are removed and regenerated from M3.
# MET1         H   Track-Pitch = 2.4000    Line-2-Via Pitch = 2.2000
# MET2         V   Track-Pitch = 2.0000    Line-2-Via Pitch = 2.5000
#WARNING (NRAG-44) Track pitch is too small compared with line-2-via pitch.
# MET3         H   Track-Pitch = 2.4000    Line-2-Via Pitch = 2.6000
#WARNING (NRAG-44) Track pitch is too small compared with line-2-via pitch.
```
