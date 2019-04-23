import json
import base64

import logger
import torbanlist
import router
import config
import util
import storage
import ratelimiter
import compiler
import tokens
import savparser
import augment
import checks
import event_flags

rt = router.Router()

TAG = "Main"

HEADERS_CORS = [
    ('Access-Control-Allow-Origin', '*'),
    ('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
]
HEADERS_HTML = [
    ('Content-Type', 'text/html')
]
HEADERS_TEXT = [
    ('Content-Type', 'text/plain')
]
HEADERS_JSON = [
    ('Content-Type', 'application/json')
]

@rt.route("^/", ["OPTIONS"])
def appPreflightRequest(environ, start_response):
    start_response('200 OK', HEADERS_CORS)
    return []

@rt.route("^/ping/[0-f]+$")
def appDoPing(environ, start_response):
    session_key = environ['PATH_INFO'].split('/')[-1]
    q = storage.sql("""
        SELECT
            users.id AS id,
            users.username AS username,
            progress.tokens_got AS tokens,
            progress.cur_kingdom AS cur_kingdom,
            progress.cur_visit_started AS visit_started,
            progress.visited_kingdoms AS kingdoms,
            progress.save_uid AS save_uid,
            leaderboard.achievements AS achievements,
            leaderboard.score AS points
        FROM users
        LEFT OUTER JOIN progress ON progress.user_id = users.id
        LEFT OUTER JOIN leaderboard ON leaderboard.user_id = users.id
        WHERE sessid=?
    """, (session_key,))
    response = {"success": True, "logged_in": False}
    if q:
        logger.bigbrother("/ping", {'sessid': session_key, 'id': q[0].id}, environ)
        response = {
            "success": True,
            "username": q[0].username,
            "id": q[0].id,
            "tokens": q[0].tokens,
            "cur_kingdom": q[0].cur_kingdom,
            "visit_started": q[0].visit_started,
            "points": q[0].points,
            "save_uid": q[0].save_uid
        }
        achievements = json.loads(q[0].achievements)
        kingdoms = json.loads(q[0].kingdoms)
        response["pwnzord_i"] = checks.is_kingdom_accessible("pwnage01", kingdoms, achievements)
        response["pwnzord_ii"] = checks.is_kingdom_accessible("pwnage02", kingdoms, achievements)
        response["pwnzord_iii"] = checks.is_kingdom_accessible("pwnage03", kingdoms, achievements)
        response["pwnzord_iv"] = checks.is_kingdom_accessible("pwnage04", kingdoms, achievements)
        response["completionist"] = checks.is_kingdom_accessible("last", kingdoms, achievements)
        response["central_unlocked"] = checks.is_kingdom_accessible("final", kingdoms, achievements)
        response["kingdoms_visited"] = len(kingdoms)
        response["logged_in"] = True
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(response)]

@rt.route("^/leaderboard/")
def appLeaderboard(environ, start_response):
    q = storage.sql("""
        SELECT users.username AS username,
        score, achievements, monsters
        FROM leaderboard
        LEFT OUTER JOIN users ON users.id = leaderboard.user_id
        WHERE score >= 0
        ORDER BY score DESC, last_update ASC
        LIMIT 30
    """)
    resp = []
    for i in q:
        resp.append({
            "username": i.username,
            "score": i.score,
            "mons": json.loads(i.monsters)
        })
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(resp)]

@rt.route("^/leaderboard_full/")
def appLeaderboardFull(environ, start_response):
    q = storage.sql("""
        SELECT users.username AS username,
        score, achievements, monsters
        FROM leaderboard
        LEFT OUTER JOIN users ON users.id = leaderboard.user_id
        WHERE score >= 0
        ORDER BY score DESC, last_update ASC
    """)
    resp = []
    for i in q:
        resp.append({
            "username": i.username,
            "score": i.score,
            "mons": json.loads(i.monsters)
        })
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(resp)]

@rt.route("^/register/")
def appRegister(environ, start_response):
    data = util.get_json_post(environ)
    q = storage.sql("""
        SELECT id FROM users WHERE username = ?
    """, (data.username,))
    if q:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("That username already exists. Please choose a different one.")]
    if not (data.username.strip() and data.password.strip()):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Username and password may not be empty.")]
    if len(data.username) > 20:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Username is too long.")]
    if len(data.message) > 150:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Message is too long.")]
    if data.password != data.password2:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Your passwords do not match.")]
    if data.starter not in ("CYNDAQUIL", "TOTODILE", "CHIKORITA"):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Invalid starter choice. You dirty hacker.")]
    if not util.recaptcha_verify(data.recaptcha):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed. Please complete the reCAPTCHA challenge. Refresh the page if you encounter any problems.")]
    sessid = util.new_session_key()
    storage.sql("""
        INSERT INTO users
        (username, password, sessid, message, fun, rtc, registered_ip)
        VALUES
        (?, ?, ?, ?, ?, 1, ?)
    """, [
        data.username,
        util.password_hash(data.password),
        sessid,
        data.message,
        util.new_fun_value(),
        util.get_real_ip(environ)
    ])
    user_id = storage.get_user_id_by_username(data.username)
    if user_id is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("An unknown error occured (17). Try again in a few minutes.")]
    save_data = util.create_starter_save()
    storage.sql("""
        INSERT INTO progress
        (user_id, tokens_got, tokens_used, cur_kingdom, cur_visit_started, save_blob, visited_kingdoms, starter, laylah_blessing, save_uid)
        VALUES
        (?, 0, 0, 'none', 0, ?, '[]', ?, 0, '')
    """, (user_id, json.dumps(save_data), data.starter))
    monsters = '[{"nick":"%s","species":"%s","level":20}]' % (data.starter, data.starter)
    storage.sql("""
        INSERT INTO leaderboard
        (user_id, score, achievements, highest_rank, monsters, last_update)
        VALUES
        (?, 0, '{}', (SELECT COUNT(1)+1 FROM leaderboard WHERE score >= 0), ?, ?)
    """, (user_id, monsters, util.unix_time()))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True, "sessid": sessid})]

@rt.route("^/login/")
def appLogin(environ, start_response):
    data = util.get_json_post(environ)
    username = data.username
    password = util.password_hash(data.password)
    q = storage.sql("""
        SELECT id FROM users
        WHERE username = ? AND password = ?
    """, (username, password))
    if not q:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Invalid username and/or password.")]
    uid = q[0].id
    sessid = util.new_session_key()
    logger.log(TAG, "uid %i logged in from ip %s" % (uid, util.get_real_ip(environ)))
    storage.sql("""
        UPDATE users
        SET sessid = ?
        WHERE id = ?
    """, (sessid, uid))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True, "sessid": sessid})]

@rt.route("^/augment/info/")
def appAugmentInfo(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/info", user, environ)
    captcha_needed = ratelimiter.get_suspicion_counter(user.id) >= 3
    q = storage.sql("""
        SELECT visited_kingdoms
        FROM progress
        WHERE user_id = ?
    """, (user.id,))[0]
    result = {
        "success": True,
        "captcha": captcha_needed,
        "augmentables": [x for x in json.loads(q.visited_kingdoms) if x in config.AUGMENTABLE_KINGDOMS]
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/augment/captcha/")
def appAugmentCaptcha(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/captcha", user, environ)
    if not util.recaptcha_verify(data.recaptcha):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed. Please complete the reCAPTCHA challenge. Refresh the page if you encounter any problems.")]
    ratelimiter.reset_suspicion_counter(user.id)
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^/augment/begin/")
def appAugmentBegin(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/begin", user, environ)
    if ratelimiter.get_suspicion_counter(user.id) >= 3:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed.")]
    if data.kingdom not in config.AUGMENTABLE_KINGDOMS and data.kingdom != '@':
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Trying to augment an unknown kingdom.")]
    if ratelimiter.check_timeout("begin_augment", user.id, config.RATELIMIT_AUGMENT):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You can only augment once every 30 seconds.")]
    ratelimiter.save_current_time("begin_augment", user.id)
    token_cost = 4
    if data.kingdom != '@':
        token_cost = 8
    tokens = augment.get_balance(user.id)
    if tokens < token_cost:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You don't have enough augmentation tokens.")]
    tokens -= token_cost
    augment.subtract_balance(user.id, token_cost)
    state = augment.begin(user.id, data.kingdom)
    result = {
        "success": True,
        "type": state.type,
        "max_length": state.max_length,
        "context": "",
        "augment_id": state.sid,
        "balance": tokens
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/augment/reroll/")
def appAugmentReroll(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/reroll", user, environ)
    if ratelimiter.get_suspicion_counter(user.id) >= 3:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed.")]
    token_cost = 4
    tokens = augment.get_balance(user.id)
    if tokens < token_cost:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You don't have enough augmentation tokens.")]
    tokens -= token_cost
    augment.subtract_balance(user.id, token_cost)
    state = augment.reroll(user.id)
    result = {
        "success": True,
        "type": state.type,
        "max_length": state.max_length,
        "context": "",
        "augment_id": state.sid,
        "balance": tokens
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/augment/context/")
def appAugmentContext(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/context", user, environ)
    if ratelimiter.get_suspicion_counter(user.id) >= 3:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed.")]
    state = augment.state(user.id)
    if data.augment_id != state.sid:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("This augmentation has expired or does not exist. Did you open this page in multiple tabs? You can only do one augmentation at a time!")]
    token_cost = 3
    tokens = augment.get_balance(user.id)
    if tokens < token_cost:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You don't have enough augmentation tokens.")]
    tokens -= token_cost
    augment.subtract_balance(user.id, token_cost)
    result = {
        "success": True,
        "context": augment.format(state.context),
        "augment_id": state.sid,
        "balance": tokens
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/augment/freestyle/")
def appAugmentFreestyle(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/freestyle", user, environ)
    if ratelimiter.get_suspicion_counter(user.id) >= 3:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed.")]
    state = augment.state(user.id)
    if data.augment_id != state.sid:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("This augmentation has expired or does not exist. Did you open this page in multiple tabs? You can only do one augmentation at a time!")]
    token_cost = 12
    tokens = augment.get_balance(user.id)
    if tokens < token_cost:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You don't have enough augmentation tokens.")]
    tokens -= token_cost
    augment.subtract_balance(user.id, token_cost)
    augment.freestyle(user.id)
    result = {
        "success": True,
        "augment_id": state.sid,
        "type": "freestyle",
        "balance": tokens
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/augment/finish/")
def appAugmentFinish(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/augment/finish", user, environ)
    if ratelimiter.get_suspicion_counter(user.id) >= 3:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Bot verification failed.")]
    state = augment.state(user.id)
    if data.augment_id != state.sid:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("This augmentation has expired or does not exist. Did you open this page in multiple tabs? You can only do one augmentation at a time!")]
    try:
        augment.verify(user.id, data.word.lower())
    except augment.VerificationError as e:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json(str(e))]
    if checks.is_word_filtered(data.word.lower()) and state.type != 'freestyle':
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Even though this is a dictionary word, we must ask you to enable freestyle mode to enter this phrase. This is to prevent users from filling the system with profanity by using cheap, cost effective random augmentations.")]
    augment.store(user.id, data.word)
    ratelimiter.increment_suspicion_counter(user.id)
    tokens = augment.get_balance(user.id)
    result = {
        "success": True,
        "balance": tokens
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/travel/")
def appTravel(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/travel", user, environ)
    q = storage.sql("""
        SELECT
            users.id AS id,
            leaderboard.achievements AS achievements,
            progress.visited_kingdoms AS kingdoms,
            progress.cur_kingdom AS cur_kingdom,
            progress.save_uid AS save_uid,
            progress.cur_visit_started AS cur_visit_started
        FROM users
        LEFT OUTER JOIN progress ON progress.user_id = users.id
        LEFT OUTER JOIN leaderboard ON leaderboard.user_id = users.id
        WHERE users.id = ?
    """, (user.id,))[0]
    visit_delay = util.time_delta(q.cur_visit_started, config.RATELIMIT_VISIT_KINGDOM)
    if visit_delay and user.id != config.ADMIN_USER_ID:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You need to wait %i more seconds before visiting a new kingdom." % visit_delay)]
    if q.cur_kingdom != 'none' or q.save_uid:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are already visiting a kingdom.")]
    kingdoms = json.loads(q.kingdoms)
    achievements = json.loads(q.achievements)
    if not checks.is_kingdom_accessible(data.kingdom, kingdoms, achievements):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You can't access this kingdom yet.")]
    storage.sql("""
        UPDATE progress SET
        cur_kingdom = ?,
        cur_visit_started = ?,
        save_uid = ''
        WHERE user_id = ?
    """, (data.kingdom, util.unix_time(), user.id))
    compiler.queue_compilation(user.id, data.kingdom)
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^/leave_no_save/")
def appLeaveNoSave(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/leave_no_save", user, environ)
    q = storage.sql("""
        SELECT cur_kingdom, save_uid
        FROM progress
        WHERE user_id = ?
    """, (user.id,))[0]
    if q.cur_kingdom == 'none' or not q.save_uid:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not visiting a kingdom.")]
    storage.sql("""
        UPDATE progress
        SET cur_kingdom = 'none', save_uid = ''
        WHERE user_id = ?
    """, (user.id,))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^/queue_give_up/")
def appQueueGiveUp(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/queue_give_up", user, environ)
    storage.sql("""
        UPDATE queue
        SET save_uid = '_'
        WHERE user_id = ?
    """, (user.id,))
    storage.sql("""
        UPDATE progress
        SET cur_kingdom = 'none', save_uid = ''
        WHERE user_id = ?
    """, (user.id,))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^/finish/")
def appFinish(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/finish", user, environ)
    if ratelimiter.check_timeout("upload_save_data", user.id, config.RATELIMIT_FINISH_KINGDOM):
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You can only upload one save file every 30 seconds.")]
    ratelimiter.save_current_time("upload_save_data", user.id)
    save = base64.b64decode(data.save.split(",")[1])
    savparser_errors = [
        "bepis",
        "The format of the uploaded file could not be recognized. Make sure you're uploading a valid SAV file.",
        "There is no completed save data present in the uploaded file. Check out the <a href='faq.html'>troubleshooting section</a> for possible solutions.",
        "The save data contained in this file is corrupted or invalid. Try replaying the save. If the problem persists, check out the <a href='faq.html'>troubleshooting section</a> for possible solutions.",
        "Your save data contains an illegal game state. This is usually caused by Gamesharking, memory hacking, or otherwise messing with the game. Please play legit, otherwise you'll miss out on a lot of stuff! If you're not a dirty hacker and you got this message, I'm sorry for doubting you - let me know about this problem, and I'll see what I can do!",
        "The save data you uploaded has expired. You are probably using an old save file, a save file for a wrong kingdom, or a save file created by a different user. Check out the <a href='faq.html'>troubleshooting section</a> for more information."
    ]
    result = savparser.perform(user.id, save)
    kingdom = ""
    if type(result) is tuple:
        result, kingdom = result
    if result:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json(savparser_errors[result])]
    response = {"success": True}
    if kingdom == 'pwnage04':
        response['good_work'] = "<b>You have completed all four Pwnage Kingdom challenges. All residents of Glitch Islands are in awe of your glitching and hacking skills. Congratulations!</b><br><br>Hope you enjoyed your stay. How about exploring the rest of the world now? And better yet, try to do it all legitimately!";
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(response)]

@rt.route("^/save/[0-f]+$", ["GET"])
def appQueueGetSave(environ, start_response):
    session_key = environ['PATH_INFO'].split('/')[-1]
    user = storage.get_user_by_sessid(session_key)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/save", user, environ)
    q = storage.sql("""
        SELECT save_uid
        FROM progress
        WHERE user_id = ?
    """, (user.id,))[0]
    with open(config.DATA_DIRECTORY + "/save/%s.sav" % q.save_uid, "rb") as f:
        save_data = f.read()
    start_response('200 OK', [
        ("Content-Type", "application/octet-stream"),
        ("Content-Disposition", "attachment; filename=fools.sav")
    ])
    return [save_data]

@rt.route("^/profile/")
def appUserProfile(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    q = storage.sql("""
        SELECT
            users.username AS username,
            users.message AS message,
            users.registered_ip AS ip,
            progress.tokens_used AS tokens_spent,
            progress.visited_kingdoms AS kingdoms,
            progress.save_blob AS save_data,
            progress.save_uid AS save_uid,
            progress.cur_kingdom AS cur_kingdom,
            leaderboard.score AS score,
            leaderboard.highest_rank AS highest_rank,
            leaderboard.achievements AS achievements
        FROM users
        LEFT OUTER JOIN leaderboard ON leaderboard.user_id = users.id
        LEFT OUTER JOIN progress ON progress.user_id = users.id
        WHERE username = ?
    """, (data.user,))
    if not q:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("This user does not exist.")]
    q = q[0]
    result = {
        "success": True,
        "username": q.username,
        "score": q.score,
        "tokens_spent": q.tokens_spent,
        "kingdoms_visited": len(json.loads(q.kingdoms)),
        "current_rank": q.current_rank,
        "highest_rank": q.highest_rank,
        "achievements": json.loads(q.achievements)
    }
    if user is not None and user.id == config.ADMIN_USER_ID:
        save_data = json.loads(q.save_data)
        html = "<b>Message:</b> %1<br>"
        html += "<b>Visited kingdoms:</b> %2<br>"
        html += "<b>Current kingdom:</b> %3<br>"
        html += "<b>Registered IP address:</b> %4<br>"
        html += "<br>Event flag status:<br><br><div style='overflow-y:scroll;width:100%;height:200px;border:1px solid #ccc;padding:8px'>"
        flags = [i for i in dir(event_flags) if i.startswith("EVENT_")]
        flags.sort(key=lambda x: eval("event_flags.%s" % x))
        for flag in flags:
            if save_data["events"][eval("event_flags.%s" % flag)]:
                html += "<b style='color:green'>%s = True</b><br>" % flag
            else:
                html += "<span style='color:red'>%s = False</span><br>" % flag
        html += "</div><br><b>Save file name if exists:</b><br>`%s`" % q.save_uid
        result["admin"] = [
            html,
            q.message,
            q.kingdoms,
            q.cur_kingdom,
            q.ip
        ]
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/save_bytes/[0-f]+$", ["GET"])
def appQueueGetSaveBytes(environ, start_response):
    session_key = environ['PATH_INFO'].split('/')[-1]
    user = storage.get_user_by_sessid(session_key)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/save_bytes", user, environ)
    q = storage.sql("""
        SELECT save_uid
        FROM progress
        WHERE user_id = ?
    """, (user.id,))[0]
    with open(config.DATA_DIRECTORY + "/save/%s.sav" % q.save_uid, "rb") as f:
        save_data = f.read()
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True, "sav": list(save_data)})]

@rt.route("^/get_settings/")
def appGetSettings(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/get_settings", user, environ)
    q = storage.sql("""
        SELECT message, rtc
        FROM users
        WHERE id = ?
    """, (user.id,))[0]
    result = {
        "success": True,
        "message": q.message,
        "rtc": q.rtc
    }
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes(result)]

@rt.route("^/set_message/")
def appSetMessage(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/set_message", user, environ)
    if len(data.message) > 150:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("Message is too long.")]
    q = storage.sql("""
        UPDATE users
        SET message = ?
        WHERE id = ?
    """, (data.message, user.id))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^/set_rtc/")
def appSetRTC(environ, start_response):
    data = util.get_json_post(environ)
    user = storage.get_user_by_sessid(data.sessid)
    if user is None:
        start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
        return [util.err_json("You are not logged in.")]
    logger.bigbrother("/set_rtc", user, environ)
    val = 1 if int(data.rtc) else 0
    q = storage.sql("""
        UPDATE users
        SET rtc = ?
        WHERE id = ?
    """, (val, user.id))
    start_response('200 OK', HEADERS_JSON + HEADERS_CORS)
    return [util.json_bytes({"success": True})]

@rt.route("^.*$")
def appDefault(environ, start_response):
    start_response('404 Not Found', HEADERS_HTML + HEADERS_CORS)
    html = '''
        <script>window.location = 'https://zzazzdzz.github.io/fools2019/'</script>
        <center>
            <span style="font-size: 200px">bepis 404</span>
            <br><br><br>
            <a href='https://zzazzdzz.github.io/fools2019/'>
                Click here if your browser doesn't redirect you automatically
            </a>
        </center>
    '''
    return [bytes(html, 'utf-8')]

if __name__ == "__main__":
    augment.init()
    compiler.start_service()
    tokens.start_service()
    torbanlist.prepare()

    import wsgiserver
    server = wsgiserver.WSGIServer(rt, host='127.0.0.1', port=12710)
    server.start()
