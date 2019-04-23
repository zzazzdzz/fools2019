; *** dma_hijacking.asm
; Manages and implements DMA hijacking. This technique is used in order to
; have fully customizable wild encounters and trainer battles, replace
; the in-game save function, change respawn location after blackout,
; apply a simple walk-through-walls anticheat, and more.

sOriginalReturnAddressLowByte equs "(DMAHijackingCallbackSMC1 + 1)"
sOriginalReturnAddressHighByte equs "(DMAHijackingCallbackSMC1 + 2)"
wDMAHookExecutionCounter equ $c000

sHBufferBackup:
    db 0
sBCBufferBackup:
    dw 0
sRAMBankBackup:
    db 0
sMapGroupTainted:
    db 0
    
; Apply DMA hijacking. Copy the required functions to HRAM and WRAM, and hook
; the DMA copy routine to call these.

ApplyDMAHijacking:
    di
    ld hl, DMAHijackingHRAMProc
    ld de, $ffec
    ld bc, 19
    call CopyBytes
    ld hl, DMAHijackingWRAMProc
    ld de, $c000
    ld bc, 32
    call CopyBytes
    ld hl, $ff80
    ld [hl], $18
    inc hl
    ld [hl], $6a ; jr $ffec
    ei
    ret

; Second stage of the DMA hijacking procedure. This routine is called once
; at the beginning of each frame - this is accomplished by manipulating the
; stack. After vBlank, code execution is resumed from here instead of the
; original return address.

DMAHijackingCallback:
    di
    call DMAHijackingBlackoutCheck
    ; preserve ROM bank, RAM bank and farcall variables
    ldh a, [hROMBank]
	ldh [hROMBankBackup], a
    ldh a, [hBuffer]
    ld [sHBufferBackup], a
    ld a, [wFarCallBCBuffer]
    ld [sBCBufferBackup], a
    ld a, [wFarCallBCBuffer+1]
    ld [sBCBufferBackup+1], a
    ldh a, [rSVBK]
    ld [sRAMBankBackup], a
    ; switch to WRA1
    ld a, 1
	ldh [rSVBK], a
    ; read the original return address
    ld hl, sp + -70
    ld de, DMAHijackingCallbackSMC1 + 1
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ; error check; if we somehow ended up in an infinite loop (return address
    ; is in the DMA hijacking routine), bail out
    cp $c0
    call z, DMAHijackingBailOut
    call DMAHijackingSpoofMap
    ; perform the following actions only if vblank happened during DelayFrame
    ld a, [sOriginalReturnAddressLowByte]
    cp LOW(DelayFrame + 6)
    jr nz, .skip
    ld a, [sOriginalReturnAddressHighByte]
    cp HIGH(DelayFrame + 6)
    jr nz, .skip
    call DMAHijackingPreventSaving
    call DMAHijackingEncounters
    call DMAHijackingAntiCheat
    call DMAHijackingMapRoofsOnMenuExit
.skip
    ld a, [wTrainerCurrentTheme]
    cp $ff
    jr nz, .noDeliria
    ld a, [wChannel1Tempo]
    cp $90
    jr z, .noDeliria
    ; apply Deliria music distortion to the current map if necessary
    xor a
    ld [$c11f], a
    ld [$c151], a 
    ld [$c183], a
    dec a
    ld [$c120], a
    ld [$c152], a
    ld [$c184], a
.noDeliria
    ; prevent phone calls
    ld a, $ff
    ld [wReceiveCallDelay_MinsRemaining], a
    ; restore everything now
    ld [wDMAHookExecutionCounter], a
    ldh a, [hROMBankBackup]
	rst $10
    ld a, [sHBufferBackup]
    ld [hBuffer], a
    ld a, [sBCBufferBackup]
    ld [wFarCallBCBuffer], a
    ld a, [sBCBufferBackup+1]
    ld [wFarCallBCBuffer+1], a
    ld a, [sRAMBankBackup]
	ldh [rSVBK], a
    ; jump to the original return address, also make sure all registers are
    ; preserved
    pop hl
    ld de, DMAHijackingCallbackSMC2 + 1
    ld a, l
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    pop de
    pop bc
    pop af
