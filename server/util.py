# util.py

import json
import hashlib
import binascii
import os
import random
import time

import urllib3
import urllib.parse

import config
import storage

HEADERS_CORS = [
    ('Access-Control-Allow-Origin', '*'),
    ('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
]
HEADERS_HTML = [
    ('Content-Type', 'text/html')
]
HEADERS_TEXT = [
    ('Content-Type', 'text/plain')
]
HEADERS_JSON = [
    ('Content-Type', 'application/json')
]

def translate_charset(text, chrA, chrB, terminator):
    if isinstance(text, str):
        text = bytes(text, 'ascii')
    res = []
    for i in text:
        if i == terminator:
            break
        if i not in chrA:
            continue
        res.append(chrB[chrA.index(i)])
    return bytes(res)
    
CHARSET_ASCII = b''.join([
    b"_ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    b"abcdefghijklmnopqrstuvwxyz!",
    b",?\"-.:() ~$'/0123456789%"
])

CHARSET_ENHANCED = bytes(range(0, 256))

CHARSET_STANDARD = b''.join([
    b"\x00",
    b"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91",
    b"\x92\x93\x94\x95\x96\x97\x98\x99\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9",
    b"\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xe7\xf4",
    b"\xe6\x00\xe3\xe8\x9c\x9a\x9b\x7f\x01\xf0\xe0\xf3\xf6\xf7\xf8\xf9\xfa\xfb",
    b"\xfc\xfd\xfe\xff\xba"
])

def to_enhanced_charset(text):
    return translate_charset(text, CHARSET_ASCII, CHARSET_ENHANCED, 0x00) + b'\xf6'
def from_enhanced_charset(text):
    return translate_charset(text, CHARSET_ENHANCED, CHARSET_ASCII, 0xf6)
def to_standard_charset(text):
    return translate_charset(text, CHARSET_ASCII, CHARSET_STANDARD, 0x00) + b'\x50'
def from_standard_charset(text):
    return translate_charset(text, CHARSET_STANDARD, CHARSET_ASCII, 0x50)
def to_enhanced_charset_unterminated(text):
    return translate_charset(text, CHARSET_ASCII, CHARSET_ENHANCED, 0x00)

class DotDict(dict):
    __getattr__ = dict.get
    __setattr__ = dict.__setitem__
    __delattr__ = dict.__delitem__

def json_bytes(x):
    return bytes(json.dumps(x), 'utf-8')
    
def password_hash(x):
    return hashlib.sha256(bytes(x, 'utf-8') + config.PASSWORD_SALT).hexdigest()
    
def new_session_key():
    return binascii.hexlify(os.urandom(64)).decode('ascii')

def new_fun_value():
    return random.randrange(0, 256)

def new_save_file_name(identifier):
    if isinstance(identifier, int):
        identifier = str(identifier)
    return hashlib.sha1(bytes(identifier, 'utf-8') + config.SECRET_KEY).hexdigest()

def set_bit_in_bitfield(arr, bit):
    byte_no = bit // 8
    bit_no = bit % 8
    arr[byte_no] |= (1 << bit_no)

def get_json_post(environ):
    data_len = int(environ.get('CONTENT_LENGTH', 0))
    data = environ['wsgi.input'].read(data_len)
    data = urllib.parse.parse_qs(
        data.decode('utf-8'),
        keep_blank_values=True
    )
    result = DotDict()
    for k, v in data.items():
        result[k] = urllib.parse.unquote(v[0])
    return result

def err_json(message):
    return json_bytes({
        "success": False,
        "message": message
    })

def recaptcha_verify(token):
    if config.RECAPTCHA_SECRET == "bepis":
        return True
    http = urllib3.PoolManager()
    r = http.request(
        "POST",
        "https://www.google.com/recaptcha/api/siteverify",
        fields={
            "secret": config.RECAPTCHA_SECRET,
            "response": token
        }
    )
    result = json.loads(r.data)
    return result['success']

def create_starter_save():
    return {
        "party": [],
        "dex": {
            "seen": [False] * 256,
            "caught": [False] * 256
        },
        "items": {
            "tms_hms": [],
            "items": [],
            "balls": [],
            "key_items": []
        },
        "events": [False] * 224,
        "money": 0,
        "playername": "AAAAAAAAAAAAAAA="
    }

def unix_time():
    return int(time.time())

def get_save_id(username, kingdom, visit_started):
    hash_str = bytes(username, "utf-8") + config.SECRET_KEY +  b"_save_id"
    if kingdom != 'pwnage04':
        hash_str += bytes(str(visit_started), 'ascii')
    h = hashlib.sha1(hash_str).hexdigest()
    sid = [
        int(h[3:5], 16),
        int(h[7:9], 16),
        int(h[11:13], 16),
        int(h[15:17], 16)
    ]
    return sid

def time_delta(x, y):
    diff = unix_time() - x
    if diff >= y:
        return 0
    else:
        return y - diff

def get_compiler_session(user_id):
    q = storage.sql("""
        SELECT
            users.username AS username,
            users.fun AS fun,
            users.rtc AS rtc,
            progress.starter AS starter,
            progress.save_blob AS save,
            progress.visited_kingdoms AS kingdoms,
            progress.cur_kingdom AS cur_kingdom,
            progress.cur_visit_started AS visit_started,
            progress.laylah_blessing AS laylah_blessing
        FROM users
        LEFT OUTER JOIN progress ON progress.user_id = users.id
        WHERE users.id = ?
    """, (user_id,))[0]
    visited_kingdoms = json.loads(q.kingdoms)
    kingdom = q.cur_kingdom
    kingdom_undecorated = kingdom
    if kingdom in config.DUAL_KINGDOMS:
        if kingdom in visited_kingdoms:
            kingdom += "_post"
        else:
            kingdom += "_pre"
    return {
        "user": q.username,
        "fun": q.fun,
        "rtc": q.rtc,
        "starter_species": q.starter,
        "current_kingdom": kingdom,
        "current_kingdom_undecorated": kingdom_undecorated,
        "current_save_id": get_save_id(q.username, kingdom, q.visit_started),
        "current_save": json.loads(q.save),
        "visited_kingdoms": visited_kingdoms,
        "visit_started": q.visit_started,
        "laylah_blessing": q.laylah_blessing
    }

def get_real_ip(environ):
    return environ.get("HTTP_X_REAL_IP", environ.get("REMOTE_ADDR", ""))
