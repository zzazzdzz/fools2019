; *** generic_scripts.asm
; Some commonly used map scripts and data.

; A generic script that displays VWF text.

GenericTextboxScript:
    faceplayer
    opentext
    writetext MapWriteTextInSRAM
    waitbutton
    closetext
    return

; A generic Yes/No textbox.

GenericYesNoBoxset:
    db $98,$a4,$b2,$4f
    db $8d,$ae,$50

; A generic No/Yes textbox.

GenericNoYesBoxset:
    db $8d,$ae,$4f
    db $98,$a4,$b2,$50

; This error handler text is displayed when no valid script is found for an
; overworld event, like an NPC or sign.

UndefinedEventErrorHandlerText:
    text "Guess what we have here?"
    next "An undefined text script!"
    para "That's probably a bug. Either"
    next "that, or you're just a dirty"
    cont "hacker."
    para "If you got here without"
    next "hacking, please let me know!"
    done

; Map blocks for a typical 4x4 house. Used in pretty much every map, so they
; are included here.

GenericHouseBlocks:
    db $04, $03, $05, $1D
    db $0F, $01, $02, $0F
    db $0F, $0C, $0D, $0F
    db $06, $0B, $0F, $07
