import random
import copy

from config import SECRET_KEY, EXTRAS_DIRECTORY

with open(EXTRAS_DIRECTORY + '/basics.txt', 'rb') as fp:
    BASIC_MONS = [x.strip() for x in fp.read().split(b"\n")]
with open(EXTRAS_DIRECTORY + '/first_stage.txt', 'rb') as fp:
    FIRST_STAGE_MONS = [x.strip() for x in fp.read().split(b"\n")]
with open(EXTRAS_DIRECTORY + '/second_stage.txt', 'rb') as fp:
    SECOND_STAGE_MONS = [x.strip() for x in fp.read().split(b"\n")]

HELD_ITEM_MONS = [b"BUTTERFREE", b"BEEDRILL", b"FEAROW", b"PIKACHU", b"RAICHU", b"CLEFAIRY", b"CLEFABLE", b"VULPIX", b"NINETALES", b"PARAS", b"PARASECT", b"GROWLITHE", b"ARCANINE", b"POLIWHIRL", b"POLIWRATH", b"GEODUDE", b"GRAVELER", b"GOLEM", b"SLOWPOKE", b"SLOWBRO", b"MAGNEMITE", b"MAGNETON", b"FARFETCH_D", b"DODRIO", b"GRIMER", b"MUK", b"SHELLDER", b"CLOYSTER", b"CUBONE", b"MAROWAK", b"CHANSEY", b"HORSEA", b"SEADRA", b"STARYU", b"STARMIE", b"MR_MIME", b"JYNX", b"MAGMAR", b"SNORLAX", b"DRATINI", b"DRAGONAIR", b"DRAGONITE", b"MEWTWO", b"MEW", b"SENTRET", b"FURRET", b"PICHU", b"CLEFFA", b"POLITOED", b"SLOWKING", b"MISDREAVUS", b"STEELIX", b"SHUCKLE", b"SNEASEL", b"KINGDRA", b"SMOOCHUM", b"MAGBY", b"MILTANK", b"BLISSEY", b"HO_OH", b"CELEBI"]

for v in HELD_ITEM_MONS:
    try:
        BASIC_MONS.remove(v)
    except:
        pass
    try:
        FIRST_STAGE_MONS.remove(v)
    except:
        pass
    try:
        SECOND_STAGE_MONS.remove(v)
    except:
        pass

class Randomizer:
    """Random number generator, unique for each user and map."""
    
    def __init__(self, user, map_name):
        self.rng = random.Random()
        self.basic_mons = copy.copy(BASIC_MONS)
        self.first_stage_mons = copy.copy(FIRST_STAGE_MONS)
        self.second_stage_mons = copy.copy(SECOND_STAGE_MONS)
        user = bytes(user, 'utf-8')
        map_name = bytes(map_name, 'utf-8')
        self.rng.seed(SECRET_KEY + user + b"PRE")
        self.rng.shuffle(self.basic_mons)
        self.rng.shuffle(self.first_stage_mons)
        self.rng.shuffle(self.second_stage_mons)
        self.rng.seed(SECRET_KEY + user + b"POST" + map_name)

    def basic_mon(self):
        return self.rng.choice(self.basic_mons).strip()

    def first_stage_mon(self):
        return self.rng.choice(self.first_stage_mons).strip()

    def randrange(self, l, r):
        return self.rng.randrange(l, r)

    def repeatable_basic_mon(self, i):
        return self.basic_mons[i]

    def repeatable_first_stage_mon(self, i):
        return self.first_stage_mons[i]

    def repeatable_randrange(self, i, l, r):
        h = int(hashlib.sha1(SECRET_KEY + bytes([i])).hexdigest()[0:8], 16)
        return l + h % (r - l)
