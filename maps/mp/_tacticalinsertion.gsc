#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

init() {
	level.tacticalInsertionWeapon = "tactical_insertion_mp";
	loadFX("misc/fx_equip_tac_insert_light_grn");
	loadFX("misc/fx_equip_tac_insert_light_red");
	level._effect["tacticalInsertionFizzle"] = loadFX("misc/fx_flare_tac_dest_mp");
}

postLoadout() {
	self endon("death");
	self endon("disconnect");
	
	self.lastTacticalInsertionOrigin = self.origin;
	self.lastTacticalInsertionAngles = self.angles;
	hasTacticalInsertion = self hasWeapon(level.tacticalInsertionWeapon);
	if (hasTacticalInsertion) {		
		for (;;) {
			latestOrigin = self.origin;
			latestAngles = self.angles;
			if (self isOnGround(true) && testSpawnPoint(latestOrigin)) {
				if (self depthOfPlayerInWater() > 0)
				{
					trace = bulletTrace(latestOrigin + (0, 0, 60), latestOrigin, false, self);
					self.lastTacticalInsertionOrigin = trace["position"];
				}
				else
				{
					self.lastTacticalInsertionOrigin = latestOrigin;
				}

				self.lastTacticalInsertionAngles = latestAngles;
			}

			wait 0.05;
		}
	}
}

isTacSpawnTouchingCrates(origin, angles) {
	crate_ents = getEntArray("care_package", "script_noteworthy");
	mins = (-17, -17, -40);
	maxs = (17, 17, 40);
	for (i = 0 ; i < crate_ents.size ; i++) {
		if (crate_ents[i] isTouchingVolume(origin + (0, 0, 40), mins, maxs)) {	
			return true;
		}
	}
	
	return false;
}

overrideSpawn() {	
	if (!isDefined(self.tacticalInsertion)) {
		return false;
	}

	origin = self.tacticalInsertion.origin;
	angles = self.tacticalInsertion.angles;
	team = self.tacticalInsertion.team;
	self.tacticalInsertion destroy_tactical_insertion();
	if (team != self.team) {
		return false;
	}

	if (isTacSpawnTouchingCrates(origin)) {
		return false;
	}

	self spawn(origin, angles, "tactical insertion");
	self setSpawnClientFlag("SCDFL_DISABLE_LOGGING");
    self maps\mp\gametypes\_globallogic_score::setWeaponStat("tactical_insertion_mp", 1, "used");
	self.lastTacticalSpawnTime = getTime();
	return true;
}

watch(player) {
	if (isDefined(player.tacticalInsertion)) {
		player.tacticalInsertion destroy_tactical_insertion();
	}
	
	wait 0.05;
	player thread spawnTacticalInsertion();
	self delete();
}

watchUseTrigger(trigger, callback, playerSoundOnUse, npcSoundOnUse) {
	self endon("delete");
	
	for (;;) {
		trigger waittill("trigger", player);
		if (!isAlive(player)) {
			continue;
		}

		if (!player isOnGround()) {
			continue;
		}

		if (isDefined(trigger.triggerTeam) && (player.team != trigger.triggerTeam)) {
			continue;
		}

		if (isDefined(trigger.claimedBy) && (player != trigger.claimedBy)) {
			continue;
		}

		if (player useButtonPressed() && !player.throwingGrenade && !player meleeButtonPressed()) {
			if (isDefined(playerSoundOnUse)) {
				player playLocalSound(playerSoundOnUse);
			}

			if (isDefined(npcSoundOnUse)) {
				player playSound(npcSoundOnUse);
			}

			self thread [[callback]](player);
		}
	}
}

watchDisconnect() {
	self.tacticalInsertion endon("delete");

	self waittill("disconnect");
	self.tacticalInsertion thread destroy_tactical_insertion();
}

destroy_tactical_insertion(attacker) {
	self.owner.tacticalInsertion = undefined;
	self notify("delete");
	self.friendlyTrigger delete();
	self.enemyTrigger delete();
	if (isDefined(attacker) && isDefined(attacker.pers["team"]) && isDefined(self.owner) && isDefined(self.owner.pers["team"])) {
		if (level.teambased) {
			if (attacker.pers["team"] != self.owner.pers["team"]) {
				attacker notify("destroyed_explosive");
				attacker maps\mp\_properks::destroyedEquiptment();
			}
		}
		else {
			if (attacker != self.owner) {
				attacker notify("destroyed_explosive");
				attacker maps\mp\_properks::destroyedEquiptment();
			}		
		}
	}
	
	self delete();
}

fizzle(attacker) {
	if (isDefined(self.fizzle) && self.fizzle) {
		return;
	}

	self.fizzle = true;
	playFX(level._effect["tacticalInsertionFizzle"], self.origin);
	self.owner maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer("tact_destroyed", "item_destroyed");
	self destroy_tactical_insertion(attacker);
}

pickUp(attacker) {
	player = self.owner;
	self destroy_tactical_insertion();
	player giveWeapon(level.tacticalInsertionWeapon);
	player setWeaponAmmoClip(level.tacticalInsertionWeapon, 1);
}

spawnTacticalInsertion() {
	self endon( "disconnect" );
	
	self.tacticalInsertion = spawn("script_model", self.lastTacticalInsertionOrigin);
	self.tacticalInsertion setModel("t5_weapon_tactical_insertion_world");
	self.tacticalInsertion.origin = self.lastTacticalInsertionOrigin;
	self.tacticalInsertion.angles = self.lastTacticalInsertionAngles;
	self.tacticalInsertion.team = self.team;
	self.tacticalInsertion setTeam(self.team);
	self.tacticalInsertion.owner = self;
	self.tacticalInsertion setOwner(self);
	self.tacticalInsertion thread maps\mp\gametypes\_weaponobjects::attachReconModel("t5_weapon_tactical_insertion_world_detect", self);
	self.tacticalInsertion endon("delete");

	triggerHeight = 64;
	triggerRadius = 128;
	self.tacticalInsertion.friendlyTrigger = spawn("trigger_radius_use", self.tacticalInsertion.origin);
	self.tacticalInsertion.friendlyTrigger setCursorHint("HINT_NOICON", level.tacticalInsertionWeapon);
	self.tacticalInsertion.friendlyTrigger setHintString(&"MP_TACTICAL_INSERTION_PICKUP");
	if (level.teambased) {
		self.tacticalInsertion.friendlyTrigger setTeamForTrigger(self.team);
		self.tacticalInsertion.friendlyTrigger.triggerTeam = self.team;
	}

	self ClientClaimTrigger(self.tacticalInsertion.friendlyTrigger);
	self.tacticalInsertion.friendlyTrigger.claimedBy = self;
	self.tacticalInsertion.enemyTrigger = spawn("trigger_radius_use", self.tacticalInsertion.origin);
	self.tacticalInsertion.enemyTrigger setCursorHint("HINT_NOICON", level.tacticalInsertionWeapon);
	self.tacticalInsertion.enemyTrigger setHintString(&"MP_TACTICAL_INSERTION_DESTROY");
	self.tacticalInsertion.enemyTrigger setInvisibleToPlayer(self);
	if (level.teambased) {
		self.tacticalInsertion.enemyTrigger setTeamForTrigger(getOtherTeam(self.team));
		self.tacticalInsertion.enemyTrigger.triggerTeam = getOtherTeam(self.team);
	}
	
	self.tacticalInsertion setClientFlag(level.const_flag_tactical_insertion);
	self thread watchDisconnect();
	watcher = maps\mp\gametypes\_weaponobjects::getWeaponObjectWatcherByWeapon(level.tacticalInsertionWeapon);
	self.tacticalInsertion thread watchUseTrigger(self.tacticalInsertion.friendlyTrigger, ::pickUp, watcher.pickUpSoundPlayer, watcher.pickUpSound);
	self.tacticalInsertion thread watchUseTrigger(self.tacticalInsertion.enemyTrigger, ::fizzle);
	if (isDefined( self.tacticalInsertionCount)) {
		self.tacticalInsertionCount++;
	}
	else {
		self.tacticalInsertionCount = 1;
	}

	self.tacticalInsertion setCanDamage(true);
	for (;;) {
		self.tacticalInsertion waittill("damage", damage, attacker, direction, point, type, tagName, modelName, partname, weaponName, iDFlags);
		if (hasWeaponSplashDamage(weaponName)) {
			continue;
		}
		
		if (level.teambased && ( !isDefined(attacker) || !isPlayer(attacker) || attacker.team == self.team) && attacker != self) {
			continue;
		}

		if (attacker != self) {
			attacker maps\mp\_properks::destroyedEquiptment();
		}

		if (isDefined( weaponName)) {
			switch (weaponName) {
				case "concussion_grenade_mp":
				case "flash_grenade_mp":
					if (level.teambased && self.tacticalInsertion.owner.team != attacker.team)
					{
						if (maps\mp\gametypes\_globallogic_player::doDamageFeedback(weaponName, attacker))
						{
							attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback(false);
						}
					}
					else if (!level.teambased && self.tacticalInsertion.owner != attacker)
					{
						if (maps\mp\gametypes\_globallogic_player::doDamageFeedback(weaponName, attacker))
						{
							attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback(false);
						}
					}

					break;
				default:
					if(maps\mp\gametypes\_globallogic_player::doDamageFeedback(weaponName, attacker))
					{
						attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback(false);
					}

					break;
			}
		}
		
		self maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer("tact_destroyed", "item_destroyed");
		self.tacticalInsertion thread fizzle();
	}
}

hasWeaponSplashDamage(weapon) {
	switch (weapon) {
		case "concussion_grenade_mp":
		case "flash_grenade_mp":
		case "willy_pete_mp":
		case "tabun_gas_mp":
		case "nightingale_mp":
		case "frag_grenade_mp":
		case "sticky_grenade_mp":
		case "rpg_mp":
		case "m72_law_mp":
		case "china_lake_mp":
		case "crossbow_explosive_mp":
		case "satchel_charge_mp":
		case "claymore_mp":
			return true;
		default:
			return false;
	}
}

cancel_button_think() {
	if (!isDefined(self.tacticalInsertion)) {
		return;
	}

	text = cancel_text_create();
	self thread cancel_button_press();
	event = self waittill_any_return("disconnect", "end_killcam", "abort_killcam", "tactical_insertion_canceled", "spawned");
	if (event == "tactical_insertion_canceled") {
		self.tacticalInsertion destroy_tactical_insertion();
	}

	text Destroy();
}

cancelTackInsertionButton() {
	if (level.console) {
		return self changeSeatButtonPressed();
	}
	else {
		return self jumpButtonPressed();
	}
}

cancel_button_press() {
	self endon( "disconnect" );
	self endon( "end_killcam" );
	self endon( "abort_killcam" );

	for (;;) {
		wait .05;
		if (self cancelTackInsertionButton()) {
			break;
		}
	}

	self notify("tactical_insertion_canceled");
}

cancel_text_create() {
	text = newClientHudElem(self);
	text.archived = false;
	text.y = -100;
	text.alignX = "center";
	text.alignY = "middle";
	text.horzAlign = "center";
	text.vertAlign = "bottom";
	text.sort = 10; 
	text.font = "small";
	text.foreground = true;
	text.hideWhenInMenu = true;
	if (self isSplitscreen()) {
		text.y = -80;
		text.fontscale = 1.2;
	}
	else {
		text.fontscale = 1.6;
	}

	text setText(&"PLATFORM_PRESS_TO_CANCEL_TACTICAL_INSERTION");
	text.alpha = 1;
	return text;
}
