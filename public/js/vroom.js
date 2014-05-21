/*
This file is part of the VROOM project
released under the MIT licence
Copyright 2014 Firewall Services
*/


// Default notifications
$.notify.defaults( { globalPosition: 'bottom left' } );
// Enable tooltip on required elements
$('.help').tooltip({container: 'body'});

// Strings we need translated
var locale = {
  ERROR_MAIL_INVALID: '',
  ERROR_OCCURED: '',
  CANT_SHARE_SCREEN: '',
  SCREEN_SHARING_ONLY_FOR_CHROME: '',
  SCREEN_SHARING_CANCELLED: '',
  EVERYONE_CAN_SEE_YOUR_SCREEN: '',
  SCREEN_UNSHARED: '',
  MIC_MUTED: '',
  MIC_UNMUTED: '',
  CAM_SUSPENDED: '',
  CAM_RESUMED: '',
  SET_YOUR_NAME_TO_CHAT: '',
  ONE_OF_THE_PEERS: '',
  ROOM_LOCKED_BY_s: '',
  ROOM_UNLOCKED_BY_s: '',
  PASSWORD_PROTECT_ON_BY_s: '',
  PASSWORD_PROTECT_OFF_BY_s: '',
  OWNER_PASSWORD_CHANGED_BY_s: '',
  OWNER_PASSWORD_REMOVED_BY_s: '',
  CANT_SEND_TO_s: '',
  SCREEN_s: '',
  TO_INVITE_SHARE_THIS_URL: '',
  NO_SOUND_DETECTED: '',
  DISPLAY_NAME_TOO_LONG: '',
  s_IS_MUTING_YOU: '',
  s_IS_MUTING_s: '',
  s_IS_UNMUTING_YOU: '',
  s_IS_UNMUTING_s: '',
  s_IS_SUSPENDING_YOU: '',
  s_IS_SUSPENDING_s: '',
  s_IS_RESUMING_YOU: '',
  s_IS_RESUMING_s: '',
  s_IS_KICKING_s: '',
  MUTE_PEER: '',
  SUSPEND_PEER: '',
  KICK_PEER: '',
  YOU_HAVE_MUTED_s: '',
  YOU_HAVE_UNMUTED_s: '',
  CANT_MUTE_OWNER: '',
  YOU_HAVE_SUSPENDED_s: '',
  YOU_HAVE_RESUMED_s: '',
  CANT_SUSPEND_OWNER: '',
  YOU_HAVE_KICKED_s: '',
  CANT_KICK_OWNER: '',
  REMOVE_THIS_ADDRESS: '',
  DISPLAY_NAME_REQUIRED: ''
};

// Localize the strings we need
$.ajax({
  url: rootUrl + 'localize',
  type: 'POST',
  dataType: 'json',
  data: {
    strings: JSON.stringify(locale),
  },
  success: function(data) {
    locale = data;
  }
});

// Popup with the URL to share
function inviteUrlPopup(){
  window.prompt(locale.TO_INVITE_SHARE_THIS_URL, window.location.href);
  return false;
}

// Add a new email address to be notified whn someone joins
function addNotifiedEmail(email){
  var id = email.replace('@', '_AT_').replace('.', '_DOT_');
  $('<li></li>').html(email + '  <a href="javascript:void(0);" onclick="removeNotifiedEmail(\'' + email + '\');" title="' + locale.REMOVE_THIS_ADDRESS + '">' +
                              '    <span class="glyphicon glyphicon-remove-circle"></span>' +
                              '  </a>')
   .attr('id', 'emailNotification_' + id)
   .appendTo('#emailNotificationList');
}

// Remove the address from the list
function removeNotifiedEmail(email){
  var id = email.replace('@', '_AT_').replace('.', '_DOT_');
  $.ajax({
    data: {
      action: 'emailNotification',
      type: 'remove',
      email: email,
      room: roomName
    },
    error: function() {
      $.notify(locale.ERROR_OCCURED, 'error');
    },
    success: function(data) {
      if (data.status == 'success'){
        $.notify(data.msg, 'success');
        $('#emailNotification_' + id).remove();
        webrtc.sendToAll('notif_change', {});
      }
      else{
        $.notify(data.msg, 'error');
      }
    }
  });
}

// Escape entities
function stringEscape(string){
  string = string.replace(/[\u00A0-\u99999<>\&]/gim, function(i) {
    return '&#' + i.charCodeAt(0) + ';';
  });
  return string;
}

// Select a color (randomly) from this list, used for text chat
function chooseColor(){
  // Shamelessly taken from http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
  var colors = [
    '#B1C7FD', '#DDFDB1', '#FDB1F3', '#B1FDF0', '#FDDAB1', '#C4B1FD', '#B4FDB1', '#FDB1CA',
    '#B1E1FD', '#F7FDB1', '#EDB1FD', '#B1FDD7', '#FDC1B1', '#B1B7FD', '#CEFDB1', '#FDB1E4',
    '#B1FAFD', '#FDEAB1', '#D4B1FD', '#B1FDBD', '#FDB1BB', '#B1D1FD', '#E7FDB1', '#FDB1FD',
    '#B1FDE7', '#B1FDE7'
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

// Just play a sound
function playSound(sound){
  var audio = new Audio(rootUrl + 'snd/' + sound);
  audio.play();
}

// Request full screen
function fullScreen(el){
  if (el.requestFullScreen){
    el.requestFullScreen();
  }
  else if (el.webkitRequestFullScreen){
    el.webkitRequestFullScreen();
  }
  else if (el.mozRequestFullScreen){
    el.mozRequestFullScreen();
  }
}

// Linkify urls
// Taken from http://rickyrosario.com/blog/converting-a-url-into-a-link-in-javascript-linkify-function/
function linkify(text){
  if (text) {
    text = text.replace(
      /((https?\:\/\/)|(www\.))(\S+)(\w{2,4})(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/gi,
      function(url){
        var full_url = url;
        if (!full_url.match('^https?:\/\/')) {
          full_url = 'http://' + full_url;
        }
        return '<a href="' + full_url + '" target="_blank">' + url + '</a>';
      }
    );
  }
  return text;
}

// Save content to a file
function downloadContent(filename, content){
  var blob = new Blob([content], {type: 'text/html;charset=utf-8'});
  saveAs(blob, filename);
}

// Return current time formatted as XX:XX:XX
function getTime(){
  var d = new Date();
  var hours   = d.getHours().toString(),
      minutes = d.getMinutes().toString(),
      seconds = d.getSeconds().toString();
  hours   = (hours.length < 2)   ? '0' + hours:hours;
  minutes = (minutes.length < 2) ? '0' + minutes:minutes;
  seconds = (seconds.length < 2) ? '0' + seconds:seconds;
  return hours + ':' + minutes + ':' + seconds;
}

// get max height for the main video and the preview div
function maxHeight(){
  // Which is the window height, minus toolbar, and a margin of 25px
  return $(window).height()-$('#toolbar').height()-25;
}

function initVroom(room) {

  var peers = {
    local: {
      screenShared: false,
      micMuted: false,
      videoPaused: false,
      displayName: '',
      color: chooseColor(),
      role: 'participant'
    }
  };
  var roomInfo;
  var mainVid = false,
      chatHistory = {},
      chatIndex = 0,
      maxVol = -100;

  $('#name_local').css('background-color', peers.local.color);

  $.ajaxSetup({
    url: rootUrl + 'action',
    type: 'POST',
    dataType: 'json',    
  });

  // Screen sharing is only suported on chrome > 26
  if ( !$.browser.webkit || $.browser.versionNumber < 26 ) {
    $('#shareScreenLabel').addClass('disabled');
  }

  // If browser doesn't support webRTC or dataChannels
  if (!webrtc.capabilities.support || !webrtc.capabilities.dataChannel){
    $('#noWebrtcSupport').modal('show');
  }

  // Update our role
  function getRoomInfo(){
    $.ajax({
      data: {
        action: 'getRoomInfo',
        room: roomName,
        id: peers.local.id
      },
      async: false,
      error: function(data){
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data){
        // Notify others if our role changed
        if (data.role != peers.local.role){
          webrtc.sendToAll('role_change', {});
        }
        peers.local.role = data.role;
        roomInfo = data;
        // Enable owner reserved menu
        if (data.role == 'owner'){
          $('.unauthEl').hide(500);
          $('.ownerEl').show(500);
          var notif = JSON.parse(data.notif);
          $.each(notif.email, function(index, val){
            addNotifiedEmail(val);
          });
        }
        else{
          $('.ownerEl').hide(500);
          if (data.owner_auth == 'yes'){
            $('.unauthEl').show(500);
          }
          else{
            $('.unauthEl').hide(500);
          }
        }
        if (data.locked == 'yes'){
          $('#lockLabel').addClass('btn-danger active');
          $('#lockButton').prop('checked', true);
        }
        if (data.ask_for_name == 'yes'){
          $('#askForNameLabel').addClass('btn-danger active');
          $('#askForNameButton').prop('checked', true);
        }
      }
    });
  }

  // Get the role of a peer
  function getPeerRole(id){
    $.ajax({
      data: {
        action: 'getPeerRole',
        room: roomName,
        id: id
      },
      error: function(data){
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data){
        if (peers[id]){
          peers[id].role = data.role;
          if (data.role == 'owner'){
            $('#overlay_' + id).append('<div id="owner_' + id + '" class="owner"></div>');
            $('#ownerActions_' + id).remove();
          }
          else{
            $('#owner_' + id).remove();
          }
        }
      }
    });
  }

  // Logout
  function hangupCall(){
    webrtc.connection.disconnect();
  }

  // Handle a new video (either another peer, or a screen
  // including our own local screen
  function addVideo(video,peer){
    playSound('join.mp3');
    // The main div of this new video
    // will contain the video plus all other info like displayName, overlay and volume bar
    var div = $('<div></div>').addClass('col-xs-6 col-sm-12 col-lg-6 previewContainer').append(video).appendTo('#webRTCVideo');
    // Peer isn't defined ? it's our own local screen
    var id;
    if (!peer){
      id = 'local';
      $('<div></div>').addClass('displayName').attr('id', 'name_local_screen').appendTo(div);
      updateDisplayName(id);
    }
    // video id contains screen ? it's a peer sharing it's screen
    else if (video.id.match(/screen/)){
      id = peer.id + '_screen';
      var peer_id = video.id.replace('_screen_incoming', '');
      $('<div></div>').addClass('displayName').attr('id', 'name_' + peer_id + '_screen').appendTo(div);
      updateDisplayName(peer_id);
    }
    // It's the webcam of a peer
    // add the volume bar and the mute/pause overlay
    else{
      id = peer.id;
      // Create 4 divs which will contains the volume bar, the displayName, the muted/paused and
      // the owner actions (overlay)
      $('<div></div>').addClass('volumeBar').attr('id', 'volume_' + id).appendTo(div);
      $('<div></div>').addClass('displayName').attr('id', 'name_' + id).appendTo(div);
      $('<div></div>').attr('id', 'overlay_' + id).appendTo(div);
      $('<div></div>').addClass('ownerActions').attr('id', 'ownerActions_' + id).appendTo(div)
        .append($('<div></div>',{
           class: 'btn-group'
         })
        .append($('<button></button>', {
           class: 'actionMute btn btn-default btn-sm',
           id: 'actionMute_' + id,
           click: function() { mutePeer(id) },
         }).prop('title', locale.MUTE_PEER))
        .append($('<button></button>', {
           class: 'actionPause btn btn-default btn-sm',
           id: 'actionPause_' + id,
           click: function() { pausePeer(id) },
         }).prop('title', locale.SUSPEND_PEER))
        .append($('<button></button>', {
           class: 'actionKick btn btn-default btn-sm',
           id: 'actionKick_' + id,
           click: function() { kickPeer(id) },
         }).prop('title', locale.KICK_PEER)));
      $(div).hover(
        function(){
          if (peers.local.role == 'owner'){
            $('#ownerActions_' + id).show(200);
          }
        },
        function(){
          $('#ownerActions_' + id).hide(200);
        }
      );
      // Create a new dataChannel
      // will be used for text chat and displayName
      var color = chooseColor();
      peers[peer.id] = {
        displayName: peer.id,
        color: color,
        micMuted: false,
        videoPaused: false,
        dc: peer.getDataChannel('vroom'),
        obj: peer
      };
      // Send our info to this peer (displayName/color)
      // but wait a bit so the "vroom" dataChannel acreated earlier is fully setup (or have more chances to be)
      // before we send
      setTimeout(function(){
        if ($('#displayName').val() !== '') {
          peer.sendDirectly('vroom','setDisplayName', $('#displayName').val());
        }
        peer.send('peer_color', {color: peers.local.color});
        // We don't have chat history yet ? Lets ask to this new peer
        if(!peers.local.hasHistory && chatIndex == 0){
          peer.sendDirectly('vroom', 'getHistory', '');
        }
        // Get the role of this peer
        getPeerRole(peer.id);
      }, 3500);
    }
    $(div).attr('id', 'peer_' + id);
    // Disable context menu on the video
    $(video).bind('contextmenu', function(){
      return false;
    });
    // And go full screen on double click
    // TODO: also handle double tap
    $(video).dblclick(function() {
      fullScreen(this);
    });
    // Simple click put this preview in the mainVideo div
    $(video).click(function() {
      // This video was in the mainVideo div ? lets remove it
      if ($(this).hasClass('selected')){
        $(this).removeClass('selected');
        $('#mainVideo').html('');
      }
      else {
        $('#mainVideo').html($(video).clone().dblclick(function() {
          fullScreen(this);
          }).css('max-height', maxHeight()).bind('contextmenu', function(){ return false; }));
        $('.selected').removeClass('selected');
        $(this).addClass('selected');
        mainVid = id;
      }
    });
  }

  // Update volume of the corresponding peer
  function showVolume(el, volume) {
    if (!el){
      return;
    }
    if (volume < -45) { // vary between -45 and -20
      el.css('height', '0px');
    }
    else if (volume > -20) {
      el.css('height', '100%');
    }
    else {
      el.css('height', Math.floor((volume + 100) * 100 / 25 - 220) + '%');
    }
  }

  // Add a new message to the chat history
  function newChatMessage(from,message,time,color){
    // displayName has already been escaped
    var cl = (from === 'local') ? 'chatMsgSelf':'chatMsgOthers';
    if (!time || !time.match(/^\d{1,2}:\d{1,2}:\d{1,2}$/)){
      time = getTime();
    }
    if (peers[from] && peers[from].color){
      var color = peers[from].color;
      var displayName = peers[from].displayName;
    }
    // this peer might not be defined if we're importing chat history
    // So just use the from as the displayName and the provided color
    else{
      var color = (color && color.match(/#[\da-f]{6}/i)) ? color:chooseColor();
      var displayName = from;
    }
    var newmsg = $('<div class="chatMsg ' + cl + '">' + time + ' ' + stringEscape(displayName) + '<p>' + linkify(stringEscape(message)) + '</p></div>').css('background-color', color);
    $('<div class="row chatMsgContainer"></div>').append(newmsg).appendTo('#chatHistory');
    $('#chatHistory').scrollTop($('#chatHistory').prop('scrollHeight'));
    // Record this message in the history object
    // so we can send it to other peers asking for it
    chatHistory[chatIndex] = {
      time: time,
      from: displayName,
      color: color,
      message: message
    }
    chatIndex++;
  }

  // Update the displayName of the peer
  // and its screen if any
  function updateDisplayName(id){
    // We might receive the screen before the peer itself
    // so check if the object exists before using it, or fallback with empty values
    var display = (peers[id] && peers[id].hasName) ? stringEscape(peers[id].displayName) : '';
    var color = (peers[id] && peers[id].color) ? peers[id].color : chooseColor();
    var screenName = (peers[id] && peers[id].hasName) ? sprintf(locale.SCREEN_s, stringEscape(peers[id].displayName)) : '';
    $('#name_' + id).html(display).css('background-color', color);
    $('#name_' + id + '_screen').html(screenName).css('background-color', color);
  }

  // Mute a peer
  function mutePeer(id){
    if (peers[id] && peers[id].role != 'owner'){
      var msg    = locale.YOU_HAVE_MUTED_s;
      if (peers[id].micMuted){
        msg    = locale.YOU_HAVE_UNMUTED_s
      }
      webrtc.sendToAll('owner_toggle_mute', {peer: id});
      $.notify(sprintf(msg, peers[id].displayName), 'info');
    }
    else{
      $.notify(locale.CANT_MUTE_OWNER, 'error');
    }
  }
  // Pause a peer
  function pausePeer(id){
    if (peers[id] && peers[id].role != 'owner'){
      var msg    = locale.YOU_HAVE_SUSPENDED_s;
      if (peers[id].videoPaused){
        msg    = locale.YOU_HAVE_RESUMED_s;
      }
      webrtc.sendToAll('owner_toggle_pause', {peer: id});
      $.notify(sprintf(msg, peers[id].displayName), 'info');
    }
    else{
      $.notify(locale.CANT_SUSPEND_OWNER, 'error');
    }
  }
  // Kick a peer
  function kickPeer(id){
    if (peers[id] && peers[id].role != 'owner'){
      webrtc.sendToAll('owner_kick', {peer: id});
      // Wait a bit for the peer to leave, but end connection if it's still here
      // after 2 seconds
      setTimeout(function(){
        if (peers[id]){
          peers[id].obj.end();
        }
      }, 2000);
      $.notify(sprintf(locale.YOU_HAVE_KICKED_s, peers[id].displayName), 'info');
    }
    else{
      $.notify(locale.CANT_KICK_OWNER, 'error');
    }
  }

  // Mute our mic
  function muteMic(){
    webrtc.mute();
    peers.local.micMuted = true;
    showVolume($('#localVolume'), -45);
  }
  // Unmute
  function unmuteMic(){
    webrtc.unmute();
    peers.local.micMuted = false;
  }
  // Suspend or webcam
  function suspendCam(){
    webrtc.pauseVideo();
    peers.local.videoPaused = true;
  }
  // Resume webcam
  function resumeCam(){
    webrtc.resumeVideo();
    peers.local.videoPaused = false;
  }

  // An owner is muting/unmuting ourself
  webrtc.on('owner_toggle_mute', function(data){
    if (peers[data.id].role != 'owner'){
      return;
    }
    if (data.payload.peer && data.payload.peer == peers.local.id && peers.local.role != 'owner'){
      // Ignore this if the remote peer isn't the owner of the room
      if (!peers.local.micMuted){
        muteMic();
        $('#muteMicLabel').addClass('btn-danger active');
        $('#muteMicButton').prop('checked', true);
        $.notify(sprintf(locale.s_IS_MUTING_YOU, peers[data.id].displayName), 'info');
      }
      else {
        unmuteMic();
        $('#muteMicLabel').removeClass('btn-danger active');
        $('#muteMicButton').prop('checked', false);
        $.notify(sprintf(locale.s_IS_UNMUTING_YOU, peers[data.id].displayName), 'info');
      }
    }
    else if (data.payload.peer != peers.local.id){
      if (peers[data.payload.peer].micMuted){
        $.notify(sprintf(locale.s_IS_UNMUTING_s, peers[data.id].displayName, peers[data.payload.peer].displayName), 'info');
      }
      else{
        $.notify(sprintf(locale.s_IS_MUTING_s, peers[data.id].displayName, peers[data.payload.peer].displayName), 'info');
      }
    }
  });
  // An owner is pausing/resuming our webcam
  webrtc.on('owner_toggle_pause', function(data){
    if (peers[data.id].role != 'owner'){
      return;
    }
    if (data.payload.peer && data.payload.peer == peers.local.id && peers.local.role != 'owner'){
      if (!peers.local.videoPaused){
        suspendCam();
        $('#suspendCamLabel').addClass('btn-danger active');
        $('#suspendCamButton').prop('checked', true);
        $.notify(sprintf(locale.s_IS_SUSPENDING_YOU, peers[data.id].displayName), 'info');
      }
      else{
        resumeCam();
        $('#suspendCamLabel').removeClass('btn-danger active');
        $('#suspendCamButton').prop('checked', false);
        $.notify(sprintf(locale.s_IS_RESUMING_YOU, peers[data.id].displayName), 'info');
      }
    }
    else if (data.payload.peer != peers.local.id){
      if (peers[data.payload.peer].videoPaused){
        $.notify(sprintf(locale.s_IS_RESUMING_s, peers[data.id].displayName, peers[data.payload.peer].displayName), 'info');
      }
      else{
        $.notify(sprintf(locale.s_IS_SUSPENDING_s, peers[data.id].displayName, peers[data.payload.peer].displayName), 'info');
      }
    }
  });
  // An owner is kicking us from the room
  webrtc.on('owner_kick', function(data){
    if (peers[data.id].role != 'owner'){
      return;
    }
    if (data.payload.peer && data.payload.peer == peers.local.id && peers.local.role != 'owner'){
      hangupCall;
      window.location.assign(rootUrl + 'kicked/' + roomName);
    }
    else if (data.payload.peer != peers.local.id && peers[data.payload.peer] && peers[data.payload.peer].role != 'owner'){
      $.notify(sprintf(locale.s_IS_KICKING_s, peers[data.id].displayName, peers[data.payload.peer].displayName), 'info');
      // Wait a bit for the peer to leave, but end connection if it's still here
      // after 2 seconds
      setTimeout(function(){
        if (peers[data.payload.id]){
          peers[data.payload.id].obj.end();
        }
      }, 2000);
    }
  });

  // Handle volume changes from our own mic
  webrtc.on('volumeChange', function (volume, treshold) {
    if (volume > maxVol){
      maxVol = volume;
    }
    if (peers.local.micMuted) {
      return;
    }
    showVolume($('#localVolume'), volume);
  });

  // Handle dataChannel messages (incoming)
  webrtc.on('channelMessage', function (peer, label, data){
    // Handle volume changes from remote peers
    if (data.type == 'volume'){
      showVolume($('#volume_' + peer.id), data.volume);
    }
    // We only want to act on data receive from the vroom channel
    if (label !== 'vroom'){
      return;
    }
    // The peer sets a displayName, record this in our peers struct
    else if (data.type == 'setDisplayName'){
      var name = data.payload;
      if (name.length > 50){
        return;
      }
      peer.logger.log('Received displayName ' + stringEscape(name) + ' from peer ' + peer.id);
      // Set display name under the video
      peers[peer.id].displayName = name;
      if (name !== ''){
        peers[peer.id].hasName = true;
      }
      else {
        peers[peer.id].hasName = false;
      }
      updateDisplayName(peer.id);
    }
    // This peer asked for our chat history, lets send him
    else if (data.type == 'getHistory'){
      peer.sendDirectly('vroom', 'chatHistory', JSON.stringify(chatHistory));
    }
    // This peer is sending our chat history (and we don't have it yet)
    else if (data.type == 'chatHistory' && !peers.local.hasHistory){
      peers.local.hasHistory = true;
      var history = JSON.parse(data.payload);
      for (var i = 0; i < Object.keys(history).length; i++){
        newChatMessage(history[i].from,history[i].message,history[i].time,history[i].color);
      }
    }
    // One peer just sent a text chat message
    else if (data.type == 'textChat'){
      if ($('#chatDropdown').hasClass('collapsed')){
        $('#chatDropdown').addClass('btn-danger');
        playSound('newmsg.mp3');
      }
      newChatMessage(peer.id,data.payload);
    }
  });

  webrtc.on('peer_color', function(data){
    var color = data.payload.color;
    if (!color.match(/#[\da-f]{6}/i)){
      return;
    }
    peers[data.id].color = color;
    $('#name_' + data.id).css('background-color', color);
    $('#name_' + data.id + '_screen').css('background-color', color);
    // Update the displayName but only if it has been set (no need to display a cryptic peer ID)
    if (peers[data.id].hasName){
      updateDisplayName(data.id);
    }
  });

  // Received when a peer mute his mic, or pause the video
  webrtc.on('mute', function(data){
    if (data.name === 'audio'){
      showVolume($('#volume_' + data.id), -46);
      var div = 'mute_' + data.id,
          cl = 'muted';
      peers[data.id].micMuted = true;
    }
    else if (data.name === 'video'){
      var div = 'pause_' + data.id,
          cl = 'paused';
      peers[data.id].videoPaused = true;
    }
    else{
      return;
    }
    $('#overlay_' + data.id).append('<div id="' + div + '" class="' + cl + '"></div>');
  });

  // Handle unmute/resume
  webrtc.on('unmute', function(data){
    if (data.name === 'audio'){
      var el = '#mute_' + data.id;
      peers[data.id].micMuted = false;
    }
    else if (data.name === 'video'){
      var el = '#pause_' + data.id;
      peers[data.id].videoPaused = false;
    }
    else{
      return;
    }
    $(el).remove();
  });

  // This peer claims he changed its role (usually from participant to owner)
  // Lets check this
  webrtc.on('role_change', function(data){
    getPeerRole(data.id);
  });

  // A new notified email has been added
  webrtc.on('notif_change', function(data){
    if (peers.local.role != 'owner'){
      return;
    }
    $('#emailNotificationList > li').remove();
    getRoomInfo();
  });

  // askForName set
  webrtc.on('ask_for_name_on', function(data){
    if (peers.local.role != 'owner'){
      return;
    }
    getRoomInfo();
    $('#askForNameLabel').addClass('btn-danger active');
    $('#askForNameButton').prop('checked', true);
  });
  webrtc.on('ask_for_name_off', function(data){
    if (peers.local.role != 'owner'){
      return;
    }
    getRoomInfo();
    $('#askForNameLabel').removeClass('btn-danger active');
    $('#askForNameButton').prop('checked', false);
  });

  // A few notif on password set/unset or lock/unlock
  webrtc.on('room_locked', function(data){
    $('#lockLabel').addClass('btn-danger active');
    $('#lockButton').prop('checked', true);
    $.notify(sprintf(locale.ROOM_LOCKED_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });
  webrtc.on('room_unlocked', function(data){
    $('#lockLabel').removeClass('btn-danger active');
    $('#lockButton').prop('checked', false);
    $.notify(sprintf(locale.ROOM_UNLOCKED_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });
  webrtc.on('password_protect_on', function(data){
    $.notify(sprintf(locale.PASSWORD_PROTECT_ON_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });
  webrtc.on('password_protect_off', function(data){
    $.notify(sprintf(locale.PASSWORD_PROTECT_OFF_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });
  webrtc.on('owner_password_changed', function(data){
    if (peers.local.role == 'owner'){
      $.notify(sprintf(locale.OWNER_PASSWORD_CHANGED_BY_s, stringEscape(peers[data.id].displayName)), 'warn');
    }
    else{
      getRoomInfo();
    }
  });
  webrtc.on('owner_password_removed', function(data){
    if (peers.local.role == 'owner'){
      $.notify(sprintf(locale.OWNER_PASSWORD_REMOVED_BY_s, stringEscape(peers[data.id].displayName)), 'warn');
    }
    else{
      getRoomInfo();
    }
  });

  // Handle the readyToCall event: join the room
  webrtc.once('readyToCall', function () {
    peers.local.id = webrtc.connection.socket.sessionid;
    getRoomInfo();
    if (roomInfo.ask_for_name && roomInfo.ask_for_name == 'yes'){
      $('#setDisplayName').modal('show');
    }
    else{
      webrtc.joinRoom(room);
    }
  });

  // When we joined the room
  webrtc.on('joinedRoom', function(){
    // Check if sound is detected and warn if it hasn't
    setTimeout(function (){
      if (maxVol < -40){
        $.notify(locale.NO_SOUND_DETECTED, {
          className: 'error',
          autoHide: false
        });
      }
    }, 10000);
  });

  // Handle new video stream added: someone joined the room
  webrtc.on('videoAdded', function(video,peer){
    addVideo(video,peer);
  });

  webrtc.on('localScreenAdded', function(video){
    addVideo(video);
  });

  // Handle video stream removed: someone leaved the room
  // TODO: don't trigger on local screen unshare
  webrtc.on('videoRemoved', function(video,peer){
    playSound('leave.mp3');
    var id = (peer) ? peer.id : 'local';
    id = (video.id.match(/_screen_/)) ? id + '_screen' : id;
    $("#peer_" + id).remove();
    if (mainVid === id){
      $('#mainVideo').html('');
      mainVid = false;
    }
    if (peer && peers[peer.id]){
      delete peers[peer.id];
    }
  });

  // Error sending something through dataChannel
  webrtc.on('cantsend', function (peer, message){
    if (message.type == 'textChat'){
      var who = (peers[peer.id].hasName) ? stringEscape(peers[peer.id].displayName) : locale.ONE_OF_THE_PEERS;
      $.notify(sprintf(locale.CANT_SEND_TO_s, who), 'error');
    }
  });

  // Do not close the dropdown menu when filling the email recipient
  // and in other dropdown menus
  $('.dropdown-menu').on('click', 'li', function(e){
    e.stopPropagation();
  });
  // Handle Email Invitation
  $('#inviteEmail').submit(function(event) {
    event.preventDefault();
    var rcpt    = $('#recipient').val();
        message = $('#message').val();
    // Simple email address verification
    if (!rcpt.match(/\S+@\S+\.\S+/)){
      $.notify(locale.ERROR_MAIL_INVALID, 'error');
      return;
    }
    $.ajax({
      data: {
        action: 'invite',
        recipient: rcpt,
        message: message,
        room: roomName
      },
      error: function(data) {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#recipient').val('');
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Set your DisplayName
  $('#displayName').on('input', function() {
    var name = $('#displayName').val();
    if (name.length > 50){
      $('#displayName').parent().addClass('has-error');
      $('#displayName').notify(locale.DISPLAY_NAME_TOO_LONG, 'error');
      return;
    }
    else{
      $('#displayName').parent().removeClass('has-error');
    }
    // Enable chat input when you set your disaplay name
    if (name != '' && $('#chatBox').attr('disabled')){
      $('#chatBox').removeAttr('disabled');
      $('#chatBox').removeAttr('placeholder');
      peers.local.hasName = true;
    }
    // And disable it again if you remove your display name
    else if (name == ''){
      $('#chatBox').attr('disabled', true);
      $('#chatBox').attr('placeholder', locale.SET_YOUR_NAME_TO_CHAT);
      peers.local.hasName = false;
    }
    peers.local.displayName = name;
    updateDisplayName('local');
    webrtc.sendDirectlyToAll('vroom', 'setDisplayName', name);
  });
  // This is the displayName input before joining the room
  $('#displayNamePre').on('input', function() {
    var name = $('#displayNamePre').val();
    if (name.length > 0 && name.length < 50){
      $('#displayNamePreButton').removeClass('disabled');
      $('#displayNamePre').parent().removeClass('has-error');
    }
    else{
      $('#displayNamePreButton').addClass('disabled');
      $('#displayNamePre').parent().addClass('has-error');
      if (name.length < 1){
        $('#displayNamePre').notify(locale.DISPLAY_NAME_REQUIRED, 'error');
      }
      else{
        $('#displayNamePre').notify(locale.DISPLAY_NAME_TOO_LONG, 'error');
      }
    }
  });

  $('#displayNamePreForm').submit(function(event){
    event.preventDefault();
    var name = $('#displayNamePre').val();
    if (name.length > 0 && name.length < 50){
      $('#setDisplayName').modal('hide');
      $('#displayName').val(name);
      peers.local.hasName = true;
      peers.local.displayName = name;
      updateDisplayName('local');
      webrtc.joinRoom(room);
    }
  });

  // Handle room lock/unlock
  $('#lockButton').change(function() {
    var action = ($(this).is(":checked")) ? 'lock':'unlock';
    $.ajax({
      data: {
        action: action,
        room: roomName
      },
      error: function(data) {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        if (data.status == 'success'){
          $.notify(data.msg, 'info');
          if (action === 'lock'){
            $('#lockLabel').addClass('btn-danger active');
            webrtc.sendToAll('room_locked', {});
          }
          else{
            $('#lockLabel').removeClass('btn-danger active');
            webrtc.sendToAll('room_unlocked', {});
          }
        }
        else{
          $.notify(data.msg, 'error');
        }
      }  
    });
  });

  // Force participants to set a name
  $('#askForNameButton').change(function() {
    var type = ($(this).is(":checked")) ? 'set':'unset';
    $.ajax({
      data: {
        action: 'askForName',
        type: type,
        room: roomName
      },
      error: function(data) {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        if (data.status == 'success'){
          $.notify(data.msg, 'info');
          if (type === 'set'){
            $('#askForNameLabel').addClass('btn-danger active');
            webrtc.sendToAll('ask_for_name_on', {});
          }
          else{
            $('#askForNameLabel').removeClass('btn-danger active');
            webrtc.sendToAll('ask_for_name_off', {});
          }
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // ScreenSharing
  $('#shareScreenButton').change(function() {
    var action = ($(this).is(":checked")) ? 'share':'unshare';
    function cantShare(err){
      $.notify(err, 'error');
      return;
    }
    if (!peers.local.screenShared && action === 'share'){
      webrtc.shareScreen(function(err){
        if(err){
          if (err.name == 'EXTENSION_UNAVAILABLE'){
            var ver = 34;
            if ($.browser.linux) ver = 35;
            if ($.browser.webkit && $.browser.versionNumber >= ver)
              $('#chromeExtMessage').modal('show');
            else
              cantShare(locale.SCREEN_SHARING_ONLY_FOR_CHROME);
          }
          else if (err.name == 'PERMISSION_DENIED' || err.name == 'PermissionDeniedError'){
            cantShare(locale.SCREEN_SHARING_CANCELLED);
          }
          else{
            cantShare(locale.CANT_SHARE_SCREEN);
          }
          $('#shareScreenLabel').removeClass('active');
          return;
        }
        else{
          $("#shareScreenLabel").addClass('btn-danger');
          peers.local.screenShared = true;
          $.notify(locale.EVERYONE_CAN_SEE_YOUR_SCREEN, 'warn');
        }
      });
    }
    else{
      webrtc.stopScreenShare();
      $('#shareScreenLabel').removeClass('btn-danger');
      $.notify(locale.SCREEN_UNSHARED, 'success');
      peers.local.screenShared = false;
    }
  });

  // Handle microphone mute/unmute
  $('#muteMicButton').change(function() {
    var action = ($(this).is(':checked')) ? 'mute':'unmute';
    if (action === 'mute'){
      muteMic();
      $('#muteMicLabel').addClass('btn-danger');
      $.notify(locale.MIC_MUTED, 'info');
    }
    else{
      unmuteMic();
      $('#muteMicLabel').removeClass('btn-danger');
      $.notify(locale.MIC_UNMUTED, 'info');
    }
  });

  // Suspend the webcam
  $('#suspendCamButton').change(function() {
    var action = ($(this).is(':checked')) ? 'pause':'resume';
    if (action === 'pause'){
      suspendCam();
      $('#suspendCamLabel').addClass('btn-danger');
      $.notify(locale.CAM_SUSPENDED, 'info');
    }
    else{
      resumeCam();
      $('#suspendCamLabel').removeClass('btn-danger');
      $.notify(locale.CAM_RESUMED, 'info');
    }
  });

  // Handle auth
  $('#authPass').on('input', function() {
    if ($('#authPass').val() == ''){
      $('#authPassButton').addClass('disabled');
    }
    else{
      $('#authPassButton').removeClass('disabled');
    }
  });
  $('#authForm').submit(function(event) {
    event.preventDefault();
    var pass = $('#authPass').val();
    $.ajax({
      data: {
        action: 'authenticate',
        password: pass,
        room: roomName
      },
      error: function(data) {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#authPass').val('');
        if (data.status == 'success'){
          getRoomInfo();
          $.notify(data.msg, 'success');
        }
        else{
          $.notify(data.msg, 'error');
        }
        // Close the auth menu
        $('#authMenu').dropdown('toggle');
      }
    });
  });

  $('#joinPass').on('input', function() {
    if ($('#joinPass').val() == ''){
      $('#setJoinPassButton').addClass('disabled');
    }
    else{
      $('#setJoinPassButton').removeClass('disabled');
    }
  });

  // Join password protection
  $('#joinPassForm').submit(function(event) {
    event.preventDefault();
    var pass = $('#joinPass').val();
    $('#joinPass').val('');
    $('#setJoinPassButton').addClass('disabled');
    $.ajax({
      data: {
        action: 'setPassword',
        password: pass,
        type: 'join',
        room: roomName
      },
      error: function() {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#joinPass').val('');
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
          webrtc.sendToAll('password_protect_on', {});
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Remove password protection
  $('#removeJoinPassButton').click(function(event) {
    $.ajax({
      data: {
        action: 'setPassword',
        type: 'join',
        room: roomName 
      },
      error: function() {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#joinPass').val('');
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
          webrtc.sendToAll('password_protect_off', {});
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Set owner password
  $('#ownerPass').on('input', function() {
    if ($('#ownerPass').val() == ''){
      $('#setOwnerPassButton').addClass('disabled');
    }
    else{
      $('#setOwnerPassButton').removeClass('disabled');
    }
  });
  $('#ownerPassForm').submit(function(event) {
    event.preventDefault();
    var pass = $('#ownerPass').val();
    $('#ownerPass').val('');
    $('#setOwnerPassButton').addClass('disabled');
    $.ajax({
      data: {
        action: 'setPassword',
        password: pass,
        type: 'owner',
        room: roomName
      },
      error: function() {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#ownerPass').val('');
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
          webrtc.sendToAll('owner_password_changed', {});
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Remove the owner password
  $('#removeOwnerPassButton').click(function(event) {
    $.ajax({
      data: {
        action: 'setPassword',
        type: 'owner',
        room: roomName
      },
      error: function() {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        $('#ownerPass').val('');
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
          webrtc.sendToAll('owner_password_removed', {});
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Add an email to be notified when someone joins
  // First, enable the add button when you start typing
  // TODO: should be enabled only when the input looks like an email address
  $('#newEmailNotification').on('input', function() {
    if ($('#newEmailNotification').val() == ''){
      $('#newEmailNotificationButton').addClass('disabled');
    }
    else{
      $('#newEmailNotificationButton').removeClass('disabled');
    }
  });
  // Then send this new address to the frontend
  $('#newEmailNotificationForm').submit(function(event){
    event.preventDefault();
    $.ajax({
      data: {
        action: 'emailNotification',
        type: 'add',
        email: $('#newEmailNotification').val(),
        room: roomName
      },
      error: function() {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        if (data.status == 'success'){
          $.notify(data.msg, 'success');
          addNotifiedEmail($('#newEmailNotification').val());
          webrtc.sendToAll('notif_change', {});
          $('#newEmailNotification').val('');
        }
        else{
          $.notify(data.msg, 'error');
        }
      }
    });
  });

  // Choose another color. Useful if two peers have the same
  $('#changeColorButton').click(function(){
    peers.local.color = chooseColor();
    webrtc.sendToAll('peer_color', {color: peers.local.color});
    updateDisplayName('local');
  });

  $('#saveChat').click(function(){
    downloadContent('VROOM Tchat (' + room + ').html', $('#chatHistory').html());
  });

  // Handle hangup/close window
  $('#logoutButton').click(function() {
    hangupCall;
    window.location.assign(rootUrl + 'goodby/' + roomName);
  });
  window.onunload = window.onbeforeunload = hangupCall;

  // Go fullscreen on double click
  $('#webRTCVideoLocal').dblclick(function() {
    fullScreen(this);
  });
  $('#webRTCVideoLocal').click(function() {
    // If this video is already the main one, remove the main
    if ($(this).hasClass('selected')){
      $('#mainVideo').html('');
      $(this).removeClass('selected');
      mainVid = false;
    }
    // Else, update the main video to use this one
    else{
      $('#mainVideo').html($(this).clone().dblclick(function() {
        fullScreen(this);
      }).css('max-height', maxHeight()));
      $('.selected').removeClass('selected');
      $(this).addClass('selected');
      mainVid = 'self';
    }
  });

  // On click, remove the red label on the button
  $('#chatDropdown').click(function (){
    $('#chatDropdown').removeClass('btn-danger');
  });
  // The input is a textarea, trigger a submit
  // when the user hit enter, unless shift is pressed
  $('#chatForm').keypress(function(e) {
    if (e.which == 13 && !e.shiftKey){
      // Do not add \n
      e.preventDefault();
      $(this).trigger('submit');
    }
  });

  // Adapt the chat input (textarea) size
  $('#chatBox').on('input', function(){
    var h = parseInt($(this).css('height'));
    var mh = parseInt($(this).css('max-height'));
    // Scrollbar, we need to add a row
    if ($(this).prop('scrollHeight') > $(this).prop('clientHeight') && h < mh){
      // Do a loop so that we can adapt to copy/pastes of several lines
      // But do not add more than 10 rows at a time
      for (var i = 0; $(this).prop('scrollHeight') > $(this).prop('clientHeight') && h < mh && i<10; i++){
        $(this).prop('rows', $(this).prop('rows')+1);
      }
    }
    // Check if we have empty lines in our textarea
    // If we do, remove one row
    // TODO: we should only check for the last row and don't remove a row if we have empty lines in the middle
    else{
      lines = $('#chatBox').val().split(/\r?\n/);
      for(var i=0; i<lines.length && $(this).prop('rows')>1; i++) {
        var val = lines[i].replace(/^\s+|\s+$/, '');
        if (val.length == 0){
          $(this).prop('rows', $(this).prop('rows')-1);
        }
      }
    }
  });
  // Chat: send to other peers
  $('#chatForm').submit(function (e){
    e.preventDefault();
    if ($('#chatBox').val()){
      webrtc.sendDirectlyToAll('vroom', 'textChat', $('#chatBox').val());
      // Local echo of our own message
      newChatMessage('local',$('#chatBox').val());
      // reset the input box
      $('#chatBox').val('').prop('rows', 1);
    }
  });

  // Ping the room every minutes
  // Used to detect inactive rooms
  setInterval(function pingRoom(){
    $.ajax({
      data: {
        action: 'ping',
        room: roomName
      },
      error: function(data) {
        $.notify(locale.ERROR_OCCURED, 'error');
      },
      success: function(data) {
        if (data.status == 'success' && data.msg && data.msg != ''){
          $.notify(data.msg, 'success');
        }
      }
    });
  }, 60000);

  window.onresize = function (){
    $('#webRTCVideo').css('max-height', maxHeight());
    $('#mainVideo>video').css('max-height', maxHeight());
  };  
  // Preview heigh is limited to the windows heigh, minus the navbar, minus 25px
  $('#webRTCVideo').css('max-height', maxHeight());

};

