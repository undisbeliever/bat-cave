
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "controller.h"
.include "gameloop.h"

.setcpu "65816"

.code

.routine Main
	REP	#$30
	SEP	#$20
.A8
.I16
	REPEAT
		JSR	GameLoop::PlayGame
	FOREVER
.endroutine

; vim: set ft=asm:

