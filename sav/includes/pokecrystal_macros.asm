IF !DEF(POKECRYSTAL_MACROS)
POKECRYSTAL_MACROS SET 1

hlcoord EQUS "coord hl,"
bccoord EQUS "coord bc,"
decoord EQUS "coord de,"

coord: MACRO
; register, x, y[, origin]
	if _NARG < 4
		ld \1, (\3) * SCREEN_WIDTH + (\2) + wTileMap
	else
		ld \1, (\3) * SCREEN_WIDTH + (\2) + \4
	endc
ENDM

dx: MACRO
x = 8 * ((\1) - 1)
rept \1
	db ((\2) >> x) & $ff
x = x + -8
endr
ENDM

dt: MACRO ; three-byte (big-endian)
	dx 3, \1
ENDM

dd: MACRO ; four-byte (big-endian)
	dx 4, \1
ENDM

dd_le: MACRO
	db (\1) & $ff
	db ((\1)>>8) & $ff
	db ((\1)>>16) & $ff
	db ((\1)>>24) & $ff
ENDM

enum_start: MACRO
if _NARG >= 1
__enum__ = \1
else
__enum__ = 0
endc
if _NARG >= 2
__enumdir__ = \2
else
__enumdir__ = +1
endc
ENDM

enum: MACRO
\1 = __enum__
__enum__ = __enum__ + __enumdir__
ENDM

enum_set: MACRO
__enum__ = \1
ENDM

	enum_start

	enum scall_command ; $00
scall: MACRO
	db scall_command
	dw \1 ; pointer
ENDM

	enum farscall_command ; $01
farscall: MACRO
	db farscall_command
	db b_\1
	dw \1
ENDM

	enum ptcall_command ; $02
ptcall: MACRO
	db ptcall_command
	dw \1 ; pointer
ENDM

	enum jump_command ; $03
jump: MACRO
	db jump_command
	dw \1 ; pointer
ENDM

	enum farjump_command ; $04
farjump: MACRO
	db farjump_command
	db b_\1
	dw \1
ENDM

	enum ptjump_command ; $05
ptjump: MACRO
	db ptjump_command
	dw \1 ; pointer
ENDM

	enum ifequal_command ; $06
ifequal: MACRO
	db ifequal_command
	db \1 ; byte
	dw \2 ; pointer
ENDM

	enum ifnotequal_command ; $07
ifnotequal: MACRO
	db ifnotequal_command
	db \1 ; byte
	dw \2 ; pointer
ENDM

	enum iffalse_command ; $08
iffalse: MACRO
	db iffalse_command
	dw \1 ; pointer
ENDM

	enum iftrue_command ; $09
iftrue: MACRO
	db iftrue_command
	dw \1 ; pointer
ENDM

	enum ifgreater_command ; $0a
ifgreater: MACRO
	db ifgreater_command
	db \1 ; byte
	dw \2 ; pointer
ENDM

	enum ifless_command ; $0b
ifless: MACRO
	db ifless_command
	db \1 ; byte
	dw \2 ; pointer
ENDM

	enum jumpstd_command ; $0c
jumpstd: MACRO
	db jumpstd_command
	dw \1 ; predefined_script
ENDM

	enum callstd_command ; $0d
callstd: MACRO
	db callstd_command
	dw \1 ; predefined_script
ENDM

	enum callasm_command ; $0e
callasm: MACRO
	db callasm_command
	if DEF(b_\1)
		db b_\1
	else
		db 1
	endc
	dw \1
ENDM

	enum special_command ; $0f
special: MACRO
	db special_command
	dw (\1Special - SpecialsPointers) / 3
ENDM

	enum ptcallasm_command ; $10
ptcallasm: MACRO
	db ptcallasm_command
	dw \1 ; asm
ENDM

	enum checkmapscene_command ; $11
checkmapscene: MACRO
	db checkmapscene_command
	map_id \1 ; map
ENDM

	enum setmapscene_command ; $12
setmapscene: MACRO
	db setmapscene_command
	map_id \1 ; map
	db \2 ; scene_id
ENDM

	enum checkscene_command ; $13
checkscene: MACRO
	db checkscene_command
ENDM

	enum setscene_command ; $14
setscene: MACRO
	db setscene_command
	db \1 ; scene_id
ENDM

	enum writebyte_command ; $15
writebyte: MACRO
	db writebyte_command
	db \1 ; value
ENDM

	enum addvar_command ; $16
addvar: MACRO
	db addvar_command
	db \1 ; value
ENDM

	enum random_command ; $17
random: MACRO
	db random_command
	db \1 ; input
ENDM

	enum checkver_command ; $18
checkver: MACRO
	db checkver_command
ENDM

	enum copybytetovar_command ; $19
copybytetovar: MACRO
	db copybytetovar_command
	dw \1 ; address
ENDM

	enum copyvartobyte_command ; $1a
copyvartobyte: MACRO
	db copyvartobyte_command
	dw \1 ; address
ENDM

	enum loadvar_command ; $1b
loadvar: MACRO
	db loadvar_command
	dw \1 ; address
	db \2 ; value
ENDM

	enum checkcode_command ; $1c
checkcode: MACRO
	db checkcode_command
	db \1 ; variable_id
ENDM

	enum writevarcode_command ; $1d
writevarcode: MACRO
	db writevarcode_command
	db \1 ; variable_id
ENDM

	enum writecode_command ; $1e
writecode: MACRO
	db writecode_command
	db \1 ; variable_id
	db \2 ; value
ENDM

	enum giveitem_command ; $1f
giveitem: MACRO
if _NARG == 1
	giveitem \1, 1
else
	db giveitem_command
	db \1 ; item
	db \2 ; quantity
endc
ENDM

	enum takeitem_command ; $20
takeitem: MACRO
if _NARG == 1
	takeitem \1, 1
else
	db takeitem_command
	db \1 ; item
	db \2 ; quantity
endc
ENDM

	enum checkitem_command ; $21
checkitem: MACRO
	db checkitem_command
	db \1 ; item
ENDM

	enum givemoney_command ; $22
givemoney: MACRO
	db givemoney_command
	db \1 ; account
	dt \2 ; money
ENDM

	enum takemoney_command ; $23
takemoney: MACRO
	db takemoney_command
	db \1 ; account
	dt \2 ; money
ENDM

	enum checkmoney_command ; $24
checkmoney: MACRO
	db checkmoney_command
	db \1 ; account
	dt \2 ; money
ENDM

	enum givecoins_command ; $25
givecoins: MACRO
	db givecoins_command
	dw \1 ; coins
ENDM

	enum takecoins_command ; $26
takecoins: MACRO
	db takecoins_command
	dw \1 ; coins
ENDM

	enum checkcoins_command ; $27
checkcoins: MACRO
	db checkcoins_command
	dw \1 ; coins
ENDM

	enum addcellnum_command ; $28
addcellnum: MACRO
	db addcellnum_command
	db \1 ; person
ENDM

	enum delcellnum_command ; $29
delcellnum: MACRO
	db delcellnum_command
	db \1 ; person
ENDM

	enum checkcellnum_command ; $2a
checkcellnum: MACRO
	db checkcellnum_command
	db \1 ; person
ENDM

	enum checktime_command ; $2b
checktime: MACRO
	db checktime_command
	db \1 ; time
ENDM

	enum checkpoke_command ; $2c
checkpoke: MACRO
	db checkpoke_command
	db \1 ; pkmn
ENDM

	enum givepoke_command ; $2d
givepoke: MACRO
if _NARG == 2
	givepoke \1, \2, NO_ITEM, FALSE
elif _NARG == 3
	givepoke \1, \2, \3, FALSE
else
	db givepoke_command
	db \1 ; pokemon
	db \2 ; level
	db \3 ; item
	db \4 ; trainer
if \4
	dw \5 ; trainer_name_pointer
	dw \6 ; pkmn_nickname
endc
endc
ENDM

	enum giveegg_command ; $2e
giveegg: MACRO
	db giveegg_command
	db \1 ; pkmn
	db \2 ; level
ENDM

	enum givepokemail_command ; $2f
givepokemail: MACRO
	db givepokemail_command
	dw \1 ; pointer
ENDM

	enum checkpokemail_command ; $30
checkpokemail: MACRO
	db checkpokemail_command
	dw \1 ; pointer
ENDM

	enum checkevent_command ; $31
checkevent: MACRO
	db checkevent_command
	dw \1 ; event_flag
ENDM

	enum clearevent_command ; $32
clearevent: MACRO
	db clearevent_command
	dw \1 ; event_flag
ENDM

	enum setevent_command ; $33
setevent: MACRO
	db setevent_command
	dw \1 ; event_flag
ENDM

	enum checkflag_command ; $34
checkflag: MACRO
	db checkflag_command
	dw \1 ; engine_flag
ENDM

	enum clearflag_command ; $35
clearflag: MACRO
	db clearflag_command
	dw \1 ; engine_flag
ENDM

	enum setflag_command ; $36
setflag: MACRO
	db setflag_command
	dw \1 ; engine_flag
ENDM

	enum wildon_command ; $37
wildon: MACRO
	db wildon_command
ENDM

	enum wildoff_command ; $38
wildoff: MACRO
	db wildoff_command
ENDM

	enum xycompare_command ; $39
xycompare: MACRO
	db xycompare_command
	dw \1 ; pointer
ENDM

	enum warpmod_command ; $3a
warpmod: MACRO
	db warpmod_command
	db \1 ; warp_id
	dw \2 ; map
ENDM

	enum blackoutmod_command ; $3b
blackoutmod: MACRO
	db blackoutmod_command
	dw \1 ; map
ENDM

	enum warp_command ; $3c
warp: MACRO
	db warp_command
	dw \1 ; map
	db \2 ; x
	db \3 ; y
ENDM

	enum readmoney_command ; $3d
readmoney: MACRO
	db readmoney_command
	db \1 ; account
	db \2 ; memory
ENDM

	enum readcoins_command ; $3e
readcoins: MACRO
	db readcoins_command
	db \1 ; memory
ENDM

	enum vartomem_command ; $3f
vartomem: MACRO
	db vartomem_command
	db \1 ; memory
ENDM

	enum pokenamemem_command ; $40
pokenamemem: MACRO
	db pokenamemem_command
	db \1 ; pokemon
	db \2 ; memory
ENDM

	enum itemtotext_command ; $41
itemtotext: MACRO
	db itemtotext_command
	db \1 ; item
	db \2 ; memory
ENDM

	enum mapnametotext_command ; $42
mapnametotext: MACRO
	db mapnametotext_command
	db \1 ; memory
ENDM

	enum trainertotext_command ; $43
trainertotext: MACRO
	db trainertotext_command
	db \1 ; trainer_id
	db \2 ; trainer_group
	db \3 ; memory
ENDM

	enum stringtotext_command ; $44
stringtotext: MACRO
	db stringtotext_command
	dw \1 ; text_pointer
	db \2 ; memory
ENDM

	enum itemnotify_command ; $45
itemnotify: MACRO
	db itemnotify_command
ENDM

	enum pocketisfull_command ; $46
pocketisfull: MACRO
	db pocketisfull_command
ENDM

	enum opentext_command ; $47
opentext: MACRO
	db opentext_command
ENDM

	enum refreshscreen_command ; $48
refreshscreen: MACRO
if _NARG == 0
	refreshscreen 0
else
	db refreshscreen_command
	db \1 ; dummy
endc
ENDM

	enum closetext_command ; $49
closetext: MACRO
	db closetext_command
ENDM

	enum loadbytec2cf_command ; $4a
loadbytec2cf: MACRO
	db loadbytec2cf_command
	db \1 ; byte
ENDM

	enum farwritetext_command ; $4b
farwritetext: MACRO
	db farwritetext_command
	db b_\1
	dw \1
ENDM

	enum writetext_command ; $4c
writetext: MACRO
	db writetext_command
	dw \1 ; text_pointer
ENDM

	enum repeattext_command ; $4d
repeattext: MACRO
	db repeattext_command
	db \1 ; byte
	db \2 ; byte
ENDM

	enum yesorno_command ; $4e
yesorno: MACRO
	db yesorno_command
ENDM

	enum loadmenu_command ; $4f
loadmenu: MACRO
	db loadmenu_command
	dw \1 ; menu_header
ENDM

	enum closewindow_command ; $50
closewindow: MACRO
	db closewindow_command
ENDM

	enum jumptextfaceplayer_command ; $51
jumptextfaceplayer: MACRO
	db jumptextfaceplayer_command
	dw \1 ; text_pointer
ENDM

; if _CRYSTAL
	enum farjumptext_command ; $52
farjumptext: MACRO
	db farjumptext_command
	db b_\1
	dw \1
ENDM
; endc

	enum jumptext_command ; $53
jumptext: MACRO
	db jumptext_command
	dw \1 ; text_pointer
ENDM

	enum waitbutton_command ; $54
waitbutton: MACRO
	db waitbutton_command
ENDM

	enum buttonsound_command ; $55
buttonsound: MACRO
	db buttonsound_command
ENDM

	enum pokepic_command ; $56
pokepic: MACRO
	db pokepic_command
	db \1 ; pokemon
ENDM

	enum closepokepic_command ; $57
closepokepic: MACRO
	db closepokepic_command
ENDM

	enum _2dmenu_command ; $58
_2dmenu: MACRO
	db _2dmenu_command
ENDM

	enum verticalmenu_command ; $59
verticalmenu: MACRO
	db verticalmenu_command
ENDM

	enum loadpikachudata_command ; $5a
loadpikachudata: MACRO
	db loadpikachudata_command
ENDM

	enum randomwildmon_command ; $5b
randomwildmon: MACRO
	db randomwildmon_command
ENDM

	enum loadmemtrainer_command ; $5c
loadmemtrainer: MACRO
	db loadmemtrainer_command
ENDM

	enum loadwildmon_command ; $5d
loadwildmon: MACRO
	db loadwildmon_command
	db \1 ; pokemon
	db \2 ; level
ENDM

	enum loadtrainer_command ; $5e
loadtrainer: MACRO
	db loadtrainer_command
	db \1 ; trainer_group
	db \2 ; trainer_id
ENDM

	enum startbattle_command ; $5f
startbattle: MACRO
	db startbattle_command
ENDM

	enum reloadmapafterbattle_command ; $60
reloadmapafterbattle: MACRO
	db reloadmapafterbattle_command
ENDM

	enum catchtutorial_command ; $61
catchtutorial: MACRO
	db catchtutorial_command
	db \1 ; byte
ENDM

	enum trainertext_command ; $62
trainertext: MACRO
	db trainertext_command
	db \1 ; which_text
ENDM

	enum trainerflagaction_command ; $63
trainerflagaction: MACRO
	db trainerflagaction_command
	db \1 ; action
ENDM

	enum winlosstext_command ; $64
winlosstext: MACRO
	db winlosstext_command
	dw \1 ; win_text_pointer
	dw \2 ; loss_text_pointer
ENDM

	enum scripttalkafter_command ; $65
scripttalkafter: MACRO
	db scripttalkafter_command
ENDM

	enum endifjustbattled_command ; $66
endifjustbattled: MACRO
	db endifjustbattled_command
ENDM

	enum checkjustbattled_command ; $67
checkjustbattled: MACRO
	db checkjustbattled_command
ENDM

	enum setlasttalked_command ; $68
setlasttalked: MACRO
	db setlasttalked_command
	db \1 + 1; object id
ENDM

	enum applymovement_command ; $69
applymovement: MACRO
	db applymovement_command
	db \1 ; object id
	dw \2 ; data
ENDM

	enum applymovement2_command ; $6a
applymovement2: MACRO
	db applymovement2_command
	dw \1 ; data
ENDM

	enum faceplayer_command ; $6b
faceplayer: MACRO
	db faceplayer_command
ENDM

	enum faceobject_command ; $6c
faceobject: MACRO
	db faceobject_command
	db \1 ; object1
	db \2 ; object2
ENDM

	enum variablesprite_command ; $6d
variablesprite: MACRO
	db variablesprite_command
	db \1 - SPRITE_VARS ; byte
	db \2 ; sprite
ENDM

	enum disappear_command ; $6e
disappear: MACRO
	db disappear_command
	db \1 ; object id
ENDM

	enum appear_command ; $6f
appear: MACRO
	db appear_command
	db \1 ; object id
ENDM

	enum follow_command ; $70
follow: MACRO
	db follow_command
	db \1 ; object2
	db \2 ; object1
ENDM

	enum stopfollow_command ; $71
stopfollow: MACRO
	db stopfollow_command
ENDM

	enum moveobject_command ; $72
moveobject: MACRO
	db moveobject_command
	db \1 ; object id
	db \2 ; x
	db \3 ; y
ENDM

	enum writeobjectxy_command ; $73
writeobjectxy: MACRO
	db writeobjectxy_command
	db \1 ; object id
ENDM

	enum loademote_command ; $74
loademote: MACRO
	db loademote_command
	db \1 ; bubble
ENDM

	enum showemote_command ; $75
showemote: MACRO
	db showemote_command
	db \1 ; bubble
	db \2 ; object id
	db \3 ; time
ENDM

	enum turnobject_command ; $76
turnobject: MACRO
	db turnobject_command
	db \1 ; object id
	db \2 ; facing
ENDM

	enum follownotexact_command ; $77
follownotexact: MACRO
	db follownotexact_command
	db \1 ; object2
	db \2 ; object1
ENDM

	enum earthquake_command ; $78
earthquake: MACRO
	db earthquake_command
	db \1 ; param
ENDM

	enum changemap_command ; $79
changemap: MACRO
	db changemap_command
	db \1 ; map_bank
	dw \2 ; map_data_pointer
ENDM

	enum changeblock_command ; $7a
changeblock: MACRO
	db changeblock_command
	db \1 ; x
	db \2 ; y
	db \3 ; block
ENDM

	enum reloadmap_command ; $7b
reloadmap: MACRO
	db reloadmap_command
ENDM

	enum reloadmappart_command ; $7c
reloadmappart: MACRO
	db reloadmappart_command
ENDM

	enum writecmdqueue_command ; $7d
writecmdqueue: MACRO
	db writecmdqueue_command
	dw \1 ; queue_pointer
ENDM

	enum delcmdqueue_command ; $7e
delcmdqueue: MACRO
	db delcmdqueue_command
	db \1 ; byte
ENDM

	enum playmusic_command ; $7f
playmusic: MACRO
	db playmusic_command
	dw \1 ; music_pointer
ENDM

	enum encountermusic_command ; $80
encountermusic: MACRO
	db encountermusic_command
ENDM

	enum musicfadeout_command ; $81
musicfadeout: MACRO
	db musicfadeout_command
	dw \1 ; music
	db \2 ; fadetime
ENDM

	enum playmapmusic_command ; $82
playmapmusic: MACRO
	db playmapmusic_command
ENDM

	enum dontrestartmapmusic_command ; $83
dontrestartmapmusic: MACRO
	db dontrestartmapmusic_command
ENDM

	enum cry_command ; $84
cry: MACRO
	db cry_command
	dw \1 ; cry_id
ENDM

	enum playsound_command ; $85
playsound: MACRO
	db playsound_command
	dw \1 ; sound_pointer
ENDM

	enum waitsfx_command ; $86
waitsfx: MACRO
	db waitsfx_command
ENDM

	enum warpsound_command ; $87
warpsound: MACRO
	db warpsound_command
ENDM

	enum specialsound_command ; $88
specialsound: MACRO
	db specialsound_command
ENDM

	enum passtoengine_command ; $89
passtoengine: MACRO
	db passtoengine_command
	db \1 ; data_pointer
ENDM

	enum newloadmap_command ; $8a
newloadmap: MACRO
	db newloadmap_command
	db \1 ; which_method
ENDM

	enum pause_command ; $8b
pause: MACRO
	db pause_command
	db \1 ; length
ENDM

	enum deactivatefacing_command ; $8c
deactivatefacing: MACRO
	db deactivatefacing_command
	db \1 ; time
ENDM

	enum priorityjump_command ; $8d
priorityjump: MACRO
	db priorityjump_command
	dw \1 ; pointer
ENDM

	enum warpcheck_command ; $8e
warpcheck: MACRO
	db warpcheck_command
ENDM

	enum ptpriorityjump_command ; $8f
ptpriorityjump: MACRO
	db ptpriorityjump_command
	dw \1 ; pointer
ENDM

	enum return_command ; $90
return: MACRO
	db return_command
ENDM

	enum end_command ; $91
end: MACRO
	db end_command
ENDM

	enum reloadandreturn_command ; $92
reloadandreturn: MACRO
	db reloadandreturn_command
	db \1 ; which_method
ENDM

	enum endall_command ; $93
endall: MACRO
	db endall_command
ENDM

	enum pokemart_command ; $94
pokemart: MACRO
	db pokemart_command
	db \1 ; dialog_id
	dw \2 ; mart_id
ENDM

	enum elevator_command ; $95
elevator: MACRO
	db elevator_command
	dw \1 ; floor_list_pointer
ENDM

	enum trade_command ; $96
trade: MACRO
	db trade_command
	db \1 ; trade_id
ENDM

	enum askforphonenumber_command ; $97
askforphonenumber: MACRO
	db askforphonenumber_command
	db \1 ; number
ENDM

	enum phonecall_command ; $98
phonecall: MACRO
	db phonecall_command
	dw \1 ; caller_name
ENDM

	enum hangup_command ; $99
hangup: MACRO
	db hangup_command
ENDM

	enum describedecoration_command ; $9a
describedecoration: MACRO
	db describedecoration_command
	db \1 ; byte
ENDM

	enum fruittree_command ; $9b
fruittree: MACRO
	db fruittree_command
	db \1 ; tree_id
ENDM

	enum specialphonecall_command ; $9c
specialphonecall: MACRO
	db specialphonecall_command
	dw \1 ; call_id
ENDM

	enum checkphonecall_command ; $9d
checkphonecall: MACRO
	db checkphonecall_command
ENDM

	enum verbosegiveitem_command ; $9e
verbosegiveitem: MACRO
if _NARG == 1
	verbosegiveitem \1, 1
else
	db verbosegiveitem_command
	db \1 ; item
	db \2 ; quantity
endc
ENDM

	enum verbosegiveitem2_command ; $9f
verbosegiveitem2: MACRO
	db verbosegiveitem2_command
	db \1 ; item
	db \2 ; var
ENDM

	enum swarm_command ; $a0
swarm: MACRO
	db swarm_command
	db \1 ; flag
	map_id \2 ; map
ENDM

	enum halloffame_command ; $a1
halloffame: MACRO
	db halloffame_command
ENDM

	enum credits_command ; $a2
credits: MACRO
	db credits_command
ENDM

	enum warpfacing_command ; $a3
warpfacing: MACRO
	db warpfacing_command
	db \1 ; facing
	map_id \2 ; map
	db \3 ; x
	db \4 ; y
ENDM

	enum battletowertext_command ; $a4
battletowertext: MACRO
	db battletowertext_command
	db \1 ; memory
ENDM

	enum landmarktotext_command ; $a5
landmarktotext: MACRO
	db landmarktotext_command
	db \1 ; id
	db \2 ; memory
ENDM

	enum trainerclassname_command ; $a6
trainerclassname: MACRO
	db trainerclassname_command
	db \1 ; id
	db \2 ; memory
ENDM

	enum name_command ; $a7
name: MACRO
	db name_command
	db \1 ; type
	db \2 ; id
	db \3 ; memory
ENDM

	enum wait_command ; $a8
waits: MACRO
	db wait_command
	db \1 ; duration
ENDM

farcall: MACRO ; bank, address
	ld a, b_\1
	ld hl, \1
	rst $08
ENDM

dn: MACRO ; nybbles
rept _NARG / 2
	db ((\1) << 4) | (\2)
	shift
	shift
endr
ENDM

coord_event: MACRO
;\1: x: left to right, starts at 0
;\2: y: top to bottom, starts at 0
;\3: scene id: a SCENE_* constant; controlled by setscene/setmapscene
;\4: script pointer
	db \3, \2, \1
	db 0 ; filler
	dw \4
	db 0, 0 ; filler
ENDM

bg_event: MACRO
;\1: x: left to right, starts at 0
;\2: y: top to bottom, starts at 0
;\3: function: a BGEVENT_* constant
;\4: script pointer
	db \2, \1, \3
	dw \4
ENDM

object_event: MACRO
;\1: x: left to right, starts at 0
;\2: y: top to bottom, starts at 0
;\3: sprite: a SPRITE_* constant
;\4: movement function: a SPRITEMOVEDATA_* constant
;\5, \6: movement radius: x, y
;\7, \8: hour limits: h1, h2 (0-23)
;  * if h1 < h2, the object_event will only appear from h1 to h2
;  * if h1 > h2, the object_event will not appear from h2 to h1
;  * if h1 == h2, the object_event will always appear
;  * if h1 == -1, h2 is treated as a time-of-day value:
;    a combo of MORN, DAY, and/or NITE, or -1 to always appear
;\9: color: a PAL_NPC_* constant, or 0 for sprite default
;\10: function: a OBJECTTYPE_* constant
;\11: sight range: applies to OBJECTTYPE_TRAINER
;\12: script pointer
;\13: event flag: an EVENT_* constant, or -1 to always appear
	db \3, \2 + 4, \1 + 4, \4
	dn \6, \5
	db \7, \8
	shift
	dn \8, \9
	shift
	db \9
	shift
	dw \9
	shift
	dw \9
