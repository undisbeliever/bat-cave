
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

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

		REPEAT
			WAI

			LDA	JOY1H
			AND	#JOYH_START
		UNTIL_NOT_ZERO
	FOREVER
.endroutine

; vim: set ft=asm:

