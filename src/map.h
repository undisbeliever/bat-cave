.ifndef ::_MAP_H_
::_MAP_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.importmodule Map

	;; Sets up the sreen
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers, force blank, no interrupts
	.importroutine SetupScreen

	;; Initializes the background module
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine Init


	;; Loads the next chunk to VRAM
	;;
	;; REQUIRES: 16 bit A, 8 bit Index, DB access registers, DP = $4300, VBlank or Force Blank
	.importroutine VBlank

.endimportmodule

.endif

; vim: ft=asm:

