import threading
import configparser
import json
import copy
import random

import achievements
import util
import storage
import logger
import event_flags

import generator.savdecoder
import generator.anticheat
from generator.savdecoder import PASSWORD_LENGTH
from config import SAV_DIRECTORY

# generator.savdecoder is full of global and implicit state
# it was faster to create a lock to make it thread-safe rather than do a full rewrite
decoder_lock = threading.Lock()

ERROR_INVALID_FORMAT = 1
ERROR_NO_DATA_FOUND = 2
ERROR_INVALID_DATA = 3
ERROR_ANTICHEAT_REJECTED = 4
ERROR_UNKNOWN_SAVE_ID = 5

TAG = "SaveDataParser"

def perform(user_id, data):
    if len(data) > 33 * 1024:
        return ERROR_INVALID_FORMAT
    if len(data) < 31 * 1024:
        return ERROR_INVALID_FORMAT
    if data[0x120b] != 0xe6 or data[0x4000] != 0xc3:
        return ERROR_INVALID_FORMAT
    if data[0x4007] != 0x01:
        return ERROR_NO_DATA_FOUND
    session = util.get_compiler_session(user_id)
    old_data = session['current_save']
    change_fun = False
    change_blessing = False
    try:
        data = data[0x6100:0x6100+PASSWORD_LENGTH]
        with decoder_lock:
            new_data = generator.savdecoder.parse(data, session['current_kingdom'])
        if new_data['special']:
            new_data_tmp = copy.deepcopy(old_data)
            new_data_tmp['save_id'] = new_data['save_id']
            new_data = new_data_tmp
        new_data['events'][event_flags.EVENT_K1_PRE_COMPLETE] = True
        if new_data['events'][event_flags.EVENT_K4_FUN_VALUE_CHANGED]:
            change_fun = True
            new_data['events'][event_flags.EVENT_K4_FUN_VALUE_CHANGED] = False
        if new_data['events'][event_flags.EVENT_K3_LAYLAH_BLESSING] and not session['laylah_blessing']:
            change_blessing = True
    except:
        logger.log(TAG, "exception occured while decoding save data for uid %i" % user_id)
        logger.log_exc(TAG)
        return ERROR_INVALID_DATA
    valid_id = util.get_save_id(session['user'], session['current_kingdom'], session['visit_started'])
    if new_data['save_id'] != valid_id:
        logger.log(TAG, "decoding save data for uid %i: wrong save id" % user_id)
        return ERROR_UNKNOWN_SAVE_ID
    rules = configparser.ConfigParser()
    rules.read(SAV_DIRECTORY + "/template/maps/" + session['current_kingdom'] + "/meta.txt")
    verify = generator.anticheat.verify(session, old_data, new_data, rules)
    if not verify:
        logger.log(TAG, "decoding save data for uid %i, kingdom %s: anticheat verification failed" % (user_id, session['current_kingdom']))
        return ERROR_ANTICHEAT_REJECTED
    if session['current_kingdom_undecorated'] not in session['visited_kingdoms']:
        session['visited_kingdoms'].append(session['current_kingdom_undecorated'])
    storage.sql("""
        UPDATE progress SET
           cur_kingdom = 'none',
           save_blob = ?,
           save_uid = '',
           visited_kingdoms = ?
        WHERE user_id = ?
    """, (json.dumps(new_data), json.dumps(session['visited_kingdoms']), user_id))
    if change_fun:
        storage.sql("""
            UPDATE users SET fun = ?
            WHERE id = ?
        """, (random.randrange(0, 256), user_id))
    if change_blessing:
        storage.sql("""
            UPDATE progress SET laylah_blessing = 1
            WHERE user_id = ?
        """, (user_id,))
    achievements.update(user_id, session, new_data)
    return (0, session['current_kingdom'])
