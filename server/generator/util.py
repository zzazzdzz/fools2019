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
def to_standard_charset_unterminated(text):
    return translate_charset(text, CHARSET_ASCII, CHARSET_STANDARD, 0x00)
def from_standard_charset(text):
    return translate_charset(text, CHARSET_STANDARD, CHARSET_ASCII, 0x50)
def to_enhanced_charset_unterminated(text):
    return translate_charset(text, CHARSET_ASCII, CHARSET_ENHANCED, 0x00)

def bytes_to_bool_array(x):
    result = []
    for b in x:
        for i in range(0, 8):
            result.append(bool((b >> i) & 1))
    return result

def bool_array_to_bytes(x):
    result = [0] * (((len(x) - 1) // 8) + 1)
    for i in range(0, len(x)):
        result[i // 8] |= (int(x[i]) << (i % 8))
    return result