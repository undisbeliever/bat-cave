
.include "gameloop.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "common/incdec.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "controller.h"
.include "entity.h"
.include "map.h"
.include "random.h"
.include "vram.h"
.include "resources/font.h"

.import screenBrightness

.setcpu "65816"

.module GameLoop

.segment "SHADOW"
	state:		.res 2
	frameCounter:	.res 4
	scoreCursor:	.res 2

SCORE_XPOS = 20
SCORE_YPOS = 20

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


	LDA	#.lobyte(-SCORE_XPOS)
	STA	BG1HOFS
	LDA	#.hibyte(-SCORE_XPOS)
	STA	BG1HOFS

	LDA	#.lobyte(-SCORE_YPOS - 1)
	STA	BG1VOFS
	LDA	#.hibyte(-SCORE_YPOS - 1)
	STA	BG1VOFS


	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDA	#$0F
	STA	screenBrightness
.endmacro


; DB = $80
.A8
.I16
.routine PlayGame

	SetupScreen

	JSR	Console::Init

	LDA	#Font::GREEN
	JSR	Console::SetColor

	LDX	Console::cursor
	STX	scoreCursor

	PEA	$807E
	PLB			; $7E

	REP	#$30
.A16
	JSR	Map::Init
	JSR	Entity::Init

	STZ	frameCounter
	STZ	frameCounter + 2

	REPEAT
Continue:
	STZ	state
		REPEAT
			JSR	Controller::Update
			JSR	Random::AddJoypadEntropy

			; Print score
			LDX	scoreCursor
			STX	Console::cursor

			LDXY	frameCounter
			INCXY
			STXY	frameCounter

			SEP	#$20
.A8
			JSR	Console::PrintInt_U32XY

			REP	#$30
.A16

			JSR	Map::ProcessFrame
			JSR	Entity::ProcessFrame
			JSR	Entity::RenderFrame

			; Handle pausing the game
			LDA	Controller::pressed
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
	.addr	GameOver		; GAME_OVER
	.addr	Paused			; PAUSED
.endproc

.code


;; Pause the game until start is pressed
.A16
.I16
.routine Paused
	SEP	#$20
.A8
	JSR	Console::NewLine
	CPrintString	"PAUSED"

	REP	#$30
.A16

	; Loop until start pressed
	REPEAT
		WAI

		JSR	Controller::Update

		LDA	Controller::pressed
		AND	#JOY_START
	UNTIL_NOT_ZERO

	JSR	Console::Clear

	JMP	PlayGame::Continue
.endroutine


;; Show game over message
.A16
.I16
.routine GameOver
	SEP	#$20
.A8
	JSR	Console::NewLine
	CPrintString	"GAME OVER - PRESS START"

	REP	#$30
.A16

	; Loop until start pressed
	REPEAT
		WAI

		JSR	Controller::Update

		LDA	Controller::pressed
		AND	#JOY_START
	UNTIL_NOT_ZERO

	JMP	PlayGame::End
.endroutine

.endmodule

; vim: set ft=asm:

