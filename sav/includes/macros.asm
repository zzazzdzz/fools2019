; *** macros.asm
; A bunch of macro definitions.

text   EQUS "db TEXTBOX_START_MARKER," ; Start writing text.
next   EQUS "db $F2," ; Move a line down.
para   EQUS "db $F3," ; Start a new paragraph.
cont   EQUS "db $F1," ; Scroll to the next line.
done   EQUS "db $0"  ; End a text box.
wait   EQUS "db $F4,0"

tx_buf: MACRO
    db $f5
    dw \1
ENDM

tx_buf_end equs "db $f6"
tx_bold equs "db $fa"
tx_medalfanfare equs "db $fb,$00"
tx_kasstheme equs "db $fb,$01"
tx_faceplayer equs "db $fc"
tx_braille equs "db $f8,$8d"
tx_deliria equs "db $f8,$4d"
tx_restartmapmusic equs "db $f0"
tx_paranowait equs "db $f7"

tx_delayframes: MACRO
    db $f6
    db \1
ENDM

tx_snd: MACRO
    db $f8
    db \1
ENDM

tx_flagaction: MACRO
    db $fd
    db \1
ENDM

tx_far: MACRO ; bank, address
    db $fe
    db \1
    dw \2
ENDM

trainer_name: MACRO
    db \1
    db $50
ENDM

trainer_roster: MACRO
    db \1
ENDM

trainer_end: MACRO
    db $ff
ENDM

map_hdr_tileset equs "db 1,"
map_hdr_permission equs "db"
map_hdr_subhdrptr equs "dw"
map_hdr_music equs "db 1,"
map_hdr_pals equs "db $10 | "
map_hdr_fishgroup equs "db"

map_subhdr_border equs "db"
map_subhdr_dimensions: MACRO
    db \2, \1
CURRENT_MAP_WIDTH = \1
CURRENT_MAP_HEIGHT = \2
ENDM
map_subhdr_blocks: MACRO 
    db 1
    dw \1
ENDM
map_subhdr_scripts: MACRO 
    db 1
    dw \1
ENDM
map_subhdr_events equs "dw"
map_subhdr_connections equs "db"

map_callback: MACRO
	db \1
    dw \2
ENDM

prepare_sram_call: MACRO
    ld a, \1
    ld de, \2
    call PrepareSRAMCall
ENDM

prepare_sram_call_safe: MACRO
    push hl
    push de
    prepare_sram_call \1, \2
    pop de
    pop hl
ENDM

script_ptr equs "dw"
textbox_ptr equs "dw"
hybrid_ptr equs "dw $8000 ^ "
unused_ptr equs "dw EmptyScriptReturn"
rawtxt_ptr equs "textbox_ptr"

writetext_vwf: MACRO
    loadvar wSpecificTextboxPointer+0, \1 & $ff
    loadvar wSpecificTextboxPointer+1, (\1 / 256) & $ff
	writetext MapWriteTextInSRAM
ENDM

rel_base: MACRO
purge REL_BASE
REL_BASE equs "\1"
ENDM

rel_base_first: MACRO
REL_BASE equs "\1"
ENDM

SCRIPT_BASE equ $CC14

rel_ptr equs "SCRIPT_BASE - REL_BASE + "

callasm_rel: MACRO
    callasm (\1) - REL_BASE + SCRIPT_BASE
ENDM
iftrue_rel: MACRO
    iftrue (\1) - REL_BASE + SCRIPT_BASE
ENDM
iffalse_rel: MACRO
    iffalse (\1) - REL_BASE + SCRIPT_BASE
ENDM
ifequal_rel: MACRO
    ifequal \1, (\2) - REL_BASE + SCRIPT_BASE
ENDM
jump_rel: MACRO
    jump (\1) - REL_BASE + SCRIPT_BASE
ENDM
scall_rel: MACRO
    scall (\1) - REL_BASE + SCRIPT_BASE
ENDM
applymovement_rel: MACRO
    applymovement \1, (\2) - REL_BASE + SCRIPT_BASE
ENDM

callasm_sra3: MACRO
    callasm SwitchToSRA3
    callasm \1
ENDM

startandwaitbattle: MACRO
    callasm SwitchToSRA2
    callasm PrepareStartBattle
    scall $c020
ENDM

startandwaitbattlelosable: MACRO
    callasm SwitchToSRA2
    callasm PrepareStartBattleLosable
    scall $c020
ENDM

showmart: MACRO
    loadvar wMartPointer, (\1) & $ff
    loadvar wMartPointer + 1, (\1) / 256
    callasm SwitchToSRA2
    callasm DisplayMart
ENDM

showmart_rel: MACRO
    showmart (\1) - REL_BASE + SCRIPT_BASE
ENDM

save_op_set_ram_addr: MACRO
    db 1
    if \1 >= $C000 && \1 < $DE00
        dw \1 + $2000
    else
        dw \1
    endc
ENDM
save_op_set_acc: MACRO
    db 2
    db \1
ENDM
save_op_copy_byte: MACRO
    db 3
ENDM
save_op_done: MACRO
    db 4
ENDM
save_op_prng_xor: MACRO
    db 5
ENDM
save_op_shift: MACRO
    db 6
ENDM
save_op_prng_set_seed: MACRO
    db 7
    db \1, \2, \3, \4
ENDM
save_op_acc_add: MACRO
    db 8
ENDM
save_op_acc_xor: MACRO
    db 9
ENDM
save_op_acc_and: MACRO
    db 10
ENDM
save_op_acc_write: MACRO
    db 11
ENDM
save_op_rep: MACRO
    db 12
    dw \1
    db \2
ENDM
save_op_write_acc_to_ram: MACRO
    db 13
ENDM
save_op_read_acc_from_ram: MACRO
    db 14
ENDM
