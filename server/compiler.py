import subprocess
import time
import json
import os
import shutil
import threading

import util
import storage
import logger

import rgbbin.objfile

import generator.preprocess
import generator.postprocess
from config import SAV_DIRECTORY, DATA_DIRECTORY, RGBASM

TAG = "CompilerService"

def dump_rgbds_object_file(objname):
    with rgbbin.objfile.ObjectFile(objname) as obj:
        obj.parse_all()
        for section in obj.sections:
            filename = SAV_DIRECTORY + "/bin/" + section['name'] + ".bin"
            with open(filename, "wb") as f:
                f.write(section['data'])

def compile_single_save(session):
    try:
        generator.preprocess.perform(session)
        subprocess.check_call([
            RGBASM,
            "-o", SAV_DIRECTORY + "/bin/mapdata.obj",
            SAV_DIRECTORY + "/main.asm"
        ], cwd=SAV_DIRECTORY)
        dump_rgbds_object_file(SAV_DIRECTORY + "/bin/mapdata.obj")
        subprocess.check_call([
            RGBASM,
            "-o", SAV_DIRECTORY + "/bin/main.obj",
            "-D", "FINAL_PASS",
            SAV_DIRECTORY + "/main.asm"
        ], cwd=SAV_DIRECTORY)
        dump_rgbds_object_file(SAV_DIRECTORY + "/bin/main.obj")
        generator.postprocess.perform(session)
        return True
    except:
        logger.log(TAG, "an exception occured while compiling save data")
        logger.log_exc(TAG)
        return False

poke = True

def poke_compiler_thread():
    global poke
    poke = True

def compiler_handle_jobs():
    jobs = storage.sql("""
        SELECT user_id, kingdom
        FROM queue
        WHERE save_uid IS NULL
        ORDER BY id
    """)
    for job in jobs:
        logger.log(TAG, "compiling job (%i, %s)" % (job.user_id, job.kingdom))
        storage.sql("""
            UPDATE queue
            SET save_uid = '_'
            WHERE user_id = ?
        """, (job.user_id,))
        session = util.get_compiler_session(job.user_id)
        if os.path.exists(SAV_DIRECTORY + "/fools.sav"):
            os.remove(SAV_DIRECTORY + "/fools.sav")
        save_uid = "_"
        if compile_single_save(session):
            filename = util.new_save_file_name(job.user_id)
            shutil.copy(
                SAV_DIRECTORY + "/fools.sav",
                DATA_DIRECTORY + "/save/" + filename + ".sav"
            )
        storage.sql("""
            UPDATE progress
            SET save_uid = ?
            WHERE user_id = ? AND cur_kingdom = ?
        """, (filename, job.user_id, session['current_kingdom_undecorated']))
        storage.sql("""
            UPDATE queue
            SET save_uid = ?
            WHERE user_id = ?
        """, (filename, job.user_id))
        logger.log(TAG, "job (%i, %s) completed" % (job.user_id, job.kingdom))

def compiler_thread():
    global poke
    logger.log(TAG, "compiler thread started")
    while 1:
        for i in range(0, 120):
            if poke: break
            time.sleep(1)
        poke = False
        try:
            compiler_handle_jobs()
        except:
            logger.log(TAG, "an exception occured while handling jobs")
            logger.log_exc(TAG)

def queue_compilation(user_id, kingdom):
    logger.log(TAG, "queueing job (%i, %s)" % (user_id, kingdom))
    storage.sql("""
        INSERT INTO queue
        (user_id, kingdom)
        VALUES
        (?, ?)
    """, (user_id, kingdom))
    poke_compiler_thread()

t = None

def start_service():
    global t
    t = threading.Thread(target=compiler_thread)
    t.daemon = True
    t.start()

if __name__ == "__main__":
    from generator.mocksession import MOCK_SESSION
    logger.DEBUG_STDOUT = True
    compile_single_save(MOCK_SESSION)
    
