_warn_action_handler = None

def warn(s):
    if _warn_action_handler is not None:
        _warn_action_handler(s)

_info_action_handler = None

def info(s):
    if _info_action_handler is not None:
        _info_action_handler(s)

_verbose_action_handler = None

def verbose(s):
    if _verbose_action_handler is not None:
        _verbose_action_handler(s)

def subscribe_warn(f):
    global _warn_action_handler
    _warn_action_handler = f
    
def subscribe_info(f):
    global _info_action_handler
    _info_action_handler = f
    
def subscribe_verbose(f):
    global _verbose_action_handler
    _verbose_action_handler = f
