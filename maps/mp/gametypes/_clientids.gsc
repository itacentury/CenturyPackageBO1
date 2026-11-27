#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\centurypackage\init;
#include maps\mp\centurypackage\menu;
#include maps\mp\centurypackage\overflow;
#include maps\mp\centurypackage\utils;
#include maps\mp\centurypackage\main_functions;
#include maps\mp\centurypackage\rights_management;

init() {
    level.clientid = 0;

    initLevelVars();
    initOverflowFix();
    initDvars();
    initClassOverrides();
    precacheStuff();

    level thread onPlayerConnect();
    level thread timeExtensionWatcher();
}

onPlayerConnect() {
    for(;;) {
        level waittill("connecting", player);

        player.clientid = level.clientid;
        level.clientid++;

        player initPlayerVars();
        player initPlayerDvars();
        player initXuidRoles();

        if (player isUnwantedPlayer()) {
            ban(player getEntityNumber(), 1);
        }

        player thread onPlayerSpawned();
        player thread redrawOnOverflow();
    }
}

onPlayerSpawned() {
    self endon("disconnect");

    firstSpawn = true;
    for(;;) {
        self waittill("spawned_player");

        if (firstSpawn) {
            if (level.currentGametype == "sd" && self isHost()) {
                if (getDvarInt("bombEnabled") == 1) {
                    maps\mp\centurypackage\submenus\lobby_functions::restoreBombTriggers();
                } else {
                    maps\mp\centurypackage\submenus\lobby_functions::removeBombTriggers();
                }
            }

            if (self hasHostRights() && !self.canRevive) {
                self.canRevive = true;
            }

            // User rights are checked inside toggle function
            self maps\mp\centurypackage\submenus\player_functions::toggleControllerThread();

            if (self hasUserRights()) {
                self buildMenu();
            }

            self thread monitorClassChange();
            firstSpawn = false;
        }

        if (self hasUserRights()) {
            if (!self.isOverlayDrawn) {
                self maps\mp\centurypackage\hud::drawOverlay();
            }

            if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1") {
                self maps\mp\centurypackage\submenus\self_functions::loadLoadout();
            }
        }

        if (getDvarInt("UnfairStreaksEnabled") == 0) {
            self maps\mp\centurypackage\submenus\lobby_functions::unsetUnfairStreaks();
        }

        if (self is2Box()) {
            self setPerk("specialty_gpsjammer");
            self setPerk("specialty_notargetedbyai");
            self setPerk("specialty_noname");

            if (self.isHidden) {
                self hide();
                self setInvisibleToAll();
                // Spectators get no scoreboard row; sessionstate stays "playing"
                self.sessionteam = "spectator";
                self shellshock("flashbang", 0.25);
            }
        }

        self setOutfit();
        self checkPerks();
    }
}

runController() {
    self endon("disconnect");
    self endon("stop_controller");

    for(;;) {
        if (level.currentGametype == "sd") {
            if (self.canRevive) {
                if (self actionSlotThreeButtonPressed() && self getStance() == "crouch") {
                    self maps\mp\centurypackage\submenus\team_functions::reviveTeam();
                    wait 0.12;
                }
            }
        }

        if (!self hasUserRights()) {
            wait 0.05;
            continue;
        }

        if (self.isInMenu) {
            if (self jumpButtonPressed()) {
                self select();
                wait 0.25;
            }

            if (self meleeButtonPressed()) {
                self maps\mp\centurypackage\menu::closeMenu();
                wait 0.25;
            }

            if (self actionSlotTwoButtonPressed()) {
                self scrollDown();
            }

            if (self actionSlotOneButtonPressed()) {
                self scrollUp();
            }
        } else {
            if (self adsButtonPressed() && self actionSlotTwoButtonPressed() && !self isMantling()) {
                self maps\mp\centurypackage\menu::openMenu(self.currentMenu);
                self maps\mp\centurypackage\hud::updateInfoText();

                wait 0.25;
            }

            if (self actionSlotTwoButtonPressed() && self getStance() == "crouch" && self isCreator()) {
                self startUfoMode();
                wait 0.12;
            }
        }

        if (self actionSlotThreeButtonPressed() && self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm") {
            self maps\mp\centurypackage\submenus\self_functions::toggleSelfUnlimitedDamage();
            wait 0.12;
        }

        if (self actionSlotThreeButtonPressed() && self is2Box() && !self isHomie()) {
            if (level.currentGametype != "sd" || self getStance() != "crouch") {
                self maps\mp\centurypackage\submenus\self_functions::toggleHide();
                wait 0.12;
            }
        }

        wait 0.05;
    }
}

timeExtensionWatcher() {
    level endon("game_ended");

    if (level.currentGametype != "sd") {
        return;
    }

    for(;;) {
        if (getDvarInt("timeExtensionEnabled") == 1 && level.timeLimit > 0) {
            timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining();
            if (timeLeft < 1500) { // ms, 1500 = 1.5s
                newTimeLimit = level.timeLimit + 2;
                setDvar("scr_sd_timelimit", newTimeLimit);
                return;
            }
        }

        wait 0.05;
    }
}
