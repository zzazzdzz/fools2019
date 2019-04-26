; *** choice_menu.asm
; Implements programmable choice menus.

; Choice menu engine flags.

sMenuDisplayTextCoord:
    dw 0
sMenuDisplayAllowedBButton:
    db 0
sMenuDisplayCancelAction:
    db 0
sMenuDisplayAvailableOptions:
    db 0
sMenuClearOnExit:
    db 0
sMenuStartingCursorPosition:
    db 0
    
; Creates a generic Yes/No choice menu.
; Also copies the result to wScriptVar, so this routine can easily be used
; inside scripts with iftrue/iffalse.

GenericYesNoTextbox:
    ld bc, $0204
    ld hl, GenericYesNoBoxset
    ld de, $0101
    call DisplayChoiceMenu
    xor 1
    ld [wScriptVar], a
    ret

; Creates a choice menu.
; BC -> textbox dimensions
; HL -> menu text
; D -> allow or disallow pressing B to exit
; E -> which option ID to assume if B was pressed
; Returns option ID in A (0 if first option chosen, 1 if second, etc.)

DisplayChoiceMenu:
    push hl
    push bc
    push de
    call PreserveMenu
    pop de
    pop bc
    pop hl
    ; fall through to DisplayChoiceMenuNoBackup
    
; Creates a choice menu, but does not back up the tile and attribute maps.
; Takes/returns exactly the same arguments as DisplayChoiceMenu.

DisplayChoiceMenuNoBackup:
    call ChoiceMenuHandler
    push af
    ld a, [sMenuClearOnExit]
    and a
    call z, CleanseMenu
    xor a
    ld [sMenuClearOnExit], a
    pop af
    ret
    
; Back up tile and attribute maps to sScratch.

PreserveMenu:
    prepare_sram_call 0, CopyBytes
    ld de, sScratch
    coord hl, 0, 0
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CallInSRAMBank
    ld de, sScratch + SCREEN_WIDTH * SCREEN_HEIGHT
    ld hl, wAttrMap
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CallInSRAMBank
    jp DelayFrame ; essentially wait for vblank

; Restore tile and attribute maps from sScratch.

CleanseMenu:
    prepare_sram_call 0, CopyBytes
    ld hl, sScratch
    coord de, 0, 0
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CallInSRAMBank
    ld de, wAttrMap
    ld hl, sScratch + SCREEN_WIDTH * SCREEN_HEIGHT
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CallInSRAMBank
    call UpdateSprites
    jp ApplyTilemap

; Draw the menu textbox aligned to the bottom right side of the screen,
; according to dimensions in BC.

DrawChoiceMenuTextbox:
    push hl
    push de
    push bc
    ld de, -20
    coord hl, 18, 10
.calcHeight
    add hl, de
    dec b
    jr nz, .calcHeight
.calcWidth
    dec hl
    dec c
    jr nz, .calcWidth
    inc b
    inc c
    inc c
    pop bc
    push hl
    call TextBox
    call UpdateSprites
    call ApplyTilemap
    pop hl
    ld de, SCREEN_WIDTH + 2
    add hl, de
    ld de, sMenuDisplayTextCoord
    ld a, l
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    pop de
    pop hl
    ret
    
; Handle displaying and operating the choice menu.

ChoiceMenuHandler:
    ld a, b
    dec a
    ld [sMenuDisplayAvailableOptions], a
    ld a, d
    ld [sMenuDisplayAllowedBButton], a
    ld a, e
    ld [sMenuDisplayCancelAction], a
    call DrawChoiceMenuTextbox
    ld d, h
    ld e, l
    ld hl, sMenuDisplayTextCoord
    ld a, [hli]
    ld h, [hl]
    ld l, a
    push hl
    ld a, 3
    call PutStringFromSRAMBank
    pop hl
    dec hl
    ld bc, SCREEN_WIDTH
    ld a, [sMenuStartingCursorPosition]
    ld d, a
    jr .redrawCursor
.inputLoop
    ldh a, [hJoypadDown]
    and a
    jr nz, .inputLoop
.waitForInput
    call DelayFrame
    ldh a, [hJoypadDown]
    and a
    jr z, .inputLoop
.checkInputs
    ldh a, [hJoypadDown]
    rrca
    jr c, .pressedA
    rrca
    jr c, .pressedB
    swap a
    rrca
    jr c, .pressedUp
    rrca
    jr c, .pressedDown
.redrawCursor
    push hl
    ld e, 0
.cursorLoop
    ld a, e
    cp d
    ld a, $ed
    jr z, .draw
    ld a, $7f
.draw
    ld [hl], a
    add hl, bc
    inc e
    ld a, [sMenuDisplayAvailableOptions]
    inc a
    cp e
    jr nz, .cursorLoop
    pop hl
    jr .inputLoop
.pressedA
    push de
    ld de, SFX_READ_TEXT
    call PlaySFX
    pop de
    ld a, d
    ret
.pressedB
    push de
    ld de, SFX_READ_TEXT
    call PlaySFX
    pop de
    ld a, [sMenuDisplayAllowedBButton]
    and a
    jr z, .redrawCursor
    ld a, [sMenuDisplayCancelAction]
    ret
.pressedUp
    push de
    ld de, SFX_PECK
    call PlaySFX
    pop de
    ld a, d
    and a
    jr z, .redrawCursor
    dec d
    jr .redrawCursor
.pressedDown
    push de
    ld de, SFX_PECK
    call PlaySFX
    pop de
    ld a, [sMenuDisplayAvailableOptions]
    cp d
    jr z, .redrawCursor
    inc d
    jr .redrawCursor
