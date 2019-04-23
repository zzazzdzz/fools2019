var API_SERVER = "http://127.0.0.1:12710";

var LOCATIONS = [
    {"id": "k01", "name": "Tutorial Kingdom", "pos": [4, 3], "requirement": 0, "unlock": ""},
    {"id": "k02", "name": "Verdant Kingdom", "pos": [6, 5], "requirement": 1, "unlock": "Finish Tutorial Kingdom to unlock."},
    {"id": "k03", "name": "Bootleg Kingdom", "pos": [14, 4], "requirement": 1, "unlock": "Finish Tutorial Kingdom to unlock."},
    {"id": "final", "name": "Central Kingdom", "pos": [11, 7], "requirement": -6, "unlock": "Finish Tutorial, Verdant, Bootleg, Seaside, Throwback and Joyful Kingdom to unlock."},
    {"id": "k04", "name": "Seaside Kingdom", "pos": [17, 10], "requirement": 2, "unlock": "Finish % more kingdoms to unlock."},
    {"id": "k06", "name": "Throwback Kingdom", "pos": [19, 7], "requirement": 2, "unlock": "Finish % more kingdoms to unlock."},
    {"id": "k05", "name": "Joyful Kingdom", "pos": [4, 12], "requirement": 2, "unlock": "Finish % more kingdoms to unlock."},
    {"id": "pwnage01", "name": "Pwnage Kingdom I", "pos": [26, 8], "requirement": -1, "unlock": "Finish Tutorial Kingdom to unlock."},
    {"id": "pwnage02", "name": "Pwnage Kingdom II", "pos": [24, 11], "requirement": -2, "unlock": "Finish Pwnage Kingdom I to unlock."},
    {"id": "pwnage03", "name": "Pwnage Kingdom III", "pos": [22, 14], "requirement": -3, "unlock": "Finish Pwnage Kingdom II to unlock."},
    {"id": "pwnage04", "name": "Pwnage Kingdom IV", "pos": [26, 14], "requirement": -4, "unlock": "Finish Pwnage Kingdom III to unlock."},
    {"id": "last", "name": "???", "pos": [23, 3], "requirement": -5, "unlock": "Defeat the Glitch Lord and obtain all achievements from the &quot;Exploration&quot; category to unlock"}
];

function entities(s){
    return $('<div>').text(s).html();
}

function formatTimeDiff(diff){
    var time_split = [];
    time_split.push(diff % 60);
    diff = Math.floor(diff / 60);
    time_split.push(diff % 60);
    diff = Math.floor(diff / 60);
    time_split.push(diff % 24);
    diff = Math.floor(diff / 24);
    time_split.push(diff);
    time_split.reverse();
    var suffixes = ["days", "hours", "minutes", "seconds"];
    for (var i=0; i<suffixes.length; i++){
        suffixes[i] = time_split[i] + " " + suffixes[i];
        // if (time_split[i] == 0) suffixes.splice(i, 1);
    }
    return suffixes.join(", ");
}

function formatPlace(x){
    if (x >= 10 && x <= 19) return x + "th";
    return x + ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th"][x % 10];
}

function formatKingdom(x){
    if (x == "none") return "world map";
    for (i in LOCATIONS){
        if (x == LOCATIONS[i]['id']){
            return LOCATIONS[i]['name'];
        }
    }
    return "bepis";
}

function updateTimers(){
    var now = parseInt(+new Date() / 1000);
    var untilEventEnd = 1554732000 - now;
    var untilServerShutdown = 1556020800 - now;
    if (untilEventEnd > 0){
        $('#countdown').html(formatTimeDiff(untilEventEnd) + " until the end of the event.");
    }else{
        if (untilServerShutdown > 0){
            $('#countdown').html("The event has ended. " + formatTimeDiff(untilServerShutdown) + " until server shutdown and source code release.");
        }else{
            $('#countdown').html("The event has ended. Thanks for participating!");
        }
    }
}

function buildNavbar(){
    var sessid = localStorage["sessid"] || "0";
    var req = $.get(API_SERVER + "/ping/" + sessid);
    req.done(function(x){
        if (!x['success']){
            modalMessageUnclosable(x['message']);
            return;
        }
        var html = '<ul class="nav navbar-nav">';
        if (x['completionist']){
            LOCATIONS[LOCATIONS.length - 1]['name'] = atob('TGFzdCBHb29kYnll');
        }
        if (x['logged_in']){
            html += '<li><a href="/"><b>Leaderboard</b> (' + x['points'] + ' points)</a></li>';
            html += '<li><a href="play.html"><b>Play</b> (in ' + entities(formatKingdom(x['cur_kingdom'])) + ')</a></li>';
            html += '<li><a href="augment.html"><b>Augment</b> (tokens: <span id="augment-tokens-count">' + entities(x['tokens']) + '</span>)</a></li>';
            html += '<li><a href="faq.html"><b>How to play</b></a></li>';
            html += '<li><a href="profile.html"><b>Your profile</b></a></li>';
            html += '</ul><ul class="nav navbar-nav navbar-right">';
            html += '<li><a href="#" onclick="logout()"><span class="glyphicon glyphicon-log-in"></span> &nbsp;<b>Log out</b> (' + entities(x['username']) + ')</a></li>';
            html += '</ul>';
        }else{
            html += '<li><a href="/"><b>Leaderboard</b></a></li>';
            html += '<li><a href="register.html"><b>Register</b></a></li>';
            html += '<li><a href="faq.html"><b>How to play</b></a></li>';
            html += '</ul><ul class="nav navbar-nav navbar-right">';
            html += '<li><a href="login.html"><span class="glyphicon glyphicon-log-in"></span> &nbsp;<b>Log in</b></a></li>';
            html += '</ul>';
            localStorage["sessid"] = "";
        }
        $("#navbar").html(html);
        $("#loader").css("display", "none");
        $("#content").css("display", "block");
        x['sessid'] = localStorage['sessid'];
        window.SESSION = x;
        if (window.onPingCompleted) window.onPingCompleted(x);
    });
    req.fail(function(xhr){
        if (xhr.status == 503) modalMessage("It appears you are making an excessive amount of requests. To ensure our service is available for everyone at all times, we had to cut you off temporarily. Don't worry, just press OK after a minute or two to refresh this page. However, be informed that further incidents like this may result in your IP getting banned.");
        else modalMessage("Could not connect to the event server. Wait a few seconds, then press OK to refresh this page.");
        setInterval(function(){
            if (!isModalDisplayed()) window.location.reload();
        }, 500);
    });
}

function updateTooltips(){
    $('[data-tooltip]').each(function(a, e){
        e.title = e.getAttribute('data-tooltip');
        $(e).tooltip({html: true});
        e.title = '';
    });
}

function modalMessage(m){
    $("<div class='f-modal-window'>" + m + "<br><br><a href='#' rel='modal:close' class='btn btn-default'>OK</a></div>").modal({escapeClose: false, clickClose: false, showClose: false});
}

function modalMessageUnclosable(m){
    $("<div class='f-modal-window'>" + m + "</div>").modal({escapeClose: false, clickClose: false, showClose: false});
}

function modalMessageWithRedirect(m, p){
    $("<div class='f-modal-window'>" + m + "<br><br><a href='#' onclick='window.location=\"" + p + "\"' class='btn btn-default'>OK</a></div>").modal({escapeClose: false, clickClose: false, showClose: false});
}

function modalYesNo(m, f){
    $("<div class='f-modal-window'>"+m+"<br><br><a href='#' class='btn btn-success' onclick='"+f+"'>Yes</a> <a href='#' rel='modal:close' class='btn btn-default'>No</a></div>").modal({escapeClose: false, clickClose: false, showClose: false});
}

function travelToKingdomModal(k){
    modalYesNo("Are you sure you want to enter <b>" + formatKingdom(k) + "</b>?", 'travelToKingdom("' + k + '")');
}

function travelToKingdom(k){
    $(".f-modal-window").html("We are now generating your world...<br><br><img src='img/loading.svg' style='width: 50px'>");
    var req = $.post(API_SERVER + "/travel/", {
        "sessid": localStorage['sessid'],
        "kingdom": k
    });
    req.fail(function(){
        modalMessage("Could not connect to the event server. Try again in a few minutes.");
        loaderFinish();
    });
    req.done(function(x){
        if (x['success']){
            setTimeout(function(){
                window.location = "play.html";
            }, 4000);
        }else{
            modalMessage("An error occured: " + x['message']);
            loaderFinish();
        }
    });
}

$(document).ready(function(){
    updateTimers();
    buildNavbar();
    setInterval(updateTimers, 1000);
});

var loader = null;
var disabledElms = [];

function loaderStart(e, disableList){
    loader = e;
    $(e).attr("data-tx", $(e).html());
    disabledElms = disableList;
    $(e).html("<img src='img/loading.svg' class='f-inline-loader'>");
    for (var i=0; i<disableList.length; i++){
        disableList[i].disabled = true;
    }
    e.disabled = true;
}

function loaderFinish(){
    $(loader).html($(loader).attr("data-tx"));
    for (var i=0; i<disabledElms.length; i++){
        disabledElms[i].disabled = false;
    }
    loader.disabled = false;
}

function isModalDisplayed(){
    var w = $('.f-modal-window');
    if (!w.length) return false;
    if (w.css("display") == "none") return false;
    return true;
}

function renderWorldMapLocations(){
    for (i in LOCATIONS){
        var unlock = "";
        var is_locked = LOCATIONS[i]['requirement'] > SESSION['kingdoms_visited'];
        if (LOCATIONS[i]['requirement'] == -1) is_locked = !SESSION['pwnzord_i'];
        if (LOCATIONS[i]['requirement'] == -2) is_locked = !SESSION['pwnzord_ii'];
        if (LOCATIONS[i]['requirement'] == -3) is_locked = !SESSION['pwnzord_iii'];
        if (LOCATIONS[i]['requirement'] == -4) is_locked = !SESSION['pwnzord_iv'];
        if (LOCATIONS[i]['requirement'] == -5) is_locked = !SESSION['completionist'];
        if (LOCATIONS[i]['requirement'] == -6) is_locked = !SESSION['central_unlocked'];
        if (is_locked){
            unlock = "&lt;br&gt;&lt;i&gt;" + LOCATIONS[i]['unlock'] + "&lt;/i&gt;";
        }
        unlock = unlock.replace("%", LOCATIONS[i]['requirement'] - SESSION['kingdoms_visited']);
        var elm = $("<div class='f-world-map-location f-location-" + (unlock ? "inactive" : "active") + "' style='left: " + (LOCATIONS[i]['pos'][0]*24) + "px; top: " + (LOCATIONS[i]['pos'][1]*24-1) + "px' data-tooltip='&lt;b&gt;" + LOCATIONS[i]['name'] + "&lt;/b&gt;" + unlock + "' onclick='" + (unlock ? "" : "travelToKingdomModal(\"" + LOCATIONS[i]['id'] + "\")") + "'></div>");
        $("#world_map").append(elm);
    }
    updateTooltips();
}

function unixTimestamp(){
    return Math.floor((+new Date()) / 1000);
}

function visitTimerRefresh(){
    var duration = unixTimestamp() - SESSION['visit_started'];
    var mins = Math.floor(duration / 60);
    var secs = duration % 60;
    if (secs < 10) secs = "0" + secs;
    $("#kingdom-visit-counter").text(mins + ":" + secs);
}

var AUGMENT = {}

function updateAugmentInformation(){
    var augmentTypes = {
        "adjective": "an adjective",
        "noun": "a noun",
        "verb": "a verb",
        "any": "a proper name",
        "freestyle": "anything"
    };
    var augmentBareTypes = {
        "adjective": "adjective",
        "noun": "noun",
        "verb": "verb",
        "any": "proper name",
        "freestyle": "anything"
    };
    $("#augment-current-type").text(augmentTypes[AUGMENT['type']]);
    $("#augment-current-len").text(AUGMENT['max_length']);
    if (AUGMENT['context']){
        $("#augment-current-context").html("<br>Context in a sentence: <i>" + AUGMENT['context'].replace(/\@/g, "<span style='color:red'>(" + augmentBareTypes[AUGMENT['type']] + ")</span>") + "</i>");
    }else{
        $("#augment-current-context").text("");
    }
}

function logout(){
    localStorage['sessid'] = '';
    window.location.href = "index.html";
}