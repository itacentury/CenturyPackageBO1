#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

toggleGodmode()
{
	if (!self.godmodeEnabled)
	{
		self EnableInvulnerability();
		self maps\mp\gametypes\_clientids::printInfoMessage("Godmode ^2Enabled");
		self.godmodeEnabled = true;
	}
	else
	{
		self DisableInvulnerability();
		self maps\mp\gametypes\_clientids::printInfoMessage("Godmode ^1Disabled");
		self.godmodeEnabled = false;
	}
}

toggleInvisible()
{
	if (!self.invisibleEnabled)
	{
		self hide();
		self setInvisibleToAll();
		self maps\mp\gametypes\_clientids::printInfoMessage("Invisible ^2Enabled");
		self.invisibleEnabled = true;
	}
	else
	{
		self show();
		self setVisibleToAll();
		self maps\mp\gametypes\_clientids::printInfoMessage("Invisible ^1Disabled");
		self.invisibleEnabled = false;
	}
}

refillAmmo()
{
	curWeapons = self GetWeaponsListPrimaries();
	offHandWeapons = array_exclude(self GetWeaponsList(), curWeapons);
	offHandWeapons = array_remove(offHandWeapons, "knife_mp");
	for (i = 0; i < curWeapons.size; i++)
	{
		weapon = curWeapons[i];
		self GiveStartAmmo(weapon);
	}

	for (i = 0; i < offHandWeapons.size; i++)
	{
		weapon = offHandWeapons[i];
		self GiveStartAmmo(weapon);
	}
}

ToggleThirdPerson()
{
	if (!self.thirdPerson)
	{
		self setClientDvar("cg_thirdPerson", "1");
		self.thirdPerson = true;
	}
	else
	{
		self setClientDvar("cg_thirdPerson", "0");
		self.thirdPerson = false;
	}
}

doSuicide()
{
	self suicide();
	self.currentMenu = "main";
}

defaultTrickshotClass()
{	
	self ClearPerks();
	self TakeAllWeapons();

	self thread maps\mp\gametypes\_clientids::exitMenu();
	wait 0.25;

	//Lightweight Pro
	self setPerk("specialty_movefaster");
	self setPerk("specialty_fallheight");
	//Hardened Pro
	self setPerk("specialty_bulletpenetration");
	self setPerk("specialty_armorpiercing");
	self setPerk("specialty_bulletflinch");
	//Steady Aim Pro
	self setPerk("specialty_bulletaccuracy");
	self setPerk("specialty_sprintrecovery");
	self setPerk("specialty_fastmeleerecovery");
	//Sleight of Hand Pro
	self setPerk("specialty_fastreload");
	self setPerk("specialty_fastads");
	//Marathon Pro
	self setPerk("specialty_longersprint");
	self setPerk("specialty_unlimitedsprint");

	self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_lightweight_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 1, "perk_deep_impact_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 2, "perk_steady_aim_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 3, "perk_sleight_of_hand_pro", -20);
	self maps\mp\gametypes\_hud_util::showPerk( 4, "perk_marathon_pro", 15);

	self.camo = 15;
	weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	self GiveWeapon("l96a1_vzoom_mp", 0, weaponOptions);
	self GiveWeapon("python_speed_mp");
	self GiveWeapon("claymore_mp");
	self GiveWeapon("hatchet_mp");
	self GiveWeapon("concussion_grenade_mp");

	self GiveStartAmmo("claymore_mp");
	self GiveStartAmmo("hatchet_mp");
	self GiveStartAmmo("concussion_grenade_mp");

	self setSpawnWeapon("python_speed_mp");
	self SwitchToWeapon("l96a1_vzoom_mp");
	self setSpawnWeapon("l96a1_vzoom_mp");

	self SetActionSlot(1, "weapon", "claymore_mp");

	wait 3;

	for (i = 0; i < 5; i++)
	{
		self maps\mp\gametypes\_hud_util::hidePerk(i, 2);
	}
}