import rgbbin.logger as logger
import rgbbin.rpn as rpn
import sys

def read(f, args):
    if sys.version_info.major == 2:
        return list(ord(c) for c in f.read(*args))
    else:
        return f.read(*args)

class ObjectParseError(Exception):
    pass

class ParseOrderError(Exception):
    pass

class ParseState():
    NONE_PARSED = 0
    HEADER_PARSED = 1
    SYMBOLS_PARSED = 2
    SECTIONS_PARSED = 3
    PATCHES_PARSED = 4

class ObjectFile():
    def __init__(self, filename):
        self.f = open(filename, "rb")
        self.state = ParseState.NONE_PARSED
        self.sections = []
        self.symbols = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.f.close()

    def read_byte(self):
        q = self.f.read(1)[0]
        return q

    def read_bytes(self, l):
        return self.f.read(l)

    def read_word(self):
        lo, hi = self.read_bytes(2)
        return lo + hi*256

    def read_dword(self):
        lo = self.read_word()
        hi = self.read_word()
        return lo + hi*65536

    def read_string(self):
        result = ""
        r = self.read_byte()
        while r != 0:
            result += chr(r)
            r = self.read_byte()
        return result

    def parse_header(self):
        signature = self.read_bytes(4)
        if sys.version_info.major == 2:
            signature = bytearray(signature)
        if signature not in (b"RGB5", b"RGB6"):
            raise ObjectParseError("not a valid RGBASM 5/6 object file")
        self.symbol_count = self.read_dword()
        self.section_count = self.read_dword()
        self.state = ParseState.HEADER_PARSED

    def parse_symbols(self):
        if self.state < ParseState.HEADER_PARSED:
            raise ParseOrderError("header has to be parsed first")
        for i in range(0, self.symbol_count):
            symbol_name = self.read_string()
            symbol_type = self.read_byte()
            if symbol_type == 1:
                # an external symbol in single-file linking means undefined symbol
                raise ObjectParseError("undefined reference to %s" % symbol_name)
            symbol_file = self.read_string()
            symbol_source = "%s:%i" % (symbol_file, self.read_dword())
            symbol_sectid = self.read_dword()
            symbol_value = self.read_dword()
            logger.verbose("symbol %s defined in %s (id=%i, sectid=%i) = $%.4x"
                % (symbol_name, symbol_source, i, symbol_sectid, symbol_value))
            self.symbols.append({
                'name': symbol_name,
                'sectid': symbol_sectid,
                'value': symbol_value,
                'symid': len(self.symbols)
            })
        self.state = ParseState.SYMBOLS_PARSED

    def parse_sections(self):
        if self.state < ParseState.SYMBOLS_PARSED:
            raise ParseOrderError("symbols have to be parsed first")
        for i in range(0, self.section_count):
            section_name = self.read_string()
            section_size = self.read_dword()
            section_type = self.read_byte()
            section_origin = self.read_dword()
            if section_origin < 0:
                raise ObjectParseError("section %s has no origin set" % section_name)
            section_bank = self.read_dword()
            section_align = self.read_dword()
            if section_type not in (2, 3):
                logger.warn("skipping section %s of unsupported type %i" % section_type)
                continue
            section_data = self.read_bytes(section_size)
            section_patch_count = self.read_dword()
            section_patches = []
            for j in range(0, section_patch_count):
                patch_file = self.read_string()
                patch_line = self.read_dword()
                patch_offset = self.read_dword()
                patch_type = self.read_byte()
                patch_rpnsize = self.read_dword()
                patch_rpn = bytearray(self.read_bytes(patch_rpnsize))
                section_patches.append({
                    "source": "%s:%i" % (patch_file, patch_line),
                    "offset": patch_offset,
                    "type": patch_type,
                    "rpn": patch_rpn
                })
            self.sections.append({
                "name": section_name,
                "origin": section_origin,
                "data": bytearray(section_data),
                "patches": section_patches,
                "sectid": len(self.sections)
            })
            logger.verbose("section %s of size %i at org $%.4x with %i patches"
                % (section_name, section_size, section_origin, section_patch_count))
        self.state = ParseState.SECTIONS_PARSED

    def parse_patches(self):
        if self.state < ParseState.SECTIONS_PARSED:
            raise ParseOrderError("sections have to be parsed first")
        for section in self.sections:
            logger.verbose("applying %i patches for section %s"
                % (len(section['patches']), section['name']))
            for patch in section['patches']:
                value = rpn.parse(self, patch['rpn'])
                if patch['type'] == 0:
                    section['data'][patch['offset']] = value
                elif patch['type'] == 1:
                    section['data'][patch['offset']] = value % 256
                    section['data'][patch['offset']+1] = value // 256
                elif patch['type'] == 2:
                    raise ObjectParseError("unsupported 32-bit dword patch")
                elif patch['type'] == 3:
                    position = section['origin'] + patch['offset'] + 1
                    section['data'][patch['offset']] = value - position
        self.state = ParseState.PATCHES_PARSED

    def parse_all(self):
        self.parse_header()
        self.parse_symbols()
        self.parse_sections()
        self.parse_patches()

    def section_by_name(self, name):
        for i in self.sections:
            if i['name'] == name:
                return i
        return None

    def symbol_by_name(self, name):
        for i in self.symbols:
            if i['name'] == name:
                return i
        return None

    def section_by_id(self, id):
        try:
            return self.sections[id]
        except IndexError:
            return None

    def symbol_by_id(self, name):
        try:
            return self.symbols[id]
        except IndexError:
            return None
