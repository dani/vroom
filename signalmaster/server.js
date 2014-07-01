/*global console*/
var config = require('getconfig'),
    uuid = require('node-uuid'),
    mysql = require('mysql'),
    cookie_reader = require('cookie'),
    crypto = require('crypto'),
    port = parseInt(process.env.PORT || config.server.port, 10),
    io = require('socket.io').listen(port);

var sql = mysql.createConnection({
  host     : config.mysql.server,
  database : config.mysql.database,
  user     : config.mysql.user,
  password : config.mysql.password});

if (config.logLevel) {
    // https://github.com/Automattic/socket.io/wiki/Configuring-Socket.IO
    io.set('log level', config.logLevel);
}

function describeRoom(name) {
    var clients = io.sockets.clients(name);
    var result = {
        clients: {}
    };
    clients.forEach(function (client) {
        result.clients[client.id] = client.resources;
    });
    return result;
}

function safeCb(cb) {
    if (typeof cb === 'function') {
        return cb;
    } else {
        return function () {};
    }
}

function checkRoom(room,token,user,cb) {
   var q = "SELECT `participant` FROM `participants` WHERE `participant`=" + sql.escape(user) + " AND `id` IN (SELECT `id` FROM `rooms` WHERE `name`=" + sql.escape(room) + " AND `token`=" + sql.escape(token) + ");";
   console.log('Checking if ' + user + ' is allowed to join room ' + room + ' using token ' + token);
   sql.query(q, function(err, rows, fields) {
      if (err){
        throw err;
      }
      // No result ? This user hasn't joined this room through our frontend
      if (rows.length > 0){
        cb(true);
      }
      else{
        cb(false);
      }
   });
}

io.configure(function(){
  io.set('close timeout', 40);
  io.set('heartbeat timeout', 20);
  io.set('heartbeat interval', 5);
  io.set('authorization', function(data, accept){
    if(data.headers.cookie){
      data.cookie = cookie_reader.parse(data.headers.cookie);
      var session = data.cookie['vroomsession'];
      if (typeof session != 'string'){
        console.log('Cookie vroomsession not found, access unauthorized');
        accept('vroomsession cookie not found', false);
      }
      else{
        // vroomsession is base64(user:room:token) so let's decode this !
        session = new Buffer(session, encoding='base64');
        var tab = session.toString().split(':');
        var user  = tab[0],
            room  = tab[1],
            token = tab[2];
        // sanitize user input, we don't want to pass random junk to MySQL do we ?
        if (!user.match(/^[\w\@\.\-]{1,40}$/i) || !room.match(/^[\w\-]{1,50}$/) || !token.match(/^[a-zA-Z0-9]{50}$/)){
          console.log('Forbidden chars found in either participant session, room name or token, sorry, cannot allow this');
          accept('Forbidden characters found', false);
        }
        else{
          // Ok, now check if this user has joined the room (with the correct token) through vroom frontend
          checkRoom(room,token,user, function(res){
            if (res){
              accept(null, true);
            }
            else{
              console.log('User' + user + ' is not allowed to join room ' + room + ' with token ' + tohen);
              accept('not allowed', false);
            }
          });
        }
      }
    }
    else{
      accept('No cookie found', false);
    }
  });
});

io.sockets.on('connection', function (client) {
    client.resources = {
        screen: false,
        video: true,
        audio: false
    };

    // pass a message to another id
    client.on('message', function (details) {
        var otherClient = io.sockets.sockets[details.to];
        if (!otherClient) return;
        details.from = client.id;
        otherClient.emit('message', details);
    });

    client.on('shareScreen', function () {
        client.resources.screen = true;
    });

    client.on('unshareScreen', function (type) {
        client.resources.screen = false;
        removeFeed('screen');
    });

    client.on('join', join);

    function removeFeed(type) {
        if (client.room) {
            io.sockets.in(client.room).emit('remove', {
                id: client.id,
                type: type
            });
            if (!type) {
                client.leave(client.room);
                client.room = undefined;
            }
        }
    }

    function join(name, cb) {
        // sanity check
        if (typeof name !== 'string') return;
        // leave any existing rooms
        removeFeed();
        safeCb(cb)(null, describeRoom(name));
        client.join(name);
        client.room = name;
    }

    // we don't want to pass "leave" directly because the
    // event type string of "socket end" gets passed too.
    client.on('disconnect', function () {
        removeFeed();
    });
    client.on('leave', function () {
        removeFeed();
    });

    client.on('create', function (name, cb) {
        if (arguments.length == 2) {
            cb = (typeof cb == 'function') ? cb : function () {};
            name = name || uuid();
        } else {
            cb = name;
            name = uuid();
        }
        // check if exists
        if (io.sockets.clients(name).length) {
            safeCb(cb)('taken');
        } else {
            join(name);
            safeCb(cb)(null, name);
        }
    });

    // tell client about stun and turn servers and generate nonces
    if (config.stunservers) {
        client.emit('stunservers', config.stunservers);
    }
    if (config.turnservers) {
        // create shared secret nonces for TURN authentication
        // the process is described in draft-uberti-behave-turn-rest
        var credentials = [];
        config.turnservers.forEach(function (server) {
            var hmac = crypto.createHmac('sha1', server.secret);
            // default to 86400 seconds timeout unless specified
            var username = Math.floor(new Date().getTime() / 1000) + (server.expiry || 86400) + "";
            hmac.update(username);
            credentials.push({
                username: username,
                credential: hmac.digest('base64'),
                url: server.url
            });
        });
        client.emit('turnservers', credentials);
    }
});

if (config.uid) process.setuid(config.uid);
console.log('signal master is running at: http://localhost:' + port);
