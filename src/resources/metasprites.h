; resources

.ifndef ::_RESOURCES__METASPRITES_H_
::_RESOURCES__METASPRITES_H_ := 1

.import MetaSprite__FrameSet_Data

.scope MetaSprites
	.scope Bat
		frameSetId = 0
		nFrames	= 11

		.enum Frames
			Rest
			FlyRight0
			FlyRight1
			FlyRight2
			FlyRight3
			FlyRight4
			FlyLeft0
			FlyLeft1
			FlyLeft2
			FlyLeft3
			FlyLeft4
		.endenum
	.endscope
.endscope

.endif

; vim: set ft=asm:

