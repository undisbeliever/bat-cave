
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "vram.h"
.include "map.h"
.include "resources/font.h"

.setcpu "65816"

.code

.macro SetupScreen
	.assert .asize = 8, error, "Bad .asize"
	.assert .isize = 16, error, "Bad .isize"

	STZ	NMITIMEN

	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#VRAM::SCREEN_MODE
	STA	BGMODE

	SetVramBaseAndSize VRAM

	; Load tiles and palettes
	LDX	#VRAM::BG1_TILES
	STX	VMADD

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#.bankbyte(Font::Tiles)
	STA	A1B0

	LDX	#.loword(Font::Tiles)
	STX	A1T0

	LDX	#Font::Tiles_size
	STX	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN


	; Load palette
	STZ	CGADD

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_WRITE_TWICE | (.lobyte(CGDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#.bankbyte(Font::Palettes)
	STA	A1B0

	LDX	#.loword(Font::Palettes)
	STX	A1T0

	LDX	#Font::Palettes_size
	STX	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN


	JSR	Map::SetupScreen


	LDA	#TM_BG1 | TM_BG2
	STA	TM

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDA	#$0F
	STA	INIDISP
.endmacro


.routine Main
	REP	#$30
	SEP	#$20
.A8
.I16
	SetupScreen

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
	JSR	Map::Init

	REPEAT
		; ::TODO move to Map::Process ::
.import Map__GenerateChunk
		JSR	Map__GenerateChunk

		WAI
	FOREVER
.endroutine


; vim: set ft=asm:

