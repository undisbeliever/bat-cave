
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

		REPEAT
			WAI

			REP	#$30
.A16
			JSR	Controller::Update

			SEP	#$20
.A8

			LDA	Controller::current + 1
			AND	#JOYH_START
		UNTIL_NOT_ZERO
	FOREVER
.endroutine

; vim: set ft=asm:

