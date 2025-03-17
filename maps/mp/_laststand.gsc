#include maps\mp\_utility;
#include common_scripts\utility;

initLastStand() {
	precacheItem("syrette_mp");
	level.reviveTriggerRadius = getDvarFloat(#"player_reviveTriggerRadius");
	level.howLongToDoLastStandForWithRevive = getDvarFloat(#"player_lastStandBleedoutTime");
	level.howLongToDoLastStandForWithoutRevive = getDvarFloat(#"player_lastStandBleedoutTimeNoRevive");
	level.aboutToBleedOutTime = 5;
	level.amountOfLastStandPistolAmmoInClip = 0;
	level.amountOfLastStandPistolAmmoInStock = 0;
	level.lastStandCount = undefined;
	if (!isDefined(level.lastStandPistol)) {
		level.lastStandPistol = "m1911_mp";
		precacheItem(level.lastStandPistol);
	}

	level.allies_needs_revive = false;
	level.axis_needs_revive = false;
	if (getDvar(#"revive_time_taken") == "") {
		setDvar("revive_time_taken", "1.15");
	}

	precacherumble("dtp_rumble");
	precacherumble("slide_rumble");
}

keep_weapons() {
	return (set_dvar_int_if_unset("scr_laststand_keep_weapons", 0) > 0);
}

lastStandTime() {	
	if (self hasPerk("specialty_finalstand")) {
		return level.howLongToDoLastStandForWithRevive;
	}

	return level.howLongToDoLastStandForWithoutRevive;
}

playerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration) {
	self.lastStandParams = spawnstruct();
	self.lastStandParams.eInflictor = eInflictor;
	self.lastStandParams.attacker = attacker;
	if (isPlayer(attacker)) {
		self.lastStandParams.attackerStance = attacker getStance();
		if (isDefined(attacker.lastStand) && attacker.lastStand) {
			self.lastStandParams.attackerStance = "laststand";
		}
	}

	self.lastStandParams.iDamage = iDamage;
	self.lastStandParams.sMeansOfDeath = sMeansOfDeath;
	self.lastStandParams.sWeapon = sWeapon;
	self.lastStandParams.vDir = vDir;
	self.lastStandParams.sHitLoc = sHitLoc;
	self.lastStandParams.lastStandStartTime = getTime();	
	if (isDefined(attacker)) {
		self.lastStandParams.vAttackerOrigin = attacker.origin;
	}

	mayDoLastStand = mayDoLastStand(sWeapon, sMeansOfDeath, sHitLoc);
	self.useLastStandParams = true;
	if (!mayDoLastStand) {
		self ensureLastStandParamsValidity();
		return;
	}

	if (!isDefined(self.lastStandThisLife)) {
		self.lastStandThisLife = 0;		
	}

	self.lastStandThisLife++;
	self.health = 1;
	self thread maps\mp\gametypes\_gameobjects::onPlayerLastStand();
	self notify("entering_last_stand");
	self playlocalsound ("mus_last_stand");
	weaponsList = self getWeaponsList();
	assertex(isDefined(weaponsList) && weaponsList.size > 0, "Player's weapon(s) missing before dying -=Last Stand=-");
	self.previousWeaponsList = self getWeaponsList();
	self.previousAmmoClip = [];
	self.previousAmmoStock = [];
	self.lastStandPistol = level.lastStandPistol;
	self.previousPrimary = self getCurrentWeapon();
	self.hadPistol = false;
	for (i = 0; i < self.previousWeaponsList.size; i++) {
		if (weaponClass(self.previousWeaponsList[i]) == "pistol" && self.previousWeaponsList[i] != "knife_ballistic_mp" && !isSubStr(self.previousWeaponsList[i], "_auto_") && !isSubStr(self.previousWeaponsList[i], "dw_")) {
			self.lastStandPistol = self.previousWeaponsList[i];
			self.hadPistol = true;
		}
	}

	self notify ("cancel_location");
	currentWeapon = self getCurrentWeapon();
	if (currentWeapon == "syrette_mp") {
		self takeWeapon(currentWeapon);
		currentWeapon = self.previousPrimary;
		self giveWeapon(currentWeapon);
	}

	self setLastStandPrevWeap(currentWeapon);
	self disableOffHandWeapons();
	self disableWeaponCycling();
	self.previousWeaponsList = self getWeaponsList();
	for (i = 0; i < self.previousWeaponsList.size; i++) {
		weapon = self.previousWeaponsList[i];
		self.previousAmmoClip[i] = self getWeaponAmmoClip(weapon);
		self.previousAmmoStock[i] = self getWeaponAmmoStock(weapon);
	}

	if ((!level.hardcoreMode || self.team != attacker.team) && self hasPerk("specialty_finalstand")) { 
		revive_trigger_spawn();
	}

	if (!keep_weapons()) {
		if (!self.hadPistol) {
			self giveWeapon(self.lastStandPistol);
			self giveWeapon("knife_mp");
		}

		self switchToWeapon(self.lastStandPistol);
		if (level.amountOfLastStandPistolAmmoInClip == 0 && level.amountOfLastStandPistolAmmoInStock == 0) {
			self giveMaxAmmo(self.lastStandPistol);
		}
		else {
			self setWeaponAmmoClip(self.lastStandPistol, level.amountOfLastStandPistolAmmoInClip);
			self setWeaponAmmoStock(self.lastStandPistol, level.amountOfLastStandPistolAmmoInStock);
		}

		if (self isThrowingGrenade()) {
			self thread waittillGrenadeThrown();
		}
	}
	
	self lastStandTimer(lastStandTime());
}

waittillGrenadeThrown() {
	self endon("disconnect");
	self endon("death");
	self endon("player revived");
	
	self waittill("grenade_fire", grenade, weapname);
	for (i = self.previousWeaponsList.size -1; i >= 0 ; i--) {
		weapon = self.previousWeaponsList[i];
		if (weapon == weapname) {
			self.previousAmmoClip[i]-= 1;
			self.previousAmmoStock[i] -= 1;
		}
	}
}

mayDoLastStand(sWeapon, sMeansOfDeath, sHitLoc) {
	if (level.currentGametype == "sd" || level.currentGametype == "dm") {
		return false;
	}

	if (sMeansOfDeath != "MOD_PISTOL_BULLET" && sMeansOfDeath != "MOD_RIFLE_BULLET") {
		return false;	
	}

	if (level.lastStandPistol == "none") {
		return false;
	}

	if (isDefined(self.enteringVehicle) && self.enteringVehicle) {
		return false;
	}

	if (self isInVehicle()) {
		return false;
	}

	if (self isRemoteControlling()) {
		return false;
	}
	
	if (isDefined(self.selectingLocation) && self.selectingLocation) {
		return false;
	}

	if (isDefined(self.lastStand)) {
		return false;
	}
	
	if (isDefined(self.revivingTeammate) && self.revivingTeammate) {
		return false;
	}
	
	if (isDefined(self.isPlanting) && self.isPlanting) {
		return false;
	}
	
	if (isDefined(self.isDefusing) && self.isDefusing) {
		return false;
	}
	
	if (isDefined(level.lastStandCount)) {
		if (isDefined(self.lastStandThisLife) && self.lastStandThisLife >= level.lastStandCount)
		{
			return false;
		}
	}
	
	if (isDefined(sWeapon) && weaponClass(sWeapon) == "spread") {
		return false;
	}
	
	return true;
}

lastStandTimer(delay) {	
	self thread lastStandWaittillDeath();
	self.aboutToBleedOut = undefined;
	self.lastStand = true;
	self setLowerMessage(&"PLATFORM_COWARDS_WAY_OUT");
	self.lowerMessage.hideWhenInDemo = true;
	self thread lastStandBleedout(delay);
}

lastStandWaittillDeath() {
	self endon("disconnect");
	self endon("player revived");

	self waittill("death", attacker, isHeadShot, weapon);
	teammateNeedsRevive = false;
	if (isDefined(attacker) && isDefined(isHeadShot) && isHeadShot && isPlayer(attacker)) {
		if (level.teambased) {
			if (attacker.team != self.team) {
				attacker maps\mp\_medals::execution(weapon);
			}
		}
		else {
			if (attacker != self) {
				attacker maps\mp\_medals::execution(weapon);
			}
		}
	}

	self.thisPlayerisinlaststand = false;
	self clearLowerMessage();
	self.lastStand = undefined;
	if (!allowRevive()) {
		return;
	}

	players = get_players();
	if (isDefined(self.reviveTrigger)) {
		self.reviveTrigger delete();
	}

	for (i = 0; i < players.size; i++) {
		if (self.team == players[i].team) {
			if (isDefined(players[i].reviveTrigger)) {
				teammateNeedsRevive = true;
			}
		}
	}

	for (index = 0; index < 4; index++) {
		self.reviveIcons[index].alpha = 0;
		self.reviveIcons[index] setWaypoint(false);
	}

	self setTeamRevive(teammateNeedsRevive);
}

cleanupTeammateNeedsReviveList() {	
	if (!allowRevive()) {
		return;
	}

	players = get_players();
	teammateNeedsRevive = false;
	for (i = 0; i < players.size; i++) {
		if ("allies" == players[i].team) {
			if (isDefined(players[i].reviveTrigger)) {
				teammateNeedsRevive = true;
			}
		}
	}

	level.allies_needs_revive = teammateNeedsRevive;
	teammateNeedsRevive = false;
	for (i = 0; i < players.size; i++) {
		if ("axis" == players[i].team) {
			if (isDefined(players[i].reviveTrigger)) {
				teammateNeedsRevive = true;
			}
		}
	}

	level.axis_needs_revive = teammateNeedsRevive;
}

setTeamRevive(needsRevive) {
	if (self.team == "allies") {
		level.allies_needs_revive = needsRevive;
	}
	else if (self.team == "axis") {
		level.axis_needs_revive = needsRevive;
	}
}

teammateNeedsRevive() {
	teammateNeedsRevive = false;
	if (isDefined(self.team)) {
		if (self.team == "allies") {
			teammateNeedsRevive = level.allies_needs_revive;
		}
		else if (self.team == "axis") {
			teammateNeedsRevive = level.axis_needs_revive;
		}
	}

	return teammateNeedsRevive;
}

revive_trigger_spawn() {
	if (!allowRevive()) {
		return;
	}

	reviveObituary(self); 
	self setTeamRevive(true);
	self.reviveTrigger = spawn("trigger_radius", self.origin, 0, level.reviveTriggerRadius, level.reviveTriggerRadius);
	self thread clearUpOnDisconnect(self);
	self.reviveTrigger setReviveHintString(&"GAME_BUTTON_TO_REVIVE_PLAYER", self.team);
	self.reviveTrigger setCursorHint("HINT_NOICON");
	self thread revive_trigger_think();
	self thread cleanUpOnDeath();
	self needsRevive(true);
}

cleanUpOnDeath() {
	self endon("disconnect");

	self waittill("death");
	if (isDefined(self.reviveTrigger)) {
		self.reviveTrigger delete();
	}
}

revive_trigger_think() {
	self setTeamRevive(true);
	detectTeam = self.team;
	self.currentlyBeingRevived = false;
	self.thisPlayerIsInLastStand = true;
	self detectReviveIconWaiter();
	while (isDefined(self) && isAlive(self) && isDefined(self.thisPlayerIsInLastStand) && self.thisPlayerIsInLastStand) {
		players = level.aliveplayers[detectTeam];
		if (distanceSquared(self.reviveTrigger.origin, self.origin) > 1) {
			self.reviveTrigger delete();
			self.reviveTrigger = spawn("trigger_radius", self.origin, 0, level.reviveTriggerRadius, level.reviveTriggerRadius);
			self.reviveTrigger setReviveHintString(&"GAME_BUTTON_TO_REVIVE_PLAYER", self.team);
			self.reviveTrigger setCursorHint("HINT_NOICON");
			self thread clearUpOnDisconnect(self);
		}

		for (i = 0; i < players.size; i++) {
			player = players[i];
			if (can_revive(player)) {
				if (player != self && !isDefined(player.reviveTrigger))
				{
					if ((!isDefined(self.currentlyBeingRevived) || !self.currentlyBeingRevived) && !player.revivingTeammate)
					{
						if (player.health > 0 && isDefined(self.reviveTrigger) && player isTouching(self.reviveTrigger) && player useButtonPressed())
						{
							player.revivingTeammate = true;
							player thread cleanUpRevivingTeamate(self);
							currentWeapon = player getCurrentWeapon();
							if (currentWeapon == "syrette_mp")
							{
								player.currentWeapon = player.previousPrimary;
							}
							else
							{
								player.previousPrimary = currentWeapon;
								player.gun = currentWeapon;
							}

							player giveWeapon("syrette_mp");
							player switchToWeapon("syrette_mp");
							player setWeaponAmmoStock("syrette_mp", 1);
							player notify ("snd_ally_revive");
							player player_being_revived(self); 
							if (isDefined(self))
							{
								self.currentlyBeingRevived = false;
							}

							player takeWeapon("syrette_mp");
							if (player.previousPrimary == "none" || maps\mp\gametypes\_hardpoints::isKillstreakWeapon(player.previousPrimary))
							{
								player switchToValidWeapon();
							}
							else if (isWeaponEquipment(player.previousPrimary) && player getWeaponAmmoClip(player.previousPrimary) <= 0)
							{
								player switchToValidWeapon();
							}
							else
							{
								player switchToWeapon(player.previousPrimary);
							}

							player.previousPrimary = undefined;
							player notify("completedRevive");
							wait 0.1;
							player.revivingTeammate = false;
						}
					}
				}
			}
		}

		wait 0.1;
	}
}

switchToValidWeapon() {
	if (self hasWeapon(self.lastNonKillstreakWeapon)) {
		self switchToWeapon(self.lastNonKillstreakWeapon);
	}
	else if (self hasWeapon(self.lastDroppableWeapon)) {
		self switchToWeapon(self.lastDroppableWeapon);
	}
	else {
		primaries = self getWeaponsListPrimaries();
		assert(primaries.size > 0);
		self switchToWeapon(primaries[0]);
	}
}

cleanUpRevivingTeamate(revivee) {
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "completedRevive" );
	
	revivee waittill("death");
	self.revivingTeammate = false;
}

player_being_revived(playerBeingRevived) {
	self endon("death");
	self endon("disconnect");

	reviveTime = getDvarInt(#"revive_time_taken");
	if (!isDefined(playerBeingRevived.currentlyBeingRevived)) {
		playerBeingRevived.currentlyBeingRevived = false;
	}

	if (reviveTime > 0) {
		timer = 0;
		reviveTrigger = playerBeingRevived.reviveTrigger;
		while (self.health > 0 && isDefined(reviveTrigger) && self isTouching(reviveTrigger) && self useButtonPressed() && isDefined(playerBeingRevived)) {
			playerBeingRevived.currentlyBeingRevived = true;
			wait 0.05;
			timer += 0.05;			
			if (timer >= reviveTime) {
				obituary(playerBeingRevived, self, "syrette_mp", "MOD_UNKNOWN");
				self maps\mp\_medals::revives();
				self maps\mp\gametypes\_persistence::statAdd("REVIVES", 1, false);
				if (level.rankedMatch)
				{
					self maps\mp\gametypes\_missions::doMissionCallback("medic", self); 
				}

				playerBeingRevived.thisPlayerIsInLastStand = false;	
				playerBeingRevived thread takePlayerOutOfLastStand();	
			}
		}

		return false;
	}
	else {
		playerBeingRevived.thisPlayerIsInLastStand = false;	
		playerBeingRevived thread takePlayerOutOfLastStand();	
	}
}

takePlayerOutOfLastStand() {
	self notify ("player revived");		
	self clearLowerMessage();
	self playLocalSound("mus_last_stand_revive");	
	if (!keep_weapons()) {
		if (!self.hadPistol) {
			self takeWeapon(self.lastStandPistol);
		}

		for (i = self.previousWeaponsList.size -1; i >= 0; i--) {
			weapon = self.previousWeaponsList[i];
			self giveWeapon(weapon);
			self setWeaponAmmoClip(weapon, self.previousAmmoClip[i]);
			self setWeaponAmmoStock(weapon, self.previousAmmoStock[i]);
		}

		if (isDefined(self.previousPrimary) && self.previousPrimary != "none") { 
			if (!isWeaponEquipment(self.previousPrimary) && !isWeaponSpecificUse(self.previousPrimary) && !isDefined(level.grenade_array[self.previousPrimary])) {
				self switchToWeapon(self.previousPrimary);
			}
			else {
				for (i = self.previousWeaponsList.size -1; i >= 0; i--)
				{
					if (!isWeaponEquipment(self.previousWeaponsList[i]) && !isWeaponSpecificUse(self.previousWeaponsList[i]) && isWeaponPrimary(self.previousWeaponsList[i]))
					{
						self switchToWeapon(self.previousWeaponsList[i]);
						break;
					}
				}
			}
		}
		else {
			for (i = self.previousWeaponsList.size -1; i >= 0; i--) {
				if (!isWeaponEquipment(self.previousWeaponsList[i]) && !isWeaponSpecificUse(self.previousWeaponsList[i]) && isWeaponPrimary(self.previousWeaponsList[i]))
				{
					self switchToWeapon(self.previousWeaponsList[i]);
					break;
				}
			}
		}
	}
	
	self revive();
	self needsRevive(false);
	if (isDefined(self.reviveTrigger)) {
		self.reviveTrigger delete();
	}

	self.aboutToBleedOut = undefined;
	self clearLowerMessage();
	self thread maps\mp\gametypes\_hardpoints::giveOwnedKillstreak();
	self.lastStandPistol = level.lastStandPistol;
	self.lastStand = undefined;
	self enableOffhandWeapons();
	self enableWeaponCycling();
	self.useLastStandParams = undefined;
	self.lastStandParams = undefined;
	players = get_players();
	anyPlayerLeftInLastStand = false;
	for (i = 0; i < players.size; i++) {
		if (isDefined(players[i].reviveTrigger) && players[i].team == self.team) {
			anyPlayerLeftInLastStand = true;
		}
	}

	if (!anyPlayerLeftInLastStand) {
		self setTeamRevive(false);
	}
}

reviveFromConsole() {
	self endon ("player revived");

	for (;;) {
		if (getDvar(#"scr_reviveme") != "") {
			self.thisPlayerIsInLastStand = false;	
			setdvar("scr_reviveme", "");
			self thread takePlayerOutOfLastStand();
		}

		wait 0.1;
	}
}

lastStandBleedout(delay) {
	self endon("player revived");
	self endon("disconnect");
	self endon("death");

	self thread cowardsWayOut();
	self thread lastStandHealthOverlay();
	self thread lastStandEndOnForceCrouch();
	wait (delay - level.aboutToBleedOutTime);	
	self.aboutToBleedOut = true;
	wait (level.aboutToBleedOutTime);
	self notify("end coward");
	players = get_players();
	for (i = 0; i < players.size; i++) {
		players[i] notify ("stop revive pulse");
	}

	self needsRevive(false);
	self ensureLastStandParamsValidity();
	self suicide();
}

lastStandEndOnForceCrouch() {
	self endon("player revived");
	self endon("disconnect");
	self endon("death");
	self endon("end coward");

	self waittill("force crouch");
	self needsRevive(false);
	self ensureLastStandParamsValidity();
	self suicide();
}

cowardsWayOut() {
	self endon("player revived");
	self endon("disconnect");
	self endon("death");
	self endon("end coward");

	for (;;) {
		if (self useButtonPressed()) {
			pressStartTime = getTime();
			while (self useButtonPressed()) {
				wait .05;
				if (getTime() - pressStartTime > 700)
				{
					break;
				}
			}

			if (getTime() - pressStartTime > 700) {
				break;
			}
		}

		wait .05;
	}

	self needsRevive(false);
	self ensureLastStandParamsValidity();
	duration = self doCowardsWayAnims();
	wait duration;
	self.suicideWeapon = self getCurrentWeapon();	
	wait 0.05;
	self suicide();
}

clearUpOnDisconnect(player) {
	reviveTrigger = self.reviveTrigger;
	self notify("clearing revive on disconnect");
	self endon("clearing revive on disconnect");

	self waittill("disconnect");
	self.lastStand = undefined;
	cleanupTeammateNeedsReviveList();
	if (isDefined(reviveTrigger)) {
		reviveTrigger delete();
	}

	teammateNeedsRevive = false;
	players = get_players();	
	for (i = 0; i < players.size; i++) {
		player = players[i];
		if (self.team == player.team) {
			if (isdefined (player.reviveTrigger)) {
				teammateNeedsRevive = true;
			}
		}
	}

	self setTeamRevive(teammateNeedsRevive);
}

allowRevive() {
	if (!level.teambased) { 
		return false;
	}

	if (maps\mp\gametypes\_tweakables::getTweakableValue("player", "allowrevive") == 0) {
		return false;
	}

	return true;
}

setupRevive() {
	if (!allowRevive()) {
		return;
	}

	self.aboutToBleedOut = undefined;	
	for (index = 0; index < 4; index++) {
		if (!isDefined(self.reviveIcons[index])) {
			self.reviveIcons[index] = newClientHudElem(self);
		}

		self.reviveIcons[index].x = 0;
		self.reviveIcons[index].y = 0;
		self.reviveIcons[index].z = 0;
		self.reviveIcons[index].alpha = 0;
		self.reviveIcons[index].archived = true;
		self.reviveIcons[index] setShader("waypoint_second_chance", 14, 14);
		self.reviveIcons[index] setWaypoint(false);
		self.reviveIcons[index].reviveId = -1;
		self.reviveIcons[index].overrrideWhenInDemo = true;
	}

	players = get_players();
	iconCount = 4;
	for (i = 0; i < players.size && iconCount > 0; i++) {
		player = players[i];
		if (!isDefined(player.team)) {
			continue;
		}

		if (self.team != player.team) {
			continue;
		}

		if (!isDefined(player.lastStand) || !player.lastStand) {
			continue;
		}

		iconCount--;
		self thread showReviveIcon(player);
	}	
}

lastStandHealthOverlay() {
	self endon("player revived");
	self endon("death");
	self endon("disconnect");
	self endon("game_ended");
	
	for (;;) {
		self.health = 2;
		wait .05;
		self.health = 1;
		wait .5;
	}
}

ensureLastStandParamsValidity() {
	if (!isDefined(self.lastStandParams.attacker)) {
		self.lastStandParams.attacker = self;
	}
}

detectReviveIconWaiter( ) {
	level endon("game_ended");

	if (!allowRevive()) {
		return;
	}

	players = get_players();
	for (i = 0; i < players.size; i++) {
		player = players[i];
		if (player.team != self.team) {
			continue;
		}

		if (player == self) {
			continue;
		}

		if (!(can_revive(player))) {
			continue;
		}

		if (isAI(player)) {
			continue;
		}

		player thread showReviveIcon( self ); 
	}
}

showReviveIcon(lastStandPlayer) {
	self endon ("disconnect");

	if (!allowRevive()) {
		return;
	}

	triggerReviveId = lastStandPlayer getEntityNumber();
	useId = -1;
	for (index = 0; (index < 4) && (useId == -1); index++) {
		if (!isDefined(self.reviveIcons) || !isDefined(self.reviveIcons[index]) || !isDefined(self.reviveIcons[index].reviveId)) {
			continue;
		}

		reviveId = self.reviveIcons[index].reviveId;
		if (reviveId == triggerReviveId) {
			return;
		}

		if (reviveId == -1) {
			useId = index;
		}
	}

	if (useId < 0) {
		return;
	}

	loopTime = 0.05;
	self.reviveIcons[useId] setWaypoint(true, "waypoint_second_chance");
	reviveIconAlpha = 0.8;
	self.reviveIcons[useId].alpha = reviveIconAlpha;
	self.reviveIcons[useId].reviveId = triggerReviveId;
	self.reviveIcons[useId] setTargetEnt(lastStandPlayer);
	while (isDefined(lastStandPlayer.reviveTrigger)) {
		if (isDefined(lastStandPlayer.aboutToBleedOut)) {
			self.reviveIcons[useId] fadeOverTime(level.aboutToBleedOutTime);
			self.reviveIcons[useId].alpha = 0;
			while (isDefined(lastStandPlayer.reviveTrigger)) {
				wait 0.1;
			}

			wait level.aboutToBleedOutTime;
			self.reviveIcons[useId].reviveId = -1;
			self.reviveIcons[useId] setWaypoint(false);
			return;
		}	
		else if (self isInVehicle()) {
			self.reviveIcons[useId].alpha = 0;
		}
		else {
			self.reviveIcons[useId].alpha = reviveIconAlpha;
		}
			
		wait loopTime;
	}

	if (!isDefined(self)) {
		return;
	}

	self.reviveIcons[useId] fadeOverTime(0.25);
	self.reviveIcons[useId].alpha = 0;
	wait 1;
	self.reviveIcons[useId].reviveId = -1;
	self.reviveIcons[useId] setWaypoint(false);
}

can_revive(reviver) {
	if (isDefined(reviver)) { 
		return true;
	}

	return false;		
}
