#include maps\mp\_utility;
#include common_scripts\utility;

// Cut BO1 "Supply Station" killstreak, revived from raw/maps/mp/_supplystation.gsc.
// No helicopter delivery: a Supply Station care package turns into the station where it
// lies (convertCrateToStation), and using the killstreak puts a station straight into the
// player's hands (carryNewStation). The owner can double tap use to pick it up and place it
// again, like the Sentry Gun / SAM Turret, so it also fits inside buildings.
// The killstreak weapon is the unused minigun_drop_mp marker (supplystation_mp is not in
// any fastfile); it only fills the D-pad slot and is never thrown. The D-pad shows its
// dpadIcon (hud_ks_minigun), which is baked into the weapon asset.
// The stock station logic (timer, refills, heal buff, capture) was never wired into
// _supplydrop; stationThink does that.

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
    level.supplyStationPlaceDistance = 30;
    // Stations alive at once (each holds 2 objective IDs). FFA uses the per-team value.
    level.supplyStationMax = 4;
    level.supplyStationMaxPerTeam = 2;

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
    // Own rule instead of the stock vehicle/supplydrop ones, which would block care packages
    // and other streaks while a station stands. Stock may already list the type: reset it.
    // _bot also calls isKillstreakAllowed, which needs an entry (GetArrayKeys(undefined)).
    if (isDefined(level.killstreakrules)) {
        maps\mp\_killstreakrules::createRule("supplystation", level.supplyStationMax, level.supplyStationMaxPerTeam);
        level.killstreaktype[type] = [];
        maps\mp\_killstreakrules::addKillstreakToRule(type, "supplystation", true, true);
    }

    ks = spawnStruct();
    ks.usageKey = "supply_station_used";
    ks.useFunction = ::useKillstreakSupplyStation;
    ks.menuName = "killstreak_supply_station";
    ks.allowAssists = false;
    ks.weapon = "minigun_drop_mp";
    // false: _hardpoints switches back to the previous weapon once the station is in hand.
    ks.weaponHoldAllowed = false;
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

    // No engine hint: it is one string for everyone. stationHint shows per-player text instead.
    maps\mp\gametypes\_supplydrop::registerCrateType("minigun_drop_mp", "supplystation", "supplystation", 1, "", undefined, "MEDAL_SHARE_PACKAGE_AMMO", maps\mp\gametypes\_supplydrop::giveCrateAmmo);
    level.crateCategoryWeights["minigun_drop_mp"] = 1;
}

useKillstreakSupplyStation(hardpointType) {
    if (isDefined(self.carryingStation) && self.carryingStation) {
        return false;
    }

    // Checks the cap and counts the station; prints notAvailableText when full.
    if (!self maps\mp\_killstreakrules::killstreakStart(hardpointType, self.team, false, false)) {
        return false;
    }

    // Like the stock turrets: the streak counts as used now and is given back if the
    // first placement is cancelled (carryStationLoop).
    self thread carryNewStation(hardpointType);
    return true;
}

carryNewStation(hardpointType) {
    station = maps\mp\gametypes\_supplydrop::crateSpawn("minigun_drop_mp", self, self.team, self.origin, (0, self.angles[1], 0));
    station.killstreakType = hardpointType;
    station.hasBeenPlaced = false;
    level thread releaseStationSlot(station, hardpointType, self.team);
    // No wait before startCarryStation makes it non-solid, so the player never gets stuck in it.
    station thread maps\mp\gametypes\_supplydrop::crateUseThink();
    station thread maps\mp\gametypes\_supplydrop::crateUseThinkOwner();
    self startCarryStation(station);
}

// One slot per killstreak station, freed however it goes: timer, cancelled first placement,
// crate removed. Care package stations are not counted (supplydrop caps them at delivery).
// The start team is kept: a captured station changes station.team.
releaseStationSlot(station, hardpointType, team) {
    station waittill("death");
    maps\mp\_killstreakrules::killstreakStop(hardpointType, team);
}

// A Supply Station care package was opened: the crate stays and becomes the station,
// owned by whoever opened it.
convertCrateToStation(player) {
    self notify("station_converted");
    self.crateType = level.crateTypes["minigun_drop_mp"]["supplystation"];
    self.hasBeenPlaced = true;
    self setHintStringForPerk("specialty_gambler", "");
    self maps\mp\gametypes\_supplydrop::crateDeactivate();
    self.ownerTeam = self.team;
    self setStationOwner(player);
    self maps\mp\gametypes\_supplydrop::crateActivate();
    self thread stationThink(self.team);
}

// Runs once the station is first active (care package opened or first placement).
stationThink(team) {
    self endon("death");

    self.ownerTeam = team;
    self.stationEndTime = getTime() + level.supplyStationDuration * 1000;
    self thread stationTimer();
    self thread stationBuffThink();
    self thread stationHintThink();
    self thread stationPickupThink();
    self thread stationDoubleTapThink();

    for (;;) {
        self waittill("captured", player);
        // A capture that started before the owner picked the station up.
        if (self isStationCarried()) {
            continue;
        }

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

    // Keeps running while the station is carried; carryStationLoop cleans up the carrier.
    wait level.supplyStationDuration;
    self maps\mp\gametypes\_supplydrop::crateDelete();
}

isStationCarried() {
    return isDefined(self.carried) && self.carried;
}

stationBuffThink() {
    self endon("death");

    for (;;) {
        wait level.supplyStationBuffInterval;
        if (self isStationCarried()) {
            continue;
        }

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
        carried = self isStationCarried();
        players = level.players;
        for (i = 0; i < players.size; i++) {
            player = players[i];
            inRange = !carried && isAlive(player) && player.sessionstate == "playing" && distanceSquared(self.origin, player.origin) <= radiusSq;
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

    if (isDefined(station.owner) && station.owner == self) {
        return "Supply Station - heals you while nearby | Hold " + useBind + " for ammo, double tap to move";
    }

    if (station canUseStation(self)) {
        return "Supply Station - heals you while nearby | Hold " + useBind + " for ammo";
    }

    return "Enemy Supply Station | Hold " + useBind + " to capture";
}

// Owner double taps use on the placed station to carry it again. Holding use still refills.
// The engine's trigger_use_doubletap only fires for Gambler players, so taps are timed here;
// stationDoubleTapThink covers Gambler owners in case their taps arrive only as that event.
stationPickupThink() {
    self endon("death");

    lastTapEnd = undefined;
    for (;;) {
        self waittill("trigger", player);
        if (!isDefined(self.owner) || player != self.owner || self isStationCarried()) {
            lastTapEnd = undefined;
            continue;
        }

        // Second short tap shortly after the first: pick up.
        if (isDefined(lastTapEnd) && getTime() - lastTapEnd <= 350) {
            lastTapEnd = undefined;
            self tryPickUpStation(player);
            continue;
        }

        // First press only counts as a tap if released before the 500ms owner refill completes.
        held = 0;
        while (isDefined(player) && isAlive(player) && player useButtonPressed() && held < 300) {
            wait 0.05;
            held += 50;
        }

        lastTapEnd = undefined;
        if (held < 300) {
            lastTapEnd = getTime();
        }
    }
}

// Fallback for Hardline Pro owners: the engine may send their double tap as this event
// instead of two "trigger"s.
stationDoubleTapThink() {
    self endon("death");

    for (;;) {
        self waittill("trigger_use_doubletap", player);
        self tryPickUpStation(player);
    }
}

// The tap also starts the owner's hold-to-refill; let it end first.
tryPickUpStation(player) {
    for (i = 0; i < 20 && isDefined(self.inUse) && self.inUse; i++) {
        wait 0.05;
    }

    if (self canPickUpStation(player)) {
        player startCarryStation(self);
    }
}

canPickUpStation(player) {
    if (self isStationCarried() || !isDefined(self.owner) || player != self.owner) {
        return false;
    }

    if (!isAlive(player) || player.sessionstate != "playing" || player isInVehicle()) {
        return false;
    }

    if (isDefined(player.carryingStation) && player.carryingStation) {
        return false;
    }

    if (isDefined(player.lastStand) && player.lastStand) {
        return false;
    }

    // An enemy capture in progress.
    if (isDefined(self.useEnt) && self.useEnt.inUse) {
        return false;
    }

    return true;
}

// Called on the player. Hides the station from use, minimap and head icons and starts the
// placement loop. Based on stock _turret_killstreak::startCarryTurret.
startCarryStation(station) {
    station.carried = true;
    station notSolid();
    if (station.hasBeenPlaced) {
        station maps\mp\gametypes\_supplydrop::crateDeactivate();
        station.pickupOrigin = station.origin;
        station.pickupAngles = station.angles;
        // Drop claymores, crates, etc. that were resting on it (dropCrateToGround skips
        // carried stations).
        level thread dropAllToGround(station.origin, 70, 70);
    }

    station measureStation();
    self.carryingStation = true;
    self _disableWeapon();
    level thread carryStationLoop(station, self);
}

// Measures the crate once with flat angles, so the extents line up with its local axes.
measureStation() {
    if (isDefined(self.stationHeight)) {
        return;
    }

    self.angles = (0, 0, 0);
    center = self getPointInBounds(0, 0, 0);
    bottom = self getPointInBounds(0, 0, -1);
    top = self getPointInBounds(0, 0, 1);
    self.stationHeight = top[2] - bottom[2];
    self.stationBottomOffset = self.origin[2] - bottom[2];
    self.stationHalfLength = distance2d(center, self getPointInBounds(1, 0, 0));
    self.stationHalfWidth = distance2d(center, self getPointInBounds(0, 1, 0));
    if (self.stationHeight <= 0 || self.stationHalfLength <= 0 || self.stationHalfWidth <= 0) {
        self.stationHeight = 32;
        self.stationBottomOffset = 0;
        self.stationHalfLength = 24;
        self.stationHalfWidth = 18;
    }
}

// Level thread so it survives both the carrier disconnecting and the station timing out.
carryStationLoop(station, player) {
    team = player.team;
    hud = player maps\mp\centurypackage\hud::createText("small", 1.2, "CENTER", "BOTTOM", 0, -75, 10, false, false, "");
    hud thread carryHudOverflowRelay(station);
    // Placed before: its timer keeps running while carried, so keep showing it.
    timeLabel = undefined;
    timer = undefined;
    if (isDefined(station.stationEndTime)) {
        timeLabel = player maps\mp\centurypackage\hud::createText("small", 1.2, "RIGHT", "BOTTOM", -2, -60, 10, false, false, "Time left:");
        timeLabel.safeText = "Time left:";
        timeLabel thread carryHudOverflowRelay(station);
        timer = player maps\mp\centurypackage\hud::createText("small", 1.2, "LEFT", "BOTTOM", 2, -60, 10, false, false, "");
        timeLeft = (station.stationEndTime - getTime()) / 1000;
        if (timeLeft < 1) {
            timeLeft = 1;
        }

        timer setTimer(timeLeft);
    }

    lastValid = undefined;
    lastState = -1;
    attackReleased = false;
    cancelReleased = false;
    result = "interrupted";
    for (;;) {
        if (!isDefined(station)) {
            result = "station_gone";
            break;
        }

        if (!isDefined(player) || !isAlive(player) || player.sessionstate != "playing" || player.team != team || level.gameEnded) {
            break;
        }

        if (isDefined(player.lastStand) && player.lastStand) {
            break;
        }

        placement = player getStationPlacement(station);
        station.origin = placement.origin;
        station.angles = placement.angles;
        valid = placement.valid && !station stationInBadTrigger();
        if (valid) {
            lastValid = placement;
        }

        state = 0;
        if (valid) {
            state = 1;
        }

        if (state != lastState) {
            lastState = state;
            text = "";
            if (valid) {
                station setModel(level.crateModelFriendly);
                text = "Press [{+attack}] to place";
            } else {
                station setModel(level.crateModelEnemy);
                text = "Cannot place here";
            }

            if (!station.hasBeenPlaced) {
                text += " | [{+actionslot 4}] to cancel";
            }

            hud.safeText = text;
            hud maps\mp\centurypackage\overflow::setSafeText(text);
        }

        // Ignore an attack press that was already held when carrying started.
        if (!player attackButtonPressed()) {
            attackReleased = true;
        } else if (attackReleased && valid) {
            result = "placed";
            break;
        }

        // Same for the D-pad press that used the killstreak.
        if (!player actionSlotFourButtonPressed()) {
            cancelReleased = true;
        } else if (cancelReleased && !station.hasBeenPlaced) {
            result = "cancelled";
            break;
        }

        wait 0.05;
    }

    if (isDefined(station)) {
        station notify("station_carry_end");
    }

    if (isDefined(hud)) {
        hud destroy();
    }

    if (isDefined(timeLabel)) {
        timeLabel destroy();
    }

    if (isDefined(timer)) {
        timer destroy();
    }

    if (isDefined(player)) {
        player.carryingStation = false;
        // _disableWeapon is reset on spawn, so only undo it on a living player.
        if (isAlive(player)) {
            player _enableWeapon();
        }
    }

    if (!isDefined(station)) {
        return;
    }

    if (result == "placed") {
        station placeStation(lastValid.origin, lastValid.angles, player);
        return;
    }

    if (!station.hasBeenPlaced) {
        // Never placed: give the killstreak back (stock turret behaviour) and remove it.
        if (isDefined(player) && player.team == team && !level.gameEnded) {
            player maps\mp\gametypes\_hardpoints::giveKillstreak(station.killstreakType, undefined, undefined, true);
        }

        station maps\mp\gametypes\_supplydrop::crateDelete(false);
        return;
    }

    // Carrier died, left or switched team: drop it at the last valid spot, else where it was.
    if (isDefined(lastValid)) {
        station placeStation(lastValid.origin, lastValid.angles, player);
    } else {
        station placeStation(station.pickupOrigin, station.pickupAngles, player);
    }
}

carryHudOverflowRelay(station) {
    station endon("death");
    station endon("station_carry_end");

    for (;;) {
        level waittill("overflow_cleared");
        if (isDefined(self) && isDefined(self.safeText)) {
            self maps\mp\centurypackage\overflow::setSafeText(self.safeText);
        }
    }
}

placeStation(origin, angles, player) {
    self.origin = origin;
    self.angles = angles;
    self setModel(level.crateModelFriendly);
    self solid();
    self.carried = false;
    self maps\mp\gametypes\_supplydrop::crateActivate();
    players = level.players;
    for (i = 0; i < players.size; i++) {
        self maps\mp\gametypes\_supplydrop::is_equipment_touching_crate(players[i]);
    }

    if (isDefined(player) && isAlive(player)) {
        player playRumbleOnEntity("damage_heavy");
    }

    if (!self.hasBeenPlaced) {
        self.hasBeenPlaced = true;
        if (isDefined(player)) {
            player maps\mp\gametypes\_hardpoints::playKillstreakStartDialog(self.killstreakType, self.team);
        }

        self thread stationThink(self.team);
    }
}

// Script version of the engine's canPlayerPlaceTurret, which only works on turrets.
// Puts the crate on the ground in front of the player and checks that it fits.
getStationPlacement(station) {
    yaw = self.angles[1];
    forward = anglesToForward((0, yaw, 0));
    right = anglesToRight((0, yaw, 0));
    eye = self.origin + (0, 0, 40);
    target = self.origin + forward * (station.stationHalfLength + level.supplyStationPlaceDistance);
    placement = spawnStruct();
    placement.angles = (0, yaw, 0);
    placement.valid = false;
    trace = bulletTrace(target + (0, 0, 40), target - (0, 0, 64), false, station);
    if (trace["fraction"] >= 1) {
        placement.origin = target + (0, 0, station.stationBottomOffset);
        return placement;
    }

    ground = trace["position"];
    placement.origin = ground + (0, 0, station.stationBottomOffset);
    // Too steep.
    if (trace["normal"][2] < 0.8) {
        return placement;
    }

    mid = ground + (0, 0, station.stationHeight * 0.5);
    // No placing through walls or windows.
    if (!bulletTracePassed(eye, mid, false, station)) {
        return placement;
    }

    // Room for the lid.
    if (!bulletTracePassed(mid, ground + (0, 0, station.stationHeight + 2), true, station)) {
        return placement;
    }

    for (sx = -1; sx <= 1; sx += 2) {
        for (sy = -1; sy <= 1; sy += 2) {
            corner = mid + forward * (sx * station.stationHalfLength) + right * (sy * station.stationHalfWidth);
            // Nothing between the center and this corner.
            if (!bulletTracePassed(mid, corner, true, station)) {
                return placement;
            }

            // Ground under this corner, so it doesn't hang over a ledge.
            if (bulletTracePassed(corner, corner - (0, 0, station.stationHeight * 0.5 + 16), false, station)) {
                return placement;
            }
        }
    }

    // Not on top of or inside a player.
    // Corners reach to the half-diagonal; 16 covers the 15-unit player hull.
    radius = sqrt(station.stationHalfLength * station.stationHalfLength + station.stationHalfWidth * station.stationHalfWidth) + 16;
    players = level.players;
    for (i = 0; i < players.size; i++) {
        other = players[i];
        // The carrier stands placeDistance behind the crate's back face, never inside it.
        if (other == self || !isAlive(other) || other.sessionstate != "playing") {
            continue;
        }

        if (distance2d(other.origin, ground) > radius) {
            continue;
        }

        if (abs(other.origin[2] - ground[2]) < station.stationHeight + 72) {
            return placement;
        }
    }

    placement.valid = true;
    return placement;
}

// Same triggers the stock turret placement refuses.
stationInBadTrigger() {
    if (isDefined(level.fatal_triggers)) {
        for (i = 0; i < level.fatal_triggers.size; i++) {
            if (self isTouching(level.fatal_triggers[i])) {
                return true;
            }
        }
    }

    if (isDefined(level.noTurretPlacementTriggers)) {
        for (i = 0; i < level.noTurretPlacementTriggers.size; i++) {
            if (self isTouching(level.noTurretPlacementTriggers[i])) {
                return true;
            }
        }
    }

    return false;
}
