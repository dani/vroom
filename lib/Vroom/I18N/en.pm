package Vroom::I18N::en;
use base 'Vroom::I18N';

our %Lexicon = ( 
  _AUTO => 1,
  "WELCOME"                              => "Welcome on VROOM !!",
  "ERROR_NAME_INVALID"                   => "This name is not valid",
  "ERROR_NAME_CONFLICT"                  => "A room with this name already exists, please choose another one",
  "ERROR_ROOM_s_DOESNT_EXIST"            => "The room %s doesn't exist",
  "ERROR_ROOM_s_LOCKED"                  => "The room %s is locked, you cannot join it",
  "ERROR_OCCURED"                        => "An error occured",
  "ERROR_NOT_LOGGED_IN"                  => "Sorry, your not logged in",
  "EMAIL_INVITATION"                     => "Video conference invitation",
  "INVITE_SENT_TO_s"                     => "An invitation was sent to %s",
  "YOU_ARE_INVITED_TO_A_MEETING"         => "You are awaited on a video conferecing room. " .
                                            "Before joining it, make sure you have all the necessary",
  "A_MODERN_BROWSER"                     => "A modern web browser, recent versions of Mozilla Firefox, Google Chrome or Opera will work",
  "A_WEBCAM"                             => "A webcam",
  "A_MIC"                                => "A microphone",
  "WHEN_YOU_ARE_READY"                   => "When you are ready, go to this address to join the conference",
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
  "ONE_OF_THE_PEERS"                     => "one of the peers",
  "PASSWORD_PROTECT_ON_BY_s"             => "%s password protected the room",
  "PASSWORD_PROTECT_OFF_BY_s"            => "%s removed password protection",
  "OWNER_PASSWORD_CHANGED_BY_s"          => "%s changed the room manager password",
  "OWNER_PASSWORD_REMOVED_BY_s"          => "%s removed the room manager password, so this room isn't persistent anymore",
  "OOOPS"                                => "Ooops",
  "GOODBY"                               => "Goodby",
  "THANKS_SEE_YOU_SOON"                  => "Thanks and see you soon",
  "THANKS_FOR_USING"                     => "Thank you for using VROOM, we hope you enjoyed your meeting",
  "BACK_TO_MAIN_MENU"                    => "Back to main menu",
  "JOIN_THIS_ROOM"                       => "Join this room",
  "CREATE_ROOM"                          => "Create a new room",
  "ROOM_NAME"                            => "Room name",
  "RANDOM_IF_EMPTY"                      => "If you let this field empty, a random name will be given to the room",
  "ROOM_s"                               => "room %s",
  "INVITE_PEOPLE"                        => "Invite other people",
  "TO_INVITE_SHARE_THIS_URL"             => "Send this address to anyone and he will be able to join this room",
  "YOU_CAN_INVITE_BY_MAIL"               => "You can also directly send an invitation by email",
  "EMAIL_PLACEHOLDER"                    => "j.smith\@example.com",
  "SEND_INVITE"                          => "Send an email invitation",
  "MESSAGE"                              => "Message",
  "SEND_CUSTOM_MESSAGE"                  => "You can add a custom message, for example, the password needed to join this room",
  "DISPLAY_NAME"                         => "Display name",
  "YOUR_NAME"                            => "Your name",
  "NAME_SENT_TO_OTHERS"                  => "This name will be sent to the other peers so they can identify you. You need to set your name before you can chat",
  "CHANGE_COLOR"                         => "Change your color",
  "CLICK_TO_CHAT"                        => "Click to access the chat",
  "PREVENT_TO_JOIN"                      => "Prevent other participants to join this room",
  "MUTE_MIC"                             => "Turn off your microphone",
  "SUSPEND_CAM"                          => "Suspend your webcam, other will see a black screen instead, but can still hear you",
  "CONFIGURE"                            => "Configuration",
  "YOU_CAN_PASSWORD_PROTECT_JOIN"        => "You can protect this room with a password",
  "PASSWORD"                             => "Password",
  "PASSWORD_PROTECT"                     => "Password protect",
  "REMOVE_PASSWORD"                      => "Remove the password",
  "PASSWORD_SET"                         => "Password updated",
  "PASSWORD_REMOVED"                     => "Password removed",
  "AUTHENTICATE"                         => "Authentication",
  "AUTH_TO_MANAGE_THE_ROOM"              => "Authenticate to manage the room",
  "OWNER_PASSWORD_MAKES_PERSISTENT"      => "You can set a manager password. It will make this room persistent",
  "OWNER_PASSWORD"                       => "Manager password",
  "REMOVE_OWNER_PASSWORD"                => "Remove the manager password. The room will become ephemeral",
  "AUTH_SUCCESS"                         => "You are now authenticated",
  "NOT_ALLOWED"                          => "You are not allowed to do this",
  "WRONG_PASSWORD"                       => "Wrong password",
  "PASSWORD_REQUIRED"                    => "Password required",
  "A_PASSWORD_IS_NEEDED_TO_JOIN"         => "You must provide a password to join this room",
  "TRY_AGAIN"                            => "Try again",
  "LOGOUT"                               => "Leave the room",
  "SET_YOUR_NAME_TO_CHAT"                => "You need to set your name to be able to chat",
  "SEND_MESSAGE"                         => "Send the message",
  "SAVE_HISTORY"                         => "Save history to a file",
  "MIC_MUTED"                            => "Your microphone is now muted",
  "MIC_UNMUTED"                          => "Your microphone is now unmuted",
  "CAM_SUSPENDED"                        => "Your webcam is now suspended",
  "CAM_RESUMED"                          => "Your webcam is on again",
  "SHARE_YOUR_SCREEN"                    => "Share your screen with the other members of this room",
  "CANT_SHARE_SCREEN"                    => "Sorry, your configuration does not allow screen sharing",
  "SCREEN_SHARING_ONLY_FOR_CHROME"       => "Sorry, but you can't share your screen. Only Google Chrome supports this feature for now",
  "SCREEN_SHARING_CANCELLED"             => "Screen sharing has been cancelled",
  "EXTENSION_REQUIRED"                   => "An extension is required",
  "VROOM_CHROME_EXTENSION"               => "To enable screen sharing, you need to install an extension. Click on the following link and refresh this page",
  "EVERYONE_CAN_SEE_YOUR_SCREEN"         => "All other participants can see your screen now",
  "SCREEN_UNSHARED"                      => "You do no longer share your screen",
  "ERROR_MAIL_INVALID"                   => "Please enter a valid email address",
  "CANT_SEND_TO_s"                       => "Couldn't send message to %s",
  "SCREEN_s"                             => "%s's screen",
  "BROWSER_NOT_SUPPORTED"                => "Browser not supported",
  "NO_WEBRTC_SUPPORT"                    => "Sorry, but the video conference will not work because your web browser doesn't have the " .
                                            "required functionnalities. We recommand you download one of the following browsers " .
                                            "which support the latest web technologies required to use VROOM",
  "HOME"                                 => "Home",
  "HELP"                                 => "Help",
  "ABOUT"                                => "About",
  "SECURE"                               => "Secure",
  "P2P_COMMUNICATION"                    => "With VROOM, your communication is done peer to peer, and secured. " .
                                            "Our servers are only used for signaling, so that everyone can connect " .
                                            "directly to each other (see it like a virtual meeting point). All your " .
                                            "important data is sent directly. Only if you are behind a strict firewall, " .
                                            "streams will be relayed by our servers, as a last resort, but even in this case, " .
                                            "we will just relay encrypted blobs.",
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
  "SUPPORTED_BROWSERS"                   => "Supported browsers",
  "HELP_BROWSERS_SUPPORTED"              => "VROOM works with any modern, standard compliant browsers, which means any " .
                                            "recent Mozilla Firefox, Google Chrome or Opera.",
  "SCREEN_SHARING"                       => "Screen Sharing",
  "HELP_SCREEN_SHARING"                  => "VROOM lets you share your screen (or a single window) with the other members of the room. For now " .
                                            "this feature is only available in Google Chrome, and you need to install an extension " .
                                            "(you'll be prompted for it the first time you try to share your screen)",
  "OWNER_PRIVILEGES"                     => "Room creator's privileges",
  "HELP_OWNER_PRIVILEGES"                => "Room's creator (also called manager) has special privileges (compared to those who join " .
                                            "later, which are simple participants). For example, he can protect access with a password " .
                                            "which will be required before you can join the room. He also can set the manager's password " .
                                            "which will allow him, if he leaves the room, to recover its privileges when he connects again.",
  "PERSISTENT_ROOMS"                     => "Persistant rooms",
  "HELP_PERSISTENT_ROOMS"                => "By default, rooms are ephemeral, which means they are automatically deleted if they " .
                                            "have no activity for a long time (default is one hour). The room's creator can define " .
                                            "a manager's password, which will make the room persistent: it'll be kept indefinitly. " .
                                            "In order to delete the room, the owner can simply unset the manager's password, which " .
                                            "will make the room ephemeral again (it'll be deleted if no activity is detected).",
  "RESERVE_YOUR_ROOM"                    => "Reserve your room",
  "HELP_RESERVE_YOUR_ROOM"               => "Want to reserve your room name so it's always available for you (company name, ongoing project " .
                                            "etc.) ? Just set both a join password and the manager password. The room will be kept " .
                                            "as long as the manager password is set",
  "ABOUT_VROOM"                          => "VROOM is a free spftware using the latest web technologies and lets you " .
                                            "to easily organize video meetings. Forget all the pain with installing " .
                                            "a client on your computer in a hury, compatibility issues between MAC OS " .
                                            "or GNU/Linux, port redirection problems, calls to the helpdesk because " .
                                            "streams cannot establish, H323 vs SIP vs ISDN issues. All you need now is:" .
                                            "<ul>" .
                                            "  <li>A device (PC, MAC, pad, doesn't matter)</li>" .
                                            "  <li>A webcam and a microphone</li>" .
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


); 

1;
