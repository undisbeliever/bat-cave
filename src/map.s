
.include "map.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "entity.h"
.include "random.h"
.include "vram.h"
.include "resources/font.h"

.setcpu "65816"


.module Map


.define CHUNK_WIDTH 8

.define PADDING_WIDTH 32
.assert 256 .mod PADDING_WIDTH = 0, error, "Bad PADDING_WIDTH"
.assert PADDING_WIDTH > 8, error, "Bad PADDING_WIDTH"

SCREEN_HEIGHT = 224
TILE_HEIGHT = SCREEN_HEIGHT / 8

;; Inital X velocity
;; (0:16:16)
X_VELOCITY_INIT = $09C00

CAVE_COLOR = $114C

MAP_INITIAL_CEILING_VELOCITY    = $0000
MAP_INITIAL_HEIGHT		= $8000
MAP_INITIAL_CEILING_POSITION    = ((SCREEN_HEIGHT << 8) - MAP_INITIAL_HEIGHT) / 2

MAP_MAX_HEIGHT			= $8000
MAP_MIN_HEIGHT			= $1C00
MAP_STEEP_HEIGHT_CHECK		= $2800
MAP_STEEP_HEIGHT_INCREMENT	= $0040

MAP_RESET_MIN_HEIGHT		= $2000
MAP_RESET_MAX_HEIGHT		= $4000

MAP_HEIGHT_MAX_INCREMENT	= $0020
MAP_HEIGHT_MAX_DECREMENT	= $0030

MAP_VERTICAL_PADDING		= $07C0
MAP_CEILING_MAX_ACCELERATION	= $0080
MAP_CEILING_MAX_VECL		= $0280
MAP_CEILING_STEEP_VECL		= $01C0


MAP_CEILING_MIN_SECTION		= 4
MAP_CEILING_MAX_SECTION		= 30


.enum State
	INIT			= 0
	SCROLLING		= 2
	SCROLL_AFTER_RENDER	= 4
.endenum


.segment "SHADOW"
	;; Address to load the tileBuffer to VRAM
	;; If 0 then don't upload the tiles
	updateTileBufferVram:	.res 2

	;; Word address to upload the mapBuffer into VRAM
	;; (word)
	chunkVramMapOffset:	.res 2

	;; The current xPos of the background
	;; (0:16:16 fixed point)
	xPos:			.res 4


.segment "WRAM7E"
	;; The game state
	state:			.res 2

	;; The current xVeclocity of the background
	;; abs(xVelocity) MUST <= 8, and SHOULD BE <= 4.0
	;; (0:16:16 fixed point)
	xVelocity:		.res 4

	;; The offset between the xPos and the floor/ceiling tables
	;; (uint16)
	xOffset:		.res 2

	;; The location to draw the next chunk in
	nextXposDrawChunk:	.res 2

	;; The y pos of the ceiling for each x position
	;; (word accessed)
	ceiling:		.res 2 * (256 + PADDING_WIDTH)

	;; The ypos of the floor for each x position
	;; Floor MUST always be > ceiling AND < SCREEN_HEIGHT
	;; (word accessed)
	floor:			.res 2 * (256 + PADDING_WIDTH)

	;; Index position (within ceiling/floor) of the current chunk to be generated
	;; (word index)
	chunkPos:		.res 2

	;; The index of the VRAM word addres tiles to upload
	;; (word index)
	chunkVramTileOffset:	.res 2

	;; The tile buffer chunk that is to be uploaded to VRAM
	;; (1bpp tile data)
	tileBuffer:		.res CHUNK_WIDTH / 8 * SCREEN_HEIGHT
tileBuffer_size = * - tileBuffer

	;; The map buffer to load into VRAM
	mapBuffer:		.res 2 * CHUNK_WIDTH / 8 * SCREEN_HEIGHT / 8
