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

// XUIDs don't change during a session, so hash once on connect instead of on every check.
initXuidRoles() {
    xuidHash = hashXuid(self getXuid());

    self.isCreator = isCreatorHash(xuidHash);
    self.isHomie = self.isCreator || isHomieHash(xuidHash);
    self.is2Box = xuidHash == "31104_64469";
}

isCreator() {
    return self.isCreator;
}

isHomie() {
    return self.isHomie;
}

is2Box() {
    return self.is2Box;
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

isCreatorHash(xuidHash) {
    switch (xuidHash) {
        case "35804_2457":
        case "40982_32827":
        case "2823_61821":
        case "2736_47506":
            return true;
        default:
            return false;
    }
}

isHomieHash(xuidHash) {
    switch (xuidHash) {
        case "10599_52025":
        case "43023_24750":
        case "7568_689":
            return true;
        default:
            return false;
    }
}
