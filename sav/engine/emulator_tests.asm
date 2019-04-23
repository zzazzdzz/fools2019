; *** emulator_tests.asm
; Simple hardware behavior tests, to make sure the game runs on an accurate
; enough emulator to be playable.

; Check support for echo RAM. Return status in CF.

EchoRAMTest:
    ld b, 0
.loop
    ld a, b
    ld [$d000], a
    ld a, [$d000]
    cp b
    jr nz, .fail
    dec b
    jr nz, .loop
    and a
    ret
.fail
    scf
    ret

; Check VRAM inaccessibility. Return status in CF.

VRAMInaccessibilityTest:
    ld hl, $8111
    ld bc, $ff00
.loop
    ld a, [hl]
    cp $ff
    jr nz, .notFF
    inc c
.notFF
    dec b
    jr nz, .loop
    ld a, c
    and a
    scf
    ret z
    ccf
    ret
    
; Perform all of the checks above. Return status in CF.

CheckEmulationAccuracy:
    call EchoRAMTest
    ret c
    call VRAMInaccessibilityTest
    ret