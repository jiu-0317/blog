
innovus에서 바로 sdf 추출이 안돼서 spef로 추출하고 tempus에서 sdf로 변환한 뒤에 xcelium으로 기능테스트를 진행할 예정이다.  

레퍼런스 가이드를 찾아보니 write_sdf 라는 커맨드가 있다.  
일단 디자인을 import하고 실행해봐야겠다.  

![[Pasted image 20260605173333.png|318]]

필요한 파일들을 import 해준다.  
```tcl
read_lib /home/virtuoso2/genus/rf_reuse/lib/mychips_scl_0.0.1_tt_5.50v.lib
read_verilog /home/virtuoso2/genus/rf_reuse/outputs/net_top.v
set_top_module TOP
read_sdc /home/virtuoso2/genus/rf_reuse/outputs/top.sdc

```

spef는 아직 없어서 다음에 이어서 작성한다.  

레퍼런스가이드에 나오는 write_sdf이다.  

![[Pasted image 20260605173449.png]]

**By default, the write_sdf command uses the delays already cached by the system**  
이라는데 이건 update_timing 을 실행하면 Tempus가 모든 셀/넷의 딜레이를 계산해서 메모리에 저장(cache) 하는데, write_sdf는 이렇게 계산된 딜레이 값을 저장한다는거다.  
즉, write_sdf 전에 update_timing 이 선행되어야한다.  

그리고 **writes only values of the triplets** 이라는데  
기본적으로 **현재 분석 view에 해당하는 값만** triplet에 채운다는 뜻이다. 
지금은 tt(typical)만 넣었으니 (min:typ:max) 에서 typ만 채워진다. 

![[Pasted image 20260605174358.png]]

