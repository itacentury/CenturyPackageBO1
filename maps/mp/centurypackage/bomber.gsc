#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\_airsupport;

// Cut BO1 "Bomber" killstreak, revived from raw/maps/mp/_bomber.gsc.
// The stock script is not in any fastfile and its init() is never called,
// so this is a trimmed copy that only uses assets the game still ships:
// bomber_mp, mk82_mp, t5_veh_jet_f4_gearup, ac130_overlay_*, map_mortar_selector.
// Unlike the stock prototype, the player is not linked into the jet: the jets fly
// far outside the world and the engine kills players out there (MOD_SUICIDE).
// The player stays frozen on the ground and only a script camera rides along
// behind the jet, pitched onto the point where its bombs would land.
// No unknown stat writes either.

// Must run synchronously from _clientids::init (precache window).
init() {
    precacheItem("bomber_mp");
    precacheItem("mk82_mp");
    precacheModel("t5_veh_jet_f4_gearup");
    precacheModel("tag_origin");
    precacheShader("ac130_overlay_grain");
    precacheShader("ac130_overlay_105mm");
    precacheShader("waypoint_target");
    precacheLocationSelector("map_mortar_selector");
    precacheString(&"KILLSTREAK_AIRSTRIKE_NOT_AVAILABLE");

    level.bomberPlaneModel = "t5_veh_jet_f4_gearup";
    level.bomberPlaneCount = 3; // callStrike always sends three jets
    level.bomberMarkerShader = "waypoint_target";
    level.bomberDangerMaxRadius = 750;
    level.bomberLookDistance = 5000;

    level thread registerBomber();
}

// _clientids::init runs before _hardpoints::init, which resets level.killstreaks.
// Register by hand after it (registerKillstreak would precache outside the window).
registerBomber() {
    waittillframeend;
    if (!isDefined(level.killstreaks)) {
        return;
    }

    type = "bomber_mp";
    ks = spawnStruct();
    ks.usageKey = "bomber_used";
    ks.useFunction = ::useKillstreakBomber;
    ks.menuName = "killstreak_bomber";
    ks.delayStreak = true;
    ks.allowAssists = false;
    ks.weapon = "bomber_mp";
    ks.weaponHoldAllowed = false;
    ks.notAvailableText = &"KILLSTREAK_AIRSTRIKE_NOT_AVAILABLE";
    ks.informDialog = "mpl_killstreak_air";
    level.killstreaks[type] = ks;
    level.killstreakWeapons["bomber_mp"] = type;
    level.menuReferenceForKillStreak[ks.menuName] = type;

    game["dialog"][type + "_start"] = "kls_airstrike_used";
    game["dialog"][type + "_end"] = "";
    game["dialog"][type + "_enemy_start"] = "kls_airstrike_enemy";
    game["dialog"][type + "_enemy_end"] = "";
    game["dialog"][type] = "kls_airstrike_ready";
}

useKillstreakBomber(hardpointType) {
    if (isDefined(level.airSupportInProgress)) {
        self iPrintLnBold(level.killstreaks[hardpointType].notAvailableText);
        return false;
    }

    result = self selectBomberLocation();
    if (!isDefined(result) || !result) {
        return false;
    }

    return true;
}

selectBomberLocation() {
    self beginLocationSelection("map_mortar_selector", level.bomberDangerMaxRadius * 1.2);
    self.selectingLocation = true;
    self thread endSelectionThink();
    self waittill("confirm_location", location);
    if (!isDefined(location)) {
        return false;
    }

    if (isDefined(level.airSupportInProgress)) {
        self iPrintLnBold(level.killstreaks["bomber_mp"].notAvailableText);
        return false;
    }

    self thread finishHardpointLocationUsage(location, ::useBomber);
    return true;
}

useBomber(pos) {
    level.airSupportInProgress = true;
    level.bomberPlanes = [];
    // No walking around until the first jet (and the camera) arrives.
    self freezeControls(true);
    level thread doBomber(pos, self, self.team);
}

