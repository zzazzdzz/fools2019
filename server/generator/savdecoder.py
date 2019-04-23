import base64

import generator.util as util
import generator.item_consts as item_consts

rng_x = 0xc2
rng_a = 0x28
rng_b = 0xf5
rng_c = 0x6a

PASSWORD_LENGTH = 432

ACTION_XOR_PRNG = 1
ACTION_SUM_ADD = 2
ACTION_SUM_XOR = 3

PARTY_MON_BLOCK_OFFS = 0
EVENT_FLAGS_BLOCK_OFFS = 144+1
ITEMS_BLOCK_OFFS = 144+1+20+1+3
NICKNAME_BLOCK_OFFS = 144+1+20+1+3+152+1
POKEDEX_BLOCK_OFFS = 144+1+20+1+3+152+1+33+1
SAVE_ID_BLOCK_OFFS = 144+1+20+1+3+152+1+33+1+64+1
MONEY_OFFS = 144+1+20+1
REAL_NAME_BLOCK_OFFS = 283

PARTY_MON_BLOCK_SZ = 144
EVENT_FLAGS_BLOCK_SZ = 20
ITEMS_BLOCK_SZ = 152
NICKNAME_BLOCK_SZ = 33
POKEDEX_BLOCK_SZ = 64
SAVE_ID_BLOCK_SZ = 4

PARTY_MON_BLOCK_KEY = (0x2f, 0xe6, 0x10, 0x8c)
EVENT_FLAGS_BLOCK_KEY = (0xc2, 0x28, 0xf5, 0x6a)
ITEMS_BLOCK_KEY = (0xa6, 0x05, 0x73, 0xef)
NICKNAME_BLOCK_KEY = (0x38, 0xec, 0x7f, 0x2a)
POKEDEX_BLOCK_KEY = (0x15, 0x11, 0xfc, 0x4b)
SAVE_ID_BLOCK_KEY = (0x7c, 0x38, 0x3f, 0xa2)

class SaveParseError(Exception):
    pass

class SpecialSaveDataError(Exception):
    pass

def number_2byte(a, b):
    return a * 256 + b

def number_3byte(a, b, c):
    return a * 256 * 256 + b * 256 + c

def prng_seed(key):
    global rng_x, rng_a, rng_b, rng_c
    x, a, b, c = key
    rng_x = x
    rng_a = a
    rng_b = b
    rng_c = c

def prng_rnd():
    global rng_x, rng_a, rng_b, rng_c
    rng_x = (rng_x + 1) % 256
    rng_a = rng_a ^ rng_c ^ rng_x
    rng_b += rng_a
    rng_b %= 256
    rng_c = ((rng_c + (rng_b >> 1)) % 256) ^ rng_a
    return rng_c

def decrypt_block(offset, size, key):
    global data
    prng_seed(key)
    for i in range(offset, offset + size):
        data[i] ^= prng_rnd()

def verify_subchecksum(offset, size, key, acc, procedure):
    global data
    prng_seed(key)
    for i in range(offset, offset + size):
        acc = procedure(i - offset, acc, data[i], prng_rnd())
    if data[offset + size] != acc:
        raise SaveParseError("subchecksum does not match: offset=%i size=%i :: %.2x != %.2x" % (offset, size, data[offset + size], acc))

def derive_checksum_key(key):
    a = 0xcc ^ key[0]
    b = a ^ key[1]
    c = b ^ key[2]
    d = c ^ key[3]
    return (a, b, c, d)

def verify_global_checksum():
    global data
    s1, s2 = 0x55, 0x55
    for i in range(0, PASSWORD_LENGTH - 6):
        s1 = (s1 + data[i]) % 256
        s2 ^= data[i]
    if s1 != data[-2] or s2 != data[-1]:
        raise SaveParseError("global checksum check failed: %.2x%.2x != %.2x%.2x" % (s1, s2, data[-2], data[-1]))

def subchecksum_first_add_post_second_xor_pre(i, acc, val, rng):
    return (acc + (val ^ rng)) % 256 if i % 2 == 0 else acc ^ val

def subchecksum_first_post_xor_second_post_add(i, acc, val, rng):
    return acc ^ (val ^ rng) if i % 2 == 0 else (acc + (val ^ rng)) % 256

def subchecksum_xor_post(i, acc, val, rng):
    return acc ^ (val ^ rng)

def subchecksum_add_pre(i, acc, val, rng):
    return (acc + val) % 256

def subchecksum_add_post(i, acc, val, rng):
    return (acc + (val ^ rng)) % 256

