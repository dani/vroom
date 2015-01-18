package Vroom::Constants;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw/COMPONENTS MOH JS_STRINGS API_ACTIONS/;

# Components used to generate the credits part
use constant COMPONENTS => {
  "SimpleWebRTC" => {
    url => 'http://simplewebrtc.com/'
  },
  "Mojolicious" => {
    url => 'http://mojolicio.us/'
  },
  "jQuery" => {
    url => 'http://jquery.com/'
  },
  "notify.js" => {
    url => 'http://notifyjs.com/'
  },
  "jQuery-browser-plugin" => {
    url => 'https://github.com/gabceb/jquery-browser-plugin'
  },
  "jQuery-tinytimer" => {
    url => 'https://github.com/odyniec/jQuery-tinyTimer'
  },
  "jQuery-etherpad-lite" => {
    url => 'https://github.com/ether/etherpad-lite-jquery-plugin'
  },
  "sprintf.js" => {
    url => 'http://hexmen.com/blog/2007/03/printf-sprintf/'
  },
  "node.js" => {
    url => 'http://nodejs.org/'
  },
  "Bootstrap" => {
    url => 'http://getbootstrap.com/'
  },
  "MariaDB" => {
    url => 'https://mariadb.org/'
  },
  "SignalMaster" => {
    url => 'https://github.com/andyet/signalmaster/'
  },
  "rfc5766-turn-server" => {
    url => 'https://code.google.com/p/rfc5766-turn-server/'
  },
  "FileSaver" => {
    url => 'https://github.com/eligrey/FileSaver.js'
  },
  "WPZOOM Developer Icon Set" => {
    url => 'https://www.iconfinder.com/search/?q=iconset%3Awpzoom-developer-icon-set'
  },
  "Bootstrap Switch" => {
    url => 'http://www.bootstrap-switch.org/'
  }
};

# Music on hold used
# Used to generate credits
use constant MOH => {
  "Papel Secante" => {
    author      => "Angel Gaitan",
    author_url  => "http://angelgaitan.bandcamp.com/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Overjazz" => {
    author      => "Funkyproject",
    author_url  => "http://www.funkyproject.fr",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Polar Express" => {
    author      => "Koteen",
    author_url  => "http://?.?",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Funky Goose" => {
    author      => "Pepe Frias",
    author_url  => "http://www.pepefrias.tk/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "I got my own" => {
    author      => "Reole",
    author_url  => "http://www.reolemusic.com/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  }
};

# List of strings needed on client side
use constant JS_STRINGS => qw(
  ERROR_MAIL_INVALID
  ERROR_OCCURRED
  ERROR_NAME_INVALID
  CANT_SHARE_SCREEN
  SCREEN_SHARING_ONLY_FOR_CHROME
  SCREEN_SHARING_CANCELLED
  EVERYONE_CAN_SEE_YOUR_SCREEN
  SCREEN_UNSHARED
  MIC_MUTED
  MIC_UNMUTED
  CAM_SUSPENDED
  CAM_RESUMED
  SET_YOUR_NAME_TO_CHAT
  ROOM_LOCKED_BY_s
  ROOM_UNLOCKED_BY_s
  PASSWORD_PROTECT_ON_BY_s
  PASSWORD_PROTECT_OFF_BY_s
  OWNER_PASSWORD_CHANGED_BY_s
  OWNER_PASSWORD_REMOVED_BY_s
  SCREEN_s
  TO_INVITE_SHARE_THIS_URL
  NO_SOUND_DETECTED
  DISPLAY_NAME_TOO_LONG
  s_IS_MUTING_YOU
  s_IS_MUTING_s
  s_IS_UNMUTING_YOU
  s_IS_UNMUTING_s
  s_IS_SUSPENDING_YOU
  s_IS_SUSPENDING_s
  s_IS_RESUMING_YOU
  s_IS_RESUMING_s
  s_IS_PROMOTING_YOU
  s_IS_PROMOTING_s
  s_IS_KICKING_s
  MUTE_PEER
  SUSPEND_PEER
  PROMOTE_PEER
  KICK_PEER
  YOU_HAVE_MUTED_s
  YOU_HAVE_UNMUTED_s
  CANT_MUTE_OWNER
  YOU_HAVE_SUSPENDED_s
  YOU_HAVE_RESUMED_s
  CANT_SUSPEND_OWNER
  CANT_PROMOTE_OWNER
  YOU_HAVE_KICKED_s
  CANT_KICK_OWNER
  REMOVE_THIS_ADDRESS
  DISPLAY_NAME_REQUIRED
  A_ROOM_ADMIN
  A_PARTICIPANT
  PASSWORDS_DO_NOT_MATCH
  WAIT_WITH_MUSIC
  DATA_WIPED
  ROOM_DATA_WIPED_BY_s
);

# API actions
use constant API_ACTIONS => {
  admin => {
    list_rooms     => 1,
    set_persistent => 1
  },
  owner => {
    invite_email       => 1,
    lock_room          => 1,
    unlock_room        => 1,
    set_join_password  => 1,
    set_owner_password => 1,
    set_ask_for_name   => 1,
    email_notification => 1,
    promote_peer       => 1
  },
  participant => {
    ping          => 1,
    authenticate  => 1,
    get_room_info => 1,
    get_peer_role => 1,
    join          => 1
  }
};

1;
