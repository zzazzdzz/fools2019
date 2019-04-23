import threading

import util

ratelimiter_lock = threading.Lock()

ratelimiter_storage = {
    "counters": {},
    "upload_save_data": {},
    "begin_augment": {}
}

def increment_suspicion_counter(user_id):
    with ratelimiter_lock:
        if user_id not in ratelimiter_storage['counters']:
            ratelimiter_storage['counters'][user_id] = 0
        ratelimiter_storage['counters'][user_id] += 1

def get_suspicion_counter(user_id):
    result = 0
    with ratelimiter_lock:
        if user_id in ratelimiter_storage['counters']:
            result = ratelimiter_storage['counters'][user_id]
    return result

def reset_suspicion_counter(user_id):
    with ratelimiter_lock:
        ratelimiter_storage['counters'][user_id] = 0

def save_current_time(storage_id, user_id):
    with ratelimiter_lock:
        ratelimiter_storage[storage_id][user_id] = util.unix_time()

def check_timeout(storage_id, user_id, timeout):
    now = util.unix_time()
    last = 0
    with ratelimiter_lock:
        if user_id in ratelimiter_storage[storage_id]:
            last = ratelimiter_storage[storage_id][user_id]
    return now - last < timeout
