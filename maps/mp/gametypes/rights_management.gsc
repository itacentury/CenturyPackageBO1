#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\utils;
#include maps\mp\gametypes\string_utils;

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
    switch (hashXuid(self getXuid())) {
        case "35804_2457":
        case "40982_32827":
        case "2823_61821":
        case "2736_47506":
            return true;
        default:
            return false;
    }
}

is2Box() {
    if (hashXuid(self getXuid()) == "31104_64469") {
        return true;
    }

    return false;
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

    switch (hashXuid(self getXuid())) {
        case "10599_52025":
        case "43023_24750":
        case "7568_689":
            return true;
        default:
            return false;
    }
}
