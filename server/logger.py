import threading
import time
import traceback
import sys
from datetime import datetime

import util
import config

log_lock = threading.Lock()

DEBUG_STDOUT = True
ANSI = False

def log(tag, s):
    with log_lock:
        t = "[" + datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3] + "]"
        s = t + " [" + tag + "] " + s
        if DEBUG_STDOUT:
            ansi = ("\033[1;33m", "\033[0;0m") if ANSI else ("", "")
            print(ansi[0] + s + ansi[1])
        with open(config.LOG_DIRECTORY + '/fools2019.log', 'ab') as f:
            f.write(s.encode("utf-8") + b"\n")

def log_exc(tag):
    for line in traceback.format_exc().split("\n"):
        if line.strip():
            log(tag, line)
            
def bigbrother(endpoint, user, environ):
    t = "[" + datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3] + "]"
    s = t + " " + util.get_real_ip(environ) + " uid=" + str(user['id']) + " sessid=" + user['sessid'] + " :: " + endpoint
    with log_lock:
        with open(config.LOG_DIRECTORY + '/bigbrother.log', 'ab') as f:
            f.write(s.encode("utf-8") + b"\n")
