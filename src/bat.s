
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

.include "controller.h"
.include "gameloop.h"
.include "map.h"


.setcpu "65816"

FRAME_DELAY = 8

.module Bat

.entitystruct	BatEntityStruct
	;; Current frame in the animation table
	;; (index)
	animationFrame		.word

	;; Animation delay
	animationDelay		.word
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

	STZ	z:BES::xVecl
	STZ	z:BES::xVecl + 2
	STZ	z:BES::yVecl
	STZ	z:BES::yVecl + 2

	STZ	z:BES::animationFrame

	LDA	#FRAME_DELAY - 1
	STA	z:BES::animationDelay


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
	LDA	Controller::current
	IF_BIT	#JOY_LEFT
		LDXY	#-$20000

	ELSE_BIT #JOY_RIGHT
		LDXY	#$20000

	ELSE
		LDXY	#0
	ENDIF
	STXY	BES::xVecl

	LDA	Controller::current
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


	; Animate the bat
	; Process the animation
	LDA	z:BES::animationDelay
	DEC
	IF_MINUS
		LDX	z:BES::animationFrame
		INX
		INX
		CPX	#AnimationFrameTable_size
		IF_GE
			LDX	#0
		ENDIF
		STX	z:BES::animationFrame

		LDA	#FRAME_DELAY - 1
	ENDIF
	STA	z:BES::animationDelay


	LDX	z:BES::animationFrame
	LDA	f:AnimationFrameTable, X

	LDY	z:BES::xVecl + 2
	IF_MINUS
		CLC
		ADC	#MetaSprites::Bat::Frames::FlyLeft0 - MetaSprites::Bat::Frames::FlyRight0
	ENDIF

	JSR	MetaSprite::SetFrame

	RTS
.endroutine


.segment "BANK1"

AnimationFrameTable:
	.word	MetaSprites::Bat::Frames::FlyRight0
	.word	MetaSprites::Bat::Frames::FlyRight4
	.word	MetaSprites::Bat::Frames::FlyRight3
	.word	MetaSprites::Bat::Frames::FlyRight1
	.word	MetaSprites::Bat::Frames::FlyRight2
	.word	MetaSprites::Bat::Frames::FlyRight2
	.word	MetaSprites::Bat::Frames::FlyRight1
	.word	MetaSprites::Bat::Frames::FlyRight3
	.word	MetaSprites::Bat::Frames::FlyRight4
	.word	MetaSprites::Bat::Frames::FlyRight0

AnimationFrameTable_size = * - AnimationFrameTable

.endmodule

; vim: set ft=asm:

