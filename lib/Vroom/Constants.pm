package Vroom::Constants;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw/DB_VERSION COMPONENTS MOH JS_STRINGS API_ACTIONS API_NO_LOG/;

# Database version
use constant DB_VERSION => 8;

# Components used to generate the credits part
use constant COMPONENTS => {
  "SimpleWebRTC" => {
    url => 'http://simplewebrtc.com/'
  },
  "Mojolicious" => {
    url => 'http://mojolicio.us/'
  },
  "Mojolicious::Plugin::I18N" => {
    url => 'https://github.com/sharifulin/Mojolicious-Plugin-I18N'
  },
  "Mojolicious::Plugin::Mail" => {
    url => 'https://github.com/sharifulin/Mojolicious-Plugin-Mail'
  },
  "Mojolicious::Plugin::Database" => {
    url => 'https://github.com/benvanstaveren/Mojolicious-Plugin-Database'
  },
  "Mojolicious::Plugin::StaticCompressor" => {
    url => 'https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor'
  },
  "Mojo::Redis2" => {
    url => 'https://github.com/jhthorsen/mojo-redis2'
  },
  "Crypt::SaltedHash" => {
    url => 'https://github.com/campus-explorer/crypt-saltedhash'
  },
  "Session::Token" => {
    url => 'https://github.com/hoytech/Session-Token'
  },
  "Config::Simple" => {
    url => 'http://search.cpan.org/~sherzodr/Config-Simple/'
  },
  "Email::Valid" => {
    url => 'https://github.com/rjbs/Email-Valid'
  },
  "Protocol::SocketIO" => {
    url => 'https://github.com/vti/protocol-socketio'
  },
  "DateTime" => {
    url => 'https://github.com/autarch/DateTime.pm'
  },
  "Array::Diff" => {
    url=> 'https://github.com/typester/array-diff-perl'
  },
  "Locale::Maketext::Lexicon" => {
    url => 'https://github.com/clintongormley/locale-maketext-lexicon'
  },
  "Etherpad" => {
    url => 'https://git.framasoft.org/luc/etherpad'
  },
  "Mojolicious::Plugin::RenderFile" => {
    url => 'https://github.com/koorchik/Mojolicious-Plugin-RenderFile'
  },
  "Excel::Writer::XLSX" => {
    url => 'https://github.com/jmcnamara/excel-writer-xlsx'
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
  "Bootstrap" => {
    url => 'http://getbootstrap.com/'
  },
  "MariaDB" => {
    url => 'https://mariadb.org/'
  },
  "FileSaver" => {
    url => 'https://github.com/eligrey/FileSaver.js'
  },
  "WPZOOM Developer Icon Set" => {
    url => 'https://www.iconfinder.com/search/?q=iconset%3Awpzoom-developer-icon-set'
  },
  "Bootstrap Switch" => {
    url => 'http://www.bootstrap-switch.org/'
  },
  "bootpag" => {
    url => "http://botmonster.com/jquery-bootpag/"
  },
  "tocjs" => {
    url => "https://github.com/nghuuphuoc/tocjs"
  },
  "bootstrap-datpicker" => {
    url => "https://bootstrap-datepicker.readthedocs.org/en/latest/"
  },
  "Redis" => {
    url => "http://redis.io/"
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

# API actions
use constant API_ACTIONS => {
  admin => {
    get_room_list  => 1,
    get_event_list => 1,
  },
  owner => {
    invite_email       => 1,
    promote_peer       => 1,
    wipe_data          => 1,
    delete_room        => 1,
    update_room_conf   => 1
  },
  participant => {
    get_room_info    => 1,
    get_room_conf    => 1,
    get_peer_role    => 1,
    join             => 1,
    get_pad_session  => 1,
    get_rtc_conf     => 1 
  },
  anonymous => {
    create_room  => 1,
    authenticate => 1
  }
};

# List of API actions for which we do not want to log an event
use constant API_NO_LOG => qw(get_event_list get_room_list);

1;
