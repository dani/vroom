package Vroom::I18N::fr;
use base 'Vroom::I18N';

use utf8;

our %Lexicon = (
    _AUTO                                       => 1,
    "WELCOME"                                   => "Bienvenue sur VROOM !!",
    "ERROR_NAME_INVALID"                        => "Ce nom n'est pas valide",
    "ERROR_NAME_CONFLICT"                       => "Ce nom est déjà pris, choisissez en un autre",
    "ERROR_ROOM_s_DOESNT_EXIST"                 => "Le salon %s n'existe pas",
    "ERROR_ROOM_s_LOCKED"                       => "Le salon %s est verrouillé, vous ne pouvez pas le rejoindre",
    "ERROR_OCCURED"                             => "Une erreur est survenue",
    "ERROR_NOT_LOGGED_IN"                       => "Désolé, vous n'êtes pas identifié",
    "JOIN_US_ON_s"                              => "Vidéo conférence %s",
    "TO_JOIN_s_CLICK_s"                         => "Vous êtes invité à rejoindre le salon de vidéo conférence %s. " .
                                                   "Tout ce dont vous avez besoin est un navigateur web récent et " .
                                                   "une webcam. Quand vous êtes prêt, cliquez sur <a href='%s'>ce lien</a>",
    "HAVE_A_NICE_MEETING"                       => "Bonne réunion :-)",
    "EMAIL_SIGN"                                => "VROOM! Et la visio conférence devient libre, simple et sûr",
    "INVITE_SENT_TO_s"                          => "Une invitation a été envoyée à %s",
    "ROOM_LOCKED"                               => "Ce salon est maintenant verrouillé",
    "ROOM_UNLOCKED"                             => "Ce salon est maintenant déverrouillé",
    "ONE_OF_THE_PEERS"                          => "un des participants",
    "ROOM_LOCKED_BY_s"                          => "%s a verrouillé le salon",  
    "ROOM_UNLOCKED_BY_s"                        => "%s a déverrouillé le salon",
    "OOOPS"                                     => "Oups",
    "GOODBY"                                    => "Au revoir",
    "THANKS_SEE_YOU_SOON"                       => "Merci et à bientôt",
    "THANKS_FOR_USING"                          => "Nous vous remmercions de votre confiance, et espérons que " .
                                                   "vous avez passé une agréable réunion.",
    "BACK_TO_MAIN_MENU"                         => "Retour au menu principal",
    "CREATE_ROOM"                               => "Créer un salon",
    "ROOM_NAME"                                 => "Nom du salon",
    "RANDOM_IF_EMPTY"                           => "Si vous laissez ce champs vide, un nom aléatoire sera donné au salon",
    "ROOM_s"                                    => "Salon %s",
    "SEND_INVITE"                               => "Envoyez une invitation par mail",
    "EMAIL_INVITE"                              => "Inviter par email",
    "DISPLAY_NAME"                              => "Nom",
    "YOUR_NAME"                                 => "Votre nom",
    "NAME_SENT_TO_OTHERS"                       => "Ce nom sera envoyé aux autres participants pour qu'ils puissent vous identifier. " .
                                                   "Vous devez en saisir un avant de pouvoir utiliser le tchat",
    "CHANGE_COLOR"                              => "Changez de couleur",
    "CLICK_TO_CHAT"                             => "Cliquez ici pour accéder au tchat",
    "PREVENT_TO_JOIN"                           => "Empêchez d'autres participants de rejoindre ce salon",
    "MUTE_MIC"                                  => "Coupez votre micro",
    "SUSPEND_CAM"                               => "Stoppez la webcam, les autres verront un écran noir à la place, " .
                                                   "mais pourront toujours vous entendre",
    "LOGOUT"                                    => "Quitter le salon",
    "SET_YOUR_NAME_TO_CHAT"                     => "Vous devez saisir votre nom avant de pouvoir tchater",
    "MIC_MUTED"                                 => "Votre micro est coupé",
    "MIC_UNMUTED"                               => "Votre micro est à nouveau actif",
    "CAM_SUSPENDED"                             => "Votre webcam est en pause",
    "CAM_RESUMED"                               => "Votre webcam est à nouveau active",
    "SHARE_YOUR_SCREEN"                         => "Partagez votre écran avec les autres membres du salon",
    "CANT_SHARE_SCREEN"                         => "Désolé, mais votre configuration ne vous permet pas de partager votre écran",
    "SCREEN_SHARING_ONLY_FOR_CHROME"            => "Désolé, mais vous ne pouvez pas partager votre écran. Seul le navigateur Google Chrome " .
                                                   "supporte cette fonction pour l'instant",
    "SCREEN_SHARING_CANCELLED"                  => "Le partage d'écran a été annulé",
    "EXTENSION_REQUIRED"                        => "Une extension est nécessaire",
    "VROOM_CHROME_EXTENSION"                    => "Pour activer le partage d'écran, vous devez installer une extension, cliquez sur le lien ci-dessous, puis raffraîchissez cette page",
    "EVERYONE_CAN_SEE_YOUR_SCREEN"              => "Tous les autres participants peuvent voir votre écran",
    "SCREEN_UNSHARED"                           => "Vous ne partagez plus votre écran",
    "ERROR_MAIL_INVALID"                        => "Veuillez saisir une adresse email valide",
    "CANT_SEND_TO_s"                            => "Le message n'a pas pu être envoyé à %s",
    "SCREEN_s"                                  => "Écran de %s",
    "BROWSER_NOT_SUPPORTED"                     => "Navigateur non supporté",
    "NO_WEBRTC_SUPPORT"                         => "Désolé, la vidéo conférence ne fonctionnera pas (ou pas correctement) car votre navigateur " .
                                                   "ne dispose pas des fonctions nécessaires. Nous recommandons de télécharger " .
                                                   "un des navigateurs suivants, qui supportent les dernières technologies nécessaires " .
                                                   "à l'utilisation de VROOM",
    "HOME"                                      => "Accueil",
    "HELP"                                      => "Aide",
    "ABOUT"                                     => "À propos",
    "SECURE"                                    => "Sécurisé",
    "P2P_COMMUNICATION"                         => "Avec VROOM, vos communications se font de pair à pair (directement enre utilisateurs), " .
                                                   "et sont sécurisées. " .
                                                   "Nos serveurs ne servent qu'au signalement, pour que chacun puisse se connecter aux autres " .
                                                   "(comme un point de rendez-vous virtuel). Seulement si certains d'entre vous se trouvent " .
                                                   "derrière des pare feu stricts, les flux seront relayés à travers nos serveurs, en dernier " .
                                                   "recours, mais même dans ce cas, nous ne relayons que des flux chiffrés, inintelligibles",
    "WORKS_EVERYWHERE"                          => "Fonctionne partout",
    "MODERN_BROWSERS"                           => "VROOM fonctionne avec les navigateurs modernes (Google Chrome, Mozilla Firefox, Opera), " .
                                                   "vous n'avez aucun plugin à installer, ni codec, ni client logiciel, ni à " .
                                                   "envoyer la doc technique aux autres participants. Vous n'avez qu'à cliquer, et discuter",
    "MULTI_USER"                                => "Multi utilisateurs",
    "THE_LIMIT_IS_YOUR_PIPE"                    => "VROOM n'impose pas de limite sur le nombre de participants, vous pouvez discuter à " .
                                                   "plusieurs en même temps. La seule limite est la capacité de votre connexion Internet. " .
                                                   "En général, vous pouvez discuter à 5~6 personnes sans problème.",
    "SUPPORTED_BROWSERS"                        => "Navigateurs supportés",
    "HELP_BROWSERS_SUPPORTED"                   => "VROOM fonctionne avec tous les navigateurs modernes et respectueux des standards. " .
                                                   "Les technologies employées (WebRTC) étant très récentes, seules les versions " .
                                                   "récentes de Mozilla Firefox, Google Chrome et Opéra fonctionnent pour l'instant. " .
                                                   "Les autres navigateurs (principalement Internet Explorer et Safari) devraient " .
                                                   "suivrent un jour, mais ne fonctionneront pas actuellement",
    "SREEN_SHARING"                             => "Partage d'écran",
    "HELP_SCREEN_SHARING"                       => "VROOM vous permet de partager votre écran avec tous les autres participants d'une conférence. " .
                                                   "Pour l'instant, le partage d'écran ne fonctionne qu'avec le navigateur Google Chrome, " .
                                                   "et nécessite d'effectuer le réglage suivant (à partir de la version 34, ce réglage n'est " .
                                                   "plus nécessaire)" . 
                                                   "<ul>" . 
                                                   "  <li>Tapez chrome://flags/ dans la barre d'adresse</li>" .
                                                   "  <li>Recherchez \"Activer la fonctionnalité de capture d'écran dans getUserMedia()\" et cliquez sur " .
                                                   "      le lien \"Activer\" juste en dessous</li>" .
                                                   "  <li>Cliquez sur le bouton \"Relancer maintenant\" qui apparait en bas de la page</li>" .
                                                   "</ul>",
    "ABOUT_VROOM"                               => "VROOM est un logiciel libre exploitant les dernières technologies du " .
                                                   "web vous permettant d'organiser simplement des visio conférences. Fini " .
                                                   "les galères à devoir installer un client sur le poste au dernier moment, " .
                                                   "l'incompatibilité MAC OS ou GNU/Linux, les problèmes de redirection de port, " .
                                                   "les appels au support technique parce que la visio s'établie pas, les " .
                                                   "soucis d'H323 vs SIP vs ISDN. Tout ce qu'il vous faut désormais, c'est:" .
                                                   "<ul>" .
                                                   "  <li>Un poste (PC, MAC, tablette, peu importe)</li>" .
                                                   "  <li>Une webcam et un micro</li>" .
                                                   "  <li>Un navigateur web moderne</li>" .
                                                   "</ul>",
    "HOW_IT_WORKS"                              => "Comment ça marche ?",
    "ABOUT_HOW_IT_WORKS"                        => "WebRTC permet d'établir des connexions directement entre les navigateurs " .
                                                   "des participants. Cela permet d'une part d'offrir la meilleur latence possible ".
                                                   "en évitant les allés-retours avec un serveur, ce qui est toujours important " .
                                                   "lors de communications en temps réel. D'autre part, cela permet aussi de " .
                                                   "garantir la confidentialité de vos communications.",
    "SERVERLESS"                                => "Aucun serveur, vraiment ?",
    "ABOUT_SERVERLESS"                          => "On parle de pair à pair depuis tout à l'heure. En réalité, vous avez toujours " .
                                                   "besoin d'un serveur quelque part. Dans les applications WebRTC, le serveur " .
                                                   "remplis plusieurs rôles:" .
                                                   "<ol>" .
                                                   "  <li>Le point de rendez-vous: permet à tous les participants de se " .
                                                   "      retrouver et de s'échanger les informations nécessaires pour " .
                                                   "      établir les connexions en direct</li>" .
                                                   "  <li>Le client: il n'y a rien à installer sur le poste, mais votre navigateur " .
                                                   "      doit cependant télécharger un ensembles de scripts (la majorité étant du " .
                                                   "      JavaScript)</li>" .
                                                   "  <li>Le signalement: certaines données sans caractère confidentiel transitent " .
                                                   "      par ce qu'on appel le canal de signalement. Ce canal passe par un serveur. " .
                                                   "      Cependant, ce canal ne transmet aucune information personnelle ou sensible. Il " .
                                                   "      est par exemple utilisé pour synchroniser les couleurs associées à chaque " .
                                                   "      participant, quand un nouveau participant arrive, quelqu'un coupe son micro " .
                                                   "      ou encore verrouille le salon</li>" .
                                                   "  <li>Aide aux contournements du NAT: le mechanisme " .
                                                   "<a href='http://en.wikipedia.org/wiki/Interactive_Connectivity_Establishment'>ICE</a> " .
                                                   "      est utilisé pour permettre aux clients derrière un NAT d'établir leurs connexions. " .
                                                   "      Tant que c'est possible, les cannaux par lesquels les données sensibles transitent " .
                                                   "      (appelés canaux de données) sont établis en direct, cependant, dans certaines " .
                                                   "      situations, celà n'est pas possible. Un serveur " .
                                                   "<a href='http://en.wikipedia.org/wiki/Traversal_Using_Relays_around_NAT'>TURN</a> " .
                                                   "      est utilisé pour relayer les données. Même dans ces situations, le serveur " .
                                                   "      n'a pas accès aux données, il ne fait que relayer des trames " .
                                                   "      chiffrées parfaitement inintelligibles, la confidentialité des communications " .
                                                   "      n'est donc pas compromise (la latence sera par contre affectée)</li>".
                                                   "</ol>",
    "THANKS"                                    => "Remerciements",
    "ABOUT_THANKS"                              => "VROOM utilise les composants suivants, merci donc aux auteurs respectifs :-)",

);

1;
