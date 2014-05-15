/*global console*/
var config = require('getconfig'),
    uuid = require('node-uuid'),
    mysql = require('mysql'),
    cookie_reader = require('cookie'),
    io = require('socket.io').listen(config.server.port);

var sql = mysql.createConnection({
  host     : config.mysql.server,
  database : config.mysql.database,
  user     : config.mysql.user,
  password : config.mysql.password});

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

function checkRoom(room,token,user) {
   var q = "SELECT participant FROM participants WHERE participant='" + user + "' AND id IN (SELECT id FROM rooms WHERE name='" + room + "' AND token='" + token + "');";
   console.log('Checking if ' + user + ' is allowed to join room ' + room + ' using token ' + token);
   sql.query(q, function(err, rows, fields) {
      if (err) throw err;
      // No result ? This user hasn't joined this room through our frontend
      if (rows.length < 1) return false;
   });
   return true;
}

io.configure(function(){
  io.set('authorization', function(data, accept){
    if(data.headers.cookie){
      data.cookie = cookie_reader.parse(data.headers.cookie);
      var session = data.cookie['vroomsession'];
      if (typeof session != 'string'){
        console.log('Cookie vroomsession not found, access unauthorized');
        return ('error', false);
      }
      // vroomsession is base64(user:room:token) so let's decode this !
      session = new Buffer(session, encoding='base64');
      var tab = session.toString().split(':');
      var user  = tab[0],
          room  = tab[1],
          token = tab[2];
      // sanitize user input, we don't want to pass random junk to MySQL do we ?
      if (!user.match(/^[\w\@\.\-]{1,40}$/i) || !room.match(/^[\w\-]{1,50}$/) || !token.match(/^[a-zA-Z0-9]{50}$/)){
        console.log('Forbidden chars found in either participant session, room name or token, sorry, cannot allow this');
        return ('error', false);
      }
      // Ok, now check if this user has joined the room (with the correct token) through vroom frontend
      if (checkRoom(room,token,user) == false){
        console.log('Sorry, but ' + participant + ' is not allowed to join room ' + name);
        return ('error', false);
      }
      return accept(null, true);
    }
    console.log('No cookies were found, access unauthorized');
    return accept('error', false);
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
        if (client.room) removeFeed('screen');
    });

    client.on('join', join);

    function removeFeed(type) {
        io.sockets.in(client.room).emit('remove', {
            id: client.id,
            type: type
        });
    }

    function join(name, cb) {
        // sanity check
        if (typeof name !== 'string') return;
        // leave any existing rooms
        if (client.room) removeFeed();
        safeCb(cb)(null, describeRoom(name))
        client.join(name);
        client.room = name;
    }

    // we don't want to pass "leave" directly because the
    // event type string of "socket end" gets passed too.
    client.on('disconnect', function () {
        removeFeed();
    });
    client.on('leave', removeFeed);

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
});

if (config.uid) process.setuid(config.uid);
console.log('signal master is running at: http://localhost:' + config.server.port);
