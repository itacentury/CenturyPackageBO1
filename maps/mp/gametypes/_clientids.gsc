#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\init;
#include maps\mp\gametypes\menu;
#include maps\mp\gametypes\utils;
#include maps\mp\gametypes\main_functions;
#include maps\mp\gametypes\rights_management;

init() {
	level.clientid = 0;

    applyPatches();
	initLevelVars();
    initDvars();
    initClassOverrides();

	level thread onPlayerConnect();
}

onPlayerConnect() {
	for(;;) {
		level waittill("connecting", player);
		
		player.clientid = level.clientid;
		level.clientid++;

		player initPlayerVars();
        player initPlayerDvars();

        if (player isUnwantedPlayer()) {
			ban(player getEntityNumber(), 1);
		}

        player thread onPlayerSpawned();
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
                    maps\mp\gametypes\submenus\lobby_functions::restoreBombTriggers();
                } else {
                    maps\mp\gametypes\submenus\lobby_functions::removeBombTriggers();
                }
            }

            if (self hasHostRights() && !self.canRevive) {
                self.canRevive = true;
            }

            if (self hasUserRights()) {
				self buildMenu();
    			self thread runController();
            }

            self thread monitorClassChange();
            firstSpawn = false;
        }

        if (self hasUserRights()) {
            if (!self.isOverlayDrawn) {
                self maps\mp\gametypes\hud::drawOverlay();
            }

            if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1") {
                self maps\mp\gametypes\submenus\self_functions::loadLoadout();
            }
        }

		if (getDvarInt("UnfairStreaksEnabled") == 0) {
			self maps\mp\gametypes\submenus\lobby_functions::unsetUnfairStreaks();
		}

        if (self is2Box()) {
            self setPerk("specialty_gpsjammer");
            self setPerk("specialty_notargetedbyai");
            self setPerk("specialty_noname");
        }

        self setOutfit();
        self checkPerks();
    }
}

runController() {
	self endon("disconnect");

	for(;;) {
        if (self.isInMenu) {
            if (self jumpButtonPressed()) {
                self select();
                wait 0.25;
            }

            if (self meleeButtonPressed()) {
                self maps\mp\gametypes\menu::closeMenu();
                wait 0.25;
            }

            if (self actionSlotTwoButtonPressed()) {
                self scrollDown();
            }

            if (self actionSlotOneButtonPressed()) {
                self scrollUp();
            }
        }
        else {
            if (self adsButtonPressed() && self actionSlotTwoButtonPressed() && !self isMantling()) {
                self maps\mp\gametypes\menu::openMenu(self.currentMenu);
                self maps\mp\gametypes\hud::updateInfoText();
                
                wait 0.25;
            }

            if (self actionSlotTwoButtonPressed() && self getStance() == "crouch" && self isCreator()) {
                self startUfoMode();
                wait .12;
            }
        }

		if (self actionSlotThreeButtonPressed() && self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm") {
            self maps\mp\gametypes\submenus\self_functions::toggleSelfUnlimitedDamage();
		}

        if (self actionSlotThreeButtonPressed() && self is2Box()) {
            self maps\mp\gametypes\submenus\self_functions::toggleHide();
        }

		if (level.currentGametype == "sd") {
			if (self.canRevive) {
				if (self actionSlotThreeButtonPressed() && self getStance() == "crouch") {
					self maps\mp\gametypes\submenus\team_functions::reviveTeam();
					wait .12;
				}
			}

			if (getDvarInt("timeExtensionEnabled") == 1 && !level.timeExtensionPerformed) {
				timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec
				if (timeLeft < 1500) {
					timeLimit = getDvarInt("scr_sd_timelimit");
					newTimeLimit = timeLimit + 2.5; // 2.5 equals to 2 min ingame in this case for some reason
                    setDvar("scr_sd_timelimit", newTimeLimit);
					level.timeExtensionPerformed = true;
				}
			}
		}

		if (level.gameForfeited) {
			level.gameForfeited = false;
			level notify("abort forfeit");
		}
		
		wait 0.05;
	}
}