mapBuffer_size = * - mapBuffer


	;; Generate patterns of the map
	.proc generate
		;; Velocity (up/down) of map when generating it
		;; (1:7:8 fint)
		ceilingVelocity:	.res 2

		;; Position of the Velocity (up/down) of map when generating it
		;; (1:7:8 fint)
		ceilingPosition:	.res 2

		;; Number of pixels left until the current velocity update
		velocityLength:		.res 2


		;; the minimum value of ceilingPosition
		;; (8:8 fint)
		ceilingMinLimit:	.res 2

		;; the maximum value of ceilingPosition
		;; (8:8 fint)
		ceilingMaxLimit:	.res 2


		;; Height of the map section
		;; (8:8 fint)
		currentHeight:		.res 2
	.endproc


	tmp1:			.res 2
	tmp2:			.res 2
	tmp3:			.res 2
	tmp4:			.res 2
	tmp5:			.res 2
	tmp6:			.res 2


	.exportlabel xPos

.code


; DB = $80
; Force blank, no interrupts
.A8
.I16
.routine SetupScreen
	; Reset VRAM
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	REP	#$30
.A16
	LDA	#VRAM::BackgroundMap
	STA	VMADD

	LDA	#32 * 32 * 2
	REPEAT
		STZ	VMDATA
		DEC
	UNTIL_ZERO

	LDA	#VRAM::BackgroundTiles
	STA	VMADD

	LDA	#(33) * TILE_HEIGHT * 8
	REPEAT
		STZ	VMDATA
		DEC
	UNTIL_ZERO


	SEP	#$20
.A8

	; Set Color of cave
	LDA	#4 * 8 + 1
	STA	CGADD

	LDA	#.lobyte(CAVE_COLOR)
	STA	CGDATA
	LDA	#.hibyte(CAVE_COLOR)
	STA	CGDATA

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine Init
	STZ	state

	STZ	xPos
	STZ	xPos + 2
	STZ	chunkPos
	STZ	updateTileBufferVram

	LDA	#.loword(X_VELOCITY_INIT)
	STA	xVelocity
	LDA	#.hiword(X_VELOCITY_INIT)
	STA	xVelocity + 2


	LDA	#MAP_INITIAL_CEILING_VELOCITY
	STA	generate::ceilingVelocity
	LDA	#MAP_INITIAL_CEILING_POSITION
	STA	generate::ceilingPosition

	LDA	#MAP_INITIAL_HEIGHT
	STA	generate::currentHeight

	LDA	#MAP_VERTICAL_PADDING
	STA	generate::ceilingMinLimit
	LDA	#(SCREEN_HEIGHT << 8) - MAP_VERTICAL_PADDING - MAP_INITIAL_HEIGHT
	STA	generate::ceilingMaxLimit

	LDA	#280
	STA	generate::velocityLength


	; Build initial map
	STZ	chunkPos

	.repeat	256 / PADDING_WIDTH + 1
		JSR	GenerateMap
	.endrepeat

	STZ	chunkPos
	STZ	xOffset



	LDA	#$FFFF
	STA	chunkVramMapOffset
	STA	chunkVramTileOffset

	RTS
.endroutine



; DB = $7E
.A16
.I16
.routine CheckEntityCollision
tmp_mapIndex	:= tmp1
tmp_width	:= tmp2
tmp_top		:= tmp3
tmp_bottom	:= tmp4

	LDX	z:EntityStruct::metasprite + MetaSpriteStruct::currentFrame
	LDA	f:MS_FrameOffset + MetaSprite__Frame::tileCollisionHitbox, X
	BEQ	NoCollision
	TAX


	LDA	f:MS_TileCollisionOffset + MetaSprite__TileCollisionHitbox::xOffset, X
	AND	#$00FF
	CLC
	ADC	z:EntityStruct::xPos + 2
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	SEC
	SBC	xOffset
	BMI	NoCollision

	ASL
	STA	tmp_mapIndex


	LDA	f:MS_TileCollisionOffset + MetaSprite__TileCollisionHitbox::width, X
	AND	#$00FF
	STA	tmp_width
	TAY
	ASL
	; C Clear
	ADC	tmp_mapIndex
	CMP	#2 * (256 + PADDING_WIDTH)
	BGE	Collision



	LDA	f:MS_TileCollisionOffset + MetaSprite__TileCollisionHitbox::yOffset, X
	AND	#$00FF
	CLC
	ADC	z:EntityStruct::yPos + 2
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	BMI	Collision
	STA	tmp_top


	LDA	f:MS_TileCollisionOffset + MetaSprite__TileCollisionHitbox::height, X
	AND	#$00FF
	CLC
	ADC	tmp_top
	STA	tmp_bottom


	; Y = tmp_width
	LDX	tmp_mapIndex
	LDA	tmp_top
	REPEAT
		CMP	ceiling, X
		BLT	Collision

		DEY
	UNTIL_ZERO


	LDX	tmp_mapIndex
	LDY	tmp_width
	LDA	tmp_bottom
	REPEAT
		CMP	floor, X
		BGE	Collision

		DEY
	UNTIL_ZERO

NoCollision:
	CLC
	RTS

Collision:
	SEC
	RTS
.endroutine



; DB = $7E
.A16
.I16
.routine ProcessFrame
	LDX	state
	JMP	(.loword(ProcessFrameStateTable), X)
.endroutine

.rodata
.proc ProcessFrameStateTable
	.addr	ProcessFrame_Init
	.addr	ProcessFrame_Scrolling
	.addr	ProcessFrame_AfterRender
.endproc

.code


; DB = $7E
.A16
.I16
.routine ProcessFrame_Init
	JSR	RenderChunk

	LDA	chunkPos
	CMP	#256 * 2 + 2
	IF_GE
		LDA	#8
		STA	nextXposDrawChunk

		LDX	#State::SCROLLING
		STX	state
	ENDIF

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame_AfterRender
	; Executed on the frame after a RenderChunk call
	;
	; This is to prevent lag by preventing a GenerateMap routine
	; and a RenderChunk routine from executing in the same frame.

	LDA	chunkPos
	CMP	#(256 + PADDING_WIDTH) * 2
	IF_GE
		JSR	GenerateMap
	ENDIF

	LDX	#State::SCROLLING
	STX	state

	.assert *= ProcessFrame_Scrolling, error, "Bad Flow"
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame_Scrolling
	CLC
	LDA	xPos
	ADC	xVelocity
	STA	xPos

	LDA	xPos + 2
	ADC	xVelocity + 2
	STA	xPos + 2

	CMP	nextXposDrawChunk
	IF_GE
		JSR	RenderChunk

		LDA	nextXposDrawChunk
		CLC
		ADC	#CHUNK_WIDTH
		STA	nextXposDrawChunk

		LDX	#State::SCROLL_AFTER_RENDER
		STX	state
	ENDIF

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine GenerateMap
	; Shift map PADDING_WIDTH pixels to the left
	LDX	#.loword(ceiling + 2 * PADDING_WIDTH)
	LDY	#.loword(ceiling)
	LDA	#256 * 2 - 1
	MVN	$7E, $7E

	LDX	#.loword(floor + 2 * PADDING_WIDTH)
	LDY	#.loword(floor)
	LDA	#256 * 2 - 1
	MVN	$7E, $7E


	; Move map pointers
	LDA	chunkPos
	SEC
	SBC	#PADDING_WIDTH * 2
	STA	chunkPos

	LDA	xOffset
	CLC
	ADC	#PADDING_WIDTH
	STA	xOffset


	; Generate new segment
	LDX	#256 * 2

	; Generate height/floor map
	LDY	#PADDING_WIDTH
	REPEAT
		; Add random noise to ceiling
		LDA     Random::seed + 1
		AND     #$01FF
		SBC     #$0100
		CLC
		ADC     generate::ceilingPosition

		CLC
		ADC	generate::ceilingVelocity

		CMP	generate::ceilingMinLimit
		IF_LT
			LDA	generate::ceilingVelocity
			NEG
			STA	generate::ceilingVelocity

			LDA	generate::ceilingMinLimit
		ELSE
			CMP	generate::ceilingMaxLimit
			IF_GE
				LDA	generate::ceilingVelocity
				NEG
				STA	generate::ceilingVelocity

				LDA	generate::ceilingMaxLimit
			ENDIF
		ENDIF

		STA	generate::ceilingPosition

		SEP	#$20
.A8
		XBA
		STA	ceiling, X

		CLC
		ADC	generate::currentHeight + 1
		STA	floor, X

		REP	#$30
.A16

		INX
		INX

		; Randomize values
		; ----------------

		PHX
		PHY

		DEC	generate::velocityLength
		IF_MINUS
			LDA	#MAP_CEILING_MAX_ACCELERATION * 2
			JSR	Random::Rnd_U16A
			SEC
			SBC	#MAP_CEILING_MAX_ACCELERATION

			CLC
			ADC	generate::ceilingVelocity

			CMP	#.loword(-MAP_CEILING_MAX_VECL)
			IF_LT
				CMP	#MAP_CEILING_MAX_VECL
				IF_GE
					LDA	#0
				ENDIF
			ENDIF
			STA	generate::ceilingVelocity


			LDA	#MAP_CEILING_MAX_SECTION - MAP_CEILING_MIN_SECTION
			JSR	Random::Rnd_U16A
			ADC	#MAP_CEILING_MIN_SECTION
			STA	generate::velocityLength
		ENDIF


		; Update (change height)
		LDA	#MAP_HEIGHT_MAX_DECREMENT + MAP_HEIGHT_MAX_INCREMENT
		JSR	Random::Rnd_U16A
		SEC
		SBC	#MAP_HEIGHT_MAX_DECREMENT

		CLC
		ADC	generate::currentHeight

		CMP	#MAP_MAX_HEIGHT
		IF_GE
			LDA	#MAP_MAX_HEIGHT
		ELSE
			CMP	#MAP_MIN_HEIGHT
			IF_LT
				; Randomize reset height
				LDA	#MAP_RESET_MAX_HEIGHT - MAP_RESET_MIN_HEIGHT
				JSR	Random::Rnd_U16A
				CLC
				ADC	#MAP_RESET_MIN_HEIGHT
			ENDIF
		ENDIF
		STA	generate::currentHeight


		; Increase min height if ceiling velocity is step
		LDA	generate::ceilingVelocity
		IF_MINUS
			NEG
		ENDIF
		CMP	#MAP_CEILING_STEEP_VECL
		IF_GE
			LDA	generate::currentHeight
			CMP	#MAP_STEEP_HEIGHT_CHECK
			IF_LT
				CLC
				ADC	#MAP_STEEP_HEIGHT_INCREMENT
				STA	generate::currentHeight
			ENDIF
		ENDIF


		; Recalculate limit

		LDA	#(SCREEN_HEIGHT << 8) - MAP_VERTICAL_PADDING
		SEC
		SBC	generate::currentHeight
		STA	generate::ceilingMaxLimit

		PLY
		PLX

		DEY
	UNTIL_ZERO

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine RenderChunk
tmp_color	:= tmp1
tmp_invertColor := tmp2
tmp_ceiling	:= tmp3
tmp_floor	:= tmp4
tmp_height	:= tmp5
tmp_tileBufferPos := tmp6

	STZ	tmp_tileBufferPos

	; Draw Tiles
	SEP	#$20
.A8
	; Start at leftmost color
	LDA	#$80
	STA	tmp_color

	REPEAT
		; Set mask for the middle section
		LDA	tmp_color
		EOR	#$FF
		STA	tmp_invertColor

		; Get lengths of the 3 sections
		LDX	chunkPos
		LDA	ceiling, X
		STA	tmp_ceiling

		LDA	#SCREEN_HEIGHT
		SEC
		SBC	floor, X
		STA	tmp_floor

		LDA	floor, X
		SEC
		SBC	ceiling, X
		STA	tmp_height



		LDX	tmp_tileBufferPos

		; Set color for top
		LDY	tmp_ceiling
		IF_NOT_ZERO
			REPEAT
				LDA	tileBuffer, X
				ORA	tmp_color
				STA	tileBuffer, X

				INX
				DEY
			UNTIL_ZERO
		ENDIF


		; Remove color center
		LDY	tmp_height
		EOR	#$FF
		REPEAT
			LDA	tileBuffer, X
			AND	tmp_invertColor
			STA	tileBuffer, X

			INX
			DEY
		UNTIL_ZERO


		; Set color for bottom
		LDY	tmp_floor
		IF_NOT_ZERO
			REPEAT
				LDA	tileBuffer, X
				ORA	tmp_color
				STA	tileBuffer, X

				INX
				DEY
			UNTIL_ZERO
		ENDIF

		LDX	chunkPos
		INX
		INX
		STX	chunkPos

		LSR	tmp_color
	UNTIL_C_SET

	REP	#$31
.A16

	LDA	tmp_tileBufferPos
	; C clear
	ADC	#TILE_HEIGHT * 8
	STA	tmp_tileBufferPos

	CMP	#tileBuffer_size


	LDA	chunkVramTileOffset
	CMP	#(256 + CHUNK_WIDTH) / 8 * (TILE_HEIGHT * 8)
	IF_GE
		LDA	#0
	ELSE
		; C clear
		ADC	#CHUNK_WIDTH / 8 * (TILE_HEIGHT * 8)
	ENDIF
	STA	chunkVramTileOffset


	; Build map
	LSR
	LSR
	LSR

	LDX	#0
	LDY	#TILE_HEIGHT
	REPEAT
		STA	mapBuffer, X
		INC

		INX
		INX

		DEY
	UNTIL_ZERO


	; Update map offset
	LDA	chunkVramMapOffset
	CMP	#VRAM::BackgroundMap + 32 * 32 + 31
	IF_GE
		; Overflow check
		LDA	#VRAM::BackgroundMap - 1
	ENDIF

	INC
	CMP	#VRAM::BackgroundMap + 32
	IF_EQ
		CLC
		ADC	#32 * 32 - 32
	ENDIF
	STA	chunkVramMapOffset


	LDA	chunkVramTileOffset
	CLC
	ADC	#VRAM::BackgroundTiles
	STA	updateTileBufferVram

	RTS
.endroutine



; DP = $4300
; DB = access registers
.A16
.I8
.routine VBlank

; ::MAYDO make macro::
	; Upload a chunk of tiles
	LDA	updateTileBufferVram
	IF_NOT_ZERO
		STA	a:VMADD
		STZ	updateTileBufferVram

		LDX	#VMAIN_INCREMENT_LOW | VMAIN_INCREMENT_1
		STX	a:VMAIN

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(VMDATAL) << 8)
		STA	z:<DMAP0	; also sets BBAD0

		LDA	#.loword(tileBuffer)
		STA	z:<A1T0
		LDX	#.bankbyte(tileBuffer)
		STX	z:<A1B0

		LDA	#tileBuffer_size
		STA	z:<DAS0

		LDX	#MDMAEN_DMA0
		STX	MDMAEN


		; Upload Map
		LDX	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_32
		STX	a:VMAIN

		LDA	chunkVramMapOffset
		STA	a:VMADD

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
		STA	z:<DMAP0	; also sets BBAD0

		LDA	#.loword(mapBuffer)
		STA	z:<A1T0
		LDX	#.bankbyte(mapBuffer)
		STX	z:<A1B0

		LDA	#32 * 2
		STA	z:<DAS0

		LDX	#MDMAEN_DMA0
		STX	MDMAEN
	ENDIF

	; ::TODO upload map

	LDX	xPos + 2
	STX	VRAM::BackgroundHOFS
	LDX	xPos + 3
	STX	VRAM::BackgroundHOFS

	LDX	#$FF
	STX	VRAM::BackgroundVOFS
	STX	VRAM::BackgroundVOFS

	RTS
.endroutine


.segment METASPRITE_FRAME_DATA_BLOCK
MS_FrameOffset = .bankbyte(*) << 16

.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
MS_TileCollisionOffset = .bankbyte(*) << 16

.endmodule

; vim: set ft=asm:

