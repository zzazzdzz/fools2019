import struct
import time
import base64

import generator.item_consts as item_consts
import generator.util as util

from config import EXTRAS_DIRECTORY

save_base = 0x1200
save = None

def insert_at_player_data(offset, data):
    insert_at(save_base, data)

def insert_at(offset, data):
    global save
    for i in range(0, len(data)):
        save[offset + i] = data[i]

def load_save(x):
    global save
    save = x

def get_save(include_rtc=True):
    global save
    # fix second checksum
    s = sum(save[0x1209:0x1D82+1]) % 65536
    save[0x1f0d] = s % 256
    save[0x1f0e] = s // 256
    if not include_rtc:
        save = save[0:0x8000]
    return save

def write_rtc():
    global save
    rtc = struct.pack(
        "iiiiiiiiiiii",
        0, 0, 10, 0, 0,
        0, 0, 10, 0, 0,
        int(time.time()), 0
    )
    save = save[0:0x8000] + rtc

def num3bytes(x):
    return [(x >> 16) & 0xff, (x >> 8) & 0xff, x & 0xff]

def num2bytes(x):
    return [(x >> 8) & 0xff, x & 0xff]

def encode_standard_item_list(l):
    result = [len(l)]
    for p in l:
        result.append(p[0])
        result.append(p[1])
    result.append(0xff)
    return result

def encode_key_item_list(l):
    result = [len(l)]
    for p in l:
        result.append(p[0])
    result.append(0xff)
    return result

def encode_tms_hms(l):
    result = [0] * 57
    for p in l:
        result[p[0] - 1] = p[1]
    return result

def get_mon_bytes(mon):
    result = [mon['species'], mon['item']]
    result += mon['moves']
    result += num2bytes(mon['idno'])
    result += num3bytes(mon['exp'])
    result += mon['stat_exp']
    result += mon['ivs']
    result += [0, 0, 0, 0]
    result += [mon['happiness']]
    result += [0, 0, 0, mon['level'], 0, 0, 0, 0]
    result += num2bytes(mon['max_hp'])
    result += num2bytes(mon['attack'])
    result += num2bytes(mon['defense'])
    result += num2bytes(mon['speed'])
    result += num2bytes(mon['special_attack'])
    result += num2bytes(mon['special_defense'])
    return result

def get_party_bytes(party):
    result = [len(party)] + [mon['species'] for mon in party]
    while len(result) < 8: result.append(0xff)
    for i in party:
        result += get_mon_bytes(i)
    while len(result) < 296: result.append(0xff)
    for i in range(0, 6):
        result += [0xe6, 0xe6, 0xe6, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50]
    for i in party:
        result += list(util.to_standard_charset(i['nickname']).ljust(11, b'\x50'))
    return result

def get_pokedex_bytes(dex):
    result = util.bool_array_to_bytes(dex["caught"][1:])
    result += util.bool_array_to_bytes(dex["seen"][1:])
    return result

def write_player_data(d):
    insert_at(save_base + 0x54, [0, 0, 0, 0])
    insert_at(save_base + 0x3dc, num3bytes(d['money']))
    insert_at(save_base + 0x420, encode_standard_item_list(d['items']['items']))
    insert_at(save_base + 0x44a, encode_key_item_list(d['items']['key_items']))
    insert_at(save_base + 0x465, encode_standard_item_list(d['items']['balls']))
    insert_at(save_base + 0x3e7, encode_tms_hms(d['items']['tms_hms']))
    insert_at(save_base + 0x865, get_party_bytes(d['party']))
    insert_at(save_base + 0xa27, get_pokedex_bytes(d['dex']))
    insert_at(save_base + 0xd10, [20, 0xff])
    insert_at(save_base + 0x608, util.bool_array_to_bytes(d['events'][64:]))
    insert_at(save_base + 0x3e5, [0xff])
    insert_at(save_base + 0x44a + 15, base64.b64decode(d['playername']))

def check_extras():
    pos = save.find(b"\x55\xA5\x5D\x55\x95\x5F")
    if pos != -1:
        pos += 6
        with open(EXTRAS_DIRECTORY + "/lcg_pattern.bin", "rb") as f:
            key = f.read()
        for i in range(0, 512):
            save[pos+i] ^= key[i]
        return True
    return False