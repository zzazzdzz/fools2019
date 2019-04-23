import configparser
import random
import copy

import util
import storage
import logger

from config import SAV_DIRECTORY, WORDNET_DIRECTORY, SECRET_KEY

TAG = "AugmentSystem"

augment_states = {}

augments = configparser.ConfigParser()
augments.read(SAV_DIRECTORY + "/template/maps/augment.txt", encoding="utf-8")

current_augment_map = {}

wordnet_nouns = None
wordnet_verbs = None
wordnet_adjectives = None

class VerificationError(Exception):
    pass

def update_augment_map():
    for i in storage.sql("SELECT augment, content FROM augments"):
        current_augment_map[i.augment] = i.content

def wordnet_load(filename):
    result = {}
    with open(filename, "r") as f:
        for i in f.readlines():
            if i[0] == ' ': continue
            result[i.split(" ")[0]] = 1
    return result

def init():
    global wordnet_adjectives, wordnet_nouns, wordnet_verbs
    sects = augments.sections()
    logger.log(TAG, "init: populating %i augments" % len(sects))
    for i in sects:
        try:
            storage.sql("""
                INSERT INTO augments
                (augment, content)
                VALUES 
                (?, ?)
            """, (i, augments[i]["Default"]), log_errors=False)
        except:
            pass
    update_augment_map()
    logger.log(TAG, "init: loading wordnet databases")
    wordnet_nouns = wordnet_load(WORDNET_DIRECTORY + "/index.noun")
    logger.log(TAG, "init: %i nouns loaded" % len(wordnet_nouns))
    wordnet_adjectives = wordnet_load(WORDNET_DIRECTORY + "/index.adj")
    logger.log(TAG, "init: %i adjectives loaded" % len(wordnet_adjectives))
    wordnet_verbs = wordnet_load(WORDNET_DIRECTORY + "/index.verb")
    logger.log(TAG, "init: %i verbs loaded" % len(wordnet_verbs))
    logger.log(TAG, "init: finished")

def get_balance(user_id):
    return int(storage.sql("""
        SELECT tokens_got
        FROM progress
        WHERE user_id = ?
    """, (user_id,))[0].tokens_got)

def subtract_balance(user_id, amount):
    storage.sql("""
        UPDATE progress
        SET tokens_got = tokens_got - ?, tokens_used = tokens_used + ?
        WHERE user_id = ?
    """, (amount, amount, user_id))

def begin(user_id, kingdom):
    sects = augments.sections()
    c = random.choice(sects)
    if kingdom != '@':
        while 1:
            c = random.choice(sects)
            if c.startswith(kingdom.upper() + "_"):
                break
    state = util.DotDict({
        "id": c,
        "type": augments[c]["Type"],
        "max_length": int(augments[c]["Length"]),
        "context": augments[c]["Context"],
        "kingdom": kingdom,
        "sid": util.new_session_key()
    })
    augment_states[user_id] = state
    return state

def reroll(user_id):
    return begin(user_id, augment_states[user_id].kingdom)

def state(user_id):
    return augment_states[user_id]

def freestyle(user_id):
    augment_states[user_id].type = "freestyle"

def format(desc):
    for k, v in current_augment_map.items():
        desc = desc.replace("$" + k, "<b>" + v + "</b>")
    return desc

def verify(user_id, value):
    st = state(user_id)
    value = value.strip()
    if not value:
        raise VerificationError("The phrase cannot be empty.")
    if len(value) > st.max_length:
        raise VerificationError("The provided phrase is too long.")
    if not (value.isalnum() and all(ord(c) < 128 for c in value)):
        raise VerificationError("Your phrase can only contain alphanumeric characters, no spaces.")
    if st.type == "freestyle" or st.type == "any":
        return True
    if st.type == "adjective":
        if value not in wordnet_adjectives:
            raise VerificationError("Your adjective must be an English dictionary word.")
    elif st.type == "noun":
        ok = False
        if value in wordnet_nouns: ok = True
        if value.endswith("s") and value[:-1] in wordnet_nouns: ok = True
        if value.endswith("es") and value[:-2] in wordnet_nouns: ok = True
        if value.endswith("es") and value[:-1] in wordnet_nouns: ok = True
        if value.endswith("es") and value[:-3] in wordnet_nouns: ok = True
        if value.endswith("ves") and value[:-3] + "f" in wordnet_nouns: ok = True
        if value.endswith("ves") and value[:-3] + "v" in wordnet_nouns: ok = True
        if value.endswith("ves") and value[:-3] + "fe" in wordnet_nouns: ok = True
        if value.endswith("ves") and value[:-3] + "ve" in wordnet_nouns: ok = True
        if value.endswith("i") and value[:-1] + "us" in wordnet_nouns: ok = True
        if value.endswith("es") and value[:-2] + "is" in wordnet_nouns: ok = True
        if value.endswith("a") and value[:-1] + "on" in wordnet_nouns: ok = True
        if value in ("children", "geese", "men", "women", "teeth", "feet", "mice", "people"): ok = True
        if not ok: raise VerificationError("Your noun must be an English dictionary word.")
    elif st.type == "verb":
        if value not in wordnet_verbs:
            raise VerificationError("Your verb must be in bare infinitive form, and must be an English dictionary word.")
    else:
        raise VerificationError("Invalid augment type? This shouldn't happen.")

def store(user_id, value):
    i = augment_states[user_id].id
    logger.log(TAG, "user_id %i augmented `%s` to `%s`" % (user_id, i, value))
    storage.sql("""
        UPDATE augments
        SET content = ?
        WHERE augment = ?
    """, (value, i))
    update_augment_map()
    augment_states[user_id] = {}

def get_all():
    update_augment_map()
    return copy.deepcopy(current_augment_map)
