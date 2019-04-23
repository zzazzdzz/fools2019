; *** map_utility.asm
; Support functions for the custom map loader and the game engine overall.

; Several variables used by the game engine.
; Remember to update SCRATCH_RAM_AREA_SIZE if more vars are added!

wTempMapGroup:
    db 0
wCurrentMapGroup:
    db 0
wCurrentMapNumber:
    db 0
wTrainerCurrentTheme:
    db 0
wPrintTextVWFSourceBank:
    db 2
wCurrentSRAMBank:
    db 0
wForceSpecificTextboxID:
    db 0
wSpecificTextboxPointer:
    dw 0
wReturnFromTrainerBattle:
    db 0
wSaveAllowed:
    db 0
wCurrentScriptID:
    db 0

; The map callback list.

DummyScriptData:
    db 0
    db 4
    map_callback MAPCALLBACK_NEWMAP, CallbackNewMapScript
    map_callback MAPCALLBACK_SPRITES, CallbackSpritesScript
    map_callback MAPCALLBACK_OBJECTS, CallbackObjectsScript
    map_callback MAPCALLBACK_TILES, CallbackTilesScript

; Script for MAPCALLBACK_NEWMAP callback.
; Removes DMA hijacking just in case (it's gonna be installed later), and
; calls the custom loader.

CallbackNewMapScript:
    callasm SwitchToSRA2
    callasm DMAHijackingBailOut
    callasm LoadMapDataFromSRAM
    callasm SwitchToSRA3
    return

; Script for MAPCALLBACK_SPRITES callback.
; Just redirects execution to CallbackSpritesProc.

CallbackSpritesScript:
    callasm SwitchToSRA2
    callasm CallbackSpritesProc
    callasm SwitchToSRA3
    return

; Script for MAPCALLBACK_OBJECTS callback.
; Just redirects execution to CallbackObjectsProc.

CallbackObjectsScript:
    callasm SwitchToSRA2
    callasm CallbackObjectsProc
    callasm SwitchToSRA3
    return

; Script for MAPCALLBACK_TILES callback.
; Just redirects execution to CallbackTilesProc.

CallbackTilesScript:
    callasm SwitchToSRA2
    callasm CallbackTilesProc
    callasm SwitchToSRA3
    return

; Script for NPCs, signs, coord events, etc.
; Just loads the appropriate script from SRAM.

MapCallScriptInSRAM:
    callasm SwitchToSRA2
    callasm LoadScriptFromSRAM
    end

; After the script is done executing, it will return here.

MapCallScriptInSRAMReturn:
    callasm SwitchToSRA2
    callasm CopyMapSubheaderEntriesToRAM
    end

; Textbox data that writes text in custom VWF font.
; It jumps to ROM in order to bypass an error check which prevents from using
; TX_ASM in RAM.

MapWriteTextInSRAM:
    db $16              ; TX_FAR
    db $07, $49, $4f    ; Go to $4F:4907
    db $50              ; End text
    ; $4F:4907 will jump to $FC84, which will jump here:
    pop de
    call SwitchToSRA2
    jp LoadTextFromSRAM
