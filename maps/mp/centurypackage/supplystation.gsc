#include maps\mp\_utility;
#include common_scripts\utility;

// Cut BO1 "Supply Station" killstreak, revived from raw/maps/mp/_supplystation.gsc.
// Its marker weapon (supplystation_mp) is not in any fastfile, so the unused
// minigun_drop_mp marker stands in. The D-pad shows the marker's dpadIcon
// (hud_ks_minigun); it is baked into the weapon asset and cannot be changed
// from GSC. The stock station logic (timer, refills,
// heal buff, capture) was never wired into _supplydrop; stationThink does that.
// The crate itself is delivered by the normal care package path in _supplydrop.

// Must run synchronously from _clientids::init (precache window).
init() {
    precacheItem("minigun_drop_mp");

    // Friendly minimap icon (red cross); read by _supplydrop::crateActivate.
    level.supplyStationCompassIcon = "hint_health";
    precacheShader(level.supplyStationCompassIcon);

    level.supplyStationDuration = 60;
    level.supplyStationBuffInterval = 2;
    level.supplyStationBuffRadius = 175;
    level.supplyStationHealthBuff = 0.25;

    level thread registerSupplyStation();
}

// _clientids::init runs before _hardpoints::init and _supplydrop::init, which reset
// level.killstreaks and level.crateTypes. Register by hand after both.
registerSupplyStation() {
    waittillframeend;
    if (!isDefined(level.killstreaks) || !isDefined(level.crateTypes)) {
        return;
    }

    type = "supply_station_mp";
    // Stock _killstreakrules lists supply_station_mp, but don't rely on the shipped script:
    // without an entry isKillstreakAllowed does GetArrayKeys(undefined).
    if (isDefined(level.killstreakrules) && !isDefined(level.killstreaktype[type])) {
        maps\mp\_killstreakrules::addKillstreakToRule(type, "vehicle", true, true);
        maps\mp\_killstreakrules::addKillstreakToRule(type, "supplydrop", true, true);
        maps\mp\_killstreakrules::addKillstreakToRule(type, "targetableent", true, true);
    }

    ks = spawnStruct();
    ks.usageKey = "supply_station_used";
    ks.useFunction = ::useKillstreakSupplyStation;
    ks.menuName = "killstreak_supply_station";
    ks.allowAssists = false;
    ks.weapon = "minigun_drop_mp";
    ks.weaponHoldAllowed = true;
    ks.notAvailableText = &"KILLSTREAK_AIRSPACE_FULL";
    ks.informDialog = "mpl_killstreak_supply";
    // Read by utils::giveKillstreakWithPopup (no killstreakTable row for the stock popup).
    ks.earnedTitle = "Supply Station";
    ks.earnedIcon = level.supplyStationCompassIcon;
    level.killstreaks[type] = ks;
    level.killstreakWeapons["minigun_drop_mp"] = type;
    level.menuReferenceForKillStreak[ks.menuName] = type;

    game["dialog"][type + "_start"] = "kls_supply_used";
    game["dialog"][type + "_end"] = "";
    game["dialog"][type + "_enemy_start"] = "kls_supply_enemy";
    game["dialog"][type + "_enemy_end"] = "";
    game["dialog"][type] = "kls_supply_ready";

    maps\mp\gametypes\_supplydrop::registerCrateType("minigun_drop_mp", "supplystation", "supplystation", 1, &"KILLSTREAK_AMMO_CRATE", undefined, "MEDAL_SHARE_PACKAGE_AMMO", maps\mp\gametypes\_supplydrop::giveCrateAmmo);
    level.crateCategoryWeights["minigun_drop_mp"] = 1;
}

useKillstreakSupplyStation(hardpointType) {
    if (self maps\mp\gametypes\_supplydrop::isSupplyDropGrenadeAllowed(hardpointType, "minigun_drop_mp") == false) {
        return false;
    }

    self thread maps\mp\gametypes\_supplydrop::refCountDecChopperOnDisconnect(self.team);
    result = self maps\mp\gametypes\_supplydrop::useSupplyDropMarker();
    self notify("supply_drop_marker_done");
    if (!isDefined(result) || !result) {
        return false;
    }

    return result;
}

// Runs on the landed crate instead of the one-shot care package loop.
stationThink(owner, team) {
    self endon("death");

    self.ownerTeam = team;
    self.stationEndTime = getTime() + level.supplyStationDuration * 1000;
    self thread stationTimer();
    self thread stationBuffThink();
    self thread stationHintThink();

    for (;;) {
        self waittill("captured", player);
        if (self canUseStation(player)) {
            // Stock refill: skips killstreak weapons and caps lethals/tacticals.
            player maps\mp\gametypes\_supplydrop::giveCrateAmmo();
        } else {
            self setStationOwner(player);
        }
    }
}

stationTimer() {
    self endon("death");

    wait level.supplyStationDuration;
    self maps\mp\gametypes\_supplydrop::crateDelete();
}

stationBuffThink() {
    self endon("death");

    for (;;) {
        wait level.supplyStationBuffInterval;
        players = level.players;
        for (i = 0; i < players.size; i++) {
            player = players[i];
            if (!isAlive(player) || player.sessionstate != "playing") {
                continue;
            }

            if (!self canUseStation(player)) {
                continue;
            }

            if (distanceSquared(self.origin, player.origin) > level.supplyStationBuffRadius * level.supplyStationBuffRadius) {
                continue;
            }

            if (player.health < player.maxhealth) {
                player.health += int(player.maxhealth * level.supplyStationHealthBuff);
                if (player.health > player.maxhealth) {
                    player.health = player.maxhealth;
                }
            }
        }
    }
}

canUseStation(player) {
    if (level.teambased) {
        return player.team == self.ownerTeam;
    }

    return isDefined(self.owner) && player == self.owner;
}

setStationOwner(player) {
    oldOwner = self.owner;
    self.owner = player;
    self setOwner(player);
    // Retarget the team-change watcher; the old one still waits on oldOwner.
    self notify("owner_changed");
    self thread maps\mp\gametypes\_supplydrop::ownerTeamChangeWatcher();
    if (self.ownerTeam != player.team) {
        self.ownerTeam = player.team;
        self.team = player.team;
        self setTeam(player.team);
    }

    if (level.teambased) {
        if (isDefined(self.friendlyObjID)) {
            objective_team(self.friendlyObjID, self.ownerTeam);
        }

        if (isDefined(self.enemyObjID)) {
            objective_team(self.enemyObjID, level.otherTeam[self.ownerTeam]);
        }
    } else {
        // FFA: crateActivate set per-player visibility for the original owner.
        if (isDefined(self.friendlyObjID)) {
            if (isDefined(oldOwner)) {
                Objective_SetInvisibleToPlayer(self.friendlyObjID, oldOwner);
            }

            Objective_SetVisibleToPlayer(self.friendlyObjID, player);
        }

        if (isDefined(self.enemyObjID)) {
            if (isDefined(oldOwner)) {
                Objective_SetVisibleToPlayer(self.enemyObjID, oldOwner);
            }

            Objective_SetInvisibleToPlayer(self.enemyObjID, player);
        }
    }

    // Rebuild the red cross head icon for the new team (team modes) or new owner (FFA).
    self maps\mp\_entityheadicons::setEntityHeadIcon(self.team, self, level.crate_headicon_offset, level.supplyStationCompassIcon, true);

    // Hints in range switch between the friendly and enemy text.
    self notify("station_owner_changed");
}

// Shows a short explanation to every living player inside the buff radius.
stationHintThink() {
    self endon("death");

    radiusSq = level.supplyStationBuffRadius * level.supplyStationBuffRadius;
    for (;;) {
        players = level.players;
        for (i = 0; i < players.size; i++) {
            player = players[i];
            inRange = isAlive(player) && player.sessionstate == "playing" && distanceSquared(self.origin, player.origin) <= radiusSq;
            hasHint = isDefined(player.stationHintStation) && player.stationHintStation == self;
            if (inRange && !isDefined(player.stationHintStation)) {
                player.stationHintStation = self;
                player thread stationHint(self);
            } else if (!inRange && hasHint) {
                player notify("station_hint_end");
            }
        }

        wait 0.25;
    }
}

stationHint(station) {
    self endon("disconnect");

    info = self maps\mp\centurypackage\hud::createText("small", 1.2, "CENTER", "BOTTOM", 0, -75, 10, false, false, self getStationHintText(station));
    timeLabel = self maps\mp\centurypackage\hud::createText("small", 1.2, "RIGHT", "BOTTOM", -2, -60, 10, false, false, "Time left:");
    timer = self maps\mp\centurypackage\hud::createText("small", 1.2, "LEFT", "BOTTOM", 2, -60, 10, false, false, "");
    timeLeft = (station.stationEndTime - getTime()) / 1000;
    if (timeLeft < 1) {
        timeLeft = 1;
    }

    timer setTimer(timeLeft);
    self thread stationHintEndOnDeath(station);
    self thread stationHintOwnerRelay(station);
    self thread stationHintOverflowRelay(station);
    for (;;) {
        event = self waittill_any_return("station_hint_end", "station_hint_refresh", "death");
        if (event != "station_hint_refresh" || !isDefined(station)) {
            break;
        }

        info maps\mp\centurypackage\overflow::setSafeText(self getStationHintText(station));
        timeLabel maps\mp\centurypackage\overflow::setSafeText("Time left:");
    }

    self notify("station_hint_destroyed");
    info destroy();
    timeLabel destroy();
    timer destroy();
    self.stationHintStation = undefined;
}

// Closes the hint when the station times out or is destroyed.
stationHintEndOnDeath(station) {
    self endon("disconnect");
    self endon("station_hint_destroyed");

    station waittill("death");
    self notify("station_hint_end");
}

// Swap between friendly and enemy text when the station is captured.
stationHintOwnerRelay(station) {
    self endon("disconnect");
    self endon("station_hint_destroyed");
    station endon("death");

    for (;;) {
        station waittill("station_owner_changed");
        self notify("station_hint_refresh");
    }
}

// Redraw after the overflow fix wiped all script strings.
stationHintOverflowRelay(station) {
    self endon("disconnect");
    self endon("station_hint_destroyed");
    station endon("death");

    for (;;) {
        level waittill("overflow_cleared");
        self notify("station_hint_refresh");
    }
}

getStationHintText(station) {
    useBind = "[{+activate}]";
    if (level.console) {
        useBind = "[{+usereload}]";
    }

    if (station canUseStation(self)) {
        return "Supply Station - heals you while nearby";
    }

    return "Enemy Supply Station | Hold " + useBind + " to capture";
}
