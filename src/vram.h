; resources

.ifndef ::_VRAM_H_
::_VRAM_H_ := 1


.scope VRAM
	BG1_MAP   = $0000
	BG1_TILES = $1000
	BG1_SIZE  = BGXSC_SIZE_32X32

	OAM_TILES = $6000
	OAM_SIZE  = OBSEL_SIZE_8_16
	OAM_NAME  = 0

	SCREEN_MODE = 0
.endscope


.endif

; vim: set ft=asm:

