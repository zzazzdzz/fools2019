import threading
import time

import storage
import util
import logger

TAG = "TokenGrantService"

t = None

def token_grant_thread():
    logger.log(TAG, "token granting thread started")
    while 1:
        for i in range(0, 15):
            time.sleep(60)
        logger.log(TAG, "granting 1 extra token for blessed users")
        storage.sql("""
            UPDATE progress
            SET tokens_got = tokens_got + 1
            WHERE laylah_blessing = 1
        """)
        for i in range(0, 15):
            time.sleep(60)
        logger.log(TAG, "granting 1 extra token for everyone")
        storage.sql("""
            UPDATE progress
            SET tokens_got = tokens_got + 1
        """)

def start_service():
    global t
    t = threading.Thread(target=token_grant_thread)
    t.daemon = True
    t.start()