doBomber(origin, owner, team) {
    targetPoint = determineTargetPoint(owner, origin);
    owner maps\mp\gametypes\_hardpoints::playKillstreakStartDialog("bomber_mp", team);
    owner notify("begin_bomber");

    if (!isDefined(level.bomberFlightPlan)) {
        level.bomberFlightPlan = spawnStruct();
    }

    level.bomberFlightPlan.distance = 48000;
    level.bomberFlightPlan.height = 4000;
    level.bomberFlightPlan.speed = 2000;
    level.bomberFlightPlan.bombSpeedScale = 1;
    level.bomberFlightPlan.target = targetPoint;
    level.bomberFlightPlan.owner = owner;
    level.bomberFlightPlan.yaw = "random";
    level.bomberFlightPlan.planeSpawnCallback = ::planeSpawnedCallback;
    level.bomberFlightPlan.planeSpacing = calculateFallTime(level.bomberFlightPlan.height) + 1;

    callStrike(level.bomberFlightPlan);

    wait 8.5;
    level.airSupportInProgress = undefined;
}

planeSpawnedCallback(owner, requiredDeathCount, pathStart, pathEnd, bombTime, bombSpeedScale, flyTime, flyspeed) {
    self setModel(level.bomberPlaneModel);
    if (level.bomberPlanes.size == 0 && isDefined(owner) && isAlive(owner)) {
        self thread bomberAttachPlayer(owner);
    }

    level.bomberPlanes[level.bomberPlanes.size] = self;
    level notify("bomber_plane_spawned");
    self thread bombDropWaiter(owner);
    if (isDefined(owner)) {
        self thread bomberDetachOnPlaneDelete(owner);
    }
}

bombDropWaiter(owner) {
    owner endon("disconnect");
    owner endon("death");
    owner endon("bombing_done");

    while (!isDefined(owner.currentPlane) || self != owner.currentPlane || !owner attackButtonPressed()) {
        wait 0.05;
    }

    self.bomberDropped = true;
    owner notify("bomber_hint_refresh");
    self thread bombsAway(owner);

    while (owner attackButtonPressed()) {
        wait 0.05;
    }

    plane = getNextAvailablePlane(self);
    if (!isDefined(plane) && level.bomberPlanes.size < level.bomberPlaneCount) {
        // Dropped before all jets arrived: wait for the next one.
        level waittill("bomber_plane_spawned");
        plane = getNextAvailablePlane(self);
    }

    if (isDefined(plane)) {
        plane attachToPlane(owner);
    } else {
        wait 2;
        owner notify("bombing_done");
    }
}

bombsAway(owner) {
    owner endon("disconnect");
    for (i = 0; i < 10; i++) {
        velocity = vector_scale(anglesToForward(self.angles), level.bomberFlightPlan.speed * level.bomberFlightPlan.bombSpeedScale);
        offset = (randomFloatRange(-50, 50), randomFloatRange(-50, 50), randomFloatRange(-50, 50));
        velOffset = (randomFloatRange(-10, 10), 10, 0);
        owner launchBomb("mk82_mp", self.origin + offset, velocity + velOffset);
        wait randomFloatRange(0.05, 0.2);
    }
}

bomberAttachPlayer(player) {
    player endon("disconnect");
    player endon("death");

    player setClientDvar("cg_fov", 30);
    player thread bomberOverlay();
    player freezeControls(true);

    // The camera ignores its entity's angles, so it gets an explicit look-at
    // target, kept on the jet's bomb impact point by bomberCameraThink.
    cam = spawn("script_model", self.origin);
    cam setModel("tag_origin");
    look = spawn("script_model", self.origin);
    look setModel("tag_origin");
    player.bomberCam = cam;
    player.bomberLook = look;
    player.bomberStartAngles = player getPlayerAngles();
    self attachToPlane(player);
    player cameraSetPosition(cam);
    player cameraSetLookAt(look);
    player cameraActivate(true);
    player thread bomberCameraThink();
    player thread bomberImpactMarker();

    player thread bomberHint();
    player thread changePlanes();
    player thread bomberDetachOnDone(cam, look);
    player thread bomberDetachOnFrag();
}

attachToPlane(player) {
    bombX = getBombForwardDistance();
    playerOffset = (-1000, 0, -100);
    if (playerOffset[0] > bombX) {
        playerOffset = (bombX, playerOffset[1], playerOffset[2]);
    }

    angles = (atan((level.bomberFlightPlan.height + playerOffset[2]) / (bombX - playerOffset[0])), 0, 0);
    player.bomberCam unlink();
    player.bomberCam.origin = self.origin;
    player.bomberCam linkTo(self, "tag_origin", playerOffset, angles);

    player.bomberBasePitch = angles[0];
    player.currentPlane = self;
    player notify("bomber_plane_changed");
}

// Horizontal distance a bomb travels ahead of the jet before it hits the ground.
getBombForwardDistance() {
    falltime = calculateFallTime(level.bomberFlightPlan.height);
    return (level.bomberFlightPlan.speed * level.bomberFlightPlan.bombSpeedScale) * falltime;
}

// Next jet after current (wrapping) that still exists and has not dropped yet.
getNextAvailablePlane(current) {
    index = -1;
    for (i = 0; i < level.bomberPlanes.size; i++) {
        if (isDefined(current) && isDefined(level.bomberPlanes[i]) && level.bomberPlanes[i] == current) {
            index = i;
            break;
        }
    }

    for (i = 1; i <= level.bomberPlanes.size; i++) {
        plane = level.bomberPlanes[(index + i) % level.bomberPlanes.size];
        if (!isDefined(plane) || (isDefined(current) && plane == current) || isDefined(plane.bomberDropped)) {
            continue;
        }

        return plane;
    }

    return undefined;
}

changePlanes() {
    self endon("disconnect");
    self endon("death");
    self endon("bombing_done");

    for (;;) {
        while (!self useButtonPressed()) {
            wait 0.05;
        }

        // Only while the current jet still has its bombs (otherwise bombDropWaiter switches).
        if (isDefined(self.currentPlane) && !isDefined(self.currentPlane.bomberDropped)) {
            plane = getNextAvailablePlane(self.currentPlane);
            if (isDefined(plane)) {
                plane attachToPlane(self);
            }
        }

        while (self useButtonPressed()) {
            wait 0.05;
        }
    }
}

bomberDetachOnFrag() {
    self endon("disconnect");
    self endon("death");
    self endon("bombing_done");

    while (!self fragButtonPressed()) {
        wait 0.05;
    }

    self notify("bombing_done");
}

// Runs per jet: only the jet being watched matters when it leaves the map.
bomberDetachOnPlaneDelete(player) {
    player endon("disconnect");
    player endon("death");
    player endon("bombing_done");

    self waittill("delete");
    if (!isDefined(player.currentPlane) || player.currentPlane != self) {
        return;
    }

    // Unlink first: the camera entity would be removed together with the jet.
    player.bomberCam unlink();
    plane = getNextAvailablePlane(self);
    if (isDefined(plane)) {
        plane attachToPlane(player);
    } else {
        player notify("bombing_done");
    }
}

bomberDetachOnDone(cam, look) {
    event = self waittill_any_return("bombing_done", "death", "disconnect");
    if (isDefined(cam)) {
        cam delete();
    }

    if (isDefined(look)) {
        look delete();
    }

    if (event == "disconnect" || !isDefined(self)) {
        return;
    }

    self cameraActivate(false);
    if (!level.gameEnded) {
        self freezeControls(false);
    }
    self setClientDvar("cg_fov", 65);
    self.currentPlane = undefined;
    if (isDefined(self.bomberStartAngles)) {
        self setPlayerAngles(self.bomberStartAngles);
    }

    self.bomberCam = undefined;
    self.bomberLook = undefined;
    self.bomberStartAngles = undefined;
    self.bomberBasePitch = undefined;
}

// Keeps the camera looking along the current jet, pitched onto its impact point.
bomberCameraThink() {
    self endon("disconnect");
    self endon("death");
    self endon("bombing_done");

    for (;;) {
        if (isDefined(self.currentPlane) && isDefined(self.bomberCam) && isDefined(self.bomberLook) && isDefined(self.bomberBasePitch)) {
            dir = anglesToForward((self.bomberBasePitch, self.currentPlane.angles[1], 0));
            self.bomberLook.origin = self.bomberCam.origin + vector_scale(dir, level.bomberLookDistance);
            self cameraSetLookAt(self.bomberLook);
        }

        wait 0.05;
    }
}

// World marker on the ground where the first bomb of the current jet would land.
bomberImpactMarker() {
    self endon("disconnect");

    // The waypoint follows an entity: entity origins are interpolated by the
    // client, raw hud x/y/z are not (the marker would jump ~100 units per frame).
    ent = spawn("script_model", level.bomberFlightPlan.target);
    ent setModel("tag_origin");

    marker = newClientHudElem(self);
    marker.x = 0;
    marker.y = 0;
    marker.z = 0;
    marker.alpha = 0;
    marker.archived = false;
    marker setShader(level.bomberMarkerShader, 8, 8);
    marker setWaypoint(true);
    marker setTargetEnt(ent);
    self thread bomberImpactMarkerUpdate(marker, ent);

    self waittill_any("bombing_done", "death");
    marker destroy();
    ent delete();
}

bomberImpactMarkerUpdate(marker, ent) {
    self endon("disconnect");
    self endon("death");
    self endon("bombing_done");

    bombX = getBombForwardDistance();
    targetZ = level.bomberFlightPlan.target[2];
    groundZ = targetZ;
    for (;;) {
        plane = self.currentPlane;
        if (isDefined(plane) && !isDefined(plane.bomberDropped)) {
            pos = plane.origin + vector_scale(anglesToForward((0, plane.angles[1], 0)), bombX);
            // Trace around map level, not from the jet: starting up there often
            // begins outside the world or in sky clips and returns garbage.
            trace = bulletTrace((pos[0], pos[1], targetZ + 1500), (pos[0], pos[1], targetZ - 1500), false, plane);
            if (trace["fraction"] < 1) {
                groundZ = trace["position"][2];
            }

            ent.origin = (pos[0], pos[1], groundZ);
            marker.alpha = 1;
        } else {
            marker.alpha = 0;
        }

        wait 0.05;
    }
}

bomberHint() {
    self endon("disconnect");

    info = self maps\mp\centurypackage\hud::createText("small", 1.2, "CENTER", "BOTTOM", 0, -75, 10, false, false, getBomberInfoText());
    hint = self maps\mp\centurypackage\hud::createText("small", 1.2, "CENTER", "BOTTOM", 0, -60, 10, false, false, self getBomberHintText());
    self thread bomberHintRefreshRelay();
    for (;;) {
        event = self waittill_any_return("bomber_plane_changed", "bomber_hint_refresh", "bombing_done", "death");
        if (event == "bombing_done" || event == "death") {
            break;
        }

        if (event == "bomber_hint_refresh") {
            info maps\mp\centurypackage\overflow::setSafeText(getBomberInfoText());
        }

        hint maps\mp\centurypackage\overflow::setSafeText(self getBomberHintText());
    }

    info destroy();
    hint destroy();
}

// Redraw the hint when the overflow fix wiped all script strings or a new jet arrived.
bomberHintRefreshRelay() {
    self endon("disconnect");
    self endon("death");
    self endon("bombing_done");

    for (;;) {
        level waittill_any("overflow_cleared", "bomber_plane_spawned");
        self notify("bomber_hint_refresh");
    }
}

getBomberInfoText() {
    return "Bombs land at the marker - drop when it is on the target";
}

getBomberHintText() {
    // Count only jets that still have their bombs.
    planeNumber = 0;
    available = 0;
    for (i = 0; i < level.bomberPlanes.size; i++) {
        plane = level.bomberPlanes[i];
        if (!isDefined(plane) || isDefined(plane.bomberDropped)) {
            continue;
        }

        available++;
        if (isDefined(self.currentPlane) && plane == self.currentPlane) {
            planeNumber = available;
        }
    }

    if (planeNumber == 0) {
        return "Bombs away | [{+frag}] Exit";
    }

    useBind = "[{+activate}]";
    if (level.console) {
        useBind = "[{+usereload}]";
    }

    return "Jet " + planeNumber + "/" + available + " |[{+attack}] Drop bombs | " + useBind + " Switch jet | [{+frag}] Exit";
}

bomberOverlay() {
    self endon("disconnect");

    overlay = newClientHudElem(self);
    overlay.x = 0;
    overlay.y = 0;
    overlay.alignX = "center";
    overlay.alignY = "middle";
    overlay.horzAlign = "center";
    overlay.vertAlign = "middle";
    overlay.foreground = true;
    overlay setShader("ac130_overlay_105mm", 640, 480);

    grain = newClientHudElem(self);
    grain.x = 0;
    grain.y = 0;
    grain.alignX = "left";
    grain.alignY = "top";
    grain.horzAlign = "fullscreen";
    grain.vertAlign = "fullscreen";
    grain.foreground = true;
    grain setShader("ac130_overlay_grain", 640, 480);
    grain.alpha = 0.5;

    self waittill_any("bombing_done", "death");
    overlay destroy();
    grain destroy();
}
