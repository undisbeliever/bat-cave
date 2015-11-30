.ifndef ::_ENTITY_H_
::_ENTITY_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.setcpu "65816"

.struct EntityStruct
	;; Entity position
	;; (0:16:16 fixed point)
	xPos		.res 4
	yPos		.res 4

	;; Entity Velocity
	;; (0:16:16 fixed point)
	xVecl		.res 4
	yVecl		.res 4

	metasprite	.tag MetaSpriteStruct

	animationDelay	.res 1
	animationFrame	.res 1
.endstruct


.importmodule Entity

	;; Initialize the entity module
	;; REQUIRES: 8 bit A, 16 bit Index
	.importroutine Init

	;; Processes a single frame of the gameloop
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	.importroutine ProcessFrame


	;; Renders the entities to the screen
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	.importroutine RenderFrame

.endimportmodule

.endif

; vim: ft=asm:

