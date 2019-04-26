SECTION "main_sram0", ROM0[$A71A]

REPT $ABF0 - $A71A
    db $ff
ENDR
REPT $AC70 - $ABF0
    db $00
ENDR

include "includes/music_medalfanfare.asm"
include "includes/music_kasstheme.asm"

PlayMedalFanfare:
    di
    ld hl, $c100
    ld de, sScratch
    ld bc, $01a0
    call CopyBytes
    ei
    ld hl, Music_TCGMedal
    call PlayCustomMusic
.wait
    call DelayFrame
    ld a, [wChannel1MusicAddress]
    cp LOW(Music_TCGMedal_Finished)
    jr nz, .wait
    ld c, 20
    call DelayFrames
    di
    ld hl, sScratch
    ld de, $c100
    ld bc, $01a0
    call CopyBytes
    ei
    ld c, 20
    jp DelayFrames

PlayKassTheme:
    ld hl, Music_KassTheme
    ld de, $d290
    ld bc, 350
    call CopyBytes
    ld hl, $d290
    jp PlayCustomMusic
    
PlayCustomMusic:
    push hl
    ld a, b__PlayMusic
    rst $10
    call MusicOff
    pop de
    jp _PlayMusic+$16

sOrigTilemap equ sScratch
sOrigAttrmap equ sScratch + SCREEN_WIDTH * SCREEN_HEIGHT

anim_tile: MACRO
    db \2 * SCREEN_WIDTH + \1
ENDM
anim_done: MACRO
    db 0
ENDM

UnmissingnedAnimationScript:
    anim_tile 8, 7
    anim_tile 9, 7
    anim_tile 8, 6
    anim_tile 9, 6
    anim_tile 8, 5
    anim_tile 9, 5
    anim_tile 8, 4
    anim_tile 9, 4
    anim_tile 7, 5
    anim_tile 10, 5
    anim_tile 8, 3
    anim_tile 9, 3
    anim_tile 7, 4
    anim_tile 10, 4
    anim_tile 8, 2
    anim_tile 9, 2
    anim_tile 7, 3
    anim_tile 10, 3
    anim_tile 8, 1
    anim_tile 9, 1
    anim_tile 7, 2
    anim_tile 10, 2
    anim_tile 6, 3
    anim_tile 11, 3
    anim_tile 8, 0
    anim_tile 9, 0
    anim_tile 7, 1
    anim_tile 10, 1
    anim_tile 6, 2
    anim_tile 11, 2
    anim_tile 7, 0
    anim_tile 10, 0
    anim_tile 6, 1
    anim_tile 11, 1
    anim_tile 6, 0
    anim_tile 11, 0
    anim_tile 5, 1
    anim_tile 12, 1
    anim_tile 5, 0
    anim_tile 12, 0
    anim_done

IncAllTiles:
    ld hl, wTileMap
.loop
    ld a, [hli]
    bit 7, a
    jr z, .test
    dec hl
    inc a
    and $0f
    add $80
    ld [hli], a
.test
    ld a, l
    cp $40
    jr nz, .loop
    ret

UnmissingnedAnimation:
    coord hl, 0, 0
    ld de, sOrigTilemap
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CopyBytes
    ld hl, wAttrMap
    ld de, sOrigAttrmap
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call CopyBytes
    ld hl, $8800
    ld de, $1234
    ld bc, $0110
    call Request2bpp
    ld de, SFX_SURF
    call PlaySFX
    ld c, 0
    ld d, 0
    ld hl, UnmissingnedAnimationScript
.animFirstPart
    ld a, [hli]
    and a
    jr z, .animSecondPart
    push hl
    push bc
    ld e, a
    ld hl, wTileMap
    add hl, de
    ld a, c
    and $0f
    add $80
    ld [hl], a
    ld hl, wAttrMap
    add hl, de
    ld [hl], 7
    call IncAllTiles
    call ApplyTilemap
    pop bc
    pop hl
    inc c
    inc c
    jr .animFirstPart
.animSecondPart
    ld c, 50
.waitLoop
    ld de, SFX_SURF
    ld a, c
    cp 16
    call z, PlaySFX
    push bc
    call IncAllTiles
    call ApplyTilemap
    pop bc
    dec c
    jr nz, .waitLoop
    ld d, 0
    ld hl, UnmissingnedAnimationScript
.animThirdPart
    ld a, [hli]
    and a
    jr z, .animFinish
    push hl
    push bc
    ld e, a
    ld hl, sOrigTilemap
    add hl, de
    ld b, [hl]
    ld hl, sOrigAttrmap
    add hl, de
    ld c, [hl]
    ld hl, wTileMap
    add hl, de
    ld [hl], b
    ld hl, wAttrMap
    add hl, de
    ld [hl], c
    call IncAllTiles
    call ApplyTilemap
    pop bc
    pop hl
    jr .animThirdPart
.animFinish
    ld c, 50
    call DelayFrames
    ld de, SFX_SPITE
    call PlaySFX
    ld c, 140
    call DelayFrames
    jp LoadFonts_NoOAMUpdate

VerboseBagFuck:
    ld a, b_CurItemName
    rst $10
    call CurItemName
    ld de, wStringBuffer1
    ld a, 1
    call CopyConvertedText
    ld hl, BagFuckReceivedText
    call PrintText
    farcall Script_specialsound
    xor a
    ld [wCallInSRAMBankParent], a
    prepare_sram_call 0, WaitButton
    call CallInSRAMBank
    farcall CheckItemPocket
    ld a, [wItemAttributeParamBuffer]
    dec a
    and 3
    add a
    ld c, a
    ld b, 0
    ld hl, BagFuckPocketNames
    add hl, bc
    ld a, [hli]
    ld d, [hl]
    ld e, a
    ld hl, wStringBuffer3
    call CopyName2
    prepare_sram_call 0, PrintText
    ld hl, BagFuckItemPocketText
    call CallInSRAMBank
    ld a, 2
    ld [wCallInSRAMBankParent], a
    ret

BagFuckReceivedText:
    db $00                       ; <begin text>
    db $52,$e7,$7f               ; <PLAYER>!<space>
    db $50,$01,$AC,$D0           ; text_from_ram wStringBuffer4
    db $00                       ; <begin text>
    db $4f                       ; <nl>
    db $85,$88,$8d,$83,$e7       ; FIND!
    db $7f,$7f,$7f,$57           ; <3x space><end>

BagFuckItemPocketText:
    db $00                       ; <begin text>
    db $52,$e7,$7f               ; <PLAYER>!<space>
    db $50,$01,$AC,$D0           ; text_from_ram wStringBuffer4
    db $00                       ; <begin text>
    db $4f                       ; <nl>
    db $50,$01,$99,$D0           ; text_from_ram wStringBuffer3
    db $00                       ; <begin text>
    ; you know the rest
    db $85,$94,$82,$8a,$58

BagFuckPocketNames:
    dw BagFuckItemPocketName
    dw NULL
    dw BagFuckBallPocketName
    dw BagFuckTMPocketName

BagFuckItemPocketName:
    db $81,$80,$86,$7f,$7f,$7f,$7f,$50
BagFuckBallPocketName:
    db $81,$80,$8b,$8b,$7f,$7f,$7f,$50
BagFuckTMPocketName:
    db $8c,$80,$82,$87,$88,$8d,$84,$7f,$7f,$50

PlayerNamingScreen:
    ld a, b_NamingScreen
    rst $10
    call DisableSpriteUpdates
    ld hl, ReturnToMapWithSpeechTextbox
    push hl
    ld de, wStringBuffer1
    ld hl, wNamingScreenDestinationPointer
    ld [hl], e
    inc hl
    ld [hl], d
    ld a, 1
    ld [wNamingScreenType], a ; PLAYER
    ld hl, wOptions
    ld a, [hl]
    push af
    set 4, [hl]
    ldh a, [hMapAnims]
    push af
    xor a
    ldh [hMapAnims], a
    ldh a, [hInMenu]
    push af
    ld a, $1
    ldh [hInMenu], a
    call $56f8
    ld a, 10
    ld [wNamingScreenMaxNameLength], a
    ld hl, wStringBuffer1+7
    ld a, $eb
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], $50
    jp $56e2 ; NamingScreen+? (too lazy to count, just paste address from bgb... lul)