def subchecksum_xor_post_then_add_post(i, acc, val, rng):
    return ((acc ^ (val ^ rng)) + (val ^ rng)) % 256

def parse_data():
    party_mons = []
    i = PARTY_MON_BLOCK_OFFS
    while data[i] not in (0, 255):
        if len(party_mons) >= 3: break
        mon = {
            "species": data[i],
            "item": data[i+1],
            "moves": [data[i+2], data[i+3], data[i+4], data[i+5]],
            "idno": number_2byte(data[i+6], data[i+7]),
            "exp": number_3byte(data[i+8], data[i+9], data[i+10]),
            "stat_exp": [data[i+11], data[i+12], data[i+13], data[i+14], data[i+15], data[i+16], data[i+17], data[i+18], data[i+19], data[i+20]],
            "ivs": [data[i+21], data[i+22]],
            "happiness": data[i+27],
            "level": data[i+31],
            "unused": data[i+33],
            "cur_hp": number_2byte(data[i+34], data[i+35]),
            "max_hp": number_2byte(data[i+36], data[i+37]),
            "attack": number_2byte(data[i+38], data[i+39]),
            "defense": number_2byte(data[i+40], data[i+41]),
            "speed": number_2byte(data[i+42], data[i+43]),
            "special_attack": number_2byte(data[i+44], data[i+45]),
            "special_defense": number_2byte(data[i+46], data[i+47]),
        }
        party_mons.append(mon)
        i += 48
    i = NICKNAME_BLOCK_OFFS
    for mon in party_mons:
        mon["nickname"] = util.from_standard_charset(data[i:i+11]).decode('ascii')
        i += 11
    i = POKEDEX_BLOCK_OFFS
    dex = {}
    dex["caught"] = [False] + util.bytes_to_bool_array(data[i:i+32])
    dex["seen"] = [False] + util.bytes_to_bool_array(data[i+32:i+64])
    i = ITEMS_BLOCK_OFFS
    items = {"tms_hms": [], "items": [], "balls": [], "key_items": []}
    for x in range(0, 50+7):
        if data[i + x] > 0:
            items["tms_hms"].append((x + 1, data[i + x]))
    i += 57
    i += 1
    for x in range(0, 20 + 1):
        if data[i + x*2] == 0xff: break
        items["items"].append((data[i + x*2], data[i + x*2 + 1]))
    i += 41
    i += 1
    for x in range(0, 25 + 1):
        if data[i + x] == 0xff: break
        items["key_items"].append((data[i + x], 1))
    i += 26
    i += 1
    for x in range(0, 12 + 1):
        if data[i + x*2] == 0xff: break
        items["balls"].append((data[i + x*2], data[i + x*2 + 1]))
    i = EVENT_FLAGS_BLOCK_OFFS
    events = [False] * 64 + util.bytes_to_bool_array(data[i:i+EVENT_FLAGS_BLOCK_SZ])
    i = MONEY_OFFS
    money = number_3byte(data[i], data[i+1], data[i+2])
    i = REAL_NAME_BLOCK_OFFS
    playername = data[i:i+11]
    i = SAVE_ID_BLOCK_OFFS
    save_id = [data[i], data[i+1], data[i+2], data[i+3]]
    return {
        "party": party_mons,
        "dex": dex,
        "items": items,
        "events": events,
        "money": money,
        "playername": base64.b64encode(playername).decode('ascii'),
        "save_id": save_id,
        "special": False
    }

def check_special_kingdom_saves(kingdom):
    global data
    if kingdom == 'pwnage02':
        target_signature = bytes([i ^ 0x3c for i in bytearray.fromhex("04C1E1C9C52B2A47E5212D152AFEFF28")])
        signature = data[EVENT_FLAGS_BLOCK_OFFS:EVENT_FLAGS_BLOCK_OFFS+16]
        if signature != target_signature:
            raise SpecialSaveDataError("signature for pwnage02 does not match")
        return True
    if kingdom == 'pwnage03':
        target_signature = bytes([i ^ 0xcf for i in bytearray.fromhex("E5C51139091904040C0CCD353FC1E1CD")])
        signature = data[EVENT_FLAGS_BLOCK_OFFS:EVENT_FLAGS_BLOCK_OFFS+16]
        if signature != target_signature:
            raise SpecialSaveDataError("signature for pwnage03 does not match")
        return True
    if kingdom == 'pwnage04':
        excluded_bytes = [SAVE_ID_BLOCK_OFFS, SAVE_ID_BLOCK_OFFS+1, SAVE_ID_BLOCK_OFFS+2, SAVE_ID_BLOCK_OFFS+3, SAVE_ID_BLOCK_OFFS+4]
        excluded_bytes += [PASSWORD_LENGTH-1, PASSWORD_LENGTH-2, PASSWORD_LENGTH-3, PASSWORD_LENGTH-4, PASSWORD_LENGTH-5, PASSWORD_LENGTH-6]
        excluded_bytes += [PARTY_MON_BLOCK_OFFS + PARTY_MON_BLOCK_SZ]
        excluded_bytes += [EVENT_FLAGS_BLOCK_OFFS + EVENT_FLAGS_BLOCK_SZ]
        excluded_bytes += [ITEMS_BLOCK_OFFS + ITEMS_BLOCK_SZ]
        excluded_bytes += [NICKNAME_BLOCK_OFFS + NICKNAME_BLOCK_SZ]
        excluded_bytes += [POKEDEX_BLOCK_OFFS + POKEDEX_BLOCK_SZ]
        excluded_bytes += [SAVE_ID_BLOCK_OFFS + SAVE_ID_BLOCK_SZ]
        for i in range(0, len(data)):
            if i in excluded_bytes: continue
            if data[i] != i % 256:
                raise SpecialSaveDataError("pwnage04 failed, byte at index %.3x does not match" % i)
        return True
    return False

def parse(d, kingdom):
    global data
    data = bytearray(d)
    global_key = (data[-6], data[-5], data[-4], data[-3])

    decrypt_block(0, PASSWORD_LENGTH - 6, global_key)
    decrypt_block(PASSWORD_LENGTH - 2, 2, derive_checksum_key(global_key))
    verify_global_checksum()

    decrypt_block(PARTY_MON_BLOCK_OFFS, PARTY_MON_BLOCK_SZ, PARTY_MON_BLOCK_KEY)
    decrypt_block(EVENT_FLAGS_BLOCK_OFFS, EVENT_FLAGS_BLOCK_SZ, EVENT_FLAGS_BLOCK_KEY)
    decrypt_block(ITEMS_BLOCK_OFFS, ITEMS_BLOCK_SZ, ITEMS_BLOCK_KEY)
    decrypt_block(NICKNAME_BLOCK_OFFS, NICKNAME_BLOCK_SZ, NICKNAME_BLOCK_KEY)
    decrypt_block(POKEDEX_BLOCK_OFFS, POKEDEX_BLOCK_SZ, POKEDEX_BLOCK_KEY)
    decrypt_block(SAVE_ID_BLOCK_OFFS, SAVE_ID_BLOCK_SZ, SAVE_ID_BLOCK_KEY)

    verify_subchecksum(PARTY_MON_BLOCK_OFFS, PARTY_MON_BLOCK_SZ, PARTY_MON_BLOCK_KEY, 0x7f, subchecksum_first_add_post_second_xor_pre)
    verify_subchecksum(EVENT_FLAGS_BLOCK_OFFS, EVENT_FLAGS_BLOCK_SZ, EVENT_FLAGS_BLOCK_KEY, 0xc2, subchecksum_xor_post)
    verify_subchecksum(ITEMS_BLOCK_OFFS, ITEMS_BLOCK_SZ, ITEMS_BLOCK_KEY, 0x06, subchecksum_first_post_xor_second_post_add)
    verify_subchecksum(NICKNAME_BLOCK_OFFS, NICKNAME_BLOCK_SZ, NICKNAME_BLOCK_KEY, 0x3c, subchecksum_add_pre)
    verify_subchecksum(POKEDEX_BLOCK_OFFS, POKEDEX_BLOCK_SZ, POKEDEX_BLOCK_KEY, 0xe2, subchecksum_add_post)
    verify_subchecksum(SAVE_ID_BLOCK_OFFS, SAVE_ID_BLOCK_SZ, SAVE_ID_BLOCK_KEY, 0x16, subchecksum_xor_post_then_add_post)

    if check_special_kingdom_saves(kingdom):
        save_id = [data[SAVE_ID_BLOCK_OFFS], data[SAVE_ID_BLOCK_OFFS+1], data[SAVE_ID_BLOCK_OFFS+2], data[SAVE_ID_BLOCK_OFFS+3]]
        return {"special": True, "save_id": save_id}

    d = parse_data()
    return d

def test_save_data(fname='w:/code/fools2019/generator/save8.dmp'):
    with open(fname, 'rb') as fp:
        d = bytearray(fp.read())
    return parse(d)

if __name__ == "__main__":
    print(test_save_data())