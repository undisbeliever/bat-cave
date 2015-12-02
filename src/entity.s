
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

.include "bat.h"
.include "map.h"

.setcpu "65816"

MetaSpriteDpOffset = EntityStruct::metasprite

.module Entity

.segment "SHADOW"
	bat:	.res ENTITY_STRUCT_SIZE


.code

.A16
.I16
.routine Init
	JSR	MetaSprite::Reset

	PHD

	LDA	#bat
	TCD

	LDX	#.loword(Bat::FunctionTable)
	STX	z:EntityStruct::functionPtr

	JSR	(EntityFunctions::Init, X)

	JSR	MetaSprite::Activate

	PLD

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame
	PHD

	LDA	#.loword(bat)
	TCD

	LDX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::ProcessFrame, X)

	PLD
	RTS
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

