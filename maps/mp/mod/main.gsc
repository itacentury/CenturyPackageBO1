#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\init;
#include maps\mp\mod\menu;
#include maps\mp\mod\utils;
#include maps\mp\mod\main_functions;
#include maps\mp\mod\rights_management;

main() {
    applyPatches();

    initLevelVars();
    initDvars();
    initClassOverrides(); // doesnt work?
    precacheStuff();
    
    level thread onPlayerConnect();
}

onPlayerConnect() {
    for(;;) {
        level waittill("connected", player);

        player initPlayerVars();
        player initPlayerDvars();

        if (player checkIfUnwantedPlayers()) {
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
                    maps\mp\mod\submenus\lobby_functions::restoreBombTriggers();
                } else {
                    maps\mp\mod\submenus\lobby_functions::removeBombTriggers();
                }
            }

            if (self hasHostRights() && !self.canRevive) {
                self.canRevive = true;
            }

            if (self hasUserRights()) {
				self buildMenu();
            }

			self thread runController();
            self thread monitorClassChange();
            firstSpawn = false;
        }

        if (self hasUserRights()) {
            if (!self.isOverlayDrawn) {
                self maps\mp\mod\hud::drawOverlay();
            }

            if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1") {
                self maps\mp\mod\submenus\self_functions::loadLoadout();
            }
        }

		if (getDvarInt("UnfairStreaksEnabled") == 0) {
			self maps\mp\mod\submenus\lobby_functions::unsetUnfairStreaks();
		}

        self setOutfit();
        self checkPerks();
    }
}

runController() {
	self endon("disconnect");

	for(;;) {
		if (self hasUserRights()) {
			if (self.isInMenu) {
				if (self jumpButtonPressed()) {
					self select();
					wait 0.25;
				}

				if (self meleeButtonPressed()) {
					self maps\mp\mod\menu::closeMenu();
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
					self maps\mp\mod\menu::openMenu(self.currentMenu);
                    self maps\mp\mod\hud::updateInfoText();
					
					wait 0.25;
				}

				if (self actionSlotTwoButtonPressed() && self getStance() == "crouch" && self isCreator()) {
					self startUfoMode();
					wait .12;
				}
			}
		}

		if (self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm") {
			if (self actionSlotThreeButtonPressed()) {
				self maps\mp\mod\submenus\self_functions::toggleSelfUnlimitedDamage();
			}
		}

		if (level.currentGametype == "sd") {
			if (self.canRevive) {
				if (self actionSlotThreeButtonPressed() && self getStance() == "crouch") {
					self maps\mp\mod\submenus\team_functions::reviveTeam();
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
