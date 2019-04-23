# Cryptographic secrets. You should set them to something, well, secret.
# In order to generate strong cryptographic secrets for use in fools2019,
# please apply your face to the keyboard and roll.

PASSWORD_SALT = b"X"
SECRET_KEY = b"X"

# Recaptcha secret API key. The captcha type should be "v2 Tickbox".
# Get an API key at https://www.google.com/recaptcha/.

# You can choose to not use Recaptcha if you want - if you do, set this
# variable to "bepis". This will skip server side verification of Recaptcha
# challenges. Captcha fields will still appear in forms, they just won't
# be verified. If you want to remove them from HTML to make the site completely
# captcha-free, you definitely can, but you're on your own on that one.

# And if you decide to use Recaptcha with your own key, remember to change
# the site key too! It appears twice, in augment.html and register.html.

RECAPTCHA_SECRET = "bepis"

# The project's root directory. Provide an absolute path!

ROOT_DIRECTORY = "/srv/fools2019"

# All other directories. Repoint these if you want, but you should generally
# leave these ones alone.

SERVICE_DIRECTORY = ROOT_DIRECTORY + "/server/generator"
SAV_DIRECTORY = ROOT_DIRECTORY + "/sav"
EXTRAS_DIRECTORY = ROOT_DIRECTORY + "/sav/extras"
WORDNET_DIRECTORY = ROOT_DIRECTORY + "/wordnet"
LOG_DIRECTORY = ROOT_DIRECTORY + "/server/log"
DATA_DIRECTORY = ROOT_DIRECTORY + "/server/data"

# Absolute path to your RGBASM binary.

RGBASM = r"rgbasm"

# List of kingdoms that have multiple versions (_pre and _post).

DUAL_KINGDOMS = ["k01", "k02", "k03", "k04", "k05", "k06", "final"]

# List of kingdoms that can be augmented.

AUGMENTABLE_KINGDOMS = ["k01", "k02", "k03", "k04", "k05", "k06"]

# List of all kingdoms.

ALL_KINGDOMS = ["k01", "k02", "k03", "k04", "k05", "k06", "final", "last", "pwnage01", "pwnage02", "pwnage03", "pwnage04"]

# Ratelimiting options. Setting them to 0 will disable ratelimiting.

RATELIMIT_VISIT_KINGDOM = 5 * 60      # 5 minutes
RATELIMIT_FINISH_KINGDOM = 30         # 30 seconds
RATELIMIT_AUGMENT = 30                # 30 seconds

# Setting DEBUG to True will cause the server to crash on error, instead of
# giving a generic "oopsie woopsie" message. Don't set this in production.

DEBUG = False

# ID of the admin user. 0 = no admin user.
# By default, the first user created (ID=1) will be the admin.

ADMIN_USER_ID = 1

# IP of the admin user. If requesting the API with this IP address, the site
# will be always available, even if the event has ended or the server is set
# to maintenance mode.

ADMIN_IP = "0.0.0.0"

# Once this UNIX timestamp is reached, the server will enter maintenance mode.
# Change the exact maintenance message in router.py.

EVENT_END = 1956020800

# The SQLite database file.

DB_FILE = DATA_DIRECTORY + '/db.sqlite3'
