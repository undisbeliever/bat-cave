
.include "gameloop.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "entity.h"
.include "map.h"
.include "vram.h"
.include "resources/font.h"

.setcpu "65816"

.module GameLoop

.segment "SHADOW"
	state:		.res 2


.exportlabel state

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


	LDA	#TM_BG1 | TM_BG2 | TM_OBJ
	STA	TM

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDA	#$0F
	STA	INIDISP
.endmacro


; DB = $80
.A8
.I16
.routine PlayGame

	SetupScreen

	PEA	$807E
	PLB			; $7E

	REP	#$30
.A16
	JSR	Map::Init
	JSR	Entity::Init

	REPEAT
Continue:
	STZ	state
		REPEAT
			JSR	Map::ProcessFrame
			JSR	Entity::ProcessFrame
			JSR	Entity::RenderFrame

			; Handle pausing the game
			LDA	f:JOY1
			ORA	f:JOY2
			IF_BIT	#JOY_START
				LDX	#GameState::PAUSED
				STX	state
			ENDIF

			WAI
			LDX	state
			.assert GameState::PLAYING = 0, error, "Bad Code"
		UNTIL_NOT_ZERO

		JMP	(.loword(GameStateTable), X)
	FOREVER

End:

	PLB			; $80
	SEP	#$20
.A8
	RTS
.endroutine


;; These functions are called when the game state changes
;; They will jump to either `PlayGame::Continue` or `PlayGame::End` upon completion.
;; 
.rodata
.proc GameStateTable
	.addr	PlayGame::Continue	; PLAYING
	.addr	PlayGame::End		; GAME_OVER
	.addr	Paused			; PAUSED
.endproc


;; Pause the game until start is pressed
.A16
.I16
.routine Paused
	; Wait for start to be released
	REPEAT
		LDA	f:JOY1
		ORA	f:JOY2
		AND	#JOY_START
	UNTIL_ZERO


	; Loop until start pressed
	REPEAT
		WAI

		LDA	f:JOY1
		ORA	f:JOY2
		AND	#JOY_START
	UNTIL_NOT_ZERO

	; Wait for start to be released
	REPEAT
		LDA	f:JOY1
		ORA	f:JOY2
		AND	#JOY_START
	UNTIL_ZERO

	JMP	PlayGame::Continue
.endroutine

.endmodule

; vim: set ft=asm:

