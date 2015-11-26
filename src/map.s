
.include "map.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "vram.h"
.include "resources/font.h"

.setcpu "65816"

.define CHUNK_WIDTH 8
SCREEN_HEIGHT = 224
TILE_HEIGHT = SCREEN_HEIGHT / 8

CAVE_COLOR = $114C

.segment "SHADOW"
	;; Address to load the tileBuffer to VRAM
	;; If 0 then don't upload the tiles
	updateTileBufferVram:	.res 2

	;; Word address to upload the mapBuffer into VRAM
	;; (word)
	chunkVramMapOffset:	.res 2

	;; The current xPos of the background
	;; (0:16:16 fixed point)
	xPos:		.res 4


.segment "WRAM7E"
	;; The y pos of the ceiling for each x position
	;; the last CHUNK_WIDTH entries are equal to the first CHUNK_WIDTH entries
	;; (word accessed)
	ceiling:	.res 2 * (256 + CHUNK_WIDTH * 2)

	;; The ypos of the floor for each x position
	;; the last CHUNK_WIDTH entries are equal to the first CHUNK_WIDTH entries
	;; Floor MUST always be > ceiling AND < SCREEN_HEIGHT
	;; (word accessed)
	floor:		.res 2 * (256 + CHUNK_WIDTH * 2)

	;; The current xVeclocity of the background
	;; (0:16:16 fixed point)
	xVelocity:	.res 4

	;; Index position (within ceiling/floor) of the current chunk to be generated
	;; (word index)
	chunkPos:	.res 2

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


	tmp1:			.res 2
	tmp2:			.res 2
	tmp3:			.res 2
	tmp4:			.res 2
	tmp5:			.res 2
	tmp6:			.res 2

.code


.module Map

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
	LDA	#0
	STZ	xVelocity
	STZ	xVelocity + 2
	STZ	xPos
	STZ	xPos + 2
	STZ	chunkPos
	STZ	updateTileBufferVram

	LDA	#$FFFF
	STA	chunkVramMapOffset
	STA	chunkVramTileOffset

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine GenerateChunk
tmp_color	:= tmp1
tmp_invertColor := tmp2
tmp_ceiling	:= tmp3
tmp_floor	:= tmp4
tmp_height	:= tmp5
tmp_tileBufferPos := tmp6

	LDX	chunkPos

	; Generate height/floor map
	LDY	#CHUNK_WIDTH
	REPEAT
		; ::TODO code::
		LDA	#25
		STA	ceiling, X
		LDA	#128
		STA	floor, X

		INX
		INX
		DEY
	UNTIL_ZERO

	; ::TODO mirror height/ceiling map for collision testing


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
	; Wrap chunk pos
	CPX	#(256 + CHUNK_WIDTH) * 2
	IF_GE
		STZ	chunkPos
	ENDIF


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

.endmodule

; vim: set ft=asm:

