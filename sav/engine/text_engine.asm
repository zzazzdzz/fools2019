; *** text_engine.asm
; The custom VWF text engine.

CHAR_DEFINITION_SIZE equ 9
CHAR_TILE_BUFFER_SIZE equ 38

sWorkingBlocks:
sWorkingBlock1:
    ds 8
sWorkingBlock2:
    ds 8

TextEngineVarsStart:

sCurrentXPosition:
    db 0
sCurrentCharIndex:
    db 0
sCurrentTilemapIndex:
    db 0
sBoldFace:
    db 0
sCurrentCharOffset:
    db 0
sParentTextBuffer:
    dw 0

TextEngineVarsEnd:

; Reads a byte at [wPrintTextVWFSourceBank]:HL, returns in A.
; HL is incremented afterwards.

GetTextByte:
    push bc
    ld a, [wPrintTextVWFSourceBank]
    call LdFromSRAMBank
    inc hl
    ld a, c
    pop bc
    ret

InitVariables:
    xor a
    ld hl, TextEngineVarsStart
    ld bc, TextEngineVarsEnd - TextEngineVarsStart
    call ByteFill
    ; fall through to ClearWorkingBlocks

ClearWorkingBlocks:
    xor a
    ld bc, 16
    ld hl, sWorkingBlocks
    jp ByteFill

; Main text printing function. Prints text at HL.

PrintTextVWF:
    push hl
    call GetTextByte
    call InitVariables
    call SpeechTextBox
    pop hl
PrintTextVWFCommandProcessor:
    call GetTextByte
    and a
    jr z, .done
    cp $f0
    jr nc, .command
    cp $3e
    jr z, .space
    ld c, a
    ld a, [sCurrentCharOffset]
    add c
.space
    call PutCharVWF
    jr PrintTextVWFCommandProcessor
.command
    sub $f0
    ld c, a
    ld b, 0
    push hl
    ld hl, VWFCommandsJumptable
    add hl, bc
    add hl, bc
    ld a, [hli]
    ld d, [hl]
    ld e, a
    pop hl
    push de
    ret
.done
    ld hl, sParentTextBuffer
    ld a, [hli]
    or [hl]
    jr nz, .printParent
    call RotateBlocks
    ld a, 3
    ld [wPrintTextVWFSourceBank], a
    ret
.printParent
    ld b, [hl]
    dec hl
    ld c, [hl]
    xor a
    ld [hli], a
    ld [hl], a
    ld h, b
    ld l, c
    inc hl
    inc hl
    jr PrintTextVWFCommandProcessor

VWFCommandsJumptable:
    dw TextCommandF0
    dw TextCommandF1
    dw TextCommandF2
    dw TextCommandF3
    dw TextCommandF4
    dw TextCommandF5
    dw TextCommandF6
    dw TextCommandF7
    dw TextCommandF8
    dw TextCommandF9
    dw TextCommandFA
    dw TextCommandFB
    dw PrintTextVWFCommandProcessor ; dummy
    dw TextCommandFD
    dw TextCommandFE
    dw PrintTextVWFCommandProcessor ; also dummy

TextCommandF0:
    push hl
    call RestartMapMusic
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF1:
    push hl
    call RotateBlocks
	call LoadBlinkingCursor
	call Text_WaitBGMap
    prepare_sram_call 2, ButtonSound
	call CallInSRAMBank
    call UnloadBlinkingCursor
    call TextScroll
	call TextScroll
    call ClearWorkingBlocks
	ld a, SCREEN_WIDTH * 2
    ld [sCurrentTilemapIndex], a
    xor a
    ld [sCurrentXPosition], a
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF2:
    push hl
    call RotateBlocks
    call ClearWorkingBlocks
	ld a, SCREEN_WIDTH * 2
    ld [sCurrentTilemapIndex], a
    xor a
    ld [sCurrentXPosition], a
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF3:
    push hl
    call RotateBlocks
	call LoadBlinkingCursor
	call Text_WaitBGMap
    prepare_sram_call 2, ButtonSound
	call CallInSRAMBank
    call UnloadBlinkingCursor
TextCommandParagraph:
    call ClearWorkingBlocks
    coord hl, 1, 13
    ld bc, $0412
    call ClearBox
    xor a
    ld [sCurrentXPosition], a
    ld [sCurrentCharIndex], a
    ld [sCurrentTilemapIndex], a
    ld c, 16
    call DelayFrames
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF4:
    push hl
    call RotateBlocks
	call LoadBlinkingCursor
	call Text_WaitBGMap
    prepare_sram_call 2, ButtonSound
	call CallInSRAMBank
    call UnloadBlinkingCursor
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF5:
    ld bc, sParentTextBuffer
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    call GetTextByte
    ld b, a
    call GetTextByte
    ld h, a
    ld l, b
    jp PrintTextVWFCommandProcessor

TextCommandF6:
    call GetTextByte
    push hl
    push af
    call RotateBlocks
    pop af
    ld c, a
    call DelayFrames
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandF7:
    push hl
    jp TextCommandParagraph

TextCommandF8:
    call GetTextByte
    ld [sCurrentCharOffset], a
    jp PrintTextVWFCommandProcessor

TextCommandF9:
    xor a
    ld [sBoldFace], a
    jp PrintTextVWFCommandProcessor

TextCommandFA:
    ld a, 1
    ld [sBoldFace], a
    jp PrintTextVWFCommandProcessor

TextCommandFB:
    call GetTextByte
    push hl
    and a
    jr z, .medalFanfare
    prepare_sram_call 0, PlayKassTheme
    call CallInSRAMBank
    jr .end
.medalFanfare
    call RotateBlocks
    prepare_sram_call 0, PlayMedalFanfare
    call CallInSRAMBank
.end
    pop hl
    jp PrintTextVWFCommandProcessor

; Unused. There were plans to include a text command that makes the last
; interacted sprite face the player; but this was deemed unnecessary later.

FacePlayer:
    farcall Script_faceplayer
    call SafeUpdateSprites
    call ReplaceKrisSprite
    ret

TextCommandFD:
    call GetTextByte
    push hl
	ld b, 1 ; SET_FLAG
    ld e, a
    ld d, 0
	call EventFlagAction
    pop hl
    jp PrintTextVWFCommandProcessor

TextCommandFE:
    call GetTextByte
    ld d, a
    call GetTextByte
    ld e, a
    call GetTextByte
    ld h, a
    ld l, e
    ld a, d
    ld [wPrintTextVWFSourceBank], a
    jp PrintTextVWFCommandProcessor

RotateAndCopySingleLine:
    push af
    push de
    push hl
    ld b, [hl]
    ld a, [sBoldFace]
    and a
    ld a, b
    jr z, .noBold
    srl b
    or b
    ; A more advanced bold face algorithm; it was scrapped because it didn't
    ; work very well with the font I was using.
    ; See this for more information: https://i.imgur.com/bs8sD35.png
    ; srl a
    ; srl a
    ; cpl
    ; and b
    ; srl b
    ; or b
.noBold
    ld b, a
    ld c, 0
    ld a, [sCurrentXPosition]
.shiftATimes
    and a
    jr z, .isZero
    rr b
    rr c
    dec a
    jr .shiftATimes
.isZero
    ld h, d
    ld l, e
    ld de, 8
    ld a, b
    or [hl]
    ld [hl], a
    add hl, de
    ld [hl], c
    pop hl
    pop de
    pop af
    ret

RotateBlocks:
    push af
    ld hl, $8ba0
    ld bc, $0010
    ld a, [sCurrentCharIndex]
    inc a
    cp CHAR_TILE_BUFFER_SIZE
    jr c, .noOverflow
    sub CHAR_TILE_BUFFER_SIZE
.noOverflow
    ld [sCurrentCharIndex], a
    call AddNTimes
    ld de, sWorkingBlocks
    call UpdateVRAMAndDelayFrame
    ld bc, 8
    ld hl, sWorkingBlock2
    ld de, sWorkingBlock1
    call CopyBytes
    ld hl, sCurrentTilemapIndex
    inc [hl]
    pop af
    ret

CopyCharToWorkingBlocks:
    ld a, [hli]
    push af
    ld a, [sBoldFace]
    and a
    jr z, .noBold
    pop af
    inc a
    push af
.noBold
    ld a, 8
    ld de, sWorkingBlock1
.eachByte
    call RotateAndCopySingleLine
    inc hl
    inc de
    dec a
    jr nz, .eachByte
    ld a, [sCurrentXPosition]
    ld b, a
    pop af
    add b
    inc a
    cp 8
    call nc, RotateBlocks
    and 7
    ld [sCurrentXPosition], a
    ret

PutCharVWF:
    push hl
    ld bc, CHAR_DEFINITION_SIZE
    ld hl, CharacterSet
    dec a
    call AddNTimes
    call CopyCharToWorkingBlocks
    pop hl
    ret

UpdateVRAMAndDelayFrame:
    di
    ld c, 8
.waitHblank
    ldh a, [rSTAT]
    and %00000011
    jr nz, .waitHblank
    ld a, [de]
    ld [hli], a
    ld [hli], a
    inc de
.waitNoHblank
    ldh a, [rSTAT]
    and %00000011
    jr z, .waitNoHblank
    dec c
    jr nz, .waitHblank
.recalc
    coord hl, 1, 14
    ld a, [sCurrentTilemapIndex]
    ld b, 0
    ld c, a
    add hl, bc
    ld a, h
    cp $c6
    jr c, .ok
    xor a
    ld [sCurrentTilemapIndex], a
    jr .recalc
.ok
    ld a, [sCurrentCharIndex]
    add $ba
    ld [hl], a
    ld a, $7C
    ld [$C5F3], a
    ld [$C5CB], a
    inc a
    ld [$C5F4], a
    ei
    jp DelayFrame

CharacterSet:
    include "includes/charset.asm"