package Vroom::I18N::en;
use base 'Vroom::I18N';

our %Lexicon = ( 
  _AUTO => 1,
  "WELCOME"                              => "Welcome on VROOM !!",
  "VROOM_DESC"                           => "VROOM is a simple video conferencing solution",
  "VROOM_IS_FREE_SOFTWARE"               => "VROOM is a free software, released under the MIT licence",
  "POWERED_BY"                           => "Proudly powered by",
  "ERROR_NAME_INVALID"                   => "This name is not valid",
  "ERROR_NAME_RESERVED"                  => "This name is reserved and cannot be used",
  "ERROR_NAME_CONFLICT"                  => "A room with this name already exists, please choose another one",
  "ERROR_ROOM_s_DOESNT_EXIST"            => "The room %s doesn't exist",
  "ERROR_ROOM_s_LOCKED"                  => "The room %s is locked, you cannot join it",
  "ERROR_OCCURRED"                       => "An error occurred",
  "ERROR_NOT_LOGGED_IN"                  => "Sorry, your not logged in",
  "JS_REQUIRED"                          => "VROOM needs javascript to work properly",
  "EMAIL_INVITATION"                     => "Video conference invitation",
  "INVITE_SENT_TO_s"                     => "An invitation was sent to %s",
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
  "ROOM_LOCKED"                          => "This room is now locked",
  "ROOM_UNLOCKED"                        => "This room is now unlocked",
  "ROOM_LOCKED_BY_s"                     => "%s locked the room",
  "ROOM_UNLOCKED_BY_s"                   => "%s unlocked the room",
  "PASSWORD_PROTECT_ON_BY_s"             => "%s password protected the room",
  "PASSWORD_PROTECT_OFF_BY_s"            => "%s removed password protection",
  "OWNER_PASSWORD_CHANGED_BY_s"          => "%s changed the room manager password",
  "OWNER_PASSWORD_REMOVED_BY_s"          => "%s removed the room manager password, so this room isn't persistent anymore",
  "DATA_WIPED"                           => "Data has been wiped",
  "ROOM_DATA_WIPED_BY_s"                 => "Room data (chat history and pad content) has been wiped by %s",
  "NOT_ENABLED"                          => "This feature isn't enabled",
  "OOOPS"                                => "Ooops",
  "GOODBYE"                              => "Goodbye",
  "THANKS_SEE_YOU_SOON"                  => "Thanks and see you soon",
  "THANKS_FOR_USING"                     => "Thank you for using VROOM, we hope you enjoyed your meeting",
  "BACK_TO_MAIN_MENU"                    => "Back to main menu",
  "JOIN_THIS_ROOM"                       => "Join this room",
  "CREATE_ROOM"                          => "Create a new room",
  "ROOM_NAME"                            => "Room name",
  "RANDOM_IF_EMPTY"                      => "If you let this field empty, a random name will be given to the room",
  "THIS_ROOM_ALREADY_EXISTS"             => "This room already exists",
  "CONFIRM_OR_CHOOSE_ANOTHER_NAME"       => "Do you want to join it or choose another name ?",
  "CHOOSE_ANOTHER_NAME"                  => "Choose another name",
  "ROOM_s"                               => "room %s",
  "INVITE_PEOPLE"                        => "Invite other people",
  "TO_INVITE_SHARE_THIS_URL"             => "Send this address to anyone and he will be able to join this room",
  "YOU_CAN_INVITE_BY_MAIL"               => "You can also directly send an invitation by email",
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
  "NAME_SENT_TO_OTHERS"                  => "This name will be sent to the other peers so they can identify you. You need to set your name before you can chat",
  "DISPLAY_NAME_TOO_LONG"                => "This name is too long",
  "DISPLAY_NAME_REQUIRED"                => "You need to enter your name",
  "SET_A_DISPLAY_NAME"                   => "Please set your name before you can join the room",
  "FORCE_DISPLAY_NAME"                   => "Participants will be asked for their name before they can join the room",
  "NAME_WONT_BE_ASKED"                   => "Participant won't have to type their name before they can join the room",
  "WIPE_CHAT_AND_PAD"                    => "Wipe chat history and pad content",
  "WIPE_CHAT"                            => "Wipe chat history",
  "WIPE_ROOM_DATA"                       => "Wipe room data",
  "YOU_ARE_ABOUT_TO_WIPE_DATA"           => "You are about to wipe room data",
  "THIS_INCLUDE"                         => "This includes",
  "CHAT_HISTORY"                         => "Chat history",
  "PAD_CONTENT"                          => "The collaborative pad content",
  "CONFIRM_WIPE"                         => "Wipe",
  "TERMINATE_ROOM"                       => "Stop the call and delete the room",
  "YOU_ARE_ABOUT_TO_TERMINATE_ROOM"      => "You are about to delete this room. This will have the following effects",
  "ALL_PEERS_WILL_HANGUP"                => "All the peers will hangup immediatly",
  "ALL_DATA_WILL_BE_WIPED"               => "All the data of the room will be deleted",
  "ROOM_WILL_BE_DELETED"                 => "The room itself, including all its configuration will be deleted",
  "CONFIRM_TERMINATE"                    => "Stop the call and delete the room",
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
  "PASSWORD_PROTECT_SET"                 => "A password will be needed to join this room",
  "PASSWORD_PROTECT_UNSET"               => "No password will be asked to join this room",
  "ROOM_NOW_RESERVED"                    => "This room is now reserved",
  "ROOM_NO_MORE_RESERVED"                => "This room isn't reserved anymore",
  "PASSWORDS_DO_NOT_MATCH"               => "Passwords do not match",
  "RESERVE_THIS_ROOM"                    => "Reserve this room",
  "SET_OWNER_PASS"                       => "To reserve this room, you must set an owner password. Keep it carefully, " .
                                            "it'll grant you access to the configuration menus next time you connect.",
  "A_STANDARD_ROOM_EXPIRES_AFTER_d"      => "A standard room will be deleted after %d hour(s) without activity",
  "A_RESERVED_ROOM"                      => "A reserved room",
  "EXPIRE_AFTER_d"                       => "will be deleted after %d day(s) without activity",
  "WILL_NEVER_EXPIRE"                    => "will be kept forever",
  "CONFIRM_PASSWORD"                     => "Confirm password",
  "PROTECT_ROOM_WITH_PASSWORD"           => "If this password is set, participants will have to type it before the system let them in",
  "ERROR_COMMON_ROOM_NAME"               => "Sorry, this room name is too comon to be reserved",
  "AUTHENTICATE"                         => "Authentication",
  "AUTH_TO_MANAGE_THE_ROOM"              => "Authenticate to manage the room",
  "ADD_NOTIFICATION"                     => "Add a notification",
  "ADD_THIS_ADDRESS"                     => "Add this address",
  "REMOVE_THIS_ADDRESS"                  => "Remove this address",
  "NOTIFICATION_ON_JOIN"                 => "You can set a list of email address which will receive a notification each time " .
                                            "someone joins this room",
  "s_WILL_BE_NOTIFIED"                   => "%s will receive a notification each time someone joins this room",
  "s_WONT_BE_NOTIFIED_ANYMORE"           => "%s won't be notified anymore",
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
  "EXISTING_ROOMS"                       => "Existing rooms",
  "MANAGE"                               => "Manage",
  "ROOM_DETAILS"                         => "Room details",
  "ROOM_ID"                              => "ID",
  "CREATION_DATE"                        => "Creation date",
  "LAST_ACTIVITY"                        => "Last activity",
  "NUMBER_OF_PARTICIPANTS"               => "Number of participants",
  "LOCKED"                               => "Locked",
  "ASK_FOR_NAME"                         => "Require to enter a name",
  "JOIN_PASSWORD"                        => "Password to join the room",
  "OWNER_PASSWORD"                       => "Password to manage the room",
  "PERSISTENT"                           => "Persistent",
  "ROOM_NOW_PERSISTENT"                  => "This room is now persistent",
  "ROOM_NO_MORE_PERSISTENT"              => "This rooms isn't persistent anymore",
  "EMAIL_INVITE"                         => "Email invitation",
  "DELETE_THIS_ROOM"                     => "Delete this room",
  "CONFIRM_DELETE"                       => "Confirm delation",
  "HELP_SET_DISPLAY_NAME"                => "This field lets you type your name which will be displayed for other participants. " .
                                            "It must be set before you can use the chat. no need to validate anything, the name " .
                                            "will be sent to others as you type.",
  "HELP_CHANGE_COLOR_BUTTON"             => "Randomly choose another color. Usefull when two peers have the same, are too close colors.",
  "HELP_CHAT_BUTTON"                     => "Display or hide the chat menu",
  "HELP_MUTE_BUTTON"                     => "Mute or unmute your microphone",
  "HELP_SUSPEND_CAM_BUTTON"              => "Suspend or resum your webcam. Others will still hear you (unless you also muted your mic)",
  "HELP_MOH_BUTTON"                      => "This button only appears when you're alone in the room. It lets you play/stop music on hold.",
  "HELP_SHARE_SCREEN_BUTTON"             => "Share your screen, or just a window with others. Only available with Google Chrome for now.",
  "HELP_INVITE_MENU"                     => "This menu lets you invite other people",
  "HELP_EMAIL_INVITE_BUTTON"             => "This button send an invitation to the email adress you enterred",
  "HELP_GROUP_ACTIONS"                   => "This menu contains global actions (which affects all the peers at once). It'll " .
                                            "only be displayed if there's 3 or more participants in the room.",
  "HELP_MUTE_EVERYONE_BUTTON"            => "This button will mute all the microphones (peers already muted won't be affected)",
  "HELP_UNMUTE_EVERYONE_BUTTON"          => "This button will unmute all the microphones (peers already unmuted won't be affected)",
  "HELP_SUSPEND_EVERYONE_BUTTON"         => "This button will suspend all the webcams (peers already suspended won't be affected)",
  "HELP_RESUME_EVERYONE_BUTTON"          => "This button will resume all the webcam (peers already resumed wont be affected)",
  "HELP_CONF_MENU"                       => "This menu contains room configuration",
  "HELP_LOCK_BUTTON"                     => "This button will lock the room: nobody will be able to join it (except owners of the room)",
  "HELP_PASSWORD_BUTTON"                 => "This button will protect access to this room with a password. Note that this password " .
                                            "isn't asked it you join the room through an email invitation (in which case the " .
                                            "authentication is done with a uniq token valid for two hours)",
  "HELP_RESERVE_BUTTON"                  => "Reserve this room, you'll be able to leave, reconnect, and get configuration menus back. " .
                                            "The room will also be kept much longer.",
  "HELP_ASK_FOR_NAME_BUTTON"             => "This will enforce participants to set their name before joining the room.",
  "HELP_WIPE_DATA_BUTTON"                => "This will wipe room data (chat history and collaborative pad content)",
  "HELP_LOGOUT_BUTTON"                   => "This will end the call and disconnect you from the room",
  "HELP_PEER_ACTIONS_BUTTONS"            => "This menu will appear when you put the mouse over a video preview. It'll allow " .
                                            "you to run actions which only affect this peer (mute/suspend/grant admin rights/kick " .
                                            "from the room). Warning: grating admin rights to someone is irrevocable, and he will " .
                                            "be able to change configuration parameters (including passwords).",
  "LOGOUT"                               => "Leave the room",
  "LEAVE_THIS_ROOM"                      => "Leave the room",
  "ARE_YOU_SURE_YOU_WANT_TO_LEAVE"       => "Are you sure you want to leave this room ?",
  "YOU_CAN_WIPE_DATA_BEFORE_LEAVING"     => "You can wipe room data before you leave",
  "WIPE_AND_QUIT"                        => "Wipe data and leave",
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
  "MUTE_EVERYONE"                        => "Mute everyone",
  "UNMUTE_EVERYONE"                      => "Unmute everyone",
  "SUSPEND_EVERYONE"                     => "Suspend everyone's webcam",
  "RESUME_EVERYONE"                      => "Resume everyone's webcam",
  "SHARE_YOUR_SCREEN"                    => "Share your screen with the other members of this room",
  "CANT_SHARE_SCREEN"                    => "Sorry, your configuration does not allow screen sharing",
  "SCREEN_SHARING_ONLY_FOR_CHROME"       => "Sorry, but you can't share your screen. Only Google Chrome supports this feature for now",
  "SCREEN_SHARING_CANCELLED"             => "Screen sharing has been cancelled",
  "EXTENSION_REQUIRED"                   => "An extension is required",
  "VROOM_CHROME_EXTENSION"               => "To enable screen sharing, you need to install an extension. Click on the following link and refresh this page",
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
  "HOME"                                 => "Home",
  "HELP"                                 => "Help",
  "ABOUT"                                => "About",
  "SECURE"                               => "Secure",
  "P2P_COMMUNICATION"                    => "With VROOM, your communications are done peer to peer, and secured",
  "WORKS_EVERYWHERE"                     => "Universal",
  "MODERN_BROWSERS"                      => "VROOM works with modern browsers (Chrome, Mozilla Firefox or Opera), " .
                                            "you don't have to install plugins, codecs, client software, then " .
                                            "send the tech documentation to all other parties. Just click, " .
                                            "and hangout",
  "MULTI_USER"                           => "Multi User",
  "THE_LIMIT_IS_YOUR_PIPE"               => "VROOM doesn't have a limit on the number of participants, " .
                                            "you can chat with several people at the same time. The only limit " .
                                            "is the capacity of your Internet pipe. Usually, you can chat with " .
                                            "up to 5~6 person without problem",
  "NO_SIGNIN"                            => "No need to register",
  "YOU_DONT_HAVE_TO_REGISTER"            => "Tired of creating an account on each and every service you can find, checking " .
                                            "your friends or coworkers did the same ? Well, great news, with VROOM, you do not need to, " .
                                            "in fact, you don't have to register at all",
  "QUICK"                                => "Quick",
  "STOP_WASTING_TIME"                    => "Stop wasting time checking, installing, explaining. Just click, send a link, and talk. " .
                                            "It couldn't be simpler or faster",
  "SHARE_DESKTOP_OR_WINDOW"              => "Share your entire screen, or only a window in a single click, with an great quality. " .
                                            "With this feature, broadcast any content (images, presententions, documents etc...)",
  "TEXT_CHAT"                            => "Chat Included",
  "SECURED_TEXT_CHAT"                    => "Video and audio are not enough ? You can also use the included text chat, and fully secured: " .
                                            "your discussions are done directly between members and will never be sent on our servers.",
  "COLLABORATIVE_NOTETAKING"             => "Realtime notetaking",
  "TAKE_NOTE_IN_REALTIME"                => "Write your meating notes with others, all in real time with the included editor",
  "SUPPORTED_BROWSERS"                   => "Supported browsers",
  "HELP_BROWSERS_SUPPORTED"              => "VROOM works with any modern, standard compliant browsers, which means any " .
                                            "recent Mozilla Firefox, Google Chrome or Opera.",
  "I_DONT_HAVE_A_WEBCAM"                 => "I don't have a webcam",
  "HELP_I_DONT_HAVE_A_WEBCAM"            => "You'll still be able to participate. If no webcam is detected when you join a room " .
                                            "you'll get a message. Click on the link at the bottom and you'll join with audio " .
                                            "only. You'll be able to see others, and they will hear you, but will get a black " .
                                            "screen instead of your video.",
  "SCREEN_SHARING"                       => "Screen Sharing",
  "HELP_SCREEN_SHARING"                  => "VROOM lets you share your screen (or a single window) with the other members of the room. For now " .
                                            "this feature is only available in Google Chrome, and you need to install an extension " .
                                            "(you'll be prompted for it the first time you try to share your screen)",
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
  "RESERVE_YOUR_ROOM"                    => "Reserve your room",
  "HELP_RESERVE_YOUR_ROOM"               => "Want to reserve your room name so it's always available for you (company name, ongoing project " .
                                            "etc.) ? Just set both a join password and the owner password. The room will be kept " .
                                            "as long as the owner password is set (and as long as you use it from time to time)",
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
                                            "  <li>A device (PC, MAC, pad, doesn't matter)</li>" .
                                            "  <li>A webcam (optional but recommanded)</li>" .
                                            "  <li>A microphone and speakers (or headphones)</li>" .
                                            "  <li>A web browser</li>" .
                                            "</ul>",
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
  "FROM_AUTHOR"                          => "from"


); 

1;
