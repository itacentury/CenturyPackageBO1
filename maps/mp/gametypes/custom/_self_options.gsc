#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

refillAmmo()
{
	curWeapons = self GetWeaponsListPrimaries();
	offHandWeapons = array_exclude(self GetWeaponsList(), curWeapons);
	offHandWeapons = array_remove(offHandWeapons, "knife_mp");
	for (i = 0; i < curWeapons.size; i++)
	{
		weapon = curWeapons[i];
		self GiveStartAmmo(weapon);
		if (weapon == "china_lake_mp")
		{
			self GiveMaxAmmo(weapon);
		}
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
	self maps\mp\gametypes\_clientids::exitMenu();
	wait 0.25;
	//Lightweight Pro
	self setPerk("specialty_movefaster");
	self setPerk("specialty_fallheight");
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lightweight", "1");
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
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("sleightOfHand", "1");
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

giveUnlockAll()
{
	if (level.players.size > 1)
	{
		self iprintln("^1Too many ^7players in your game!");
		return;
	}

	//RANKED GAME
	level.rankedMatch = true;
	level.contractsEnabled = true;
	setDvar("onlinegame", 1);
	setDvar("xblive_rankedmatch", 1);
	setDvar("xblive_privatematch", 0);
	//LEVEL 50
	self maps\mp\gametypes\_persistence::statSet("rankxp", 1262500, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "rankxp", 1262500);
	self.pers["rank"] = 49;
	self setRank(49);
	//PRESTIGE
	prestigeLevel = 15;
	self.pers["plevel"] = prestigeLevel;
	self.pers["prestige"] = prestigeLevel;
	self setdstat("playerstatslist", "plevel", "StatValue", prestigeLevel);
	self maps\mp\gametypes\_persistence::statSet("plevel", prestigeLevel, true);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "plevel", prestigeLevel);
	self setRank(self.pers["rank"], prestigeLevel);
	//PERKS
	perks = [];
	perks[1] = "PERKS_SLEIGHT_OF_HAND";
	perks[2] = "PERKS_GHOST";
	perks[3] = "PERKS_NINJA";
	perks[4] = "PERKS_HACKER";
	perks[5] = "PERKS_LIGHTWEIGHT";
	perks[6] = "PERKS_SCOUT";
	perks[7] = "PERKS_STEADY_AIM";
	perks[8] = "PERKS_DEEP_IMPACT";
	perks[9] = "PERKS_MARATHON";
	perks[10] = "PERKS_SECOND_CHANCE";
	perks[11] = "PERKS_TACTICAL_MASK";
	perks[12] = "PERKS_PROFESSIONAL";
	perks[13] = "PERKS_SCAVENGER";
	perks[14] = "PERKS_FLAK_JACKET";
	perks[15] = "PERKS_HARDLINE";
	for (i = 1; i < 16; i++)
	{
		perk = perks[i];
		for (j = 0; j < 3; j++)
		{
			self maps\mp\gametypes\_persistence::unlockItemFromChallenge("perkpro " + perk + " " + j);
		}
	}

	//COD POINTS
	points = 1000000000;
	self maps\mp\gametypes\_persistence::statSet("codpoints", points, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "codpoints", points);
	self maps\mp\gametypes\_persistence::setPlayerStat("PlayerStatsList", "CODPOINTS", points);
	self.pers["codpoints"] = points;
	//ITEMS
	self setClientDvar("allItemsPurchased", "1");
	self setClientDvar("allItemsUnlocked", "1");
	//EMBLEMS
	self setClientDvar("allEmblemsPurchased", "1");
	self setClientDvar("allEmblemsUnlocked", "1");
	self setClientDvar("ui_items_no_cost", "1");
	self setClientDvar("lb_prestige", "1");
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();
	self iprintln("Full unlock all ^2given");
}
