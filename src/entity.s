
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

.include "map.h"

.setcpu "65816"

MetaSpriteDpOffset = EntityStruct::metasprite

FRAME_DELAY = 10

.module Entity


.segment "SHADOW"
	bat:	.res .sizeof(EntityStruct)


.code

.A8
.I16
.routine Init
	REP	#$30
.A16
	JSR	MetaSprite::Reset

	PHD

	LDA	#bat
	TCD

	LDA	#128
	STZ	z:EntityStruct::xPos
	STA	z:EntityStruct::xPos + 2

	LDA	#112
	STZ	z:EntityStruct::yPos
	STA	z:EntityStruct::yPos + 2


	LDA	#MetaSprites::Bat::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	LDA	#MetaSprites::Bat::Frames::FlyRight0
	JSR	MetaSprite::SetFrame

	JSR	MetaSprite::Activate

	PLD

	SEP	#$20
.A8
	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame
	PHD

	LDA	#.loword(bat)
	TCD

	; ::TODO check collisions::

	; ::TODO move entity::

	; ::TODO animate the bat::

	PLD
	.assert *= RenderFrame, error, "Bad Flow"
.endroutine

.A16
.I16
.routine RenderFrame
	PHD

	JSR	MetaSprite::RenderLoopInit

	LDA	#.loword(bat)
	TCD

	LDA	z:EntityStruct::xPos + 2
	SEC
	SBC	Map::xPos + 2
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	STA	MetaSprite::xPos

	LDA	z:EntityStruct::yPos + 2
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	STA	MetaSprite::yPos

	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	PLD
	RTS
.endroutine

.endmodule

; vim: set ft=asm:

