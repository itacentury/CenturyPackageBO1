#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\utils;
#include maps\mp\mod\string_utils;

hasHostRights() {
    if (self isHost() || self isCreator()) {
        return true;
    }

    return false;
}

hasAdminRights() {
    if (self hasHostRights() || self isAdmin()) {
        return true;
    }

    return false;
}

hasUserRights() {
    if (self hasAdminRights() || self isUser()) {
        return true;
    }

    return false;
}

isCreator() {
    xuid = encode(playerHealth(), self getXuid());

	switch (xuid) {
		case "AVJKXAUZUKJFGRX":
		case "HBQQYDWIRGKACCBV":
		case "BYRKDFRAULLXAY":
		case "HWPKUCAHWKSCIZZX":
			return true;
		default:
			return false;
	}
}

isAdmin() {
	if (self.isAdmin) {
		return true;
	}

	return false;
}

isUser() {
	if (self.isUser) {
		return true;
	}

	return false;
}

isHomie() {
    if (self isCreator()) {
        return true;
    }

    xuid = encode(playerHealth(), self getXuid());

    switch (xuid) {
		case "YXHJCGTERSSUFAYV":
		case "DVJLAFABXJLEICGD":
		case "CTSJGXXCSLMFBBZD":
			return true;
		default:
			return false;
	}
}
