import os
import sys
import base64

import logger

import generator.savtools as savtools
import generator.savdecoder as savdecoder
from config import SAV_DIRECTORY

TAG = "CompilerPostProcess"

def perform(session):
    with open(SAV_DIRECTORY + '/bin/main_sram0.bin', 'rb') as f:
        s0 = f.read()
    with open(SAV_DIRECTORY + '/bin/main_sram1.bin', 'rb') as f:
        s1 = f.read()
    with open(SAV_DIRECTORY + '/bin/main_sram2.bin', 'rb') as f:
        s2 = f.read()
    with open(SAV_DIRECTORY + '/bin/main_sram3.bin', 'rb') as f:
        s3 = f.read()
    s0_sz = 0xB1F0 - 0xA71A
    s1_sz = 0xBE30 - 0xB260
    s2_sz = 0x1FE0
    s3_sz = 0x1FE0
    logger.log(TAG, "free space report:")
    logger.log(TAG, "sra0 | %i/%i (%.2f%%)" % (len(s0), s0_sz, 100*(len(s0)/s0_sz)))
    logger.log(TAG, "sra1 | %i/%i (%.2f%%)" % (len(s1), s1_sz, 100*(len(s1)/s1_sz)))
    logger.log(TAG, "sra2 | %i/%i (%.2f%%)" % (len(s2), s2_sz, 100*(len(s2)/s2_sz)))
    logger.log(TAG, "sra3 | %i/%i (%.2f%%)" % (len(s3), s3_sz, 100*(len(s3)/s3_sz)))
    if len(s0) > s0_sz:
        raise RuntimeError("sram0 is overfilled")
    if len(s1) > s1_sz:
        raise RuntimeError("sram1 is overfilled")
    if len(s2) > s2_sz:
        raise RuntimeError("sram2 is overfilled")
    if len(s3) > s3_sz:
        raise RuntimeError("sram3 is overfilled")
    source = SAV_DIRECTORY + '/base.sav'
    target = SAV_DIRECTORY + '/fools.sav'
    with open(source, 'rb') as f:
        savtools.load_save(bytearray(f.read()))
    s0_at = savtools.save.index(b'OFFS_SR0')
    s1_at = savtools.save.index(b'OFFS_SR1') + 0x1250
    s2_at = savtools.save.index(b'OFFS_SR2')
    s3_at = savtools.save.index(b'OFFS_SR3')
    savtools.insert_at(s0_at, s0)
    savtools.insert_at(s1_at, s1)
    savtools.insert_at(s2_at, s2)
    savtools.insert_at(s3_at, s3)
    savtools.write_rtc()
    savtools.write_player_data(session['current_save'])
    if savtools.check_extras():
        logger.log(TAG, "!!! pwnage kingdom III data detected; encrypting")
    logger.log(TAG, "creating save data to %s" % target)
    save_data = savtools.get_save(include_rtc=session['rtc'])
    with open(target, 'wb') as f:
        f.write(save_data)
    return save_data

if __name__ == "__main__":
    from mocksession import MOCK_SESSION
    print("*** map postprocessor for fools2019")
    print("*** TheZZAZZGlitch 2018-2019")
    save_data = perform(MOCK_SESSION)

    # bgb savestate creation

    source = r'D:\Różne dane\Pokemon Crystal.sn3'
    target = r'D:\Różne dane\Pokemon Crystal.sn4'

    print("creating bgb state to %s" % target)

    with open(source, 'rb') as fp:
        cont = bytearray(fp.read())
    mark = b'SRAM\x00\x00\x80\x00\x00'
    sram_data_at = cont.index(mark) + len(mark)
    def insert_at(offset, data):
        global cont
        for i in range(0, len(data)):
            cont[offset + i] = data[i]
    insert_at(sram_data_at, save_data[0:0x8000])
    with open(target, 'wb') as fp:
        fp.write(cont)