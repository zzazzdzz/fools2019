import json
import copy

import util
import storage
from event_flags import *

def EventFlagCheck(flag):
    def f(save_data, session):
        return save_data['events'][flag]
    return f

def MultipleEventFlagCheck(flags):
    def f(save_data, session):
        for i in flags:
            if not save_data['events'][i]: return False
        return True
    return f

def CountSetEventsCheck(threshold, flags):
    def f(save_data, session):
        total = 0
        for i in flags:
            if save_data['events'][i]: total += 1
        return total >= threshold
    return f

def KingdomVisitedCheck(kingdom):
    def f(save_data, session):
        return kingdom in session['visited_kingdoms']
    return f

def VisitedKingdomCountCheck(num):
    def f(save_data, session):
        return len(session['visited_kingdoms']) >= num
    return f

def MonsterCoachCheck(save_data, session):
    for mon in save_data['party']:
        if mon['level'] >= 40: return True
    return False

def SquadAssembledCheck(save_data, session):
    return len(save_data['party']) >= 3

def IllustratedHandbookCheck(save_data, session):
    return sum(save_data['dex']['seen']) >= 100

ACHIEVEMENTS = {
    "attempt_was_made": KingdomVisitedCheck("k01"),
    "kingdoms_3": VisitedKingdomCountCheck(3),
    "kingdoms_5": VisitedKingdomCountCheck(5),
    "the_finishist": KingdomVisitedCheck("final"),
    "the_completionist": KingdomVisitedCheck("last"),
    "monster_coach": MonsterCoachCheck,
    "squad_assembled": SquadAssembledCheck,
    "illustrated_handbook": IllustratedHandbookCheck,
    "ancient_puzzles": MultipleEventFlagCheck([EVENT_K1_POST_ANCIENT_PUZZLE_SOLVED, EVENT_K2_POST_ANCIENT_PUZZLE_SOLVED, EVENT_K4_POST_ANCIENT_PUZZLE_SOLVED]),
    "lights_out": EventFlagCheck(EVENT_K1_POST_CORRUPTION_CLEANSED),
    "hooked_metapod": EventFlagCheck(EVENT_SHOWED_METAPOD),
    "delirious": EventFlagCheck(EVENT_K3_VISITED_DELIRIA),
    "yahaha": MultipleEventFlagCheck([EVENT_YAHAHA_INITIATED, EVENT_YAHAHA_FIRST, EVENT_YAHAHA_SECOND, EVENT_YAHAHA_THIRD, EVENT_YAHAHA_FOURTH, EVENT_YAHAHA_FIFTH]),
    "laylah_blessing": EventFlagCheck(EVENT_K3_LAYLAH_BLESSING),
    "seaside_maze": EventFlagCheck(EVENT_K4_SECRET_PATH),
    "seaside_stocks": EventFlagCheck(EVENT_K4_STOCK_MARKET_PROFIT),
    "joyful_rockets_defeated": EventFlagCheck(EVENT_K5_PRE_ROCKETS_DEFEATED),
    "joyful_pentakill": EventFlagCheck(EVENT_K5_POST_PENTAKILL),
    "throwback_flash": EventFlagCheck(EVENT_K5_PRE_FLASH_HOUSE),
    "throwback_lost_item": EventFlagCheck(EVENT_K6_POST_LOST_ITEM),
    "verdant_laptop": EventFlagCheck(EVENT_K2_LAPTOP),
    "radio": MultipleEventFlagCheck([EVENT_K1_RADIO, EVENT_K2_RADIO, EVENT_K3_RADIO, EVENT_K5_RADIO]),
    "itemballs": MultipleEventFlagCheck([EVENT_ITEMBALL_K1_PRE_1, EVENT_ITEMBALL_K1_POST_1, EVENT_ITEMBALL_K1_POST_2, EVENT_ITEMBALL_K1_POST_3, EVENT_ITEMBALL_K2_PRE_1, EVENT_ITEMBALL_K2_POST_1, EVENT_ITEMBALL_K2_POST_2, EVENT_ITEMBALL_K2_POST_3, EVENT_ITEMBALL_K3_POST_1, EVENT_ITEMBALL_K3_POST_2, EVENT_ITEMBALL_K3_POST_3, EVENT_ITEMBALL_K3_POST_4, EVENT_ITEMBALL_K3_POST_5, EVENT_ITEMBALL_K3_POST_6, EVENT_ITEMBALL_K3_POST_7, EVENT_ITEMBALL_K3_POST_8, EVENT_ITEMBALL_K3_POST_9, EVENT_ITEMBALL_K4_PRE_1, EVENT_ITEMBALL_K4_PRE_2, EVENT_ITEMBALL_K4_PRE_3, EVENT_ITEMBALL_K4_POST_1, EVENT_ITEMBALL_K4_POST_2, EVENT_ITEMBALL_K5_PRE_1, EVENT_ITEMBALL_K5_PRE_2, EVENT_ITEMBALL_K5_PRE_3, EVENT_ITEMBALL_K5_PRE_4, EVENT_ITEMBALL_K5_POST_1, EVENT_ITEMBALL_K6_PRE_1, EVENT_ITEMBALL_K6_POST_1, EVENT_ITEMBALL_K6_POST_2, EVENT_ITEMBALL_K6_POST_3, EVENT_ITEMBALL_K6_POST_4, EVENT_ITEMBALL_K6_POST_5, EVENT_ITEMBALL_K6_POST_6, EVENT_ITEMBALL_FINAL_1, EVENT_ITEMBALL_FINAL_2, EVENT_ITEMBALL_FINAL_3, EVENT_ITEMBALL_FINAL_4, EVENT_ITEMBALL_FINAL_5, EVENT_ITEMBALL_FINAL_6, EVENT_ITEMBALL_FINAL_7]),
    "trainers": CountSetEventsCheck(30, [EVENT_TRAINER_K1_PRE_1, EVENT_TRAINER_K1_PRE_2, EVENT_TRAINER_K1_PRE_3, EVENT_TRAINER_K1_PRE_4, EVENT_TRAINER_K1_POST_1, EVENT_TRAINER_K1_POST_2, EVENT_TRAINER_K1_POST_3, EVENT_TRAINER_K2_PRE_1, EVENT_TRAINER_K2_PRE_2, EVENT_TRAINER_K2_PRE_3, EVENT_TRAINER_K2_PRE_4, EVENT_TRAINER_K2_POST_1, EVENT_TRAINER_K2_POST_2, EVENT_TRAINER_K3_PRE_1, EVENT_TRAINER_K3_PRE_2, EVENT_TRAINER_K3_PRE_3, EVENT_TRAINER_K3_PRE_4, EVENT_TRAINER_K3_PRE_5, EVENT_TRAINER_K3_PRE_6, EVENT_TRAINER_K3_PRE_7, EVENT_TRAINER_K3_PRE_8, EVENT_TRAINER_K3_PRE_9, EVENT_TRAINER_K4_PRE_1, EVENT_TRAINER_K4_PRE_2, EVENT_TRAINER_K4_PRE_3, EVENT_TRAINER_K4_PRE_4, EVENT_TRAINER_K4_PRE_5, EVENT_TRAINER_K5_PRE_1, EVENT_TRAINER_K5_PRE_2, EVENT_TRAINER_K5_PRE_3, EVENT_TRAINER_K5_ROCKET_1, EVENT_TRAINER_K5_ROCKET_2, EVENT_TRAINER_K5_ROCKET_3, EVENT_TRAINER_K5_ROCKET_4, EVENT_TRAINER_K5_ROCKET_5, EVENT_TRAINER_K5_ROCKET_6, EVENT_TRAINER_K6_PRE_1, EVENT_TRAINER_K6_PRE_2, EVENT_TRAINER_K6_PRE_3, EVENT_TRAINER_K6_PRE_4, EVENT_TRAINER_K6_PRE_5, EVENT_TRAINER_K6_PRE_6, EVENT_TRAINER_K6_PRE_7, EVENT_TRAINER_K6_PRE_8]),
    "pwnage_1": KingdomVisitedCheck("pwnage01"),
    "pwnage_2": KingdomVisitedCheck("pwnage02"),
    "pwnage_3": KingdomVisitedCheck("pwnage03"),
    "pwnage_4": KingdomVisitedCheck("pwnage04")
}

ACHIEVEMENT_REWARDS = {
    "attempt_was_made": (20, 20),
    "kingdoms_3": (40, 20),
    "kingdoms_5": (40, 20),
    "the_finishist": (50, 30),
    "the_completionist": (60, 100),
    "monster_coach": (50, 20),
    "squad_assembled": (30, 20),
    "illustrated_handbook": (40, 30),
    "ancient_puzzles": (50, 40),
    "lights_out": (30, 20),
    "hooked_metapod": (40, 20),
    "delirious": (40, 20),
    "yahaha": (60, 40),
    "laylah_blessing": (50, 40),
    "seaside_maze": (50, 20),
    "seaside_stocks": (30, 20),
    "joyful_rockets_defeated": (20, 10),
    "joyful_pentakill": (50, 30),
    "throwback_flash": (30, 20),
    "throwback_lost_item": (40, 20), 
    "verdant_laptop": (30, 20),
    "radio": (50, 30),
    "itemballs": (60, 40),
    "trainers": (40, 30),
    "pwnage_1": (50, 20),
    "pwnage_2": (50, 20),
    "pwnage_3": (100, 40),
    "pwnage_4": (137, 100)
}

def generate_monsters(save_data):
    mons = []
    for mon in save_data['party']:
        species = str(mon['species']).rjust(3, '0')
        if mon['ivs'][1] == 0xaa and mon['ivs'][0] in (0x2a, 0x3a, 0x6a, 0x7a, 0xaa, 0xba, 0xea, 0xfa):
            species += " color-shiny"
        mons.append({
            "nick": mon['nickname'],
            "species": species,
            "level": mon['level']
        })
    return mons

def calc_pending_rewards(old, new):
    rewards = [0, 0]
    for i in new:
        if i in old and old[i]: continue
        rewards[0] += ACHIEVEMENT_REWARDS[i][0]
        rewards[1] += ACHIEVEMENT_REWARDS[i][1]
    return tuple(rewards)

def update(user_id, session, save_data):
    q = storage.sql("""
        SELECT achievements, score, highest_rank
        FROM leaderboard
        WHERE user_id = ?
    """, (user_id,))[0]
    old_achievements = json.loads(q.achievements)
    new_achievements = copy.deepcopy(old_achievements)
    for k, v in ACHIEVEMENTS.items():
        if v(save_data, session):
            new_achievements[k] = True
    rewards = calc_pending_rewards(old_achievements, new_achievements)
    monsters = generate_monsters(save_data)
    storage.sql("""
        UPDATE progress
        SET tokens_got = tokens_got + ?
        WHERE user_id = ?
    """, (rewards[1], user_id))
    if rewards[0]:
        storage.sql("""
            UPDATE leaderboard
            SET last_update = ?
            WHERE user_id = ?
        """, (util.unix_time(), user_id))
    storage.sql("""
        UPDATE leaderboard SET
            score = score + ?,
            achievements = ?,
            monsters = ?
        WHERE user_id = ?
    """, (rewards[0], json.dumps(new_achievements), json.dumps(monsters), user_id))
    storage.sql("""
        UPDATE leaderboard
        SET highest_rank = MIN(highest_rank, (
            SELECT COUNT(1)
            FROM leaderboard
            WHERE score >= (SELECT score FROM leaderboard WHERE user_id = ?)
        ))
        WHERE user_id = ?
    """, (user_id, user_id))