ENDM

trainer: MACRO
;\1: trainer group
;\2: trainer id
;\3: flag: an EVENT_BEAT_* constant
;\4: seen text
;\5: win text
;\6: loss text
;\7: after-battle text
	dw \3
	db \1, \2
	dw \4, \5, \6, \7
ENDM

warp_event: MACRO
;\1: x: left to right, starts at 0
;\2: y: top to bottom, starts at 0
;\3: map id: from constants/map_constants.asm
;\4: warp destination: starts at 1
	db \2, \1, \4
	dw \3
ENDM

; Connections go in order: north, south, west, east
connection: MACRO
;\1: direction
;\2: map name
;\3: map id
;\4: offset of the target map relative to the current map
;    (x offset for east/west, y offset for north/south)

; LEGACY: Support for old connection macro
if _NARG == 6
	connection \1, \2, \3, (\4) - (\5)
else

; Calculate tile offsets for source (current) and target maps
_src = 0
_tgt = (\4) + 3
if _tgt < 0
_src = -_tgt
_tgt = 0
endc

if "\1" == "north"
_blk = \3_WIDTH * (\3_HEIGHT + -3) + _src
_map = _tgt
_win = (\3_WIDTH + 6) * \3_HEIGHT + 1
_y = \3_HEIGHT * 2 - 1
_x = (\4) * -2
_len = CURRENT_MAP_WIDTH + 3 - (\4)
if _len > \3_WIDTH
_len = \3_WIDTH
endc

elif "\1" == "south"
_blk = _src
_map = (CURRENT_MAP_WIDTH + 6) * (CURRENT_MAP_HEIGHT + 3) + _tgt
_win = \3_WIDTH + 7
_y = 0
_x = (\4) * -2
_len = CURRENT_MAP_WIDTH + 3 - (\4)
if _len > \3_WIDTH
_len = \3_WIDTH
endc

elif "\1" == "west"
_blk = (\3_WIDTH * _src) + \3_WIDTH + -3
_map = (CURRENT_MAP_WIDTH + 6) * _tgt
_win = (\3_WIDTH + 6) * 2 + -6
_y = (\4) * -2
_x = \3_WIDTH * 2 - 1
_len = CURRENT_MAP_HEIGHT + 3 - (\4)
if _len > \3_HEIGHT
_len = \3_HEIGHT
endc

elif "\1" == "east"
_blk = (\3_WIDTH * _src)
_map = (CURRENT_MAP_WIDTH + 6) * _tgt + CURRENT_MAP_WIDTH + 3
_win = \3_WIDTH + 7
_y = (\4) * -2
_x = 0
_len = CURRENT_MAP_HEIGHT + 3 - (\4)
if _len > \3_HEIGHT
_len = \3_HEIGHT
endc

else
fail "Invalid direction for 'connection'."
endc

	dw \3
	dw \2_Blocks + _blk
	dw wOverworldMapBlocks + _map
	db _len - _src
	db \3_WIDTH
	db _y, _x
	dw wOverworldMapBlocks + _win
endc
ENDM

note: MACRO
	dn (\1), (\2) - 1
ENDM

sound: MACRO
	note \1, \2
	db \3 ; intensity
	dw \4 ; frequency
ENDM

noise: MACRO
	note \1, \2 ; duration
	db \3 ; intensity
	db \4 ; frequency
ENDM

; MusicCommands indexes (see audio/engine.asm)
	enum_start $d8

	enum notetype_cmd ; $d8
octave: MACRO
	db notetype_cmd - (\1)
ENDM

notetype: MACRO
	db notetype_cmd
	db \1 ; note_length
	if _NARG >= 2
	db \2 ; intensity
	endc
ENDM

	enum pitchoffset_cmd ; $d9
pitchoffset: MACRO
	db pitchoffset_cmd
	dn \1, \2 - 1 ; octave, key
ENDM

	enum tempo_cmd ; $da
tempo: MACRO
	db tempo_cmd
	bigdw \1 ; tempo
ENDM

	enum dutycycle_cmd ; $db
dutycycle: MACRO
	db dutycycle_cmd
	db \1 ; duty_cycle
ENDM

	enum intensity_cmd ; $dc
intensity: MACRO
	db intensity_cmd
	db \1 ; intensity
ENDM

	enum soundinput_cmd ; $dd
soundinput: MACRO
	db soundinput_cmd
	db \1 ; input
ENDM

	enum sound_duty_cmd ; $de
sound_duty: MACRO
	db sound_duty_cmd
	if _NARG == 4
	db \1 | (\2 << 2) | (\3 << 4) | (\4 << 6) ; duty sequence
	else
	db \1 ; LEGACY: Support for one-byte duty value
	endc
ENDM

	enum togglesfx_cmd ; $df
togglesfx: MACRO
	db togglesfx_cmd
ENDM

	enum slidepitchto_cmd ; $e0
slidepitchto: MACRO
	db slidepitchto_cmd
	db \1 - 1 ; duration
	dn \2, \3 ; octave, pitch
ENDM

	enum vibrato_cmd ; $e1
vibrato: MACRO
	db vibrato_cmd
	db \1 ; delay
	db \2 ; extent
ENDM

	enum unknownmusic0xe2_cmd ; $e2
unknownmusic0xe2: MACRO
	db unknownmusic0xe2_cmd
	db \1 ; unknown
ENDM

	enum togglenoise_cmd ; $e3
togglenoise: MACRO
	db togglenoise_cmd
	db \1 ; id
ENDM

	enum panning_cmd ; $e4
panning: MACRO
	db panning_cmd
	db \1 ; tracks
ENDM

	enum volume_cmd ; $e5
volume: MACRO
	db volume_cmd
	db \1 ; volume
ENDM

	enum tone_cmd ; $e6
tone: MACRO
	db tone_cmd
	bigdw \1 ; tone
ENDM

	enum unknownmusic0xe7_cmd ; $e7
unknownmusic0xe7: MACRO
	db unknownmusic0xe7_cmd
	db \1 ; unknown
ENDM

	enum unknownmusic0xe8_cmd ; $e8
unknownmusic0xe8: MACRO
	db unknownmusic0xe8_cmd
	db \1 ; unknown
ENDM

	enum tempo_relative_cmd ; $e9
tempo_relative: MACRO
	db tempo_relative_cmd
	bigdw \1 ; value
ENDM

	enum restartchannel_cmd ; $ea
restartchannel: MACRO
	db restartchannel_cmd
	dw \1 ; address
ENDM

	enum newsong_cmd ; $eb
newsong: MACRO
	db newsong_cmd
	bigdw \1 ; id
ENDM

	enum sfxpriorityon_cmd ; $ec
sfxpriorityon: MACRO
	db sfxpriorityon_cmd
ENDM

	enum sfxpriorityoff_cmd ; $ed
sfxpriorityoff: MACRO
	db sfxpriorityoff_cmd
ENDM

	enum unknownmusic0xee_cmd ; $ee
unknownmusic0xee: MACRO
	db unknownmusic0xee_cmd
	dw \1 ; address
ENDM

	enum stereopanning_cmd ; $ef
stereopanning: MACRO
	db stereopanning_cmd
	db \1 ; tracks
ENDM

	enum sfxtogglenoise_cmd ; $f0
sfxtogglenoise: MACRO
	db sfxtogglenoise_cmd
	db \1 ; id
ENDM

	enum music0xf1_cmd ; $f1
music0xf1: MACRO
	db music0xf1_cmd
ENDM

	enum music0xf2_cmd ; $f2
music0xf2: MACRO
	db music0xf2_cmd
ENDM

	enum music0xf3_cmd ; $f3
music0xf3: MACRO
	db music0xf3_cmd
ENDM

	enum music0xf4_cmd ; $f4
music0xf4: MACRO
	db music0xf4_cmd
ENDM

	enum music0xf5_cmd ; $f5
music0xf5: MACRO
	db music0xf5_cmd
ENDM

	enum music0xf6_cmd ; $f6
music0xf6: MACRO
	db music0xf6_cmd
ENDM

	enum music0xf7_cmd ; $f7
music0xf7: MACRO
	db music0xf7_cmd
ENDM

	enum music0xf8_cmd ; $f8
music0xf8: MACRO
	db music0xf8_cmd
ENDM

	enum unknownmusic0xf9_cmd ; $f9
unknownmusic0xf9: MACRO
	db unknownmusic0xf9_cmd
ENDM

	enum setcondition_cmd ; $fa
setcondition: MACRO
	db setcondition_cmd
	db \1 ; condition
ENDM

	enum jumpif_cmd ; $fb
jumpif: MACRO
	db jumpif_cmd
	db \1 ; condition
	dw \2 ; address
ENDM

	enum jumpchannel_cmd ; $fc
jumpchannel: MACRO
	db jumpchannel_cmd
	dw \1 ; address
ENDM

	enum loopchannel_cmd ; $fd
loopchannel: MACRO
	db loopchannel_cmd
	db \1 ; count
	dw \2 ; address
ENDM

	enum callchannel_cmd ; $fe
callchannel: MACRO
	db callchannel_cmd
	dw \1 ; address
ENDM

	enum endchannel_cmd ; $ff
endchannel: MACRO
	db endchannel_cmd
ENDM

dbw: MACRO
	db \1
	dw \2
ENDM

musicheader: MACRO
	; number of tracks, track idx, address
	dbw ((\1 - 1) << 6) + (\2 - 1), \3
ENDM

bigdw: MACRO ; big-endian word
	dx 2, \1 ; db HIGH(\1), LOW(\1)
ENDM

notetype1: MACRO
	intensity \1 * 16
ENDM
notetype2: MACRO
	intensity $f0 + \1
ENDM

	enum_start 0, +4

	enum movement_turn_head ; $00
turn_head: MACRO
	db movement_turn_head | \1
ENDM

	enum movement_turn_step ; $04
turn_step: MACRO
	db movement_turn_step | \1
ENDM

	enum movement_slow_step ; $08
slow_step: MACRO
	db movement_slow_step | \1
ENDM

	enum movement_step ; $0c
step: MACRO
	db movement_step | \1
ENDM

	enum movement_big_step ; $10
big_step: MACRO
	db movement_big_step | \1
ENDM

	enum movement_slow_slide_step ; $14
slow_slide_step: MACRO
	db movement_slow_slide_step | \1
ENDM

	enum movement_slide_step ; $18
slide_step: MACRO
	db movement_slide_step | \1
ENDM

	enum movement_fast_slide_step ; $1c
fast_slide_step: MACRO
	db movement_fast_slide_step | \1
ENDM

	enum movement_turn_away ; $20
turn_away: MACRO
	db movement_turn_away | \1
ENDM

	enum movement_turn_in ; $24
turn_in: MACRO
	db movement_turn_in | \1
ENDM

	enum movement_turn_waterfall ; $28
turn_waterfall: MACRO
	db movement_turn_waterfall | \1
ENDM

	enum movement_slow_jump_step ; $2c
slow_jump_step: MACRO
	db movement_slow_jump_step | \1
ENDM

	enum movement_jump_step ; $30
jump_step: MACRO
	db movement_jump_step | \1
ENDM

	enum movement_fast_jump_step ; $34
fast_jump_step: MACRO
	db movement_fast_jump_step | \1
ENDM

__enumdir__ = +1

; Control
	enum movement_remove_sliding ; $38
remove_sliding: MACRO
	db movement_remove_sliding
ENDM

	enum movement_set_sliding ; $39
set_sliding: MACRO
	db movement_set_sliding
ENDM

	enum movement_remove_fixed_facing ; $3a
remove_fixed_facing: MACRO
	db movement_remove_fixed_facing
ENDM

	enum movement_fix_facing ; $3b
fix_facing: MACRO
	db movement_fix_facing
ENDM

	enum movement_show_object ; $3c
show_object: MACRO
	db movement_show_object
ENDM

	enum movement_hide_object ; $3d
hide_object: MACRO
	db movement_hide_object
ENDM

; Sleep

	enum movement_step_sleep ; $3e
step_sleep: MACRO
if \1 <= 8
	db movement_step_sleep + \1 - 1
else
	db movement_step_sleep + 8, \1
endc
ENDM

__enum__ = __enum__ + 8

	enum movement_step_end ; $47
step_end: MACRO
	db movement_step_end
ENDM

	enum movement_step_48 ; $48
step_48: MACRO
	db movement_step_48
	db \1 ; ???
ENDM

	enum movement_remove_object ; $49
remove_object: MACRO
	db movement_remove_object
ENDM

	enum movement_step_loop ; $4a
step_loop: MACRO
	db movement_step_loop
ENDM

	enum movement_step_4b ; $4b
step_4b: MACRO
	db movement_step_4b
ENDM

	enum movement_teleport_from ; $4c
teleport_from: MACRO
	db movement_teleport_from
ENDM

	enum movement_teleport_to ; $4d
teleport_to: MACRO
	db movement_teleport_to
ENDM

	enum movement_skyfall ; $4e
skyfall: MACRO
	db movement_skyfall
ENDM

	enum movement_step_dig ; $4f
step_dig: MACRO
	db movement_step_dig
	db \1 ; length
ENDM

	enum movement_step_bump ; $50
step_bump: MACRO
	db movement_step_bump
ENDM

	enum movement_fish_got_bite ; $51
fish_got_bite: MACRO
	db movement_fish_got_bite
ENDM

	enum movement_fish_cast_rod ; $52
fish_cast_rod: MACRO
	db movement_fish_cast_rod
ENDM

	enum movement_hide_emote ; $53
hide_emote: MACRO
	db movement_hide_emote
ENDM

	enum movement_show_emote ; $54
show_emote: MACRO
	db movement_show_emote
ENDM

	enum movement_step_shake ; $55
step_shake: MACRO
	db movement_step_shake
	db \1 ; displacement
ENDM

	enum movement_tree_shake ; $56
tree_shake: MACRO
	db movement_tree_shake
ENDM

	enum movement_rock_smash ; $57
rock_smash: MACRO
	db movement_rock_smash
	db \1 ; length
ENDM

	enum movement_return_dig ; $58
return_dig: MACRO
	db movement_return_dig
	db \1 ; length
ENDM

	enum movement_skyfall_top ; $59
skyfall_top: MACRO
	db movement_skyfall_top
ENDM

itemball: MACRO
;\1: item: from constants/item_constants.asm
;\2: quantity: default 1
if _NARG == 1
	itemball \1, 1
else
	db \1, \2
endc
ENDM

hiddenitem: MACRO
;\1: item: from constants/item_constants.asm
;\2: flag: an EVENT_* constant
	dwb \2, \1
ENDM

ENDC ; POKECRYSTAL_MACROS