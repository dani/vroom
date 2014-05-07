/*
This file is part of the VROOM project
released under the MIT licence
Copyright 2014 Firewall Services
*/


// Default notifications
$.notify.defaults( { globalPosition: "bottom left" } );
// Enable tooltip on required elements
$('.help').tooltip({container: 'body'});
// set the height of the thumbnails so they are always equals
$(".thumbnail").height(Math.max.apply(null, $(".thumbnail").map(function() { return $(this).height(); })));

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
  CANT_SEND_TO_s: '',
  SCREEN_s: ''
};

// Localize the strings we need
$.ajax({
  url: '/localize',
  type: 'POST',
  dataType: 'json',
  data: {
    strings: JSON.stringify(locale),
  },
  success: function(data) {
    locale = data;
  }
});

function initVroom(room) {

  var peers = {
    local: {
      screenShared: false,
      micMuted: false,
      videoPaused: false,
      displayName: '',
      color: chooseColor()
    }
  };
  var mainVid = false,
      chatHistory = {},
      chatIndex = 0;

  $('#name_local').css('background-color', peers.local.color);

  $.ajaxSetup({
    url: rootUrl + 'action',
    type: 'POST',
    dataType: 'json',    
  });

  // Screen sharing is only suported on chrome > 26
  if ( !$.browser.webkit || $.browser.versionNumber < 26 ) {
    $("#shareScreenLabel").addClass('disabled');
  }

  // If browser doesn't support webRTC or dataChannels
  if (!webrtc.capabilities.support || !webrtc.capabilities.dataChannel){
    $('#noWebrtcSupport').modal('show');
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
    var audio = new Audio('/snd/'+sound);
    audio.play();
  }

  // Request full screen
  function fullScreen(el){
    if (el.requestFullScreen)
      el.requestFullScreen();
    else if (el.webkitRequestFullScreen)
      el.webkitRequestFullScreen();
    else if (el.mozRequestFullScreen)
      el.mozRequestFullScreen();
  }

  // get max height for the main video and the preview div
  function maxHeight(){
    // Which is the window height, minus toolbar, and a margin of 25px
    return $(window).height()-$('#toolbar').height()-25;
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
    var div = $('<div></div>').addClass('col-xs-6 col-sm-12 col-lg-6 previewContainer').append(video).appendTo("#webRTCVideo");
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
      // Create 3 divs which will contains the volume bar, the displayName and the muted/paused el (overlay)
      $('<div></div>').addClass('volumeBar').attr('id', 'volume_' + id).appendTo(div);
      $('<div></div>').addClass('displayName').attr('id', 'name_' + id).appendTo(div);
      $('<div></div>').attr('id', 'overlay_' + id).appendTo(div);
      // Create a new dataChannel
      // will be used for text chat and displayName
      var color = chooseColor();
      peers[peer.id] = {
        displayName: peer.id,
        color: color,
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
      }, 3500);
    }
    $(div).attr('id', 'peer_' + id);
    // Disable context menu on the video
    $(video).bind("contextmenu", function(){
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
          }).css('max-height', maxHeight()).bind("contextmenu", function(){ return false; }));
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

  // Return curren time formatted as XX:XX:XX
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

  // Save content to a file
  function downloadContent(filename, content){
    var blob = new Blob([content], {type: "text/html;charset=utf-8"});
    saveAs(blob, filename);
  }

  // Handle volume changes from our own mic
  webrtc.on('volumeChange', function (volume, treshold) {
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
    }
    else if (data.name === 'video'){
      var div = 'pause_' + data.id,
          cl = 'paused';
    }
    else{
      return;
    }
    $("#overlay_" + data.id).append('<div id="' + div + '" class="' + cl + '"></div>');
  });

  // Handle unmute/resume
  webrtc.on('unmute', function(data){
    if (data.name === 'audio'){
      var el = "#mute_" + data.id;
    }
    else { // if (data.name === 'video')
      var el = "#pause_" + data.id;
    }
    $(el).remove();
  });

  webrtc.on('room_locked', function(data){
    $('#lockLabel').addClass('btn-danger active');
    $.notify(sprintf(locale.ROOM_LOCKED_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });

  webrtc.on('room_unlocked', function(data){
    $('#lockLabel').removeClass('btn-danger active');
    $.notify(sprintf(locale.ROOM_UNLOCKED_BY_s, stringEscape(peers[data.id].displayName)), 'info');
  });

  // Handle the readyToCall event: join the room
  webrtc.once('readyToCall', function () {
    webrtc.joinRoom(room);
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
  });

  // Error sending something through dataChannel
  webrtc.on('cantsend', function (peer, message){
    if (message.type == 'textChat'){
      var who = (peers[peer.id].hasName) ? stringEscape(peers[peer.id].displayName) : locale.ONE_OF_THE_PEERS;
      $.notify(sprintf(locale.CANT_SEND_TO_s, who), 'error');
    }
  });

  // Handle Email Invitation
  $('#inviteEmail').submit(function(event) {
    event.preventDefault();
    var rcpt = $('#recipient').val();
    // Simple email address verification
    if (!rcpt.match(/\S+@\S+\.\S+/)){
      $.notify(locale.ERROR_MAIL_INVALID, 'error');
      return;
    }
    $.ajax({
      data: {
        action: 'invite',
        recipient: rcpt,
        room: roomName
      },
      error: function(data) {
        var msg = (data && data.msg) ? data.msg : locale.ERROR_OCCURED;
        $.notify(msg, 'error');
      },
      success: function(data) {
        $.notify(data.msg, 'success');
        $('#recipient').val('');
      }
    });
  });

  // Set your DisplayName
  $('#displayName').on('input', function() {
    // Enable chat input when you set your disaplay name
    if ($('#displayName').val() != '' && $('#chatBox').attr('disabled')){
      $('#chatBox').removeAttr('disabled');
      $('#chatBox').removeAttr('placeholder');
      peers.local.hasName = true;
    }
    // And disable it again if you remove your display name
    else if ($('#displayName').val() == ''){
      $('#chatBox').attr('disabled', true);
      $('#chatBox').attr('placeholder', locale.SET_YOUR_NAME_TO_CHAT);
      peers.local.hasName = false;
    }
    peers.local.displayName = $('#displayName').val();
    updateDisplayName('local');
    webrtc.sendDirectlyToAll('vroom', 'setDisplayName', $('#displayName').val());
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
        var msg = (data && data.msg) ? data.msg : locale.ERROR_OCCURED;
        $.notify(msg, 'error');
      },
      success: function(data) {
        $.notify(data.msg, 'info');
        if (action === 'lock'){
          $("#lockLabel").addClass('btn-danger');
          webrtc.sendToAll('room_locked', {});
        }
        else{
          $("#lockLabel").removeClass('btn-danger');
          webrtc.sendToAll('room_unlocked', {});
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
      $("#shareScreenLabel").removeClass('btn-danger');
      $.notify(locale.SCREEN_UNSHARED, 'success');
      peers.local.screenShared = false;
    }
  });

  // Handle microphone mute/unmute
  $('#muteMicButton').change(function() {
    var action = ($(this).is(":checked")) ? 'mute':'unmute';
    if (action === 'mute'){
      webrtc.mute();
      peers.local.micMuted = true;
      showVolume($('#localVolume'), -45);
      $("#muteMicLabel").addClass('btn-danger');
      $.notify(locale.MIC_MUTED, 'info');
    }
    else{
      webrtc.unmute();
      peers.local.micMuted = false;
      $("#muteMicLabel").removeClass('btn-danger');
      $.notify(locale.MIC_UNMUTED, 'info');
    }
  });

  // Suspend the webcam
  $('#suspendCamButton').change(function() {
    var action = ($(this).is(":checked")) ? 'pause':'resume';
    if (action === 'pause'){
      webrtc.pauseVideo();
      peers.local.videoPaused = true;
      $("#suspendCamLabel").addClass('btn-danger');
      $.notify(locale.CAM_SUSPENDED, 'info');
    }
    else{
      webrtc.resumeVideo();
      peers.local.videoPaused = false;
      $("#suspendCamLabel").removeClass('btn-danger');
      $.notify(locale.CAM_RESUMED, 'info');
    }
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
  $("#webRTCVideoLocal").dblclick(function() {
    fullScreen(this);
  });
  $("#webRTCVideoLocal").click(function() {
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
    if ($(this).prop("scrollHeight") > $(this).prop('clientHeight') && h < mh){
      // Do a loop so that we can adapt to copy/pastes of several lines
      // But do not add more than 10 rows at a time
      for (var i = 0; $(this).prop("scrollHeight") > $(this).prop('clientHeight') && h < mh && i<10; i++){
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
        var msg = (data && data.msg) ? data.msg : locale.ERROR_OCCURED;
        $.notify(msg, 'error');
      },
      success: function(data) {
        // In case of success, only notify if the server replied something
        if (data.msg !== ''){
          $.notify(data.msg, 'success');
        }
      }
    });
  }, 60000);

  // Preview heigh is limited to the windows heigh, minus the navbar, minus 25px
  window.onresize = function (){
    $('#webRTCVideo').css('max-height', maxHeight());
    $('#mainVideo>video').css('max-height', maxHeight());
  };
  $('#webRTCVideo').css('max-height', maxHeight());

};

