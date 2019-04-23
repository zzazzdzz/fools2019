# fools2019

TheZZAZZGlitch's April Fools Event 2019. [Here's a more accurate description of what this is](https://zzazzdzz.github.io/fools2019/).
Note: Everything here is kept for historical record. Any bugs and issues will not be resolved. Fork the repository if you wish to build something on top of it.

# Contents

- *sav/* - the base event save file, including map data templates for all of the different kingdoms.
- *server/* - the backend server, responsible for compiling save files and handling all of the usual event stuff (users, achievements, keeping track of progress).
- *site/* - the event site, just like it was on the 1st of April; along with the HTML5 game client.
- *wordnet/* - [WordNet](https://wordnet.princeton.edu/) databases, for use in the augmentation system.
- *extras/* - some other useful things, like configuration files and DDL database dumps.
- *docs/* - just the [project site](https://zzazzdzz.github.io/fools2019/), nothing useful here.

# Setup instructions

## First, get the save compiler going

You'll need [RGBDS v0.3.3](https://github.com/rednex/rgbds/releases) to compile save files. Newer versions might work, but are untested - you should just stick to v0.3.3 to avoid dealing with hard to detect bugs. You should also have Python 3 installed. The compilation system uses the [rgbbin](https://github.com/zzazzdzz/rgbbin) library, but to make your and everyone's life easier, this is already included.

After that comes configuration. Open *server/config.py* and make sure to change the following:

- *ROOT_DIRECTORY* should be an absolute path to the project's root directory. Example: *"/srv/fools2019"*.
- *RGBASM* should point to the rgbasm binary you want to use to compile the save files. Example: *"/usr/local/bin/rgbasm"*.

This is the minimal amount of changes required to get things working, but if you want to run fools2019 in a production environment, you should probably look through some other settings too.

Time to test it! Run `python3 compiler.py`. This will try to compile a test save file. If you don't see any errors and a *fools.sav* file appears in your *sav/* directory, then you know it worked. You can also play around and try compiling different save files, by changing the test session defined in *mocksession.py*.

## Then, run the backend server

The server requires the *wsgiserver* module. Install it with `pip3 install wsgiserver`. You can then run `python3 main.py` in the *server/* directory, which will start the backend on 127.0.0.1:12710. You can try going to http://127.0.0.1:12710/ping/0 to see it working.

If you only want to run fools2019 on localhost, that should be enough. However, if you want to set up a public server, you'll need to keep some things in mind. First, go through the *config.py* file and set reasonable values for all of the settings - most importantly, make sure to change your cryptographic secrets from the default "X". Next, the backend only listens on localhost by default, and you need to make it world-reachable. The recommended way is to set up whatever web server you want as a reverse proxy - the official event site used [nginx](http://nginx.org/). Last, make sure that the event server process is managed in some way (runs in background, it will be restarted if it dies, it does not run with root privileges, etc.) - for that, the official event site used [supervisor](http://supervisord.org/). An example supervisor script to run fools2019 is included in *extras/*.

## Last, host the event site

The event site (in *site/*) is just a bunch of static HTML, so it can be hosted however you want - there's no special requirements. Just remember to change the API_SERVER variable in *script.js* to match your configuration. You can quickly spin up a development HTTP server with Python: `python3 -m http.server`.

You should now have a complete instance of Fools2019 up and running!

# Everything else

The backend runs on a SQLite database, which is stored by default in *server/data/db.sqlite3*. This repository comes with a fresh, clean database (which is also at *extras/db.clean.sqlite3*, should you ever want to bring a fresh version back). With the default configuration in *server/config.py*, the first registered user will become an admin user - keep that in mind!

There is a feature to hide accounts from leaderboard by setting their score to -1. This might be useful if you want your administration account's username to be hidden from whatever reason. The server does not keep an exclusive lock on the database at all times, so you can edit the database file anytime you choose.

By default, fools2019 will store logs into *server/log* - general logs of server operation are kept in *fools2019.log*, while detailed logs of each user's operation are kept in *bigbrother.log*. You can also mess around with *logger.py* to disable/enable things like logging to stdout, or ANSI escape sequences for cool terminal colors in logs.

IPs can be permanently banned from accessing the site by adding them (one per line) to *server/data/tor.txt*. This was a security feature active during the event that prevented access from anonymous proxies and Tor exit nodes. In this release the list is empty, but you can populate it with any IPs you wish to block.

Map data (or more precisely map templates, since maps can differ for each user), are located in *sav/template/maps/*. You can edit BLK files with [Polished Map](https://github.com/Rangi42/polished-map). Editing map scripts is obvious enough if you had any Gen II scripting experience. If you change any maps, make sure to change their metadata too! The anticheat uses metadata files to check which items and event flags are available in a given kingdom. These files are called *meta.txt*, there's one for every kingdom.

Augments are defined in *sav/template/maps/augment.txt*.

Save files of all users are stored in *server/data/save*. Only the most recent save file of each user is stored, since 10000 different 32 KB files add up to a significant amount of space.

Also, there are no unused maps. Sorry for all of you hoping for some bepis. Have fun!