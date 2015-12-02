
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

.include "gameloop.h"
.include "map.h"


.setcpu "65816"

FRAME_DELAY = 10

.module Bat

.entitystruct	BatEntityStruct
.endentitystruct

.define BES BatEntityStruct

AUTOSCROLL_FORCE_PADDING = 12

.rodata

.exportlabel FunctionTable
.proc FunctionTable
	.addr	Init
	.addr	ProcessFrame
.endproc


.code

; DP = bat
.A16
.I16
.routine Init
	REP	#$30
.A16

	LDA	#200
	STZ	z:BES::xPos
	STA	z:BES::xPos + 2

	LDA	#112
	STZ	z:BES::yPos
	STA	z:BES::yPos + 2

	LDA	#MetaSprites::Bat::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	LDA	#MetaSprites::Bat::Frames::FlyRight0
	JSR	MetaSprite::SetFrame

	JSR	MetaSprite::Activate

	RTS
.endroutine


; DP = bat
; DB = $7E
.A16
.I16
.routine ProcessFrame
	; ::DEBUG move bat with joypad::
	; ::TODO do properly::
	LDA	f:JOY1
	IF_BIT	#JOY_LEFT
		LDXY	#-$20000

	ELSE_BIT #JOY_RIGHT
		LDXY	#$20000

	ELSE
		LDXY	#0
	ENDIF
	STXY	BES::xVecl

	LDA	f:JOY1
	IF_BIT	#JOY_UP
		LDXY	#-$C000

	ELSE_BIT #JOY_DOWN
		LDXY	#$C000
	ELSE
		LDXY	#0
	ENDIF
	STXY	BES::yVecl


	; Move entity
	CLC
	LDA	z:BES::xVecl
	ADC	z:BES::xPos
	STA	z:BES::xPos
	LDA	z:BES::xVecl + 2
	ADC	z:BES::xPos + 2
	STA	z:BES::xPos + 2

	CLC
	LDA	z:BES::yVecl
	ADC	z:BES::yPos
	STA	z:BES::yPos
	LDA	z:BES::yVecl + 2
	ADC	z:BES::yPos + 2
	STA	z:BES::yPos + 2


	; Force the bat onscreen
	LDA	Map::xPos + 2
	CLC
	ADC	#AUTOSCROLL_FORCE_PADDING
	CMP	z:BES::xPos + 2
	IF_GE
		STA	z:BES::xPos + 2
	ENDIF

	LDA	Map::xPos + 2
	CLC
	ADC	#256 - AUTOSCROLL_FORCE_PADDING
	CMP	z:BES::xPos + 2
	IF_LT
		STA	z:BES::xPos + 2
	ENDIF


	; Check for collisions
	JSR	Map::CheckEntityCollision
	IF_C_SET
		LDX	#GameState::GAME_OVER
		STX	GameLoop::state
	ENDIF

	; ::TODO animate the bat::

	RTS
.endroutine

.endmodule

; vim: set ft=asm:

