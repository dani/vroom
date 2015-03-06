package Vroom::I18N::en;
use base 'Vroom::I18N';

our %Lexicon = ( 
  _AUTO => 1,
  "WELCOME"                              => "Welcome on VROOM !!",
  "VROOM_DESC"                           => "VROOM is a simple video conferencing solution",
  "VROOM_IS_FREE_SOFTWARE"               => "VROOM is a free software",
  "POWERED_BY"                           => "Powered by",
  "ERROR_NAME_INVALID"                   => "This name is not valid",
  "ERROR_ROOM_NAME_MISSING"              => "Vous devez fournir un nom de salon",
  "ERROR_NAME_RESERVED"                  => "This name is reserved and cannot be used",
  "ERROR_NAME_CONFLICT"                  => "A room with this name already exists, please choose another one",
  "ERROR_ROOM_s_DOESNT_EXIST"            => "The room %s doesn't exist",
  "ERROR_ROOM_s_LOCKED"                  => "The room %s is locked, you cannot join it",
  "ERROR_OCCURRED"                       => "An error occurred",
  "ERROR_NOT_LOGGED_IN"                  => "Sorry, your not logged in",
  "ERROR_DB_UNAVAILABLE"                 => "The database is not available",
  "ERROR_DB_VERSION_MISMATCH"            => "The database must be updated",
  "JS_REQUIRED"                          => "VROOM needs javascript to work properly",
  "EMAIL_INVITATION"                     => "Video conference invitation",
  "INVITE_SENT_TO_s"                     => "An invitation was sent to the following addresses\n%s",
  "YOU_ARE_INVITED_TO_A_MEETING"         => "You are awaited on a video conferecing room. " .
                                            "Before joining it, make sure you have all the necessary",
  "A_MODERN_BROWSER"                     => "A modern web browser, recent versions of Mozilla Firefox, Google Chrome or Opera will work",
  "A_WEBCAM"                             => "A webcam (optional but recommanded)",
  "A_MIC"                                => "A microphone and speakers (or headphones)",
  "WHEN_YOU_ARE_READY"                   => "When you are ready, go to this address to join the conference",
  "MESSAGE_FROM_ORGANIZER"               => "Message from the meeting organizer",
  "HAVE_A_NICE_MEETING"                  => "Have a nice meeting :-)",
  "EMAIL_SIGN"                           => "VROOM! And video conferencing becomes free, simple and safe",
  "FEEDBACK"                             => "Feedback",
  "YOUR_MAIL_OPTIONAL"                   => "Your email address (optional)",
  "COMMENT"                              => "Comment",
  "VROOM_IS_AWESOME"                     => "VROOM is really awesome ;-)",
  "SUBMIT"                               => "Submit",
  "THANK_YOU"                            => "Thank you :-)",
  "THANKS_FOR_YOUR_FEEDBACK"             => "Your message has been sent, thank your for taking time to share your experience with us",
  "FEEDBACK_FROM_VROOM"                  => "VROOM feedback",
  "FROM"                                 => "From",
  "GIVE_US_YOUR_FEEDBACK"                => "Give us your feedback",
  "YOUR_FEEDBACK_HELPS_US"               => "Your feedback (good or bad) can help us improve this application",
  "NOT_ENABLED"                          => "This feature isn't enabled",
  "OOOPS"                                => "Ooops",
  "GOODBYE"                              => "Goodbye",
  "THANKS_SEE_YOU_SOON"                  => "Thanks and see you soon",
  "THANKS_FOR_USING"                     => "Thank you for using VROOM, we hope you enjoyed your meeting",
  "BACK_TO_MAIN_MENU"                    => "Back to main menu",
  "JOIN_THIS_ROOM"                       => "Join this room",
  "CREATE_ROOM"                          => "Create a new room",
  "ROOM_NAME"                            => "Room name",
  "RANDOM_IF_EMPTY"                      => "If you let this empty, a random name will be given to the room",
  "THIS_ROOM_ALREADY_EXISTS"             => "This room already exists",
  "CONFIRM_OR_CHOOSE_ANOTHER_NAME"       => "Do you want to join it or choose another name ?",
  "CHOOSE_ANOTHER_NAME"                  => "Choose another name",
  "ROOM_s"                               => "room %s",
  "INVITE_PEOPLE"                        => "Invite other people",
  "EMAIL_PLACEHOLDER"                    => "j.smith\@example.com",
  "ERROR_INVITATION_INVALID"             => "This link is invalid, your invitation has probably expired, or you've already responded",
  "MESSAGE_SENT"                         => "Message sent",
  "ORGANIZER_WILL_GET_YOUR_MESSAGE"      => "The organizer will get your message in a few seconds",
  "INVITATION"                           => "Invitation",
  "INVITATION_RESPONSE"                  => "Respond to an invitation",
  "CANNOT_JOIN_NOW"                      => "You cannot join this conference ? Leave a message to the organizer so he won't wait for you",
  "WILL_YOU_JOIN"                        => "Will you join later ?",
  "WILL_TRY_TO_JOIN_LATER"               => "I will try to join later, but don't wait for me",
  "WONT_BE_ABLE_TO_JOIN"                 => "I cannot participate",
  "DONT_WAIT_FOR_ME"                     => "Don't wait for me",
  "YOU_CAN_STILL_CHANGE_YOUR_MIND"       => "It's not too late to change your mind",
  "CLICK_SEND_OR_JOIN_NOW"               => "Click send to deliver your message, or join the room now",
  "IF_YOU_CANNOT_JOIN"                   => "If you cannot join the conference, or if you'll be late",
  "YOU_CAN_NOTIFY_THE_ORGANIZER"         => "you can notify the organizer",
  "INVITE_REPONSE_FROM_s"                => "%s response to your invitation",
  "HE_WILL_TRY_TO_JOIN_LATER"            => "This person will tryu to join later",
  "HE_WONT_JOIN"                         => "This person won't be able to join the conference",
  "SEND_INVITE"                          => "Send an email invitation",
  "RECIPIENT"                            => "Recipient",
  "MESSAGE"                              => "Message",
  "SEND_CUSTOM_MESSAGE"                  => "You can add a custom message",
  "DISPLAY_NAME"                         => "Display name",
  "YOUR_NAME"                            => "Your name",
  "NAME_SENT_TO_OTHERS"                  => "This name will be sent to the other peers",
  "DISPLAY_NAME_TOO_LONG"                => "This name is too long",
  "DISPLAY_NAME_REQUIRED"                => "You need to enter your name",
  "SET_A_DISPLAY_NAME"                   => "Please set your name before you can join the room",
  "ROOM_DELETED"                         => "This room has been deleted",
  "CANCEL"                               => "Cancel",
  "CHANGE_COLOR"                         => "Change your color",
  "CLICK_TO_CHAT"                        => "Click to access the chat",
  "OPEN_ETHERPAD"                        => "Collaborative notetaking",
  "PREVENT_TO_JOIN"                      => "Prevent other participants to join this room",
  "MUTE_MIC"                             => "Turn off your microphone",
  "NO_SOUND_DETECTED"                    => "No sound detected, please check your microphone (input level might be too low)",
  "SUSPEND_CAM"                          => "Suspend your webcam, other will see a black screen instead, but can still hear you",
  "CONFIGURE"                            => "Configuration",
  "YOU_CAN_PASSWORD_PROTECT_JOIN"        => "You can protect this room with a password",
  "PASSWORD"                             => "Password",
  "PASSWORD_PROTECT"                     => "Password protect",
  "PASSWORDS_DO_NOT_MATCH"               => "Passwords do not match",
  "RESERVE_THIS_ROOM"                    => "Reserve this room",
  "SET_OWNER_PASS"                       => "Keep this password carefully, it'll grant you access to the configuration menus " .
                                            "next time you connect.",
  "A_STANDARD_ROOM_EXPIRES_AFTER_d"      => "A standard room will be deleted after %d hour(s) without activity",
  "A_RESERVED_ROOM"                      => "A reserved room",
  "EXPIRE_AFTER_d"                       => "will be deleted after %d day(s) without activity",
  "WILL_NEVER_EXPIRE"                    => "will be kept forever",
  "CONFIRM_PASSWORD"                     => "Confirm password",
  "PROTECT_ROOM_WITH_PASSWORD"           => "If this password is set, participants will have to type it before the system let them in",
  "ERROR_COMMON_ROOM_NAME"               => "Sorry, this room name is too comon to be reserved",
  "AUTHENTICATE"                         => "Authentication",
  "ADD_NOTIFICATION"                     => "Add a notification",
  "ADD_THIS_ADDRESS"                     => "Add this address",
  "REMOVE_THIS_ADDRESS"                  => "Remove this address",
  "NOTIFICATION_ON_JOIN"                 => "Notification when someone joins this room",
  "s_WILL_BE_NOTIFIED"                   => "%s will receive a notification each time someone joins this room",
  "s_WONT_BE_NOTIFIED_ANYMORE"           => "%s won't be notified anymore",
  "ROOM_CONFIG_UPDATED"                  => "Room configuration has been updated",
  "s_JOINED_ROOM_s"                      => "%s joined room %s",
  "SOMEONE"                              => "Someone",
  "SOMEONE_JOINED_A_ROOM"                => "Someone joined a video conference room, and your address is configured to receive " .
                                            "this notifications",
  "PARTICIPANT_NAME"                     => "The one who just joined your room is named",
  "AUTH_SUCCESS"                         => "You are now authenticated",
  "NOT_ALLOWED"                          => "You are not allowed to do this",
  "WRONG_PASSWORD"                       => "Wrong password",
  "PASSWORD_REQUIRED"                    => "Password required",
  "A_PASSWORD_IS_NEEDED_TO_JOIN"         => "You must provide a password to join this room",
  "TRY_AGAIN"                            => "Try again",
  "AUTH_IF_OWNER"                        => "Authenticate if you are the room owner",
  "CREATE_THIS_ROOM"                     => "Create this room",
  "ADMINISTRATION"                       => "Administration",
  "ROOM_MANAGEMENT"                      => "Room management",
  "MANAGE"                               => "Manage",
  "ROOM_DETAILS"                         => "Room details",
  "ROOM_ID"                              => "ID",
  "CREATION_DATE"                        => "Creation date",
  "LAST_ACTIVITY"                        => "Last activity",
  "NUMBER_OF_PARTICIPANTS"               => "Number of participants",
  "LOCKED"                               => "Locked",
  "LOCK_ROOM"                            => "Prevent room access",
  "ASK_FOR_NAME"                         => "Require to enter a name",
  "JOIN_PASSWORD"                        => "Password to join the room",
  "OWNER_PASSWORD"                       => "Password to manage the room",
  "PERSISTENT"                           => "Persistent",
  "TOOLTIP_LOCK_ROOM"                    => "Once this option is enabled, no one else can join the room. " .
                                            "Only enable it after every participant is here. This way, nobody will be able to disturb " .
                                            "your meeting",
  "TOOLTIP_ASK_FOR_NAME"                 => "Everyone will be be asked for their name before they can join the room",
  "TOOLTIP_PASSWORD_PROTECT"             => "This password will be needed to join the room",
  "TOOLTIP_RESERVE_THIS_ROOM"            => "If this password is set, you'll be able to access the configuration menus ".
                                            "next time you connect",
  "TOOLTIP_PERSISTENT"                   => "The room will be persistent (kept forever)",
  "TOOLTIP_NOTIFICATION_ON_JOIN"         => "One or more email addresse(s) which will be notified when someone joins the room",
  "ROOM_NOW_PERSISTENT"                  => "This room is now persistent",
  "ROOM_NO_MORE_PERSISTENT"              => "This rooms isn't persistent anymore",
  "EMAIL_INVITE"                         => "Email invitation",
  "DELETE"                               => "Delete",
  "CONFIRM_DELETE"                       => "Confirm delation",
  "ROOM_WILL_BE_DELETED"                 => "This room, and its configuration will be deleted",
  "LOGOUT"                               => "Leave the room",
  "LEAVE_THIS_ROOM"                      => "Leave the room",
  "ARE_YOU_SURE_YOU_WANT_TO_LEAVE"       => "Are you sure you want to leave this room ?",
  "QUIT"                                 => "Leave the room",
  "SET_YOUR_NAME_TO_CHAT"                => "You need to set your name to be able to chat",
  "SEND_MESSAGE"                         => "Send the message",
  "SAVE_HISTORY"                         => "Save history to a file",
  "MUTE_PEER"                            => "Mute or unmute this participant's microphone",
  "SUSPEND_PEER"                         => "Suspend or resume this participant's webcam",
  "PROMOTE_PEER"                         => "Grant this participant administration privileges on the room",
  "KICK_PEER"                            => "Kick this participant out of the room",
  "s_IS_MUTING_YOU"                      => "%s has muted your microphone",
  "s_IS_MUTING_s"                        => "%s has muted %s's microphone",
  "s_IS_UNMUTING_YOU"                    => "%s has unmuted your microphone",
  "s_IS_UNMUTING_s"                      => "%s has unmuted %s's microphone",
  "s_IS_SUSPENDING_YOU"                  => "%s has suspended your webcam",
  "s_IS_SUSPENDING_s"                    => "%s has suspended %s's webcam",
  "s_IS_RESUMING_YOU"                    => "%s has resumed your webcam",
  "s_IS_RESUMING_s"                      => "%s has resumed %s's webcam",
  "s_IS_PROMOTING_YOU"                   => "%s has granted you administration privileges on the room",
  "s_IS_PROMOTING_s"                     => "%s has granted %s administration privileges on the room",
  "PEER_PROMOTED"                        => "You have granted administration privileges on the room",
  "s_IS_KICKING_s"                       => "%s has kicked %s out of the room",
  "s_CHANGED_ROOM_CONFIG"                => "%s changed room configuration",
  "KICKED"                               => "Kicked",
  "YOU_HAVE_BEEN_KICKED"                 => "You've been kicked out of the room",
  "AN_ADMIN_HAS_KICKED_YOU"              => "An administrator of the room has excluded you",
  "YOU_HAVE_MUTED_s"                     => "You have muted %s's microphone",
  "YOU_HAVE_UNMUTED_s"                   => "You have unmuted %s's microphone",
  "CANT_MUTE_OWNER"                      => "You can't mute the microphone of this participant",
  "YOU_HAVE_SUSPENDED_s"                 => "You have suspended %s's webcam",
  "YOU_HAVE_RESUMED_s"                   => "You have resumed %s's webcam",
  "CANT_SUSPEND_OWNER"                   => "You can't suspend this participant's webcam",
  "YOU_HAVE_KICKED_s"                    => "You have kicked %s out of the room",
  "CANT_KICK_OWNER"                      => "You can't kick this participant out of the room",
  "CANT_PROMOTE_OWNER"                   => "This participant already has administration privileges on the room",
  "A_ROOM_ADMIN"                         => "a room administrator",
  "A_PARTICIPANT"                        => "a participant",
  "MIC_MUTED"                            => "Your microphone is now muted",
  "MIC_UNMUTED"                          => "Your microphone is now unmuted",
  "CAM_SUSPENDED"                        => "Your webcam is now suspended",
  "CAM_RESUMED"                          => "Your webcam is on again",
  "GROUP_ACTIONS"                        => "Grouped actions",
  "SHARE_YOUR_SCREEN"                    => "Share your screen with the other members of this room",
  "CANT_SHARE_SCREEN"                    => "Sorry, your configuration does not allow screen sharing",
  "SCREEN_SHARING_ONLY_FOR_CHROME"       => "Sorry, but you can't share your screen. Only Google Chrome supports this feature for now",
  "SCREEN_SHARING_CANCELLED"             => "Screen sharing has been cancelled",
  "EXTENSION_REQUIRED"                   => "An extension is required",
  "VROOM_CHROME_EXTENSION"               => "To enable screen sharing, you need to install an extension. Click on the following link and refresh this page",
  "ALLOW_SCREEN_SHARING"                 => "You have to allow screen sharing",
  "ALLOW_SCREEN_SHARING_ON_FF"           => "For security reasons, your browser do not allow screen sharing by default. " .
                                            "To enable it, please follow these steps:",
  "SCREEN_SHARING_ABOUT_CONFIG_s"        => "<ol>" .
                                              "  <li>Open a new tab, and type <b>about:config</b> in the address bar</li>" .
                                              "  <li>Accept the warning by clicking on the \"<i>I'll be careful, I promise !</i>\" button</li>" .
                                              "  <li>Search for <b>screensharing</b> in the search bar</li>" .
                                              "  <li>Double click on <b>media.getusermedia.screensharing.allowed_domains</b> to edit it</li>" .
                                              "  <li>Add <b>%s</b> at the end of the list</li>" .
                                              "  <li>You can now use the screen sharing feature</li>" .
                                              "</ol>",
  "PAUSE_MOH"                            => "Play/Pause music",
  "WAIT_WITH_MUSIC"                      => "Why don't you listen to some music while waiting for others ?",
  "ALONE_IN_ROOM"                        => "Please wait a moment while nobody is here yet",
  "EVERYONE_CAN_SEE_YOUR_SCREEN"         => "All other participants can see your screen now",
  "SCREEN_UNSHARED"                      => "You do no longer share your screen",
  "ERROR_MAIL_INVALID"                   => "Please enter a valid email address",
  "SCREEN_s"                             => "%s's screen",
  "BROWSER_NOT_SUPPORTED"                => "Browser not supported",
  "NO_WEBRTC_SUPPORT"                    => "Sorry, but the video conference will not work because your web browser doesn't have the " .
                                            "required functionnalities.",
  "DOWNLOAD_ONE_OF_THESE_BROWSERS"       => "We recommand you download one of the following browsers which support the latest web " .
                                            "technologies required to use VROOM",
  "NO_WEBCAM"                            => "Cannot access your webcam",
  "CANT_ACCESS_WEBCAM"                   => "We couldn't access your webcam. Please check it's connected, powered on, and that you've ".
                                            "allowed the browser to access it, then reload this page",
  "CLICK_IF_NO_WEBCAM"                   => "If you don't have a webcam, click the following link, you'll be able to join the room with audio only",
  "CONNECTION_LOST"                      => "You have been disconnected",
  "CHECK_INTERNET_ACCESS"                => "Please, check your Internet connection, then refresh this page",
  "CONNECTING"                           => "Connecting",
  "CONNECTING_PLEASE_WAIT"               => "Please wait while establishing the connection",
  "HOME"                                 => "Home",
  "HELP"                                 => "Help",
  "ABOUT"                                => "About",
  "SECURE"                               => "Secure",
  "P2P_COMMUNICATION"                    => "With VROOM, your communications are done directly between users. No spying or recording of " .
                                            "your conversations",
  "WORKS_EVERYWHERE"                     => "Universal",
  "MODERN_BROWSERS"                      => "VROOM works with modern browsers (Chrome, Mozilla Firefox or Opera), " .
                                            "you don't have to install plugins, codecs, client software, then " .
                                            "send the tech documentation to all other parties. Just click, " .
                                            "and hangout",
  "MULTI_USER"                           => "Multi User",
  "THE_LIMIT_IS_YOUR_PIPE"               => "VROOM you can chat with several people at the same time. The only limit " .
                                            "is the capacity of your Internet pipe.",
  "NO_SIGNIN"                            => "No need to register",
  "YOU_DONT_HAVE_TO_REGISTER"            => "Tired of creating an account on each and every service you can find ?" .
                                            "Well, great news, with VROOM, you do not need to register at all ",
  "QUICK"                                => "Quick",
  "STOP_WASTING_TIME"                    => "Stop wasting time checking, installing, explaining. Just click, send a link, and talk. " .
                                            "It couldn't be simpler or faster",
  "SHARE_DESKTOP_OR_WINDOW"              => "Share your entire screen, or only a window in a single click, with an great quality. " .
                                            "With this feature, broadcast any content (images, presententions, documents etc...)",
  "TEXT_CHAT"                            => "Chat Included",
  "SECURED_TEXT_CHAT"                    => "Video and audio are not enough ? You can also use the included text chat.",
  "COLLABORATIVE_NOTETAKING"             => "Realtime notetaking",
  "TAKE_NOTE_IN_REALTIME"                => "Write your meating notes with others, all in real time with the included text pad",
  "SUPPORTED_BROWSERS"                   => "Supported browsers",
  "HELP_BROWSERS_SUPPORTED"              => "The technologies behind VROOM are still at their early stages, so only recent versions " .
                                            "of Mozilla Firefox, Google Chrome or Opera will work. Other browsers (mainly Internet Explorer and " .
                                            "Safari, which include Apple's devices like iPhone, iPads and iPods) won't work for now.",
  "I_DONT_HAVE_A_WEBCAM"                 => "I don't have a webcam",
  "HELP_I_DONT_HAVE_A_WEBCAM"            => "You'll still be able to participate. If no webcam is detected when you join a room " .
                                            "you'll get a message. Click on the link at the bottom and you'll join with audio " .
                                            "only. You'll be able to see others, and they will hear you, but will get a black " .
                                            "screen instead of your video.",
  "SCREEN_SHARING"                       => "Screen Sharing",
  "HELP_SCREEN_SHARING"                  => "VROOM lets you share your screen (or a single window) with the other members of the room. For now " .
                                            "this feature is only available with Google Chrome (requires a small extension, " .
                                            "you'll be prompted to install it first time you try to share your screen) or Mozilla Firefox." .
                                            "To enable this feature in Mozilla Firefox, follow these steps:",
  "OWNER_PRIVILEGES"                     => "Room creator's privileges",
  "HELP_OWNER_PRIVILEGES"                => "Room's creator (also called manager) has special privileges (compared to those who join " .
                                            "later, which are simple participants). For example, he can protect access with a password " .
                                            "which will be required before you can join the room. He also can set the manager's password " .
                                            "which will allow him, if he leaves the room, to recover its privileges when he connects again.",
  "RESERVED_ROOMS"                       => "Reserved rooms",
  "HELP_RESERVED_ROOMS"                  => "By default, rooms are ephemeral, which means they are automatically deleted if they " .
                                            "have no activity for some time. The room's creator can define an owner's password, " .
                                            "which will make the room reserved. A reserved room can still be deleted " .
                                            "if it's not used for a very long period of time, but will last longuer on the system",
  "BE_NOTIFIED"                          => "Notifications",
  "HELP_BE_NOTIFIED"                     => "You can be notified by email as soon as someone joins one of your rooms. For example, " .
                                            "create a room, add a password to make it persistent and add the link in your email signature. " .
                                            "When someone wants to talk with you, you'll get the notification",
  "ABOUT_VROOM"                          => "VROOM is a free software using the latest web technologies and lets you " .
                                            "to easily organize video meetings. Forget all the pain with installing " .
                                            "a client on your computer in a hury, compatibility issues between MAC OS " .
                                            "or GNU/Linux, port redirection problems, calls to the helpdesk because " .
                                            "streams cannot establish, H323 vs SIP vs ISDN issues. All you need now is:" .
                                            "<ul>" .
                                            "  <li>A device (PC, MAC, pad*, smartphone* doesn't matter)</li>" .
                                            "  <li>A webcam (optional but recommanded)</li>" .
                                            "  <li>A microphone and speakers (or headphones)</li>" .
                                            "  <li>A web browser</li>" .
                                            "</ul>" .
                                            "*: except iPad and iPhone",
  "HOW_IT_WORKS"                         => "How it works ?",
  "ABOUT_HOW_IT_WORKS"                   => "WebRTC allows browsers to browsers direct connections. This allows the best latency " .
                                            "as it avoids round trip through a server, which is important with real time communications. " .
                                            "But it also ensures the privacy of your communications.",
  "SERVERLESS"                           => "Serverless, really ?",
  "ABOUT_SERVERLESS"                     => "We're talking about peer to peer, but, in reality, a server is still needed somewhere" .
                                            "In WebRTC applications, server fulfil several roles: " .
                                            "<ol>" .
                                            "  <li>A meeting point: lets clients exchange each other the needed information to establish peer to peers connections</li>" .
                                            "  <li>Provides the client! you don't have anything to install, but your browser still need to download a few scripts" .
                                            "      (the core is written in JavaScript)</li>" .
                                            "  <li>Signaling: some data without any confidential or private meaning are sent through " .
                                            "      what we call the signaling channel. This channel is routed through a server. However, " .
                                            "      this channel doesn't transport any sensible information. It's used for example to " .
                                            "      sync colors between peers, notify when someone join the room, when someone mute his mic " .
                                            "      or when the rooom is locked</li>" .
                                            "  <li>NAT traversal helper: the <a href='http://en.wikipedia.org/wiki/Interactive_Connectivity_Establishment'>ICE</a> " .
                                            "      mechanism is used to allow clients behind a NAT router to establish their connections. " .
                                            "      As long as possible, channels through which sensible informations are sent (called data channels) " .
                                            "      are established peer to peer, but in some situations, this is not possible. A  " .
                                            "<a href='http://en.wikipedia.org/wiki/Traversal_Using_Relays_around_NAT'>TURN</a> server is used to relay data. " .
                                            "      But even in those cases, the server only relays ciphered packets, and has no access to the data " .
                                            "      so confidentiality is not compromised (only latency will be affected)</li>".
                                            "</ol>",
  "THANKS"                               => "Thanks",
  "ABOUT_THANKS"                         => "VROOM uses the following components, so, thanks to their respective authors :-)",
  "ABOUT_MUSICS"                         => "Also thanks to the authors of songs used",
  "FROM_AUTHOR"                          => "from",
  "PAGE_NOT_FOUND"                       => "This page does not exist",
  "SERVER_ERROR"                         => "Sorry for the inconvinience"
); 

1;
