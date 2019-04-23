; *** callbacks.asm
; Implementations of map callbacks. They are used mostly to hijack the process
; of map loading, so things like map roofs, connections and sprite sets can
; function correctly.

; If this flag is set, HandleRoofGraphics will always copy tiles directly to
; VRAM, regardless of PPU mode.

sRoofGraphicsDirectCopy:
    db 0
    
; Handler for MAPCALLBACK_SPRITES.
; Enables player input, applies the DMA hijacking routine, makes sure all map
; headers are loaded into RAM, executes the map initialization script, loads
; proper roof and Missingno. corruption graphics.

CallbackSpritesProc:
    ld a, [wMapGroup]
    cp $91
    jr z, .ok
    call RestoreMapGroupDMA
    ld hl, $416f ; RefreshSprites.Refresh
    ld a, b_RefreshSprites
    rst $08
.ok
    call StopAutoInput
    call ApplyDMAHijacking
    call CopyMapSubheaderEntriesToRAM
    call ExecuteMapInitScript
    jp HandleRoofGraphics
    
; Handler for MAPCALLBACK_OBJECTS.
; Performs all the actions from MAPCALLBACK_SPRITES, but it also loads the
; correct sprite set along the way (also disables map callbacks during the
; process, to avoid an infinite loop).

CallbackObjectsProc:
    ld a, [rLCDC]
    and $80
    jr z, .lcdOff
    ld hl, wCurMapCallbackCount
    ld a, [hl]
    ld [hl], 0
    push af
    farcall RefreshSprites
    pop af
    ld [wCurMapCallbackCount], a
.lcdOff
    jr CallbackSpritesProc

; Handler for MAPCALLBACK_TILES.
; Loads roof graphics and makes sure to properly load adjacent map connections
; (otherwise they would get corrupted after battles)

CallbackTilesProc:
    call HandleRoofGraphics
    ld hl, wOverworldMapBlocks
	ld bc, wOverworldMapBlocksEnd - wOverworldMapBlocks
	xor a
	call ByteFill
    prepare_sram_call 3, ChangeMap
    call CallInSRAMBank
    prepare_sram_call 3, FillMapConnections
    jp CallInSRAMBank

; Loads roof graphics according to sCurrentRoofTileset.

HandleRoofGraphics:
    ld a, [wMapTileset]
    cp TILESET_JOHTO
    ret nz
    ld a, b_Roofs
	rst $10
    ld a, [sCurrentRoofTileset]
    ld hl, Roofs
    ld bc, $0090
    call AddNTimes
    ld a, [rLCDC]
    and $80
    jr z, .lcdOff
    ld a, [sRoofGraphicsDirectCopy]
    and a
    jr nz, .lcdOff
    xor a
    ld [sRoofGraphicsDirectCopy], a
    ld d, h
    ld e, l
    ld hl, $90A0
    ld bc, (b_Roofs << 8) | 9
    jp Request2bpp
.lcdOff
    ld de, $90A0
    ld bc, $0090
    call CopyBytes
    ; fall through to HandleMissingnoGraphics
    
; Loads Missingno. corruption graphics.

HandleMissingnoGraphics:
    ld hl, .nineTile
    ld de, $9520
    ld bc, $0010
    call CopyBytes
    ld hl, .nineTile
    ld de, $9360
    ld bc, $0010
    call CopyBytes
    ld hl, .nineTile
    ld de, $9480
    ld bc, $0010
    jp CopyBytes
.nineTile
    db $00,$00,$7c,$7c,$c6,$c6,$c6,$c6,$7e,$7e,$06,$06,$7c,$7c,$00,$00
