; *** utils.asm
; Common functions.

sPutStringSourceSRAMBank:
    db 0

; Read a string from 2:DE and place it at HL.

PutString:
    ld a, 2
    ; fall through to PutStringFromSRAMBank
    
; Read a string from A:DE and place it at HL.

PutStringFromSRAMBank:
    ld [sPutStringSourceSRAMBank], a
_PutString:
    push bc
    push hl
    ld bc, 20
.printChr
    ld a, [sPutStringSourceSRAMBank]
    cp 2
    ld a, [de]
    call nz, .elaborateMachinery
    inc de
    cp $50
    jr z, .finished
    cp $4f
    jr z, .nextLine
    ld [hli], a
    jr .printChr
.nextLine
    pop hl
    add hl, bc
    push hl
    jr .printChr
.finished
    pop hl
    pop bc
    ret
.elaborateMachinery
    push hl
    push bc
    ld h, d
    ld l, e
    ld a, [sPutStringSourceSRAMBank]
    call LdFromSRAMBank
    ld a, c
    pop bc
    pop hl
    ret

; Plays music ID A.

SimplePlayMusic:
    push hl
    ld hl, wMusicFadeID
    ld [hl], a
    dec hl
    dec hl
    ld [hl], 1
    pop hl
    ret
    
; Checks BC == DE. Returns result in ZF.

CompareBCToDE:
    ld a, b
    cp d
    jr nz, .nope
    ld a, c
    cp e
    jr nz, .nope
    ret
.nope
    rlca
    ret
    
; Print Ath VWF text from an array of textbox pointers at HL.

TextboxTable:
    ld c, a
    ld b, 0
    add hl, bc
    add hl, bc
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jp PrintTextVWF

; Checks if the player has a specific Pokémon. Sets wScriptVar accordingly.

HasMonInParty:
    ld a, [wScriptVar]
    ld d, a
    ld hl, wPartySpecies
.loop
    ld a, [hli]
    cp d
    jr z, .has
    cp $ff
    jr nz, .loop
.hasNot
    xor a
    jr .exit
.has
    ld a, 1
.exit
    ld [wScriptVar], a
    ret

; Checks if the checksum of first 0x3F00 ROM bytes matches Crystal v1.0.
; The checksum is extremely simple, ADD + XOR based.
; Returns result in ZF.

CheckROM:
    ld hl, $0000
    ld bc, $3f00
    ld de, $0000
.loop
    ld a, [hl]
    xor d
    ld d, a
    ldi a, [hl]
    add e
    ld e, a
    dec bc
    ld a, c
    or b
    jr nz, .loop
    ld bc, $42B2
    jp CompareBCToDE

; Jumps to UnmissingnedAnimation in SRA0.
; A convenience function to make scripting easier.

RescuedSequenceTrampoline:
    prepare_sram_call 0, UnmissingnedAnimation
    jp CallInSRAMBank

; Jumps to VerboseBagFuck in SRA0.
; A convenience function to make scripting easier.

VerboseBagFuckTrampoline:
    prepare_sram_call 0, VerboseBagFuck
    jp CallInSRAMBank

; Start playing a custom radio channel. Takes an array of radio lines in HL.
; The array can be either terminated with 0xFF00, which will hang and wait
; for a B press, or with 0x0000, which will fake a game crash for 100 frames
; then close the textbox.

PlayRadioChannel:
    push hl
    ld hl, wOptions
    ld a, [hl]
    push af
    set 4, [hl]
    ld a, b_NextRadioLine
    rst $10
    xor a
    ld [wRadioTextDelay], a
    ld [wNumRadioLinesPrinted], a
    pop af
    pop hl
    push af
.goNext
    ld a, [hli]
    ld c, a
    ld a, [hli]
    and a
    jr z, .exit
    cp $ff
    jr z, .waitForExit
    push hl
    ld h, a
    ld l, c
    call NextRadioLine
    ld c, 100
.delayLoop
    call JoyTextDelay
    ldh a, [hJoyPressed]
    and %00000010
    pop hl
    jr nz, .exitNoCrash
    push hl
    call DelayFrame
    dec c
    jr nz, .delayLoop
    call RadioScroll + 9
    pop hl
    jr .goNext
.exit
    xor a
    ld [wMusicPlaying], a
    ld c, 100
    call DelayFrames
.exitNoCrash
    ld a, 1
    ld [wMusicPlaying], a
    call RestartMapMusic
    pop af
    ld [wOptions], a
    ret
.waitForExit
    call DelayFrame
    ldh a, [hJoypadDown]
    and %00000010
    jr z, .waitForExit
    jr .exitNoCrash

; Some custom radio channel strings. 

RadioBirdText:
    db 0
    db $4f,$81,$88,$91,$83 ; BIRD
    db $57
RadioSundayText:
    db 0
    db $4f,$93,$ae,$a3,$a0,$b8,$d4,$7f,$92,$94,$8d,$83,$80,$98,$f4 ; Today's SUNDAY, 
    db $57
BootlegRadioText1:
    db 0
    db $4f,$8b,$85,$7f,$88,$92,$7f,$92,$88,$8d,$86,$88,$8d,$86 ; LF IS SINGING
    db $57
BootlegRadioText2:
    db 0
    db $4f,$89,$7f,$88,$92,$7f,$8a,$84,$89,$88 ; J IS KEJI
    db $57
BootlegRadioText3:
    db 0
    db $4f,$93,$8e,$83,$80,$98,$7f,$88,$92,$7f,$fd,$96,$84,$8a ; TODAY IS 7WEK
    db $57
BootlegRadioText4:
    db 0
    db $4f,$84,$8b,$85,$92,$7f,$80,$91,$84,$7f,$85,$88,$8d,$84 ; ELFS ARE FINE
    db $57
BootlegRadioText5:
    db 0
    db $4f,$84,$8b,$85,$e7,$e7 ; ELF!!
    db $57

; The startbattle command returns execution back to where it was called once
; the battle ends. The problem is that our script buffer is in wOTPartyMons,
; so after the battle whatever we were executing is long gone.
; In order to solve this, a small stub of script bytecode is copied to $C020,
; which takes care of reloading the script to RAM once the battle finishes.

; Start a "losable" battle (reloadmap instead of reloadmapafterbattle).

PrepareStartBattleLosable:
    ld a, reloadmap_command
    jr PrepareStartBattle_Copy
    
; Start a normal battle.

PrepareStartBattle:
    ld a, reloadmapafterbattle_command
    ; fall through to PrepareStartBattle_Copy

PrepareStartBattle_Copy:
    ld [.reloadType], a
    ld hl, .script
    ld de, $c020
    ld bc, 32
    jp CopyBytes
.script
    callasm BackupCurrentScript
    startbattle
.reloadType
    reloadmapafterbattle
    callasm SwitchToSRA2
    callasm RestoreCurrentScript
    return

; Copy currently executed script to sScratchBank1.

BackupCurrentScript:
    prepare_sram_call 1, CopyBytes
    ld hl, wScriptTempLocation
    ld de, sScratchBank1
    ld bc, 256
    jp CallInSRAMBank

; Restore currently executed script from sScratchBank1.

RestoreCurrentScript:
    prepare_sram_call 1, CopyBytes
    ld hl, sScratchBank1
    ld de, wScriptTempLocation
    ld bc, 256
    call CallInSRAMBank
    xor a
    ld [wReturnFromTrainerBattle], a
    ret

; Write B to SRA3:HL.

BToHLAtSRA3:
    ; Writing single bytes to SRA3/SRA1 is so rare that it's not worth
    ; to waste WRAM for a specialized routine. Instead we'll just do a
    ; sneaky ROP chain.
    ld a, 3
    jr BToHLAtSRA
    
; Write B to SRA1:HL.

BToHLAtSRA1:
    ld a, 1
    ; fall through to BToHLAtSRA

BToHLAtSRA:
    ld de, SwitchToSRA2
    push de
    ld de, $1FEE ; ld [hl], b; ret
    push de
    jp SwitchSRAMBank

; Do post-ending stuff, that is:
; - Force all maps to play MUSIC_POST_CREDITS
; - Allow saving the game if it wasn't already

PostEnding:
    ld hl, NumberOfMaps
    ld a, 3
    call LdFromSRAMBank
    ld hl, MapHeaderEntries + 6
.loop
    ld [hl], MUSIC_POST_CREDITS
    ld de, 9
    add hl, de
    dec c
    jr nz, .loop
    ld a, 1
    ld [wSaveAllowed], a
    ld bc, 100
    ld hl, MapHeaderEntries
    ld de, $DB79
    jp CopyBytes

; Displays a mart menu. Set wMartPointer before use.

DisplayMart:
    ld a, 1
    ld [wMartPointerBank], a
    xor a
    ld [wEngineBuffer1], a
    ld [wEngineBuffer5], a
    ld [wBargainShopFlags], a
    ld [wFacingDirection], a
    ld hl, wCurMart
    ld bc, wCurMartEnd - wCurMart
    call ByteFill
    ld a, b_StandardMart
    rst $10
    jp StandardMart

; Obtain the player facing that is the reverse of the current one, return in A.
; Only used in the anticheat routine to calculate where to push the player.

GetOppositePlayerFacing:
    ld a, [wPlayerFacing]
    and %11111100
    rra
    rra
    ld hl, .facingTable
    ld b, 0
    ld c, a
    add hl, bc
    ld a, [hl]
    ret
.facingTable
    db $40, $80, $10, $20

; To make up for the rather short gameplay time of the hack, all Pokémon gain
; boosted experience; this is accomplished by force setting their IDs to 0.
; Here's the routine that does just that.

ZeroOutPlayerIDs:
    xor a
    ld hl, wPartyMon1ID
    ld bc, wPartyMon2ID - wPartyMon1ID - 1
    ld d, 6
.loop
    ld [hli], a
    ld [hl], a
    add hl, bc
    dec d
    jr nz, .loop
    ret
