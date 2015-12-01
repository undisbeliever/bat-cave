.ifndef ::_BAT_H_
::_BAT_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.include "bat.h"

.setcpu "65816"

.importmodule Bat
	.importlabel FunctionTable
.endimportmodule

.endif

; vim: ft=asm:

