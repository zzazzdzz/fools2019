; *** map_loader.asm
; Custom map loader functions that handle reading map data from SRA3.

; Read a 16-bit pointer from SRA3 at HL. Return in HL.

Ld16FromSRA3:
    ld a, 3
    call LdFromSRAMBank
    ld b, c
    inc hl
    ld a, 3
    call LdFromSRAMBank
    ld h, c
    ld l, b
    ret
    
; Copy BC bytes from SRA3:HL to DE.

FarCopyFromSRA3:
    push bc
    ld a, 3
    call LdFromSRAMBank
    ld a, c
    pop bc
    ld [de], a
    inc de
    inc hl
    dec bc
    ld a, c
    or b
    jr nz, FarCopyFromSRA3
    ret
    
; Get pointer to a specific substructure of the current map.
; Substructures are defined by DATASTRUCT_* constants.
; Takes datastruct ID in A. Return pointer in HL.

GetPointerToMapDataStruct:
    push de
    push bc
    push af
    ld a, [wCurrentMapNumber]
    sub $63
    ld c, a
    ld b, 0
    ld hl, $a000
    add hl, bc
    add hl, bc
    call Ld16FromSRA3
    pop af
    ld b, 0
    ld c, a
    add hl, bc
    add hl, bc
    call Ld16FromSRA3
    pop bc
    pop de
    ret
    
; Gets the ID of the last talked BG event. Works by taking coordinates of the
; last BG event that was interacted with and searching for the event with
; the same coordinates. Returns ID in A.

ProcessLastTalkedBGEvents:
    ld hl, wEngineBuffer1
    ld a, [hli]
    ld e, [hl]
    ld d, a
    ld hl, wCurMapBGEventsPointer
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld b, 1
    ld a, [wCurMapBGEventCount]
    inc a
    ld c, a
.loop
    push bc
    ld a, [hli]
    ld c, [hl]
    ld b, a
    call CompareBCToDE
    jr nz, .next
.found
    pop bc
    ld a, b
    ret
.next
    ld bc, 4
    add hl, bc
    pop bc
    inc b
    ld a, b
    cp c
    jr nz, .loop
    xor a
    ret

; Gets the ID of the last activated coord event. Works similar to the routine
; above. Returns ID in A.

ProcessLastTalkedCoordEvents:
    ld hl, wEngineBuffer1 + 1
    ld a, [hli]
    ld e, [hl]
    ld d, a
    ld hl, wCurMapCoordEventsPointer
    ld a, [hli]
    ld h, [hl]
    ld l, a
    inc hl
    ld a, [wCurMapObjectEventCount]
    ld b, a
    ld a, [wCurMapBGEventCount]
    add b
    add b
    add b
    inc a
    ld b, a
    ld a, [wCurMapCoordEventCount]
    add b
    ld c, a
.loop
    push bc
    ld a, [hli]
    ld c, [hl]
    ld b, a
    call CompareBCToDE
    jr nz, .next
.found
    pop bc
    ld a, b
    ret
.next
    ld bc, 7
    add hl, bc
    pop bc
    inc b
    ld a, b
    cp c
    jr nz, .loop
    xor a
    ret
    
; Gets the ID of the NPC, sign or script last triggered by the player.
; The IDs are assigned as follows:
; 0x00 - undefined, will trigger an error handler
; next wCurMapBGEventCount IDs - BG events
; next 3*wCurMapObjectEventCount IDs - object events; each object event has a
; pointer for encounter text, defeat text and post-battle text, in case it is
; a trainer
; next wCurMapCoordEventCount - coord events
; 0xFF - an empty, silent script that returns immediately
; Returns the ID in A.

GetLastTalkedID:
    ld a, [wReturnFromTrainerBattle]
    and a
    jr nz, .trainerExit
    ldh a, [hLastTalked]
    and a
    jr nz, .objectEvent
.notObjectEvent
    call ProcessLastTalkedBGEvents
    and a
    call z, ProcessLastTalkedCoordEvents
    ld [wCurrentScriptID], a
    ret
.objectEvent
    ld c, a
    ld a, [wCurMapBGEventCount]
    inc a
    dec c
    add c
    add c
    add c
    ld c, a
    ld a, [wBattleMode]
    and a
    jr nz, .inBattle
    ld a, c
    ret
.inBattle
    ld a, 1
    ld [wReturnFromTrainerBattle], a
    ld a, c
    inc a
    ret
.trainerExit
    xor a
    ld [wReturnFromTrainerBattle], a
    ld a, $ff
    ret
    
; Custom map loader routine.

LoadMapDataFromSRAM:
    ld a, [wMapGroup]
    ld [wCurrentMapGroup], a
    ld a, [wMapNumber]
    ld [wCurrentMapNumber], a
.setEventPointer
    ld a, DATASTRUCT_EVENTS
    call GetPointerToMapDataStruct
    ld d, h
    ld e, l
    ld hl, wMapEventsPointer
    ld [hl], e
    inc hl
    ld [hl], d
.setBlocksPointer
    ld a, DATASTRUCT_BLOCKS
    call GetPointerToMapDataStruct
    ld d, h
    ld e, l
    ld hl, wMapBlocksPointer
    ld [hl], e
    inc hl
    ld [hl], d
.loadOwnEvents
    prepare_sram_call 3, ReadMapEvents
    xor a
    call CallInSRAMBank
    ld a, DATASTRUCT_EVENTS
    call GetPointerToMapDataStruct
    ld de, $DEF6
    push de
    ld bc, 52
    call FarCopyFromSRA3
    pop de
    ld hl, wMapEventsPointer
    ld [hl], e
    inc hl
    ld [hl], d
    ld a, 1
    call CallInSRAMBank
.restoreFacing
    ldh a, [hMapEntryMethod]
    cp MAPSETUP_FALL
    call z, RestoreFacingAfterWarp
    cp MAPSETUP_DOOR
    call z, RestoreFacingAfterWarp
    cp MAPSETUP_TRAIN
    call z, RestoreFacingAfterWarp
    ret

; Get Ath event pointer from current map data.

GetScriptOrTextPointerFromSRAM:
    push af
    ld a, DATASTRUCT_SCRIPTS
    call GetPointerToMapDataStruct
    pop af
    ld c, a
    ld b, 0
    dec c
    add hl, bc
    add hl, bc
    jp Ld16FromSRA3

; Execute the current map's initialization script.
; Makes sure to switch to SRA3 (that's where map data is stored)

ExecuteMapInitScript:
    ld a, DATASTRUCT_INITSCRIPT
    call GetPointerToMapDataStruct
    ld a, 3
    ld d, h
    ld e, l
    call PrepareSRAMCall
    jp CallInSRAMBank

; Check which object was interacted with and run the correct script.

LoadScriptFromSRAM:
    xor a
    ld [wForceSpecificTextboxID], a
    call GetLastTalkedID
    ld b, a
    ld hl, GenericTextboxScript
    and a
    jr z, .noScript
    cp $ff
    jr nz, .retryScriptPtr
    ld hl, EmptyScriptReturn
    jr .noGeneric
.retryScriptPtr
    push bc
    call GetScriptOrTextPointerFromSRAM
    pop bc
.noScript
    ld a, h
    and $e0
    cp $20
    jr nz, .noGeneric
    ld hl, GenericTextboxScript
.noGeneric
    ld a, 3
    call LdFromSRAMBank
    ld a, c
    cp TEXTBOX_START_MARKER
    jr z, .scriptInvalid
    cp TEXTBOX_TXFAR_MARKER
    jr nz, .scriptValid
.scriptInvalid
    ld a, b
    add 2
    ld b, a
    ld [wForceSpecificTextboxID], a
    jr .retryScriptPtr
.scriptValid
    ld bc, 256
    ld de, wScriptTempLocation
    push de
    call FarCopyFromSRA3
    pop de
    ld hl, wScriptPos
    ld [hl], e
    inc hl
    ld [hl], d
    ld hl, wScriptStackSize
    ld e, [hl]
    inc [hl]
    ld d, 0
    ld hl, wScriptStack
    add hl, de
    add hl, de
    add hl, de
    ld de, MapCallScriptInSRAMReturn
    ld [hl], 1
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ret
    
; Check which object was interacted with and print its script pointer as text.

LoadTextFromSRAM:
    ld a, 3
    ld [wPrintTextVWFSourceBank], a
    ld hl, wSpecificTextboxPointer
    ld a, [hli]
    ld h, [hl]
    ld l, a
    or h
    jr nz, .noGeneric
    call GetLastTalkedID
    ld b, a
    ld hl, UndefinedEventErrorHandlerText
    and a
    jr z, .noScript
    ld a, [wForceSpecificTextboxID]
    and a
    jr nz, .forceTextbox
    ld a, b
.forceTextbox
    call GetScriptOrTextPointerFromSRAM
.noScript
    ld a, h
    and $e0
    cp $20
    jr nz, .noGeneric
    ld a, h
    add $80
    ld h, a
.noGeneric
    xor a
    ld [wForceSpecificTextboxID], a
    ld [wSpecificTextboxPointer], a
    ld [wSpecificTextboxPointer+1], a
    call PrintTextVWF
    ld hl, $0134 
    ret

; Copies map headers, subheaders, trainers and itemballs to RAM. They need to
; be loaded at all times, so they can't reside in SRAM.

CopyMapDataToRAM:
    ld hl, $DC84
    ld de, MapWriteTextInSRAM+5
    ld [hl], $c3
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ld bc, 128 - SCRATCH_RAM_AREA_SIZE
    ld hl, MapUtilityEntries + SCRATCH_RAM_AREA_SIZE
    ld de, $DF30 + SCRATCH_RAM_AREA_SIZE
    call CopyBytes
    ld bc, 100
    ld hl, MapHeaderEntries
    ld de, $DB79
    call CopyBytes
    ld bc, 200
    ld hl, MapTrainerEntries
    ld de, $D972
    call CopyBytes
    ; fall through to CopyMapSubheaderEntriesToRAM
    
; Copies just map subheaders to RAM. They need to be reloaded after every
; battle, since the area allocated for these is reused for trainer rosters.

CopyMapSubheaderEntriesToRAM:
    xor a
    ldh [hLastTalked], a
    ld bc, 256
    ld hl, MapSubHeaderEntries
    ld de, $D289
    jp CopyBytes
    
; Map headers, subheaders, trainer and itemball data. This is copied to RAM
; when necessary.

MapHeaderEntries:
    IF DEF(FINAL_PASS)
        incbin "bin/mapdata_headers.bin"
    ENDC

MapSubHeaderEntries:
    IF DEF(FINAL_PASS)
        incbin "bin/mapdata_subheaders.bin"
    ENDC

MapUtilityEntries:
    IF DEF(FINAL_PASS)
        incbin "bin/mapdata_utility.bin"
    ENDC

MapTrainerEntries:
    IF DEF(FINAL_PASS)
        incbin "bin/mapdata_trainers.bin"
    ENDC