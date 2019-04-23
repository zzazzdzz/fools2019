import generator.randomizer as randomizer
import generator.item_consts as item_consts
import generator.mon_consts as mon_consts

import logger

TAG = "AntiCheat"

def flatten(x):
    return [i for sublist in x for i in sublist]

def quantify(rules, item_name, current_save):
    if item_name not in rules['ObtainableItems']:
        return 0
    ruleset_str = rules['ObtainableItems'][item_name]
    ruleset = [x.strip() for x in ruleset_str.split(",")]
    total = 0
    for rule in ruleset:
        if rule == "any":
            return 9999999
        count, condition = rule.split("x")
        count = int(count)
        condition = condition.strip()
        if condition == 'always':
            total += count
        elif condition.startswith('$'):
            total += count * (current_save['money'] // int(condition[1:]))
        else:
            # based on event flag otherwise
            event_id = int(rules['ObtainableFlags'][condition])
            if current_save['events'][event_id]:
                total += count
    return total

def verify(session, previous_save, current_save, map_rules):
    rnd = randomizer.Randomizer(session['user'], session['current_kingdom'])
    diff_event_flags = [
        i for i in range(0, len(current_save['events']))
        if current_save['events'][i] and not previous_save['events'][i]
    ]
    allowed_flags = [
        int(x) for x in list(map_rules['ObtainableFlags'].values())
    ] + [71, 72] # EVENT_TUTORIAL_WILLOW, EVENT_K1_PRE_COMPLETE
    for i in diff_event_flags:
        if i not in allowed_flags:
            logger.log(TAG, "unallowed event flag %i" % i)
            return False
    diff_items = {}
    prev_save_all_items = previous_save['items']['items'] + previous_save['items']['balls'] + previous_save['items']['key_items']
    prev_save_all_items += [
        (i['item'], 1) for i in previous_save['party']
    ]
    current_save_all_items = current_save['items']['items'] + current_save['items']['balls'] + current_save['items']['key_items']
    current_save_all_items += [
        (i['item'], 1) for i in current_save['party']
    ]
    for k, v in prev_save_all_items:
        if k not in diff_items: diff_items[k] = 0
        diff_items[k] -= v
    for k, v in current_save_all_items:
        if k not in diff_items: diff_items[k] = 0
        diff_items[k] += v
    diff_items = {
        k: v for k, v in diff_items.items() 
        if v > 0 and k != 0
    }
    obtainable_item_ids = []
    for k in map_rules['ObtainableItems'].keys():
        if k.startswith("$"):
            item_id = int(k[1:], 16)
        else:
            item_id = item_consts.ITEM_CONSTS[k.upper()]
        obtainable_item_ids.append(item_id)
    for i in diff_items.keys():
        if i not in obtainable_item_ids:
            logger.log(TAG, "unallowed item %i" % i)
            return False
    for item_id in obtainable_item_ids:
        if item_id not in diff_items: continue
        max_allowed = quantify(map_rules, item_consts.ITEM_CONSTS_REV[item_id], current_save)
        if diff_items[item_id] > max_allowed:
            logger.log(TAG, "max allowed count for %i is %i; player had %i" % (item_id, max_allowed, diff_items[item_id]))
            return False
    prev_save_mons = [i['species'] for i in previous_save['party']]
    diff_mons = [i['species'] for i in current_save['party']]
    for i in prev_save_mons:
        if i in diff_mons: diff_mons.remove(i)
    allowed_mons = []
    obtainables = list(map_rules['ObtainableMons'].keys())
    obtainables += [x['species'] for x in previous_save['party']]
    for k in obtainables:
        if not isinstance(k, int):
            if k.startswith("_"):
                rnd_id = int(k[5:])
                mon_str_id = rnd.repeatable_basic_mon(rnd_id)
                mon_str_id = mon_str_id.decode('ascii')
            else:
                mon_str_id = k.upper()
        else:
            mon_str_id = mon_consts.MON_CONSTS_REV[k]
        evo_line = mon_consts.EVOLUTION_LINES[mon_str_id]
        for mon in evo_line:
            mon_id = mon_consts.MON_CONSTS[mon]
            allowed_mons.append(mon_id)
    for mon in diff_mons:
        if mon not in allowed_mons:
            logger.log(TAG, "unallowed mon species %s" % mon)
            return False
    for mon in current_save['party']:
        if mon['level'] > 100:
            logger.log(TAG, "party member with level >100")
            return False
    return True

if __name__ == "__main__":
    import savdecoder
    import configparser
    s1 = savdecoder.test_save_data('w:/code/fools2019/generator/save7.dmp')
    s2 = savdecoder.test_save_data('w:/code/fools2019/generator/save8.dmp')
    rules = configparser.ConfigParser()
    rules.read("w:/code/fools2019/sav/template/maps/k06_pre/meta.txt")
    sess = {'user': 'TheZZAZZGlitch', 'current_kingdom': 'k06_pre'}
    print(verify(sess, s1, s2, rules))
