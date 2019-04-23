import logger
import util
import config

TAG = "TorBanList"

banlist = {}

def prepare():
    with open(config.DATA_DIRECTORY + "/tor.txt", "r") as f:
        for i in f.readlines():
            banlist[i.strip()] = 1
    logger.log(TAG, "%i IPs banned" % len(banlist))

def is_banned(environ):
    return util.get_real_ip(environ) in banlist
