
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

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
	; ::TODO move entity::


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

	; ::TODO collision testing::


	; ::TODO animate the bat::

	RTS
.endroutine

.endmodule

; vim: set ft=asm:

