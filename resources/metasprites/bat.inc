
.scope Bat

.segment METASPRITE_TILESET_BLOCK_0
N_TILES = 9
Tiles:
	; Convert to tile16 format
	.repeat 8, i
		.incbin "bat.4bpp", i * 64, 64
		.incbin "bat.4bpp", (8 + i) * 64, 64
	.endrepeat
	.repeat (N_TILES - 8), i
		.incbin "bat.4bpp", (16 + i) * 64, 64
		.incbin "bat.4bpp", (24 + i) * 64, 64
	.endrepeat


.segment METASPRITE_DMA_TABLE_BLOCK
DmaTable0:
	.byte 8 * 2 - 2
	.repeat 8, i
		.faraddr	Tiles + 128 * i
	.endrepeat

DmaTable1:
	.byte (N_TILES - 8) * 2 - 2
	.repeat (N_TILES - 8), i
		.faraddr	Tiles + 128 * (8 + i)
	.endrepeat



.segment METASPRITE_TILESET_BLOCK
Tileset:
	.byte	MetaSprite__Tileset_Type::TWO_VRAM_ROWS ; type
	.byte	N_TILES		; nTiles
	.addr	DmaTable0
	.addr	DmaTable1



.segment METASPRITE_PALETTE_DATA_BLOCK
Palette:
	.incbin "bat.clr", 2, 30


.segment METASPRITE_PALETTE_LIST_BLOCK
N_PALETTES = 1
PaletteList:
	.addr	Palette



.segment METASPRITE_FRAME_OBJECTS_BLOCK
.scope FO
Rest:
	.byte 2
		Object  -8,	-12,	$00, 1, large
		Object  -4,	 4,	$0e, 1, small

FlyRight0:
	.byte 4
		Object -17,	-20,	$02, 2, large
		Object  -9,	 -4,	$0f, 2, small
		Object  -1,	 -6,	$1e, 2, small
		Object -25,	-20,	$1f, 2, small

FlyRight1:
	.byte 2
		Object  -9,	 -6,	$04, 2, large
		Object  -17,	  2,	$20, 2, small

FlyRight2:
	.byte 2
		Object  -9,	 -7,	$06, 2, large
		Object  -9,	  9,	$08, 2, large

FlyRight3:
	.byte 2
		Object  -9,	-10,	$0a, 2, large
		Object -17,	 -5,	$21, 2, small

FlyRight4:
	.byte 3
		Object  -9,	-15,	$0c, 2, large
		Object  -9,	  1,	$30, 2, small
		Object -17,	-14,	$31, 2, small


FlyLeft0:
	.byte 4
		Object   1,	-20,	$02, 2, large, hFlip
		Object   1,	 -4,	$0f, 2, small, hFlip
		Object  -7,	 -6,	$1e, 2, small, hFlip
		Object  17,	-20,	$1f, 2, small, hFlip

FlyLeft1:
	.byte 2
		Object  -7,	 -6,	$04, 2, large, hFlip
		Object   9,	  2,	$20, 2, small, hFlip

FlyLeft2:
	.byte 2
		Object  -7,	 -7,	$06, 2, large, hFlip
		Object  -7,	  9,	$08, 2, large, hFlip

FlyLeft3:
	.byte 2
		Object  -7,	-10,	$0a, 2, large, hFlip
		Object   9,	 -5,	$21, 2, small, hFlip

FlyLeft4:
	.byte 3
		Object  -7,	-15,	$0c, 2, large, hFlip
		Object   1,	  1,	$30, 2, small, hFlip
		Object   9,	-14,	$31, 2, small, hFlip
.endscope



.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
.scope THB
Rest:
	TileHitbox	-5,	-10,	10,	18

Fly:
	TileHitbox	-6,	-5,	12,	7
.endscope



.segment METASPRITE_FRAME_DATA_BLOCK
N_FRAMES = 11
FrameData:
	.addr	FO::Rest,      0, THB::Rest, 0, Tileset
	.addr	FO::FlyRight0, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyRight1, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyRight2, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyRight3, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyRight4, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyLeft0, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyLeft1, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyLeft2, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyLeft3, 0, THB::Fly,  0, Tileset
	.addr	FO::FlyLeft4, 0, THB::Fly,  0, Tileset


.segment METASPRITE_FRAME_LIST_BLOCK
FrameList:
.repeat N_FRAMES, i
	.addr	FrameData + 10 * i
.endrepeat



.segment METASPRITE_FRAMESET_DATA_BLOCK
FrameSet:
	.addr	Tileset		; tilesetList
	.byte	0		; tilesetLifestyle (Fixed)
	.addr	PaletteList	; paletteList
	.byte	N_PALETTES	; nPalettes
	.addr	FrameList	; frameList
	.byte	N_FRAMES	; nFrames
	.addr	0		; animationList
	.byte	0		; nAnimations


.segment METASPRITE_FRAMESET_LIST_BLOCK
    .addr	FrameSet

.endscope

; vim: set ft=asm:

