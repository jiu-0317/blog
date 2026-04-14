
자 핀을 연결하니 다음과 같은 문제가 발생한다. 

```
innovus 5> globalNetConnect VDD -type pgpin -pin VDD -all
innovus 6> globalNetConnect VSS -type pgpin -pin VSS -all
innovus 7> checkDesign -netlist -physicalLibrary -timingLibrary -powerGround -outDir RPT
Creating directory RPT.
############################################################################
# Innovus Netlist Design Rule Check
# Tue Apr 14 18:21:05 2026
############################################################################
Design: saturation_step_counter

------ Design Summary:
Total Standard Cell Number   (cells) : 180
Total Block Cell Number      (cells) : 0
Total I/O Pad Cell Number    (cells) : 0
Total Standard Cell Area     ( um^2) : 66261.17
Total Block Cell Area        ( um^2) : 0.00
Total I/O Pad Cell Area      ( um^2) : 0.00

------ Design Statistics:

Number of Instances            : 180
Number of Non-uniquified Insts : 180
Number of Nets                 : 192
Average number of Pins per Net : 2.78
Maximum number of Pins in Net  : 11

------ I/O Port summary

Number of Primary I/O Ports    : 18
Number of Input Ports          : 10
Number of Output Ports         : 8
Number of Bidirectional Ports  : 0
Number of Power/Ground Ports   : 0
Number of Floating Ports                     *: 0
Number of Ports Connected to Multiple Pads   *: 0
Number of Ports Connected to Core Instances   : 18
**WARN: (IMPREPO-202):  There are 18 Ports connected to core instances.

------ Design Rule Checking:

Number of Output Pins connect to Power/Ground *: 0
Number of Insts with Input Pins tied together ?: 0
Number of TieHi/Lo term nets not connected to instance's PG terms ?: 0
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'state_reg[1]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'state_reg[0]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[7]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[6]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[5]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[4]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[3]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[2]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[1]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPDB-2136):   Input term 'SET' of  instance 'sum_reg[0]' does not connect to a 'TieLo ' net. The netlist is not correct or the net for connecting tie high/low signals is not specified. To resolve this problem, check your netlist or run globalNetConnect to specify the tie high/low signal nets.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[0] connected to net sum[0] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[0] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[0] connected to net n_166 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[0] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[1] connected to net sum[1] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[1] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[1] connected to net n_170 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[1] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[2] connected to net sum[2] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[2] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[2] connected to net n_172 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[2] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[3] connected to net sum[3] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[3] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[3] connected to net n_168 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[3] connected to net reset but this pin has no shape.
**WARN: (IMPREPO-513):  Pin Q of inst sum_reg[4] connected to net sum[4] but this pin has no shape.
**WARN: (IMPREPO-513):  Pin CLK of inst sum_reg[4] connected to net clk but this pin has no shape.
**WARN: (IMPREPO-513):  Pin D of inst sum_reg[4] connected to net n_167 but this pin has no shape.
**WARN: (IMPREPO-513):  Pin RST of inst sum_reg[4] connected to net reset but this pin has no shape.
**WARN: (EMS-27):       Message (IMPREPO-513) has exceeded the current message display limit of 20.
To increase the message display limit, refer to the product command reference manual.
Number of Input/InOut Floating Pins            : 10
Number of Output Floating Pins                 : 0
Number of Output Term Marked TieHi/Lo         *: 0

**WARN: (IMPREPO-218):  There are 10 Floating Instance terminals.
**WARN: (IMPREPO-514):  There are 508 pin connect with net but term has no shape.
Number of nets with tri-state drivers          : 0
Number of nets with parallel drivers           : 0
Number of nets with multiple drivers           : 0
Number of nets with no driver (No FanIn)       : 0
Number of Output Floating nets (No FanOut)     : 0
Number of High Fanout nets (>50)               : 0
Design check done.
Report saved in file RPT/saturation_step_counter.main.htm.ascii

*** Summary of all messages that are not suppressed in this session:
Severity  ID               Count  Summary
WARNING   IMPDB-2136          10  %s term '%s' of %s instance '%s' does no...
WARNING   IMPREPO-513        508  Pin %s of inst %s connected to net %s bu...
WARNING   IMPREPO-514          1  There are %d pin connect with net but te...
WARNING   IMPREPO-202          1  There are %d Ports connected to core ins...
WARNING   IMPREPO-218          1  There are %d Floating Instance terminals...
*** Message Summary: 521 warning(s), 0 error(s)

0

```

