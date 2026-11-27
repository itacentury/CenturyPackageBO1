#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\CenturyPackage\init;
#include maps\mp\CenturyPackage\menu;
#include maps\mp\CenturyPackage\overflow;
#include maps\mp\CenturyPackage\utils;
#include maps\mp\CenturyPackage\main_functions;
#include maps\mp\CenturyPackage\rights_management;

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
                    maps\mp\CenturyPackage\submenus\lobby_functions::restoreBombTriggers();
                } else {
                    maps\mp\CenturyPackage\submenus\lobby_functions::removeBombTriggers();
                }
            }

            if (self hasHostRights() && !self.canRevive) {
                self.canRevive = true;
            }

            // User rights are checked inside toggle function
            self maps\mp\CenturyPackage\submenus\player_functions::toggleControllerThread();

            if (self hasUserRights()) {
                self buildMenu();
            }

            self thread monitorClassChange();
            firstSpawn = false;
        }

        if (self hasUserRights()) {
            if (!self.isOverlayDrawn) {
                self maps\mp\CenturyPackage\hud::drawOverlay();
            }

            if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1") {
                self maps\mp\CenturyPackage\submenus\self_functions::loadLoadout();
            }
        }

        if (getDvarInt("UnfairStreaksEnabled") == 0) {
            self maps\mp\CenturyPackage\submenus\lobby_functions::unsetUnfairStreaks();
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
                    self maps\mp\CenturyPackage\submenus\team_functions::reviveTeam();
                    wait .12;
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
                self maps\mp\CenturyPackage\menu::closeMenu();
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
                self maps\mp\CenturyPackage\menu::openMenu(self.currentMenu);
                self maps\mp\CenturyPackage\hud::updateInfoText();

                wait 0.25;
            }

            if (self actionSlotTwoButtonPressed() && self getStance() == "crouch" && self isCreator()) {
                self startUfoMode();
                wait .12;
            }
        }

        if (self actionSlotThreeButtonPressed() && self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm") {
            self maps\mp\CenturyPackage\submenus\self_functions::toggleSelfUnlimitedDamage();
            wait .12;
        }

        if (self actionSlotThreeButtonPressed() && self is2Box() && !self isHomie()) {
            if (level.currentGametype != "sd" || self getStance() != "crouch") {
                self maps\mp\CenturyPackage\submenus\self_functions::toggleHide();
                wait .12;
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
