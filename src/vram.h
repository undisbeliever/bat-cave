; resources

.ifndef ::_VRAM_H_
::_VRAM_H_ := 1


.scope VRAM
	BG1_MAP		= $0000
	BG1_TILES	= $1000
	BG1_SIZE	= BGXSC_SIZE_32X32

	BG2_MAP		= $0400
	BG2_TILES	= $2000
	BG2_SIZE	= BGXSC_SIZE_64X32

	OAM_TILES	= $6000
	OAM_SIZE	= OBSEL_SIZE_8_16
	OAM_NAME	= 0

	SCREEN_MODE	= 0

	BackgroundMap   = BG2_MAP
	BackgroundTiles	= BG2_TILES
	BackgroundHOFS	= BG2HOFS
	BackgroundVOFS	= BG2VOFS
.endscope


.endif

; vim: set ft=asm:

