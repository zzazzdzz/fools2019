; credits

StartCredits:
    xor a
    ldh [hMapAnims], a
    ld bc, 32
    ld de, $c900
    ld hl, LoadFrontPicRoutine
    call CopyBytes
    ld bc, 32
    ld de, $c930
    ld hl, AnimateFrontPicRoutine
    call CopyBytes
    ld bc, 64
    ld de, $c960
    ld hl, CreditsFinalRoutine
    call CopyBytes
    call HideSprites
    call ClearScreen
    call WaitBGMap
	ld b, 8
	call GetSGBLayout
	call SetPalettes
    ld c, 80
    call DelayFrames
    ld de, MUSIC_MYSTICALMAN_ENCOUNTER
    call PlayMusic
    coord hl, 0, 0
    ld a, 4
    ldh [hSCY], a
    ld bc, 5 * 20
    ld a, $60
    call ByteFill
    coord hl, 0, 14
    ld bc, 4 * 20
    ld a, $60
    call ByteFill
    ld de, CreditsString1
    call SingleCreditsParagraph
    ld de, CreditsString2
    call SingleCreditsParagraph
    ld de, CreditsString3
    call SingleCreditsParagraph
    ld de, CreditsString4
    call SingleCreditsParagraph
    ld de, CreditsString5
    call SingleCreditsParagraph
    ld de, CreditsTitle1
    coord hl, 2, 6
    call SingleCreditsParagraphCustomCoords
    ld a, [wPokemonData]
    ld c, a
    ld hl, wPartyMon1
    ld de, wPartyMonNicknames
.showMons
    push hl
    push de
    push bc
    call PresentSinglePartyMon
    pop bc
    pop de
    pop hl
    push bc
    ld bc, wPartyMon2 - wPartyMon1
    add hl, bc
    REPT 11
        inc de
    ENDR
    pop bc
    dec c
    jr nz, .showMons
.dex
    ld hl, wPokedexSeen
	ld b, wEndPokedexSeen - wPokedexSeen
	call CountSetBits
	ld [wd002], a
	ld hl, wPokedexCaught
	ld b, wEndPokedexCaught - wPokedexCaught
	call CountSetBits
	ld [wd003], a
    ld hl, CreditsDexTextSeen
    ld de, wd002
    ld bc, $0103
    call PrintNum
    ld hl, CreditsDexTextCaught
    ld de, wd003
    ld bc, $0103
    call PrintNum
    ld de, CreditsDexText
    coord hl, 1, 8
    call SingleCreditsParagraphCustomCoords
    ld a, $33
    ld [wMusicFade], a
    ld de, CreditsFinalText
    coord hl, 1, 7
    call SingleCreditsParagraphCustomCoords
    coord hl, 3, 9
    ld de, CreditsTheEndText
    call DelayedStringWriter
    ld c, 120
    call DelayFrames
    call FillWithNine
    farcall FadeOutPalettes
    xor a
    ld [hSCY], a
    call ClearScreen
    jp $c960

CreditsFinalRoutine:
    ld c, 50
    call DelayFrames
    ld a, 3
    ld [wPrintTextVWFSourceBank], a
    call SwitchToSRA2
    call WaitBGMap
	ld b, 8
	call GetSGBLayout
	call SetPalettes
    ld hl, CreditsEndTextbox
    call PrintTextVWF
    call WaitButton
    call ClearScreen
    ld c, 50
    call DelayFrames
    jp Save

CreditsEndTextbox:
    text "You might have saved Glitch"
    next "Islands, but your adventure"
    cont "isn't quite over yet."
    para "You still have many places to"
    next "see, people to meet, locations"
    cont "to explore."
    para "Get all the achievements!"
    next "Battle for the top score!"
    done

FillWithNine:
    coord hl, 0, 5
    ld d, (9*20)/2
.go
    ld a, $ff
    ld [hli], a
    ld [hli], a
    call DelayFrame
    dec d
    jr nz, .go
    ret

PresentSinglePartyMon:
    push de
	ld d, [hl]
    ld bc, wPartyMon1DVs - wPartyMon1
    add hl, bc
	ld a, [hli]
	ld [wTempMonDVs], a
	ld a, [hl]
	ld [wTempMonDVs + 1], a
    ld bc, wPartyMon1Level - (wPartyMon1DVs + 1)
    add hl, bc
    push hl
    ld a, d
    call $c900
	ld b, $1c
	call GetSGBLayout
	call SetPalettes
    call AnimateFrontPicTilemapEntry
    ld c, 5
    call DelayFrames
    call $c930
    ld c, 20
    call DelayFrames
    ld a, 1
    ld [wNamedObjectTypeBuffer], a
    call GetName
    coord hl, 1, 9
    ld de, wStringBuffer1
    call PlaceString
    ld hl, MonLevelString_Num
    ld a, $7f
    ld [hli], a
    ld [hli], a
    ld [hl], a
    pop de
    ld hl, MonLevelString_Num
    ld bc, $4103
    call PrintNum
    coord hl, 1, 11
    ld de, MonLevelString
    call PlaceString
    coord hl, 1, 7
    pop de
    call PlaceString
    ld c, 150
    call DelayFrames
    jp SCYAnimation

frontpic_anim_entry: MACRO
    db (\2) * 20 + (\1)
    db \3
ENDM

AnimateFrontPicTilemapEntry:
    ld a, $ff
    ld [.forceTile], a
    call .animate
    xor a
    ld [.forceTile], a
    ; fall through to .animate
.animate
    ld b, 0
    ld de, .animation
.next
    push de
    call IsSFXPlaying
    jr nc, .nope
    ld de, SFX_SHINE
    call PlaySFX
.nope
    pop de
    ld a, [de]
    inc de
    and a
    ret z
    ld c, a
    ld hl, wTileMap + 11
    add hl, bc
    ld a, [.forceTile]
    and a
    jr nz, .skip
    ld a, [de]
.skip
    inc de
    ld [hl], a
    call DelayFrame
    jr .next
.forceTile
    db 0
.animation
    frontpic_anim_entry 1, 6, $00
    frontpic_anim_entry 2, 6, $07
    frontpic_anim_entry 1, 7, $01
    frontpic_anim_entry 3, 6, $0E
    frontpic_anim_entry 2, 7, $08
    frontpic_anim_entry 1, 8, $02
    frontpic_anim_entry 4, 6, $15
    frontpic_anim_entry 3, 7, $0F
    frontpic_anim_entry 2, 8, $09
    frontpic_anim_entry 1, 9, $03
    frontpic_anim_entry 5, 6, $1C
    frontpic_anim_entry 4, 7, $16
    frontpic_anim_entry 3, 8, $10
    frontpic_anim_entry 2, 9, $0A
    frontpic_anim_entry 1, 10, $04
    frontpic_anim_entry 6, 6, $23
    frontpic_anim_entry 5, 7, $1D
    frontpic_anim_entry 4, 8, $17
    frontpic_anim_entry 3, 9, $11
    frontpic_anim_entry 2, 10, $0B
    frontpic_anim_entry 1, 11, $05
    frontpic_anim_entry 7, 6, $2A
    frontpic_anim_entry 6, 7, $24
    frontpic_anim_entry 5, 8, $1E
    frontpic_anim_entry 4, 9, $18
    frontpic_anim_entry 3, 10, $12
    frontpic_anim_entry 2, 11, $0C
    frontpic_anim_entry 1, 12, $06
    frontpic_anim_entry 7, 7, $2B
    frontpic_anim_entry 6, 8, $25
    frontpic_anim_entry 5, 9, $1F
    frontpic_anim_entry 4, 10, $19
    frontpic_anim_entry 3, 11, $13
    frontpic_anim_entry 2, 12, $0D
    frontpic_anim_entry 7, 8, $2C
    frontpic_anim_entry 6, 9, $26
    frontpic_anim_entry 5, 10, $20
    frontpic_anim_entry 4, 11, $1A
    frontpic_anim_entry 3, 12, $14
    frontpic_anim_entry 7, 9, $2D
    frontpic_anim_entry 6, 10, $27
    frontpic_anim_entry 5, 11, $21
    frontpic_anim_entry 4, 12, $1B
    frontpic_anim_entry 7, 10, $2E
    frontpic_anim_entry 6, 11, $28
    frontpic_anim_entry 5, 12, $22
    frontpic_anim_entry 7, 11, $2F
    frontpic_anim_entry 6, 12, $29
    frontpic_anim_entry 7, 12, $30
    db 0

LoadFrontPicRoutine:
    ld [wCurSpecies], a
    ld [wCurPartySpecies], a
	ld a, b_GetMonFrontpic
    rst $10
    push hl
    ld de, vTiles2
    call GetMonFrontpic
    pop hl
    jp SwitchToSRA3

AnimateFrontPicRoutine:
    ld de, vTiles2
    farcall GetAnimatedFrontpic
	ld a, b_AnimateFrontpic
    rst $10
    ld de, 1
    coord hl, 12, 6
    call AnimateFrontpic
    ld a, 1
	ldh [hBGMapMode], a
    jp SwitchToSRA3

SingleCreditsParagraph:
    coord hl, 1, 6
SingleCreditsParagraphCustomCoords:
    call DelayedStringWriter
    ld c, 120
    call DelayFrames
    ; fall through to SCYAnimation

SCYAnimation:
    ld hl, .animation1
    ld b, 60
    call .animate
    coord hl, 0, 6
    ld bc, 8 * 20
    ld a, $7f
    call ByteFill
    ld hl, .animation2
    ld b, 60
    jp .animate
.animate
    ld a, [hli]
    ldh [hSCY], a
    call DelayFrame
    dec b
    jr nz, .animate
    ret
.animation1
    db 4, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 8, 9, 10, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 33, 35, 37, 40, 43, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 76, 79, 83, 86, 89, 93, 96, 100, 104, 107, 111, 115, 118, 122, 126, 129, 133, 137, 141, 144
.animation2
    db 144, 147, 150, 153, 156, 159, 162, 165, 168, 171, 174, 176, 179, 182, 185, 188, 191, 193, 196, 199, 202, 204, 207, 209, 212, 214, 217, 219, 221, 223, 226, 228, 230, 232, 234, 236, 237, 239, 241, 242, 244, 245, 247, 248, 249, 251, 252, 253, 254, 255, 0, 0, 1, 2, 2, 3, 3, 3, 3, 4

DelayedStringWriter:
    push hl
.loop
    ld a, [de]
    inc de
    and a
    jr z, .end
    cp $4f
    jr z, .lineFeed
    ld [hli], a
    cp $f4
    call z, .extraDelay
    ld c, 3
    call DelayFrames
    jr .loop
.end
    pop hl
    ret
.lineFeed
    pop hl
    ld bc, 40
    add hl, bc
    push hl
    jr .loop
.extraDelay
    ld c, 20
    jp DelayFrames

MonLevelString:
    db $8b,$b5,$e8,$7f
MonLevelString_Num:
    db $7f,$7f,$7f,$50

CreditsString1:
    db $80,$ad,$a3,$7f,$ae,$ad,$7f,$b3,$a7,$a0,$b3,$7f,$a3,$a0,$b8,$f4,$4f
    db $b3,$a7,$a4,$7f,$b1,$a4,$a8,$a6,$ad,$7f,$ae,$a5,$7f,$b3,$a7,$a4,$4f
    db $86,$ab,$a8,$b3,$a2,$a7,$7f,$8b,$ae,$b1,$a3,$7f,$a7,$a0,$b2,$4f
    db $a2,$ae,$ac,$a4,$7f,$b3,$ae,$7f,$a0,$ad,$7f,$a4,$ad,$a3,$e8,$00

CreditsString2:
    db $82,$ae,$b1,$b1,$b4,$af,$b3,$a8,$ae,$ad,$7f,$b2,$b3,$a0,$b1,$b3,$a4,$a3,$4f
    db $a3,$a8,$b2,$a0,$af,$af,$a4,$a0,$b1,$a8,$ad,$a6,$f4,$7f,$a0,$ad,$a3,$4f
    db $a4,$b5,$a4,$b1,$b8,$b3,$a7,$a8,$ad,$a6,$7f,$b2,$ab,$ae,$b6,$ab,$b8,$4f
    db $b1,$a4,$b3,$b4,$b1,$ad,$a4,$a3,$7f,$b3,$ae,$7f,$ae,$b1,$a3,$a4,$b1,$e8,$00

CreditsString3:
    db $80,$ab,$ab,$7f,$b3,$a7,$a0,$ad,$aa,$b2,$7f,$b3,$ae,$7f,$b8,$ae,$b4,$f4,$4f
    db $b3,$a7,$a4,$7f,$b2,$a0,$b5,$a8,$ae,$b1,$7f,$ae,$a5,$4f
    db $86,$ab,$a8,$b3,$a2,$a7,$7f,$88,$b2,$ab,$a0,$ad,$a3,$b2,$f4,$4f
    db $ae,$b4,$b1,$7f,$ae,$ad,$ab,$b8,$7f,$a7,$a4,$b1,$ae,$e7,$00

CreditsString4:
    db $93,$a7,$a8,$b2,$7f,$b2,$b3,$ae,$b1,$b8,$7f,$a7,$a0,$b2,$4f
    db $a0,$7f,$a7,$a0,$af,$af,$b8,$7f,$a4,$ad,$a3,$a8,$ad,$a6,$f4,$4f
    db $a1,$b4,$b3,$7f,$b6,$a4,$7f,$ac,$b4,$b2,$b3,$7f,$b1,$a4,$ac,$a0,$a8,$ad,$4f
    db $a4,$b5,$a4,$b1,$7f,$b5,$a8,$a6,$a8,$ab,$a0,$ad,$b3,$e8,$00

CreditsString5:
    db $96,$a7,$ae,$7f,$aa,$ad,$ae,$b6,$b2,$7f,$b6,$a7,$a4,$ad,$4f
    db $b3,$a7,$a8,$b2,$7f,$aa,$a8,$ad,$a3,$7f,$ae,$a5,$4f
    db $a3,$a0,$ad,$a6,$a4,$b1,$7f,$ac,$a8,$a6,$a7,$b3,$7f,$a0,$b1,$a8,$b2,$a4,$4f
    db $a0,$a6,$a0,$a8,$ad,$e8,$e8,$e8,$00

CreditsTitle1:
    db $93,$a7,$a4,$99,$99,$80,$99,$99,$86,$ab,$a8,$b3,$a2,$a7,$e0,$b2,$4f
    db $80,$af,$b1,$a8,$ab,$7f,$85,$ae,$ae,$ab,$b2,$7f,$f8,$f6,$f7,$ff,$4f
    db $7f,$7f,$72,$93,$b1,$ae,$b4,$a1,$ab,$a4,$7f,$a8,$ad,$4f
    db $7f,$86,$ab,$a8,$b3,$a2,$a7,$7f,$88,$b2,$ab,$a0,$ad,$a3,$b2,$73,$00

CreditsDexText:
    db $8f,$ae,$aa,$ea,$ac,$ae,$ad,$7f,$b2,$a4,$a4,$ad,$9c,$7f,$7f
CreditsDexTextSeen:
    db $7f,$7f,$7f
    db $4f
    db $8f,$ae,$aa,$ea,$ac,$ae,$ad,$7f,$ae,$b6,$ad,$a4,$a3,$9c,$7f
CreditsDexTextCaught:
    db $7f,$7f,$7f
    db $00

CreditsFinalText:
    db $93,$a7,$a0,$ad,$aa,$7f,$b8,$ae,$b4,$7f,$a5,$ae,$b1,$4f
    db $af,$ab,$a0,$b8,$a8,$ad,$a6,$e7,$7f,$92,$a4,$a4,$7f,$b8,$ae,$b4,$4f
    db $a8,$ad,$7f,$f8,$f6,$f8,$f6,$e7,$00

CreditsTheEndText:
    db $93,$7f,$87,$7f,$84,$7f,$7f,$7f,$7f,$84,$7f,$8d,$7f,$83,$00