DMAHijackingCallbackSMC1:
    ld hl, $1337
    push hl
    push af
DMAHijackingCallbackSMC2:
    ld hl, $1337
    jp $C012

; Handles reloading map roof graphics when the Start menu is closed.

DMAHijackingMapRoofsOnMenuExit:
    ld hl, sp + 14
    ld a, [hl]
    cp LOW(FinishExitMenu + 14)
    ret nz
    ld a, 1
    ld [sRoofGraphicsDirectCopy], a
    jp HandleRoofGraphics

; Handles wild encounters and trainer battles.

DMAHijackingEncounters:
    ld hl, sp + 10
    ld a, [hli]
    cp LOW(PlayBattleMusic + 16)
    ret nz
    ld a, [hl]
    cp HIGH(PlayBattleMusic + 16)
    ret nz
    ld hl, sp + 10
    ld [hl], $b1
    call ZeroOutPlayerIDs
    ld a, [wOtherTrainerClass]
    and a
    jp nz, DMAHijacking_TrainerBattle
    ; fall through to DMAHijacking_WildEncounter

; Services wild encounters: loads a random encounter from the current area's
; encounter table, and also adds some cool features!

DMAHijacking_WildEncounter:
    call Random
    and $0f
    ld b, 0
    add a
    ld c, a
    ld a, DATASTRUCT_ENCOUNTERS
    call GetPointerToMapDataStruct
    add hl, bc
    ld a, 3
    call LdFromSRAMBank
    ld a, c
    ld [wTempEnemyMonSpecies], a
    inc hl
    ld a, 3
    call LdFromSRAMBank
    ld a, c
    ld [wCurPartyLevel], a
.determineMusicAndSpecialBattles
    ld c, MUSIC_KANTO_WILD_BATTLE
    call Random
    cp $69
    jr nz, .notShinyBattle
    ; 1/256 shiny encounter with increased level?
    ld a, 7
    ld [wBattleType], a
    ld a, [wCurPartyLevel]
    add 8
    cp 101
    jr c, .notOver100
    ld a, 100
.notOver100
    ld [wCurPartyLevel], a
    ld c, MUSIC_SUICUNE_BATTLE
.notShinyBattle
    ld a, [wTempEnemyMonSpecies]
    cp METAPOD
    jr nz, .notMetapod
    ; hooked metapod battle?
    ld a, 4
    ld [wBattleType], a
    ld c, MUSIC_ROCKET_BATTLE
.notMetapod
    ld hl, sp + 4
    ld [hl], c
    call RestoreMapGroupDMA
    jp DMAHijackingSwitchToBattle

; Check if the current trainer is a Rocket, sets ZF on success.

CheckIsRocket:
    cp GRUNTM
    ret z
    cp GRUNTF
    ret z
    cp EXECUTIVEM
    ret z
    cp EXECUTIVEF
    ret

; Services trainer battles; loads the correct trainer roster and appropriate
; battle music.

DMAHijacking_TrainerBattle:
    ld c, MUSIC_KANTO_TRAINER_BATTLE
    ld a, [wOtherTrainerClass]
    call CheckIsRocket
    jr nz, .notRocket
    ld c, MUSIC_ROCKET_BATTLE
.notRocket
    ld a, [wTrainerCurrentTheme]
    and a
    jr z, .default
    ld c, a
.default
    ld hl, sp + 4
    ld [hl], c
    ld a, DATASTRUCT_TRAINERS
    call GetPointerToMapDataStruct
    ldh a, [hLastTalked]
    ld c, a
    ld b, 0
    dec c
    add hl, bc
    add hl, bc
    call Ld16FromSRA3
    push hl
.clearOTMons
    ld hl, wOTPartyCount
    xor a
    ld [hli], a
    dec a
    ld [hl], a
.writeTrainerName
    ld a, [wOtherTrainerID]
    ld b, a
    ld a, [wOtherTrainerClass]
    ld c, a
    farcall GetTrainerName
    ld hl, wStringBuffer1
    ld de, wOTPlayerName
    ld bc, $B ; NAME_LENGTH
    call CopyBytes
