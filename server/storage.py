import sqlite3
import threading

import util
import logger
import config

TAG = "DBConnection"

db = sqlite3.connect(config.DB_FILE, check_same_thread=False)
db.row_factory = sqlite3.Row

db_lock = threading.Lock()

def sql(query, params=(), log_errors=True):
    ret = []
    with db_lock:
        try:
            cur = db.cursor()
            for i in cur.execute(query, params):
                ret.append(util.DotDict(i))
            db.commit()
        except:
            if log_errors:
                logger.log(TAG, "sql query made a fucky wucky, a wittle fucko boingo")
                logger.log_exc(TAG)
    return ret

def get_user_by_sessid(x):
    result = sql("SELECT * FROM users WHERE sessid=?", (x,))
    if not result:
        return None
    return result[0]

def get_user_id_by_sessid(x):
    result = sql("SELECT id FROM users WHERE sessid=?", (x,))
    if not result:
        return None
    return result[0].id

def get_user_id_by_username(x):
    result = sql("SELECT id FROM users WHERE username=?", (x,))
    if not result:
        return None
    return result[0].id
