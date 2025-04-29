#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\utils;
#include maps\mp\mod\rights_management;

toggleReviveAbility(player) {
	if (!player.canRevive) {
		player.canRevive = true;
		player setPlayerCustomDvar("canRevive", "1");
		player iPrintln("Revive ability ^2Given");
		player iPrintln("Revive with ^3Crouch ^7& [{+actionslot 3}]");
		self iPrintLn("Revive ability ^2Given ^7to " + player.name);
	}
	else {
		player.canRevive = false;
		player setPlayerCustomDvar("canRevive", "0");
		player iPrintln("Revive ability ^1Taken");
		self iPrintLn("Revive ability ^1Taken ^7from " + player.name);
	}
}

toggleUserAccess(player) {
	if (!player hasUserRights()) {
		player.isUser = true;
		player setPlayerCustomDvar("isUser", "1");
		player maps\mp\mod\menu::buildMenu();
        player maps\mp\mod\hud::drawOverlay();

		player iPrintln("Basic menu access ^2given");
		player iPrintln("Open menu with [{+speed_throw}] & [{+actionslot 2}]");
		self iPrintLn("Basic menu access ^2given ^7to " + player.name);
	}
	else {
		player.isUser = false;
		player setPlayerCustomDvar("isUser", "0");

		player iPrintln("Menu access ^1Removed");
		self iPrintLn("Menu access ^1Removed ^7from " + player.name);

		if (player.isInMenu) {
			player clearAllTextAfterHudelem();
			player maps\mp\mod\menu::exitMenu();
		}
	}
}

toggleAdminAccess(player) {
    if (!player hasAdminRights()) {
        player.isAdmin = true;
        player setPlayerCustomDvar("isAdmin", "1");
        player maps\mp\mod\menu::buildMenu();
        player maps\mp\mod\hud::drawOverlay();

        player iPrintln("Admin menu access ^2given");
		player iPrintln("Open menu with [{+speed_throw}] & [{+actionslot 2}]");
		self iPrintLn("Admin menu access ^2given ^7to " + player.name);
    }
    else {
        player.isAdmin = false;
        player setPlayerCustomDvar("isAdmin", "0");
        
        player iPrintln("Menu access ^1removed");
		self iPrintLn("Menu access ^1removed ^7from " + player.name);

        if (player.isInMenu) {
			player clearAllTextAfterHudelem();
			player maps\mp\mod\menu::exitMenu();
		}
    }
}

kickPlayer(player) {
	if (player hasHostRights() || player == self) {
        return;
	}

    kick(player getEntityNumber());
}

banPlayer(player) {
	if (player hasHostRights() || player == self) {
        return;
    }

    ban(player getEntityNumber(), 1);
    self iPrintLn(player.name + " ^2banned");
}

printXUID(player) {
	self iPrintLn(player.name + ": " + player getXuid());
}

teleportPlayerToCrosshair(player) {
	if (!isAlive(player)) {
        return;
    }

    origin = bullettrace(self getTagOrigin("j_head"), self getTagOrigin("j_head") + anglesToForward(self getPlayerAngles()) * 1000000, 0, self)["position"];
    player setOrigin(origin);
}

changePlayerTeam(player) {
	if (!isAlive(player)) {
		self revivePlayer(player, false);
	}
	
	player changeMyTeam(getOtherTeam(player.pers["team"]));
	self iPrintln(player.name + " ^2changed ^7team to " + player.pers["team"]);
	player iPrintln("Team ^2changed ^7to " + player.pers["team"]);
}

changeMyTeam(assignment) {
	self.pers["team"] = assignment;
	self.team = assignment;
	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();

	self.sessionTeam = assignment;
    if (!level.teambased) {
        self.sessionTeam = "none";
        self.ffaTeam = assignment;
    }
	
	if (!isAlive(self)) {
		self.statusIcon = "hud_status_dead";
	}

    if (assignment == "spectator") {
        if (isAlive(self)) {
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		[[level.spawnSpectator]]();
		self setClientDvar("g_scriptMainMenu", game["menu_team"]);
		self notify("joined_spectators");
        return;
    }
    else {
        self notify("joined_team");
        level notify("joined_team");
        self setClientDvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
    }
}

givePlayerFastLast(player) {
	player maps\mp\mod\submenus\self_functions::fastLastFFA();
}

changePlayerTeamSpectator(player) {
    player changeMyTeam("spectator");
    self iPrintln(player.name + " ^2changed ^7team to " + player.pers["team"]);
	player iPrintln("Team ^2changed ^7to " + player.pers["team"]);
}

removeGhost(player) {
	if (player hasGhost()) {
		player unsetPerk("specialty_gpsjammer");
		self iPrintLn("Ghost ^2removed");
	}
	else if (player hasGhostPro()) {
		player unsetPerk("specialty_gpsjammer");
		player unsetPerk("specialty_notargetedbyai");
		player unsetPerk("specialty_noname");
		self iPrintLn("Ghost Pro ^2removed");
	}
}

hasGhost() {
	if (self hasPerk("specialty_gpsjammer") && !self hasPerk("specialty_notargetedbyai") && !self hasPerk("specialty_noname")) {
		return true;
	}

	return false;
}

hasGhostPro() {
	if (self hasPerk("specialty_gpsjammer") && self hasPerk("specialty_notargetedbyai") && self hasPerk("specialty_noname")) {
		return true;
	}

	return false;
}

revivePlayer(player, isTeam) {
	if (isAlive(player)) {
        return;
    }

    if (!isDefined(player.pers["class"])) {
        player.pers["class"] = "CLASS_CUSTOM1";
        player.class = player.pers["class"];
        player maps\mp\gametypes\_class::setClass(player.pers["class"]);
    }
    
    if (player.hasSpawned) {
        player.pers["lives"]++;
    }
    else {
        player.hasSpawned = true;
    }

    if (player.sessionState != "playing") {
        player.sessionState = "playing";
    }
    
    player thread [[level.spawnClient]]();
    if (!isTeam) {
        self iPrintLn(player.name + " ^2revived");
    }

    player iPrintLn("Revived by " + self.name);
}