.nameFinished
    prepare_sram_call 3, $57B8 ; ReadTrainerParty.got_trainer
    ld a, b_ReadTrainerParty
	rst $10
    pop hl
    call CallInSRAMBank
    ld hl, wOTPartySpecies
    ld de, wOTPartyMonNicknames
.monNames
    ld a, [hli]
    cp $ff
    jr z, .finish
    push hl
    ld [wNamedObjectIndexBuffer], a
    push de
	call GetPokemonName
    pop de
    ld hl, wStringBuffer1
    ld bc, $B ; NAME_LENGTH
    call CopyBytes
    ld hl, $B ; NAME_LENGTH
    add hl, de
    ld d, h
    ld e, l
    pop hl
    jr .monNames
.finish
    ; this is so our trainer roster won't get overwritten
    ; (wInBattleTowerBattle skips the default trainer data loading routine)
    ld a, 1
    ld [wInBattleTowerBattle], a
    xor a
    ld [wTrainerCurrentTheme], a
    ; ...but we must hijack the stack to clear this flag later, since it
    ; causes some undesirable effects, like disabling usage of items
    ld de, DMAHijackingTrainerBattleTrampoline
    ld hl, sp+24
    ld a, [hli]
    cp $CD
    jr nz, .nope
    ld a, [hl]
    cp $74
    jr nz, .nope
    ld [hl], d
    dec hl
    ld [hl], e
.nope
    jp DMAHijackingSwitchToBattle

; Reset wInBattleTowerBattle and recompute trainer reward after battle starts.

DMAHijackingTrainerBattleTrampoline:
    xor a
    ld [wInBattleTowerBattle], a
    farcall ComputeTrainerReward
    jp $74cd

; Services map spoofing. Because the game takes place on out-of-bounds glitch
; maps, some things like wild encounters just don't work correctly, because
; of error checking. So we cleverly, temporarily spoof the map ID in certain
; situations, to make sure the dreaded error traps don't fire.

DMAHijackingSpoofMap:
    ld hl, wMornEncounterRate
    ld a, $15
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ld a, [$c540]
    cp $0b
    jr nz, .notInKeyItems
    ld a, [$c545]
    cp $7f
    jr z, SpoofMapGroupDMA
.notInKeyItems
    ld a, [wPlayerStandingTile]
    cp $29
    jr z, RestoreMapGroupDMA
    farcall CheckGrassCollision
    jr nc, RestoreMapGroupDMA
    ld a, [$c402]
    and $f0
    cp $80
    jr z, SpoofMapGroupDMA
    ; fall through to RestoreMapGroupDMA
    
; Restore the original map group and number after spoofing.

RestoreMapGroupDMA:
    ld a, [sMapGroupTainted]
    and a
    ret z
    xor a
    ld [sMapGroupTainted], a
    ld a, [wCurrentMapGroup]
    ld [wMapGroup], a
    ld a, [wCurrentMapNumber]
    ld [wMapNumber], a
    ret
    
; Spoof the map group and number by replacing them with $0D01 (Route 1).
    
SpoofMapGroupDMA:
    ld a, 1
    ld [sMapGroupTainted], a
    ld hl, wMapGroup
    ld [hl], $0d
    inc hl
    ld [hl], $01
    ret

; Handles the custom saving routine that should be executed when choosing
; the SAVE option in the Start menu.

DMAHijackingPreventSaving:
    ld a, [$c4cd]
    cp $8f
    ret nz
    ld hl, sp + 18
    ld a, [hli]
    cp LOW(Text_WouldYouLikeToSaveTheGame)
    ret nz
    ld a, [hld]
    cp HIGH(Text_WouldYouLikeToSaveTheGame)
    ret nz
    ; make the save text empty, so our text appears without interruptions
    ld [hl], LOW(EmptyTextbox)
    inc hl
    ld [hl], HIGH(EmptyTextbox)
    ld hl, sp + 22
    ld [hl], $ca
    inc hl
    inc hl
    ld [hl], $4a
    inc hl
    ld [hl], $4a
    ; set 2:SavePrompt as the new return address
    ld hl, SavePrompt
    ld a, l
    ld [sOriginalReturnAddressLowByte], a
    ld a, h
    ld [sOriginalReturnAddressHighByte], a
    ld a, 2
    ld [wCurrentSRAMBank], a
    ret

