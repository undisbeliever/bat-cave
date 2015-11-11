
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"


; The Renderer assumes:
;	* The sprites are 8x8 and 16x16
;	* The screen size is 256x224
;
;
; The handling of the OAM hi-Table was inspired by psycopathicteen[1].
;
; The MetaSprite block*CharAttrOffset variales are designed to allow the
; MetaSprite VRAM allocator to allocate and deallocate 2 VRAM Rows/Tiles
; without worrying about fragmentation.
;
; [1] http://forums.nesdev.com/viewtopic.php?p=92234#p92234

.module MetaSprite

.segment METASPRITE_FRAME_DATA_BLOCK
	frameDataOffset = .bankbyte(*) << 16

.segment METASPRITE_FRAME_OBJECTS_BLOCK
	fobjDataOffset	= .bankbyte(*) << 16


.exportlabel xPos
.exportlabel yPos
.exportlabel updateBufferOnZero
.exportlabel oamBuffer, far
.assert oamHiBuffer = oamBuffer + 128 * 4, error, "Bad Alignment"


FRAME_CHARATTR_SIZEBIT	= $0100
FRAME_CHARATTR_BLOCKBIT	= $0020
FRAME_CHARATTR_MASK	= $F01F

; ::DEBUG::
; ::TODO make it entity::metaSpriteState in the future::
.export MetaSpriteDpOffset = 0
.define MSDP MetaSpriteDpOffset + MetaSpriteStruct



.segment "SHADOW"
	updateBufferOnZero:	.res 1

.segment "WRAM7E"
	oamBuffer:		.res 128 * 4
	oamHiBuffer:		.res 128 / 4

	;; Buffer the oam's x8/size bits
	;; bits 11-15 of each 4 byte block MUST BE CLEAR
	xposBuffer:		.res 128 * 4

	; Only hald of xPosBuffer is acutally used, save the bytes for variables
	bufferPos	:= xposBuffer + 0*4 + 2

	xPos		:= xposBuffer + 1*4 + 2
	yPos		:= xposBuffer + 2*4 + 2

	tmp1		:= xposBuffer + 3*4 + 2


.code


; DB = $7E
.I16
.routine Init

	; Reset the xPosBuffer - prevent possible bugs
	LDX	#127 * 4
	REPEAT
		STZ	xposBuffer + OamFormat::xPos + 1, X
		DEX
		DEX
		DEX
		DEX
	UNTIL_MINUS

	RTS
.endroutine


; DB = $7E
.A16
.routine RenderLoopInit
	SEP	#$20
.A8
	; Prevent VBlank from copying a bad sprite state
	LDA	#$FF
	STA	updateBufferOnZero
	REP	#$20
.A16

	STZ	bufferPos

	RTS
.endroutine


; INPUT:
; A: MetaSprite__State address
; xPos: sprite.xPos - POSITION_OFFSET
; yPos: sprite.yPos - POSITION_OFFSET
; DB = $7E
.A16
.I16
.routine RenderFrame_A
	; Faster to do this then to store the three
	; required variables to tmp.

	PHD
	SEC
	SBC	#MetaSpriteDpOffset
	TCD

	JSR	RenderFrame

	PLD
::Return:
	RTS
.endroutine


