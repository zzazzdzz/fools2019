; *** bankswitch.asm
; Functions related to SRAM bank management.

; All of these routines are copied to $D920.

SwitchToSRA2 equs "($d920 + (_SwitchToSRA2 - BankswitchCode))"
SwitchToSRA3 equs "($d920 + (_SwitchToSRA3 - BankswitchCode))"
SwitchSRAMBank equs "($d920 + (_SwitchSRAMBank - BankswitchCode))"
LdFromSRAMBank equs "($d920 + (_LdFromSRAMBank - BankswitchCode))"
CallInSRAMBank equs "($d920 + (_CallInSRAMBank - BankswitchCode))"
PrepareSRAMCall equs "($d920 + (_PrepareSRAMCall - BankswitchCode))"
wCallInSRAMBankPtr equs "($d920 + (_wCallInSRAMBankPtr - BankswitchCode))"
wCallInSRAMBankWhich equs "($d920 + (_wCallInSRAMBankWhich - BankswitchCode))"
wCallInSRAMBankParent equs "($d920 + (_wCallInSRAMBankParent - BankswitchCode))"

BankswitchCode:

; Switches to SRAM bank in A
; (Includes dedicated parameterless functions to switch to SRA2/SRA3)

_SwitchToSRA2:
    ld a, 2
_SwitchSRAMBank:
    ld [wCurrentSRAMBank], a
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ret
_SwitchToSRA3:
    ld a, 3
    jr _SwitchSRAMBank

; Loads an 8-bit value from HL at SRAM bank in A
; Returns in C

_LdFromSRAMBank:
    call SwitchSRAMBank
    ld c, [hl]
    ld a, 2
    jr _SwitchSRAMBank

; Prepare CallInSRAMBank - make it execute DE in bank A
; Self modifying code is used to preserve WRAM space

_PrepareSRAMCall:
    ld [wCallInSRAMBankWhich], a
    ld hl, wCallInSRAMBankPtr
    ld [hl], e
    inc hl
    ld [hl], d
    ret

; Executes the function set up by CallInSRAMBank
; Makes sure to preserve the caller's SRAM bank

_CallInSRAMBank:
    push af
    db $3e ; ld a, ...
_wCallInSRAMBankWhich:
    db 0
    call SwitchSRAMBank
    pop af
    db $cd ; call ...
_wCallInSRAMBankPtr:
    dw 0
    db $3e ; ld a, ...
_wCallInSRAMBankParent:
    db 2
    jr _SwitchSRAMBank
    
; Copies the bank management routines to WRAM at $D920

PrepareBankswitchCode:
    ld bc, 52
    ld hl, BankswitchCode
    ld de, $d920
    jp CopyBytes