; Handles blacking out, so the player respawns at a custom location.

DMAHijackingBlackoutCheck:
    ld hl, wScriptBank
    ld a, [hli]
    cp $04
    jr nz, .exit
    ld a, [hli]
    cp $d7
    ret nz
    ld a, [hl]
    cp $64
    ret nz
    ld de, $c020
    ld bc, 32
    ld hl, Script_Blackout
    call CopyBytes
    ld hl, wScriptPos
    ld [hl], $20
    inc hl
    ld [hl], $c0
.exit
    ldh a, [$ffec + 1]
    cp LOW(wScriptPos)
    ret nz
    pop hl ; drop return address
    pop hl
    pop de
    pop bc
    pop af
    ret

; Anticheat system. It checks the tile under the player (in the tilemap, to
; make detection harder) and compares it to the list of unpassable tiles,
; depending on tileset. Player is forcefully pushed back if WTW is detected.

; It was planned to support other tilesets than TILESET_JOHTO, but the idea
; was discarded.

DMAHijackingAntiCheat:
    ld a, [wMapTileset]
    ld hl, BannedTileArrayEmpty
    cp TILESET_JOHTO
    jr nz, .noJohto
    ld hl, BannedTileArrayJohto
.noJohto
    ld a, [$c55d]
    ld b, a
.loop
    ld a, [hli]
    cp $ff
    ret z
    cp b
    jr nz, .loop
.found
    ld a, [wInputType]
    and a
    ret nz
    call GetOppositePlayerFacing
    ld hl, $C020
    push hl
    ld [hli], a
    ld [hl], $00
    inc hl
    ld [hl], $ff
    pop hl
    call StartAutoInput
    ret

BannedTileArrayJohto:
    db $2F, $3F, $16, $02, $26, $0B, $0E, $36, $48, $52, $5F, $1D, $17, $3C
    ; terminator in BannedTileArrayEmpty
BannedTileArrayEmpty:
    db $FF

; Disables the DMA hijacking hook.

DMAHijackingBailOut:
    ld hl, $ff80
    ld [hl], $3e
    inc hl
    ld [hl], $c4
    ret
    
; Copies the in-battle DMA hijacking hook.
; Different procedures are used in battle and in overworld.

DMAHijackingSwitchToBattle:
    ld hl, DMAHijackingInBattleHRAMProc
    ld de, $ffec
    ld bc, 19
    jp CopyBytes

; First stages of the DMA hijacking procedure. Copied to and executed at $FFEC.
; This is executing during vBlank and has to fit in a really confined amount
; of space, so every cycle and byte counts.

; Overworld DMA hijacking routine.

DMAHijackingHRAMProc:
    ld hl, $c000                   ; 12
    inc [hl]                       ; 12
    ret nz                         ; 8
    inc l                          ; 4
    add sp, 2 * 6                  ; 16
    pop bc                         ; 12
    push hl                        ; 16
    add sp, -2 * 37                ; 16
    push bc                        ; 16
    add sp, 2 * 32                 ; 16
    ld a, $c4                      ; 8
    db $18, $83                    ; 12 (jr $ff82)

; In-battle DMA hijacking routine.

DMAHijackingInBattleHRAMProc:
    ld hl, wScriptPos              ; 12
    ld a, [hli]                    ; 8
    cp $d7                         ; 8
    jr nz, .nope                   ; 8/12
    ld a, [hl]                     ; 8
    cp $64                         ; 8
    jp z, $c001                    ; 12/16
.nope
    ld a, $c4                      ; 8
    db $18, $84                    ; 12 (jr $ff82)

; Second stage of the DMA hijacking procedure - WRAM routine.
; Makes sure to select and preserve the appropriate SRAM bank, as well as
; preserve all of the registers.

DMAHijackingWRAMProc:
    ; Reference counter, incremented each time the custom DMA code runs and
    ; resetted every time it ends executing. This prevents infinite loops in
    ; some weird corner cases I don't completely understand (they DID occur).
    db $ff
    ; The actual routine.
    push af
    push bc
    push de
    push hl
    ld a, 2
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    jp DMAHijackingCallback
.return
    ld a, [wCurrentSRAMBank]
    ld [$4000], a
    pop af
    reti
