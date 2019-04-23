; *** save.asm
; Functions related to saving the game.

; Display a save prompt. Intended to be called from the second stage DMA
; hijacking routine, hence preserving all of the registers, enabling
; interrupts, and returning to a weird location.

SavePrompt:
    push af
    push bc
    push de
    push hl
    ei
    call Text_WaitBGMap
.checkSaveAllowed
    ld a, [wSaveAllowed]
    and a
    jr z, .saveNotAllowed
.areYouSure
    ld hl, SaveAreYouSureText
    ld a, 2
    ld [wPrintTextVWFSourceBank], a
    call PrintTextVWF
    ld bc, $0204
    ld hl, GenericNoYesBoxset
    ld de, $0100
    call DisplayChoiceMenu
    and a
    jr z, .leave
.checkLostMons
    ld a, [wPartyCount]
    cp 4
    jr c, .justSave
.monsWillBeLost
    ld hl, SaveLostMonsText
    ld a, 2
    ld [wPrintTextVWFSourceBank], a
    call PrintTextVWF
    ld bc, $0204
    ld hl, GenericNoYesBoxset
    ld de, $0100
    call DisplayChoiceMenu
    and a
    jr z, .leave
.justSave
    farcall FadeOutPalettes
	farcall LoadMapPalettes
    jp Save
.saveNotAllowed
    ld hl, SaveNotPossibleText
    ld a, 2
    ld [wPrintTextVWFSourceBank], a
    call PrintTextVWF
.leave
    pop hl
    pop de
    pop bc
    pop af
    jp DelayFrame + 6
    
; Some variables for the game saving procedure.

sCurRAMOffset:
    dw 0
sDefaultAcc:
    db 0
sPRNGSeed:
    db 0, 0, 0, 0
sShiftBuffer:
    db 0
sPreserveDE:
    dw 0
sProgressCounter:
    db 0
sProgressTile:
    db 0
    
; Gadgets for the game saving procedure.
; Yep. We ROPing, grab the debugger!
; Reversing this is one of the Pwnage Kingdom challenges.

Gadget_ld_a_de equ $1898
Gadget_inc_de equ $106A
Gadget_add_a equ $3E3D
Gadget_pop_bc equ $08F1
Gadget_ld_c_a equ $0D8E
Gadget_pop_hl equ $0831
Gadget_add_hl_bc equ $1D17
Gadget_ld_a_hli_ld_h_hl_ld_l_a equ $1C85
Gadget_ld_sp_hl equ $1708
Gadget_ld_hli_a equ $2250
Gadget_ld_b_h equ $4404
Gadget_ld_c_l equ $18dc
Gadget_inc_hl equ $1447
Gadget_ld_hl_b equ $1fee
Gadget_inc_at_hl equ $65e1
Gadget_xor_b equ $0933
Gadget_ld_b_a equ $1489
Gadget_inc_a equ $37c2
Gadget_or_at_hl equ $2de0
Gadget_and_a equ $0394
Gadget_ld_a_e equ $18d0
Gadget_ld_hl_d equ $3351
Gadget_pop_bc_pop_de_pop_hl_pop_af equ $09A2
Gadget_pop_af equ $09a5
Gadget_pop_hl_pop_af equ $09a4
Gadget_ld_d_hl equ $5e0c
Gadget_ld_e_a equ $1fa5
Gadget_ld_l_a equ $1c87
Gadget_ld_h_a equ $4257
Gadget_dec_a equ $2ec9
Gadget_dec_de equ $1380
Gadget_ld_de_a equ $4128
Gadget_ld_d_b equ $4d6a
Gadget_ld_a_c equ $2cad

; Some of the gadgets aren't in ROM - let's define them here.

Gadget_ld_a_hli:
    ld a, [hli]
    ret
Gadget_ld_a_hld:
    ld a, [hld]
    ret
Gadget_ld_hl_c:
    ld [hl], c
    ret
Gadget_ld_b_hl:
    ld b, [hl]
    ret
Gadget_add_b:
    add b
    ret
Gadget_srl_a:
    srl a
    ret
Gadget_xor_at_hl:
    xor [hl]
    ret
Gadget_ret_z_pop_hl_ret:
    ret z
    pop hl
    ret
Gadget_mysterious:
    nop
    ret

; The saving procedure.

Save:
    call ClearScreen
    call UpdateSprites
    call DMAHijackingBailOut
    ld b, 8
	call GetSGBLayout
	call SetPalettes
    ld hl, wMusicFadeID
    ld [hl], 0
    dec hl
    dec hl
    ld [hl], 8
    ld c, 50
    call DelayFrames
    ld a, 3
	ld [wOptions], a
    ld a, b_Text_SavingDontTurnOffThePower
    rst $10
	ld hl, Text_SavingDontTurnOffThePower
	call PrintText
    ld de, SaveProgressTiles
	ld hl, $8C00
	ld bc, $0104
	call Request1bpp
    call DelayFrame
    ld de, SaveVMInstructions
    di
    call DoubleSpeed
    call Save_AnimateProgress
    ; Start the ROP chain here.
    ld sp, SaveVM
    ret

; Our ROP chain is a special bytecode interpreter for a save virtual machine,
; which supports several operations.

; Main loop of the save VM.

SaveVM:
    dw Gadget_ld_a_de
    dw Gadget_inc_de
    dw Gadget_add_a
    dw Gadget_pop_bc
    dw $0000
    dw Gadget_ld_c_a
    dw Gadget_pop_hl
    dw SaveVMJumptable - 2
    dw Gadget_add_hl_bc
    dw Gadget_ld_a_hli_ld_h_hl_ld_l_a
    dw Gadget_ld_sp_hl

; Opcode jumptable for the save VM.

SaveVMJumptable:
    dw Save_OpcodeSetRAMOffset
    dw Save_OpcodeSetDefaultACC
    dw Save_OpcodeCopyFromRAM
    dw Save_OpcodeDone
    dw Save_OpcodePRNGXor
    dw Save_OpcodeShiftLeft
    dw Save_OpcodePRNGSetSeed
    dw Save_OpcodeAddACC
    dw Save_OpcodeXorACC
    dw 0
    dw Save_OpcodeWriteACC
    dw Save_OpcodeRepeat
    dw Save_OpcodeWriteACCToRAM
    dw Save_OpcodeReadACCFromRAM

; Instruction save_op_done
; Exits the interpreter, informs that the game has been saved successfully,
; and hangs the console.

Save_OpcodeDone:
    ; Copy .finalizationRoutine to $CB00 and run it.
    dw Gadget_pop_bc_pop_de_pop_hl_pop_af
    dw $0100
    dw $CB00
    dw .finalizationRoutine
    dw $FF00
    dw CopyBytes
    dw $CB00
.finalizationRoutine
    ld sp, $C100
    call SwitchToSRA3
    ld bc, PASSWORD_LENGTH
    ld de, $A100
    ld hl, $C800
    call CopyBytes
    call SwitchToSRA2
    ld a, 1
    ld [sSaveDataFinalized], a
    call NormalSpeed
    xor a
	ldh [rIF], a
	ld a, %1111 ; enable VBlank, LCDStat, Timer, Serial
	ldh [rIE], a
    ei
    call DelayFrame
    ld de, SFX_SAVE
    call PlaySFX
    ld c, 50
    call DelayFrames
    ld hl, $CB00 + (.saveCompleteText - .finalizationRoutine)
    call PrintTextVWF
    ; Emulators don't usually write SRAM changes to disk immediately.
    ; SAV files are updated either when cartridge RAM is closed, or when
    ; the ROM is closed (which means unloading the ROM/closing the emu).
    ; We can't do much about the latter, but we can at least help with
    ; the first case.
    call CloseSRAM
    ; This does absolutely nothing on the real GBC, but in the online emulator
    ; used for this event, these writes inform the web page that saving was
    ; completed and results can be uploaded to the server.
    ld c, 1
    ld a, 17
    ld [$ff00+c], a
    add a
    ld [$ff00+c], a
    cpl
    ld [$ff00+c], a
    xor a
    ld [$ff00+c], a
.forever
    jr .forever
.saveCompleteText
    text "Save completed. It is now"
    next "safe to turn off your console."
    done

; Animate the save progress.

Save_AnimateProgress:
    ld hl, $9A12
    ld b, $C0
    ld a, [sProgressTile]
    inc a
    and 3
    ld [sProgressTile], a
    add b
    ld b, a
.waitHblank
    ldh a, [rSTAT]
    and %00000011
    jr nz, .waitHblank
    ld [hl], b
    ret

; Instruction save_op_set_ram_addr
; Sets SRC, the copy source pointer.

Save_OpcodeSetRAMOffset:
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_set_acc
; Sets ACC, a register for temporary calculations

Save_OpcodeSetDefaultACC:
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_a_de
    dw Gadget_inc_de
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_copy_byte
; Copies a byte from SRC to the front of the save buffer, then SRC <- SRC+1. 

Save_OpcodeCopyFromRAM:
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_a_hli_ld_h_hl_ld_l_a
    dw Gadget_ld_a_hli
    dw Gadget_ld_b_h
    dw Gadget_ld_c_l
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_hl_c
    dw Gadget_inc_hl
    dw Gadget_ld_hl_b
    dw Gadget_pop_hl
    dw $C800
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_prng_xor
; XORs the front byte of the save buffer with output from a simple PRNG.
; The PRNG in question has a 32-bit state with four 8-bit vars: X, A, B, C.
; Step algorithm is:
; X += 1; A ^= C^X; B += A; C += (B>>1)^A; RETURN C

Save_OpcodePRNGXor:
    dw Gadget_pop_hl
    dw sPRNGSeed
    dw Gadget_inc_at_hl
    dw Gadget_ld_b_hl
    dw Gadget_ld_a_hli ; disguised inc hl 3x, for further obfuscation
    dw Gadget_ld_a_hli
    dw Gadget_ld_a_hli
    dw Gadget_ld_a_hld
    dw Gadget_xor_b
    dw Gadget_ld_b_a
    dw Gadget_ld_a_hld ; disguised dec hl
    dw Gadget_ld_a_hld ; | 
    dw Gadget_inc_hl   ; + disguised ld a, [hl]
    dw Gadget_xor_b
    dw Gadget_ld_hli_a
    dw Gadget_ld_b_a
    dw Gadget_ld_a_hld ; |
    dw Gadget_inc_hl   ; + disguised ld a, [hl]
    dw Gadget_add_b
    dw Gadget_ld_hli_a
    dw Gadget_srl_a
    dw Gadget_ld_b_a
    dw Gadget_ld_a_hld
    dw Gadget_add_b
    dw Gadget_ld_b_a
    dw Gadget_ld_a_hld
    dw Gadget_ld_a_hli
    dw Gadget_xor_b
    dw Gadget_inc_hl
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw $C800
    dw Gadget_xor_at_hl
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_shift
; Rotates the entire save buffer left.
; Also animates the save progress tile along the way.

Save_OpcodeShiftLeft:
    dw Gadget_pop_hl
    dw sProgressCounter
    dw Gadget_ld_a_hld
    dw Gadget_inc_a
    dw Gadget_pop_hl
    dw $07FC ; [] = $c0
    dw Gadget_or_at_hl
    dw Gadget_pop_bc
    dw $C000
    dw Gadget_xor_b
    dw Gadget_pop_hl
    dw sProgressCounter
    dw Gadget_ld_hli_a
    dw Gadget_and_a
    dw Gadget_ret_z_pop_hl_ret
    dw Save_AnimateProgress
    dw Gadget_pop_hl
    dw sPreserveDE
    dw Gadget_ld_a_e
    dw Gadget_ld_hli_a
    dw Gadget_ld_hl_d
    dw Gadget_pop_hl
    dw $C800
    dw Gadget_ld_a_hli
    dw Gadget_pop_hl
    dw sShiftBuffer
    dw Gadget_ld_hli_a
    dw Gadget_pop_bc_pop_de_pop_hl_pop_af
    dw PASSWORD_LENGTH
    dw $C800
    dw $C801
    dw $FF00
    dw CopyBytes
    dw Gadget_pop_hl
    dw sShiftBuffer
    dw Gadget_ld_a_hli
    dw Gadget_pop_hl
    dw $c800 + PASSWORD_LENGTH - 1
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw sPreserveDE
    dw Gadget_ld_a_hli
    dw Gadget_ld_d_hl
    dw Gadget_ld_e_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_prng_set_seed
; Sets the PRNG initial state (X, A, B, C).

Save_OpcodePRNGSetSeed:
    dw Gadget_pop_hl
    dw sPRNGSeed
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_ld_hli_a
    dw Gadget_inc_de
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_acc_add
; Adds the front byte of the save buffer to ACC.

Save_OpcodeAddACC:
    dw Gadget_pop_hl_pop_af
    dw Gadget_mysterious
    dw $8600
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw Save_OpcodeOperationOnACC
    dw Gadget_ld_sp_hl

; Instruction save_op_acc_xor
; XORs the front byte of the save buffer to ACC.

Save_OpcodeXorACC:
    dw Gadget_pop_hl_pop_af
    dw Gadget_mysterious
    dw $AE00
    dw Gadget_ld_hli_a
    ; fall through to Save_OpcodeOperationOnACC

; Common code for two instructions above

Save_OpcodeOperationOnACC:
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_a_hli
    dw Gadget_pop_hl
    dw $C800
    dw Gadget_mysterious
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_acc_write
; Writes ACC to the front byte of the save buffer

Save_OpcodeWriteACC:
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_a_hli
    dw Gadget_pop_hl
    dw $C800
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_write_acc_to_ram
; Writes ACC to memory at SRC.

Save_OpcodeWriteACCToRAM:
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_b_hl
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_a_hli_ld_h_hl_ld_l_a
    dw Gadget_ld_hl_b
    dw Gadget_inc_hl
    dw Gadget_ld_b_h
    dw Gadget_ld_c_l
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_hl_c
    dw Gadget_inc_hl
    dw Gadget_ld_hl_b
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl
    
; Instruction save_op_read_acc_from_ram
; Reads memory at SRC to ACC.

Save_OpcodeReadACCFromRAM:
    dw Gadget_pop_hl
    dw sCurRAMOffset
    dw Gadget_ld_a_hli_ld_h_hl_ld_l_a
    dw Gadget_ld_a_hli
    dw Gadget_pop_hl
    dw sDefaultAcc
    dw Gadget_ld_hli_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; Instruction save_op_rep
; Repeat a block of code N times.

Save_OpcodeRepeat:
    dw Gadget_ld_a_de
    dw Gadget_ld_c_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_ld_b_a
    dw Gadget_inc_de
    dw Gadget_ld_a_de
    dw Gadget_inc_de
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_and_a
    dw Gadget_ret_z_pop_hl_ret
    dw Gadget_ld_sp_hl
    dw Gadget_dec_a
    dw Gadget_dec_de
    dw Gadget_ld_de_a
    dw Gadget_inc_de
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ret_z_pop_hl_ret
    dw Gadget_ld_sp_hl
    dw Gadget_ld_d_b
    dw Gadget_ld_a_c
    dw Gadget_ld_e_a
    dw Gadget_pop_hl
    dw SaveVM
    dw Gadget_ld_sp_hl

; The save VM bytecode follows.

SaveVMInstructions:
    save_op_set_ram_addr wPartyMons
    save_op_set_acc $7f
    save_op_prng_set_seed $2f, $e6, $10, $8c
.copyPartyMons
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_add
    save_op_shift
    save_op_copy_byte
    save_op_acc_xor
    save_op_prng_xor
    save_op_shift
    save_op_rep .copyPartyMons, 144/2
.checksumPartyMons
    save_op_acc_write
    save_op_shift
    save_op_set_ram_addr wEventFlags + 8
    save_op_set_acc $c2
    save_op_prng_set_seed $c2, $28, $f5, $6a
.copyEventFlags
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_xor
    save_op_shift
    save_op_rep .copyEventFlags, 20
.checksumEventFlags
    save_op_acc_write
    save_op_shift
    save_op_set_ram_addr wMoney
.copyMoney
    save_op_copy_byte
    save_op_shift
    save_op_rep .copyMoney, 3
    save_op_set_ram_addr wTMsHMs
    save_op_set_acc $06
    save_op_prng_set_seed $a6, $05, $73, $ef
.copyItems
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_xor
    save_op_shift
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_add
    save_op_shift
    save_op_rep .copyItems, 152/2
.checksumItems
    save_op_acc_write
    save_op_shift
    save_op_set_ram_addr wPartyMonNicknames
    save_op_prng_set_seed $38, $ec, $7f, $2a
    save_op_set_acc $3c
.copyNicknames
    save_op_copy_byte
    save_op_acc_add
    save_op_prng_xor
    save_op_shift
    save_op_rep .copyNicknames, 33
.checksumNicknames
    save_op_acc_write
    save_op_shift
    save_op_set_ram_addr wPokedexCaught
    save_op_set_acc $e2
    save_op_prng_set_seed $15, $11, $fc, $4b
.copyPokedex
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_add
    save_op_shift
    save_op_rep .copyPokedex, 64
.checksumPokedex
    save_op_acc_write
    save_op_shift
    save_op_prng_set_seed $7c, $38, $3f, $a2
    save_op_set_acc $16
    save_op_set_ram_addr $A003 ; SaveID
.copySaveID
    save_op_copy_byte
    save_op_prng_xor
    save_op_acc_xor
    save_op_acc_add
    save_op_shift
    save_op_rep .copySaveID, 4
.checksumSaveID
    save_op_acc_write
    save_op_shift
.randomSeed
    save_op_set_acc 0
    save_op_set_ram_addr $FFE1 ; hRandomAdd
    save_op_copy_byte
    save_op_acc_add
    db 1
    dw SaveVMSetSeedCommand + 1
    save_op_write_acc_to_ram
    save_op_shift
    save_op_set_ram_addr $FFE2 ; hRandomSub
    save_op_copy_byte
    save_op_acc_xor
    save_op_acc_write
    db 1
    dw SaveVMSetSeedCommand + 2
    save_op_write_acc_to_ram
    save_op_shift
    save_op_set_ram_addr $FF04 ; hDIV
    save_op_copy_byte
    save_op_acc_add
    save_op_acc_write
    db 1
    dw SaveVMSetSeedCommand + 3
    save_op_write_acc_to_ram
    save_op_shift
    save_op_set_ram_addr $FF05 ; hDIV
    save_op_copy_byte
    save_op_acc_xor
    save_op_acc_write
    db 1
    dw SaveVMSetSeedCommand + 4
    save_op_write_acc_to_ram
    save_op_shift
SaveVMSetSeedCommand:
    save_op_prng_set_seed $de, $ad, $be, $ef
    ; allow two bytes for checksum
    save_op_shift
    save_op_shift
    ; prepare double byte checksum
    save_op_set_acc $55
    save_op_set_ram_addr $D350
    save_op_write_acc_to_ram
    save_op_write_acc_to_ram
.secondPassEncode
    save_op_set_ram_addr $D350
    save_op_read_acc_from_ram
    save_op_acc_add
    save_op_write_acc_to_ram
    save_op_read_acc_from_ram
    save_op_acc_xor
    save_op_write_acc_to_ram
    save_op_prng_xor
    save_op_shift
    save_op_rep .secondPassEncode, PASSWORD_LENGTH/2 - 3
    save_op_rep .secondPassEncode, PASSWORD_LENGTH/2 - 3 + 1
.writeLastChecksum
    ; derive checksum encryption key
    save_op_set_acc $cc
    db 1
    dw sPRNGSeed
    save_op_acc_xor
    save_op_write_acc_to_ram
    save_op_shift
    save_op_acc_xor
    save_op_write_acc_to_ram
    save_op_shift
    save_op_acc_xor
    save_op_write_acc_to_ram
    save_op_shift
    save_op_acc_xor
    save_op_write_acc_to_ram
    save_op_shift
    save_op_set_ram_addr $D350
    save_op_copy_byte
    save_op_prng_xor
    save_op_shift
    save_op_copy_byte
    save_op_prng_xor
    save_op_shift
    save_op_done

SaveNotPossibleText:
    text "The aura of Missingno.'s"
    next "corruption prevents you from"
    cont "saving..."
    wait

SaveAreYouSureText:
    text "Your game data will now be"
    next "finalized in preparation for"
    cont "transfer to event servers."
    para "Once the process is complete,"
    next "you won't be able to load"
    cont "this save file anymore."
    para "You can always return to"
    next "previously visited kingdoms"
    cont "by downloading fresh save"
    cont "files on the event site."
    para "Do you really wish to"
    next "finalize your save data?"
    done

SaveLostMonsText:
    text "You have more than 3 Pokémon"
    next "in your party."
    para "The data link used for PU"
    next "grid transfers has limited"
    cont "bandwidth."
    para "As a result, any Pokémon in"
    next "your last three party slots"
    cont "will be released forever."
    cont "Is this really what you want?"
    done

SaveProgressTiles:
    db %00011000
    db %00111100
    db %00011000
    db %01000010
    db %01000010
    db %00000000
    db %00011000
    db %00000000
;--
    db %00000000
    db %00011000
    db %00000010
    db %01000111
    db %01000111
    db %00000010
    db %00011000
    db %00000000
;--
    db %00000000
    db %00011000
    db %00000000
    db %01000010
    db %01000010
    db %00011000
    db %00111100
    db %00011000
;--
    db %00000000
    db %00011000
    db %01000000
    db %11100010
    db %11100010
    db %01000000
    db %00011000
    db %00000000