; INPUT:
; DP: MetaSprite__State address - MetaSpriteDpOffset
; xPos: sprite.xPos - POSITION_OFFSET
; yPos: sprite.yPos - POSITION_OFFSET
; DB = $7E
.A16
.I16
.routine RenderFrame
.define MSF_OBJECT f:fobjDataOffset + MetaSprite__FrameObjectsList::Objects
nObjectsLeft := tmp1

	LDX	z:MSDP::currentFrame
	LDA	f:frameDataOffset + MetaSprite__Frame::frameObjectsList, X
	BEQ	Return
	TAX

	LDA	f:fobjDataOffset + MetaSprite__FrameObjectsList::count, X
	AND	#$001F
	BEQ	Return
	STA	nObjectsLeft

	; Do a single buffer overflow check here instead of muliple ones in the loop
	ASL
	ASL
	; carry clear
	ADC	bufferPos
	CMP	#128 * 4 + 1
	BGE	Return

	INX
	LDY	bufferPos
	REPEAT
		LDA	MSF_OBJECT::char, X
		IF_NOT_BIT	#FRAME_CHARATTR_SIZEBIT
			; Small
			CLC
			IF_BIT	#FRAME_CHARATTR_BLOCKBIT
				AND	#FRAME_CHARATTR_MASK
				; carry clear
				ADC	z:MSDP::blockTwoCharAttrOffset
			ELSE
				AND	#FRAME_CHARATTR_MASK
				; carry clear
				ADC	z:MSDP::blockOneCharAttrOffset
			ENDIF
			STA	oamBuffer + OamFormat::char, Y

			LDA	MSF_OBJECT::xOffset, X
			AND	#$00FF
			CLC
			ADC	xPos

			; don't render is xpos <= -8 || xpos >= 256
			CMP	#.loword(-7)
			IF_LT
				CMP	#256
				BGE	Continue
			ENDIF

			AND	#$01FF
		ELSE
			; Large
			CLC
			IF_BIT	#FRAME_CHARATTR_BLOCKBIT
				AND	#FRAME_CHARATTR_MASK
				; carry clear
				ADC	z:MSDP::blockTwoCharAttrOffset
			ELSE
				AND	#FRAME_CHARATTR_MASK
				; carry clear
				ADC	z:MSDP::blockOneCharAttrOffset
			ENDIF
			STA	oamBuffer + OamFormat::char, Y

			LDA	MSF_OBJECT::xOffset, X
			AND	#$00FF
			CLC
			ADC	xPos

			; don't render is xpos <= -16 || xpos >= 256
			CMP	#.loword(-15)
			IF_LT
				CMP	#256
				BGE	Continue
			ENDIF

			AND	#$01FF
			ORA	#$0200
		ENDIF
		STA	oamBuffer + OamFormat::xPos, Y
		STA	xposBuffer, Y


		LDA	MSF_OBJECT::yOffset, X
		AND	#$00FF
		CLC
		ADC	yPos

		; don't render is ypos <= -15 || ypos >= 224
		CMP	#.loword(-15)
		IF_LT
			CMP	#224
			BGE	Continue
		ENDIF

		SEP	#$20
.A8
		STA	oamBuffer + OamFormat::yPos, Y

		.repeat	.sizeof(OamFormat)
			INY
		.endrepeat

Continue:
		.repeat	.sizeof(MetaSprite__FrameObjectsList::Objects)
			INX
		.endrepeat

		DEC	nObjectsLeft
		REP	#$30
.A16
	UNTIL_ZERO

	STY	bufferPos

	RTS
.endroutine


.A16
.I16
.routine RenderLoopEnd
	; Convert xposBuffer into oamHiBuffer

	LDA	bufferPos
	BEQ	SkipHiTable

	DEC
	AND	#$FFF0
	TAX
	LSR
	LSR
	LSR
	LSR
	TAY

	REPEAT
		SEP	#$20
.A8
		LDA	xposBuffer + 3 * .sizeof(OamFormat) + 1, X
		ASL
		ASL
		ORA	xposBuffer + 2 * .sizeof(OamFormat) + 1, X
		ASL
		ASL
		ORA	xposBuffer + 1 * .sizeof(OamFormat) + 1, X
		ASL
		ASL
		ORA	xposBuffer + 0 * .sizeof(OamFormat) + 1, X
		STA	oamHiBuffer, Y

		REP	#$31
.A16
		TXA
		; carry clear
		SBC	#4 * .sizeof(OamFormat) - 1
		TAX

		DEY
	UNTIL_MINUS


SkipHiTable:

	; Move all other sprites offscreen

	SEP	#$20
.A8
	LDA	#224
	LDX	bufferPos
	CPX	#128 * .sizeof(OamFormat)
	IF_LT
		REPEAT
			STA	oamBuffer + OamFormat::yPos, X
			INX
			INX
			INX
			INX
			CPX	#128 * .sizeof(OamFormat)
		UNTIL_GE
	ENDIF

	STZ	updateBufferOnZero

	REP	#$30
.A16
	RTS
.endroutine

.endmodule

