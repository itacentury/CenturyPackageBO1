#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_globallogic_score;

init()
{
	level.clientid = 0;

	//Needed to display a correct match bonus
	level.currentGametype = getDvar("g_gametype");
	level.currentMapName = getDvar("mapName");
	if (level.currentGametype == "sd" && getDvar("xblive_privatematch") == 1)
	{
		level.rankedMatch = true;
		level.contractsEnabled = true;
		level.azza = true;
		setDvar("sv_cheats", "1");
		setDvar("scr_" + level.currentGametype + "_timelimit", "2.5");
	}
	else
	{
		level.azza = false;
	}

	if (level.currentGametype == "dm")
	{
		setDvar("scr_disable_tacinsert", "0");
	}

	level.spawned_bots = 0;
	level.bounceSpawned = 0;
	level.multipleSetupsEnabled = false;
	//Precache for the menu UI
	precacheShader("score_bar_bg");
	//Precache all shaders to be displayed in menu
	precacheWeaponShaders();
	//Precaching glitch weapons
	precacheModel("t5_weapon_asp_lh_world");
	precacheModel("t5_weapon_asp_world_dw_lh");
	precacheModel("t5_weapon_1911_lh_world");
	precacheModel("t5_weapon_m1911_world_dw_lh");
	precacheModel("t5_weapon_makarov_lh_world");
	precacheModel("t5_weapon_makarov_world_dw_lh");
	precacheModel("t5_weapon_python_lh_world");
	precacheModel("t5_weapon_python_world_dw_lh");
	precacheModel("t5_weapon_cz75_lh_world");
	precacheModel("t5_weapon_cz75_dw_lh_world");
	precacheModel("t5_weapon_cz75_world_dw_lh");

	level.onPlayerDamageStub = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamageHook;

	level thread onPlayerConnect();
}
onPlayerConnect()
{
	for (;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;

		player.hasSaved = false;
		player.isInMenu = false;
		player.currentMenu = "main";
		player.textDrawn = false;
		player.shadersDrawn = false;
		player.optionsAdded = false;
		player.saveLoadoutEnabled = false;
		player.isAdmin = false;
		player.rank = 49;

		if (level.azza)
		{
			player thread setMatchBonus();
		}

		player thread onPlayerSpawned();
	}
}
onPlayerSpawned()
{
	self endon("disconnect");

	firstSpawn = true;

	for (;;)
	{
		self waittill ("spawned_player");

		if (firstSpawn)
		{
			if (self isHost() || level.azza)
			{
				self iPrintln("gsc.cty loaded");
			}

			if (level.azza || self isHost() || self isAdmin())
			{
				self thread runController();
			}

			if ((level.azza || !level.console) && level.currentMapName == "mp_cosmodrome")
			{
				self thread launchRocketMonitor();
			}

			self thread buildMenu();
			self thread drawMessages();
			self.ufoEnabled = false;
			self.isFrozen = false;
			self.hasAdded = false;
			self.hasOptionsAdded = false;

			if (self isHost() && level.azza)
			{
				self thread checkIfBotHasToSpawn();
				self thread addTimeToGame();
			}

			if (level.console)
			{
				self.yAxis = 150;
				self.yAxisWeapons = 185;
			}
			else 
			{
				self.yAxis = 200;
				self.yAxisWeapons = 200;
			}

			if (level.azza)
			{
				if (!self is_bot())
				{
					if (self.pers["team"] != "allies")
						self thread changeMyTeam("allies");
				}
				else
				{
					if(self.pers["team"] != "axis")
						self thread changeMyTeam("axis");
				}
			}

			if (self isHost())
			{
				self.isAdmin = true;
			}

			self thread checkNames();
			firstSpawn = false;
			self SetClientDvar("cg_spectateThirdPerson", "1");
			self.spectatingThirdPerson = true;
		}

		self FreezeControls(false);
		self.weaponShaders.alpha = 1;
		self.getEquipment = self GetWeaponsList();
		self.getEquipment = array_remove(self.getEquipment, "knife_mp");
		if (self.saveLoadoutEnabled)
		{
			self thread loadLoadout();
		}

		self thread giveEssentialPerks();
		self thread waitChangeClassGiveEssentialPerks();
	}
}
runController()
{
	self endon("disconnect");

	for(;;)
	{
		if (self isAdmin() || level.azza)
		{
			if (self.isInMenu)
			{
				if (self jumpbuttonpressed())
				{
					self thread select();
					wait 0.25;
				}

				if (self meleebuttonpressed())
				{
					self thread closeMenu();
					wait 0.25;
				}

				if (self actionslottwobuttonpressed())
				{
					self thread scrollDown();
				}

				if (self actionslotonebuttonpressed())
				{
					self thread scrollUp();
				}
			}
			else
			{
				if (self adsbuttonpressed() && self actionslottwobuttonpressed() && !self isMantling())
				{
					self thread openMenu(self.currentMenu);
					wait 0.25;
				}

				//UFO mode
				if (self actionSlotthreeButtonPressed() && self GetStance() == "crouch")
				{
					self thread enterUfoMode();
					wait .12;
				}

				//Save position
				if (self meleeButtonPressed() && self adsButtonPressed() && self getStance() == "crouch")
				{
					self.savedPosition = self.origin;
					self thread printInfoMessageNoMenu("Position ^2saved");
					self.hasSaved = true;
					wait .12;
				}

				//Load position
				if (self GetStance() == "crouch" && self actionSlotfourButtonPressed() && self.hasSaved)
				{
					self SetOrigin(self.savedPosition);
					wait .12;
				}
			}
		}
		wait 0.05;
	}
}
/*MENU*/
buildMenu()
{
	self.menus = [];

	m = "main";
	self addMenu("", m, "gsc.cty");
	//self addOption(m, "Print origin", ::printOrigin);
	//self addOption(m, "Print weapon class", ::printWeaponClass);
	if (level.azza)
	{
		self addOption(m, "Godmode", ::toggleGodmode);
		self addOption(m, "Invisible", ::toggleInvisible);
	}

	self addOption(m, "Refill Ammo", ::refillAmmo);
	self addMenu(m, "MainSelf", "^9Self Options");
	if(self isHost())
	{
		self addMenu(m, "MainAccount", "^9Account Options");
	}

	self addMenu(m, "MainClass", "^9Class Options");
	self addMenu(m, "MainLobby", "^9Lobby Options");
	
	m = "MainSelf";
	self addOption(m, "Suicide", ::doSuicide);
	self addOption(m, "Third Person", ::ToggleThirdPerson);
	self addOption(m, "Give default ts loadout", ::defaultTrickshotClass);
	if (level.currentGametype != "sd")
	{
		self addOption(m, "Save Loadout", ::saveLoadout);
	}

	if (level.currentGametype == "dm")
	{		
		self addOption(m, "Fast last", ::fastLast);
	}

	m = "MainAccount";
	self addOption(m, "Level 50", ::levelFifty);
	self addOption(m, "Prestige Selector", ::prestigeSelector);
	self addOption(m, "Unlock all perks", ::UnlockAll);
	self addOption(m, "100m CoD Points", ::giveCODPoints);
	self addOption(m, "Ranked game", ::rankedGame);

	m = "MainClass";
	self addMenu(m, "ClassWeapon", "^9Weapon Selector");
	self addMenu(m, "ClassGrenades", "^9Grenade Selector");
	self addMenu(m, "ClassCamo", "^9Camo Selector");
	self addMenu(m, "ClassPerk", "^9Perk Selector");
	self addMenu(m ,"ClassAttachment", "^9Attachment Selector");
	self addMenu(m, "ClassKillstreaks", "^9Killstreak Menu");

	self thread buildWeaponMenu();
	
	m = "ClassGrenades";
	self addOption(m, "Frag", ::giveGrenade, "frag_grenade_mp");
	self addOption(m, "Semtex", ::giveGrenade, "sticky_grenade_mp");
	self addOption(m, "Tomahawk", ::giveGrenade, "hatchet_mp");

    m = "ClassCamo";
	self addMenu(m, "CamoOne", "^9Camos Part 1");
	self addMenu(m, "CamoTwo", "^9Camos Part 2");
	self addOption(m, "Random Camo", ::randomCamo);
    
	m = "CamoOne";
	self addOption(m, "Dusty", ::changeCamo, 1);
	self addOption(m, "Ice", ::changeCamo, 2);
	self addOption(m, "Red", ::changeCamo, 3);
	self addOption(m, "Olive", ::changeCamo, 4);
	self addOption(m, "Nevada", ::changeCamo, 5);
	self addOption(m, "Sahara", ::changeCamo, 6);
	self addOption(m, "ERDL", ::changeCamo, 7);
	
	m = "CamoTwo";
	self addOption(m, "Tiger", ::changeCamo, 8);
	self addOption(m, "Berlin", ::changeCamo, 9);
	self addOption(m, "Warsaw", ::changeCamo, 10);
	self addOption(m, "Siberia", ::changeCamo, 11);
	self addOption(m, "Yukon", ::changeCamo, 12);
	self addOption(m, "Woodland", ::changeCamo, 13);
	self addOption(m, "Flora", ::changeCamo, 14);
	self addOption(m, "Gold", ::changeCamo, 15);
	
	m = "ClassPerk";
	self addOption(m, "Toggle Lightweight Pro", ::givePlayerPerk, "lightweightPro");
	self addOption(m, "Toggle Flak Jacket Pro", ::givePlayerPerk, "flakJacketPro");
	self addOption(m, "Toggle Scout Pro", ::givePlayerPerk, "scoutPro");
	self addOption(m, "Toggle Sleight of Hand Pro", ::givePlayerPerk, "sleightOfHandPro");
	self addOption(m, "Toggle Ninja Pro", ::givePlayerPerk, "ninjaPro");
	self addOption(m, "Toggle Hacker Pro", ::givePlayerPerk, "hackerPro");
	self addOption(m, "Toggle Tactical Mask Pro", ::givePlayerPerk, "tacticalMaskPro");

	m = "ClassAttachment";
	self addOption(m, "Silencer", ::givePlayerAttachment, "silencer");
	self addOption(m, "Toggle Extended Clip", ::givePlayerAttachment, "extclip");
	self addOption(m, "Toggle Variable Zoom", ::givePlayerAttachment, "vzoom");
	self addOption(m, "Toggle IR", ::givePlayerAttachment, "ir");
	self addOption(m, "Toggle ACOG", ::givePlayerAttachment, "acog");
	self addOption(m, "Toggle Flamethrower", ::givePlayerAttachment, "ft");
	self addOption(m, "Toggle Maskerkey", ::givePlayerAttachment, "mk");
	self addOption(m, "Toggle Grenade Launcher", ::givePlayerAttachment, "gl");
	self addOption(m, "Toggle Dual Wield", ::givePlayerAttachment, "dw");
	self addOption(m, "Remove all attachments", ::removeAllAttachments);

	m = "ClassKillstreaks";
	self addOption(m, "RC-XD", ::giveUserKillstreak, "rcbomb_mp");
	self addOption(m, "Carepackage", ::giveUserKillstreak, "supply_drop_mp");
	self addOption(m, "Napalm Strike", ::giveUserKillstreak, "napalm_mp");
	self addOption(m, "Sentry Gun", ::giveUserKillstreak, "autoturret_mp");
	self addOption(m, "Valkyrie Rocket", ::giveUserKillstreak, "m220_tow_mp");
    
	m = "MainLobby";
	//addOption(m, "Backflip (Buggy)", ::toggleBackflip);
	if (!level.azza)
	{
		self addOption(m, "Add 1 minute", ::addMinuteToTimer);
		self addOption(m, "Remove 1 minute", ::removeMinuteFromTimer);
	}
	else if (level.azza)
	{
		self addOption(m, "Allow multiple setups", ::toggleMultipleSetups);
	}

	self addOption(m, "Add bot", ::addDummies);
	self addOption(m, "Toggle timer", ::toggleTimer);
	if (level.currentGametype == "tdm")
	{
		self addOption(m, "Fast last my team", ::fastLast);
		self addOption(m, "Reset enemy team score", ::resetEnemyTeamScore);
	}

	self addMenu(m, "ExtraSpawn", "^9Spawn Options");
	
	m = "ExtraSpawn";
	self addOption(m, "Spawn Bounce On Position", ::bounce);
	self addMenu(m ,"SpawnBounce", "^9Bounce Options");
	
	m = "SpawnBounce";
	self addOption(m, "Delete", ::deleteBounce);
	self addOption(m, "Invisible", ::invisibleBounce);
	self addOption(m, "Change Position", ::toggleMoveBounce);

	//WORKING
	self addMenu("main", "MainPlayers", "^9Players Menu");
	m = "MainPlayers";
	if (!level.teamBased)
	{
		for (p = 0; p < level.players.size; p++)
		{
			player = level.players[p];
			name = player.name;
			player_name = "player_" + name;
			if (p == 0 && self != level.players[0])
			{
				continue;
			}

			if (isDefined(player_name) && isAlive(player))
			{
				self addMenu(m, player_name, name + " (Alive)");
			}
			else if (isDefined(player_name) && !isAlive(player))
			{
				self addMenu(m, player_name, name + " (Dead)");
			}

			self addOption(player_name, "Teleport player to crosshair", ::teleportToCrosshair, player);
			self addOption(player_name, "Teleport player to myself", ::teleportToSelf, player);
			self addOption(player_name, "Kill Player", ::killPlayer, player);
			self addOption(player_name, "Teleport myself to player", ::teleportSelfTo, player);
			self addOption(player_name, "Freeze Player", ::freezePlayer, player);
			if (self isHost())
			{
				self addOption(player_name, "Kick Player", ::kickPlayer, player);
			}
			if (level.currentGametype != "sd")
			{
				self addOption(player_name, "Delete clantag", ::deleteClantag, player);
			}

			if (level.currentGametype == "dm")
			{
				self addOption(player_name, "Reset score", ::resetPlayerScore, player);
			}

			if (!level.azza && !player isHost())
			{
				self addOption(player_name, "Toggle menu access", ::toggleAdminAccess, player);
			}
		}
	}
	else if (level.teamBased)
	{
		myTeam = self.pers["team"];
		otherTeam = getOtherTeam(myTeam);
		
		self addMenu(m, "PlayerFriendly", "^9Friendly players");
		self addMenu(m, "PlayerEnemy", "^9Enemy players");

		for (p = 0; p < level.players.size; p++)
		{
			player = level.players[p];
			name = player.name;
			player_name = "player_" + name;
			if (p == 0 && self != level.players[0])
			{
				continue;
			}

			if (player.pers["team"] == myTeam)
			{
				m = "PlayerFriendly";

				if(isDefined(player_name) && isAlive(player))
				{
					self addMenu(m, player_name, name + " (Alive)");
				}
				else if(isDefined(player_name) && !isAlive(player))
				{
					self addMenu(m, player_name, name + " (Dead)");
				}
			}
			else if (player.pers["team"] == otherTeam)
			{
				m = "PlayerEnemy";

				if (isDefined(player_name) && isAlive(player))
				{
					self addMenu(m, player_name, name + " (Alive)");
				}
				else if (isDefined(player_name) && !isAlive(player))
				{
					self addMenu(m, player_name, name + " (Dead)");
				}
			}
			
			self addOption(player_name, "Teleport To Crosshair", ::teleportToCrosshair, player);
			self addOption(player_name, "Teleport To Self", ::teleportToSelf, player);
			self addOption(player_name, "Kill Player", ::killPlayer, player);
			self addOption(player_name, "Teleport Self To", ::teleportSelfTo, player);
			self addOption(player_name, "Freeze Player", ::freezePlayer, player);
			self addOption(player_name, "Kick Player", ::kickPlayer, player);
			if (level.currentGametype != "sd")
			{
				self addOption(player_name, "Delete clantag", ::deleteClantag, player);
			}

			if (!level.azza && !player isHost())
			{
				self addOption(player_name, "Toggle menu access", ::toggleAdminAccess, player);
			}
		}
	}
}
buildWeaponMenu()
{
	m = "ClassWeapon";
	self addMenu(m, "WeaponPrimary", "^9Primary");
	self addMenu(m, "WeaponSecondary", "^9Secondary");
	self addMenu(m, "WeaponDualWield", "^9Dual Wield");
	self addMenu(m, "WeaponGlitch", "^9Glitch");
	self addOption(m, "Take Weapon", ::takeUserWeapon);
	self addOption(m, "Drop Weapon", ::dropUserWeapon);
	
	m = "WeaponPrimary";
	self addMenu(m, "PrimarySMG", "^9SMG");
	self addMenu(m, "PrimaryAssault", "^9Assault");
	self addMenu(m, "PrimaryShotgun", "^9Shotgun");
	self addMenu(m, "PrimaryLMG", "^9LMG");
	self addMenu(m, "PrimarySniper", "^9Sniper");
	
	m = "PrimarySMG";
	self addOption(m, "MP5K", ::giveUserWeapon, "mp5k_mp");
	self addOption(m, "Skorpion", ::giveUserWeapon, "skorpion_mp");
	self addOption(m, "MAC11", ::giveUserWeapon, "mac11_mp");
	self addOption(m, "AK74u", ::giveUserWeapon, "ak74u_mp");
	self addOption(m, "UZI", ::giveUserWeapon, "uzi_mp");
	self addOption(m, "PM63", ::giveUserWeapon, "pm63_mp");
	self addOption(m, "MPL", ::giveUserWeapon, "mpl_mp");
	self addOption(m, "Spectre", ::giveUserWeapon, "spectre_mp");
	self addOption(m, "Kiparis", ::giveUserWeapon, "kiparis_mp");
	
	m = "PrimaryAssault";
	self addOption(m, "M16", ::giveUserWeapon, "m16_mp");
	self addOption(m, "Enfield", ::giveUserWeapon, "enfield_mp");
	self addOption(m, "M14", ::giveUserWeapon, "m14_mp");
	self addOption(m, "Famas", ::giveUserWeapon, "famas_mp");
	self addOption(m, "Galil", ::giveUserWeapon, "galil_mp");
	self addOption(m, "AUG", ::giveUserWeapon, "aug_mp");
	self addOption(m, "FN FAL", ::giveUserWeapon, "fnfal_mp");
	self addOption(m, "AK47", ::giveUserWeapon, "ak47_mp");
	self addOption(m, "Commando", ::giveUserWeapon, "commando_mp");
	self addOption(m, "G11", ::giveUserWeapon, "g11_mp");
	
	m = "PrimaryShotgun";
	self addOption(m, "Olympia", ::giveUserWeapon, "rottweil72_mp");
	self addOption(m, "Stakeout", ::giveUserWeapon, "ithaca_grip_mp");
	self addOption(m, "SPAS-12", ::giveUserWeapon, "spas_mp");
	self addOption(m, "HS10", ::giveUserWeapon, "hs10_mp");
	
	m = "PrimaryLMG";
	self addOption(m, "HK21", ::giveUserWeapon, "hk21_mp");
	self addOption(m, "RPK", ::giveUserWeapon, "rpk_mp");
	self addOption(m, "M60", ::giveUserWeapon, "m60_mp");
	self addOption(m, "Stoner63", ::giveUserWeapon, "stoner63_mp");
	
	m = "PrimarySniper";
	self addOption(m, "Dragunov", ::giveUserWeapon, "dragunov_mp");
	self addOption(m, "WA2000", ::giveUserWeapon, "wa2000_mp");
	self addOption(m, "L96A1", ::giveUserWeapon, "l96a1_mp");
	self addOption(m, "PSG1", ::giveUserWeapon, "psg1_mp");
	
	m = "WeaponSecondary";
	self addMenu(m, "SecondaryPistol", "^9Pistol");
	self addMenu(m, "SecondaryLauncher", "^9Launcher");
	self addMenu(m, "SecondarySpecial", "^9Special");
	
	m = "SecondaryPistol";
	self addOption(m, "ASP", ::giveUserWeapon, "asp_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarov_mp");
	self addOption(m, "Python", ::giveUserWeapon, "python_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75_mp");
	
	m = "SecondaryLauncher";
	self addOption(m, "M72 LAW", ::giveUserWeapon, "m72_law_mp");
	self addOption(m, "RPG", ::giveUserWeapon, "rpg_mp");
	self addOption(m, "Strela-3", ::giveUserWeapon, "strela_mp");
	self addOption(m, "China Lake", ::giveUserWeapon, "china_lake_mp");
	
	m = "SecondarySpecial";
	self addOption(m, "Ballistic Knife", ::giveUserWeapon, "knife_ballistic_mp");
	self addOption(m, "Crossbow", ::giveUserWeapon, "crossbow_explosive_mp");
	
	m = "WeaponDualWield";
	self addOption(m, "ASP", ::giveUserWeapon, "aspdw_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarovdw_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911dw_mp");
	self addOption(m, "Python", ::giveUserWeapon, "pythondw_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75dw_mp");
	self addOption(m, "HS10", ::giveUserWeapon, "hs10dw_mp");
	self addOption(m, "Skorpion", ::giveUserWeapon, "skorpiondw_mp");
	self addOption(m, "PM63", ::giveUserWeapon, "pm63dw_mp");
	self addOption(m, "Kiparis", ::giveUserWeapon, "kiparisdw_mp");

	m = "WeaponGlitch";
	self addOption(m, "ASP", ::giveUserWeapon, "asplh_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911lh_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarovlh_mp");
	self addOption(m, "Python", ::giveUserWeapon, "pythonlh_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75lh_mp");
	self addOption(m, "Syrette", ::giveUserWeapon, "syrette_mp");
	self addOption(m, "Briefcase Bomb", ::giveUserWeapon, "briefcase_bomb_mp");
	self addOption(m, "Autoturret", ::giveUserWeapon, "autoturret_mp");
}
/*MENU FUNCTIONS*/
isAdmin()
{
	if (self.isAdmin)
	{
		return true;
	}

	return false;
}
toggleAdminAccess(player)
{
	if (!player.isAdmin)
	{
		player.isAdmin = true;
		player thread runController();
		player iPrintln("Menu access ^2Given");
		player iPrintln("Open with [{+speed_throw}] & [{+actionslot 2}]");
		self printInfoMessage("Menu access ^2Given ^7to " + player.name);
	}
	else 
	{
		player.isAdmin = false;
		player iPrintln("Menu access ^1Removed");
		self printInfoMessage("Menu access ^1Removed ^7from " + player.name);
	}
}
closeMenuOnDeath()
{
	self endon("exit_menu");

	self waittill("death");
	
	self ClearAllTextAfterHudelem();
	self thread exitMenu();
}

openMenu(menu)
{
	self.isInMenu = true;
	self.currentMenu = menu;
	currentMenu = self getCurrentMenu();
	if (currentMenu == self.menus["MainPlayers"])
	{
		self thread buildMenu();
	}

	self.currentMenuPosition = currentMenu.position;
	self thread closeMenuOnDeath();
	self TakeWeapon("knife_mp");
	self AllowJump(false);
	self DisableOffHandWeapons();
	self UpdateShaderIcons(currentMenu);
	for (i = 0; i < self.getEquipment.size; i++)
	{
		self.curEquipment = self.getEquipment[i];

		switch (self.curEquipment)
		{
			case "claymore_mp":
			case "c4_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
				self TakeWeapon(self.curEquipment);
				break;
			default:
				break;
		}
	}

	self thread drawMenu(currentMenu);
}

closeMenu()
{
	currentMenu = self getCurrentMenu();

	if (currentMenu.parent == "" || !isDefined(currentMenu.parent))
	{
		self thread exitMenu();
	}
	else
	{
		self thread openMenu(currentMenu.parent);
	}

	if (self.weaponShadersDrawn)
	{
		self thread destroyWeaponShaders();
	}
}

exitMenu()
{
	self.isInMenu = false;
	
	self thread destroyMenu();
	
	self GiveWeapon("knife_mp");
	self AllowJump(true);
	self EnableOffHandWeapons();
	for (i = 0; i < self.getEquipment.size; i++)
	{
		self.curEquipment = self.getEquipment[i];

		switch (self.curEquipment)
		{
			case "claymore_mp":
			case "c4_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
				self GiveWeapon(self.curEquipment);
				self GiveStartAmmo(self.curEquipment);
				break;
			default:
				self GiveWeapon("claymore_mp");
				self GiveStartAmmo("claymore_mp");
				break;
		}
	}

	self.infoMessage.alpha = 0;
	self ClearAllTextAfterHudelem();
	
	self notify("exit_menu");
}

select()
{
	selected = self getHighlightedOption();

	if (isDefined(selected.function))
	{
		if (isDefined(selected.argument))
		{
			self thread [[selected.function]](selected.argument);
		}
		else
		{
			self thread [[selected.function]]();
		}
	}
}

scrollUp()
{
	self thread scroll(-1);
}

scrollDown()
{
	self thread scroll(1);
}

scroll(number)
{
	currentMenu = self getCurrentMenu();
	optionCount = currentMenu.options.size;
	textCount = self.menuOptions.size;

	oldPosition = currentMenu.position;
	newPosition = currentMenu.position + number;
	
	if (newPosition < 0)
	{
		newPosition = optionCount - 1;
	}
	else if (newPosition > optionCount - 1)
	{
		newPosition = 0;
	}

	currentMenu.position = newPosition;
	self.currentMenuPosition = newPosition;
	self UpdateShaderIcons(currentMenu);

	self thread moveScrollbar();
}

moveScrollbar()
{
	self.menuScrollbar1.y = self.yAxis + (self.currentMenuPosition * 15);
}

addMenu(parent, name, title)
{
	menu = spawnStruct();
	menu.parent = parent;
	menu.name = name;
	menu.title = title;
	menu.options = [];
	menu.position = 0;

	self.menus[name] = menu;
	
	getMenu(name);
	
	if (isDefined(parent))
	{
		self addOption(parent, title, ::openMenu, name);
	}
}

addOption(parent, label, function, argument)
{
	menu = self getMenu(parent);
	index = menu.options.size;

	menu.options[index] = spawnStruct();
	menu.options[index].label = label;
	menu.options[index].function = function;
	menu.options[index].argument = argument;
}

getCurrentMenu()
{
	return self.menus[self.currentMenu];
}

getHighlightedOption()
{
	currentMenu = self getCurrentMenu();
	
	return currentMenu.options[currentMenu.position];
}

getMenu(name)
{
	return self.menus[name];
}

drawMenu(currentMenu)
{
	if (self.shadersDrawn)
	{
		self thread moveScrollbar();
	}
	else
	{
		self thread drawShaders();
	}

	if (self.textDrawn)
	{
		self thread updateText();
	}
	else
	{
		self thread drawText();
	}
}

drawShaders()
{
	self.menuBackground = createRectangle("CENTER", "CENTER", -250, 0, 200, 250, 1, "black");
	self.menuBackground setColor(0, 0, 0, 1);
	self.menuScrollbar1 = createRectangle("CENTER", "TOP", -250, self.yAxis + (15 * self.currentMenuPosition), 200, 35, 2, "score_bar_bg");
	self.menuScrollbar1 setColor(1, 1, 1, 1);
	
	self.shadersDrawn = true;
}
drawWeaponShaders(currentWeaponDisplay, width) //weapon 45
{
	self.weaponShaders = createRectangle("CENTER", "CENTER", -250, self.yAxisWeapons - 265, width, 25, 2, currentWeaponDisplay);
	self.weaponShaders setColor(1,1,1,1);

	self.weaponShadersDrawn = true;
}
destroyWeaponShaders()
{
	self.weaponShaders destroy();

	self.weaponShadersDrawn = false;
}
drawMessages()
{
	self.infoMessage = self createText2("default", 1, " ", "CENTER", "CENTER", -250, 100, 3, 0, (1, 1, 1));
	//self.infoMessage.archived = false;
	self.ufoMessage1 = self createText2("default", 1, " ", "LEFT", "CENTER", -370, -10, 3, 0, (1, 1, 1));
	self.ufoMessage1.archived = false;
	self.ufoMessage2 = self createText2("default", 1, " ", "LEFT", "CENTER", -370, 5, 3, 0, (1, 1, 1));
	self.ufoMessage2.archived = false;
	self.ufoMessage3 = self createText2("default", 1, " ", "LEFT", "CENTER", -370, 20, 3, 0, (1, 1, 1));
	self.ufoMessage3.archived = false;
	self.infoMessageNoMenu = self createText2("default", 1, " ", "LEFT", "CENTER", -370, -100, 3, 0, (1, 1, 1));
	self.infoMessageNoMenu.archived = false;
}
drawText()
{
	self.menuTitle = self createText("objective", 1.3, "CENTER", "TOP", -250, self.yAxis - 50, 3, "");
	self.menuTitle setColor(1, 1, 1, 1);
	self.menuTitle.archived = false;

	for (i = 0; i < 11; i++)
	{
		self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", -250, self.yAxis + (15 * i), 3, "");
	}

	self.textDrawn = true;
	
	self thread updateText();
}
elemFade(time, alpha)
{
    self fadeOverTime(time);
    self.alpha = alpha;
}
updateText()
{
	currentMenu = self getCurrentMenu();
	
	self.menuTitle setText(self.menus[self.currentMenu].title);
	for (i = 0; i < self.menuOptions.size; i++)
	{
		optionString = "";

		if (isDefined(self.menus[self.currentMenu].options[i]))
		{
			optionString = self.menus[self.currentMenu].options[i].label;
		}

		self.menuOptions[i] setText(self.menus[self.currentMenu].options[i].label);
	}
}

UpdateShaderIcons(currentMenu)
{
	currentMenuName = currentMenu.name;
	if (isWeaponMenu(currentMenu) || currentMenuName == "CamoOne" || currentMenuName == "CamoTwo")
	{
		if (self.weaponShadersDrawn)
		{
			self thread destroyWeaponShaders();
		}

		currentWeaponDisplay = weaponNameToShader(currentMenu.options[currentMenu.position].label);
		if (!self.weaponShadersDrawn)
		{
			self thread drawWeaponShaders(currentWeaponDisplay, 45);
		}
	}

	if (currentMenuName == "ClassAttachment" || currentMenuName == "ClassPerk" || currentMenuName == "ClassKillstreaks")
	{
		if (self.weaponShadersDrawn)
		{
			self thread destroyWeaponShaders();
		}

		currentWeaponDisplay = weaponNameToShader(currentMenu.options[currentMenu.position].label);
		if (!self.weaponShadersDrawn)
		{
			self thread drawWeaponShaders(currentWeaponDisplay, 25);
		}
	}
}

destroyMenu()
{
	self thread destroyShaders();
	self thread destroyText();
	self.hasAdded = false;
	self.hasOptionsAdded = false;
}

destroyShaders()
{
	self.menuBackground destroy();
	self.menuTitleDivider destroy();
	self.menuScrollbar1 destroy();
	
	self.shadersDrawn = false;
}

destroyText()
{
	self.menuTitle destroy();
	for ( o = 0; o < self.menuOptions.size; o++)
	{
		self.menuOptions[o] destroy();
		self iprintln(self.menuOptions[o].label);
	}

	self.textDrawn = false;
}

createText( font , fontScale , point , relative , xOffset , yOffset , sort , hideWhenInMenu , text )
{
    textElem = createFontString( font , fontScale );
    textElem setText( text );
    textElem setPoint( point , relative , xOffset , yOffset );
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    return textElem;
}
createText2(font, fontScale, text, point, relative, xOffset, yOffset, sort, alpha, color)
{
    textElem = createFontString(font, fontScale);
    textElem setText(text);
    textElem setPoint( point, relative, xOffset, yOffset );
    textElem.sort = sort;
    textElem.alpha = alpha;
    textElem.color = color;
    return textElem;
}

createRectangle( align , relative , x , y , width , height , sort , shader )
{
    barElemBG = newClientHudElem( self );
    barElemBG.elemType = " bar ";
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG setParent( level.uiParent );
    barElemBG setShader( shader , width , height );
    barElemBG.hidden = false;
    barElemBG setPoint( align , relative , x , y );
    return barElemBG;
}

setColor(r, g, b, a)
{
	self.color = (r, g, b);
	self.alpha = a;
}

setGlow(r, g, b, a)
{
	self.glowColor = (r, g, b);
	self.glowAlpha = a;
}

printInfoMessage(text)
{
	self.infoMessage setText(text);
	self.infoMessage.alpha = 1;
	self.infoMessage elemFade(2.5, 0);
}

printInfoMessageNoMenu(text)
{
	self.infoMessageNoMenu setText(text);
	self.infoMessageNoMenu.alpha = 1;
	self.infoMessageNoMenu elemFade(2.5, 0);
}

printUFOMessage1(text)
{
	self.ufoMessage1 setText(text);
	self.ufoMessage1.alpha = 1;
}

ufoMessage1Fade()
{
	self.ufoMessage1 elemFade(2.5, 0);
}

printUFOMessage2(text)
{
	self.ufoMessage2 setText(text);
	self.ufoMessage2.alpha = 1;
}

ufoMessage2Fade()
{
	self.ufoMessage2 elemFade(2.5, 0);
}

printUFOMessage3(text)
{
	self.ufoMessage3 setText(text);
	self.ufoMessage3.alpha = 1;
}

ufoMessage3Fade()
{
	self.ufoMessage3 elemFade(2.5, 0);
}

/*FUNCTIONS*/
vectorScale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

onPlayerDamageHook(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	IsClose = Distance(self.origin, eattacker.origin) < 500;

	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE" && level.azza)
	{
		if (sMeansOfDeath == "MOD_MELEE")
		{
			iDamage = 1;
		}
		else if (einflictor != eattacker && sweapon == "hatchet_mp" && !IsClose)
		{
			iDamage = 10000000;
		}
		else if (einflictor != eattacker && sweapon == "knife_ballistic_mp" && !IsClose)
		{
			iDamage = 10000000;
		}
		else if (maps\mp\gametypes\_missions::getWeaponClass(sWeapon) == "weapon_sniper")
		{
			iDamage = 10000000;
		}
		else
		{
			iDamage = 1;
		}

		if (sHitLoc == "head")
		{
			setDvar("scr_sd_score_kill", "1100");
		}
		else
		{
			setDvar("scr_sd_score_kill", "550");
		}
	}
	else if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE" && !level.azza) 
	{
		if (maps\mp\gametypes\_missions::getWeaponClass( sWeapon ) == "weapon_sniper")
		{
			iDamage = 10000000;
		}
		else 
		{
			iDamage -= 5;
		}
	}
	
	if (sMeansOfDeath != "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath != "MOD_FALLING" || eattacker.classname == "trigger_hurt") 
	{
		self.attackers = undefined;
	}

	[[level.onPlayerDamageStub]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE" && level.azza)
	{
		if (maps\mp\gametypes\_missions::getWeaponClass(sWeapon) == "weapon_sniper" && iDamage == 10000000)
		{
			if (level.multipleSetupsEnabled)
			{
				level beginFinalKillcam(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			}
		}
	}
}

beginFinalKillcam(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	deathTimeOffset = (gettime() - self.lastStandParams.lastStandStartTime) / 1000;
	attacker = eAttacker;
	
	lpattacknum = self getEntityNumber();
	
	killcamentity = self maps\mp\gametypes\_globallogic_player::getKillcamEntity( attacker, eInflictor, sWeapon );
	killcamentityindex = -1;
	killcamentitystarttime = 0;
	if (isDefined(killcamentity))
	{
		killcamentityindex = killcamentity getEntityNumber(); 
		if (isdefined( killcamentity.startTime))
		{
			killcamentitystarttime = killcamentity.startTime;
		}
		else
		{
			killcamentitystarttime = killcamentity.birthtime;
		}

		if (!isdefined(killcamentitystarttime))
		{
			killcamentitystarttime = 0;
		}
	}

	perks = maps\mp\gametypes\_globallogic::getPerks(attacker);
	killstreaks = maps\mp\gametypes\_globallogic::getKillstreaks(attacker);
	level.finalkillcam = true;

	level thread maps\mp\gametypes\_killcam::startFinalKillcam(lpattacknum, self getEntityNumber(), killcamentity, killcamentityindex, killcamentitystarttime, sWeapon, self.deathTime, deathTimeOffset, psOffsetTime, perks, killstreaks, attacker);

	maps\mp\gametypes\sd::sd_endGame("allies", game["strings"]["axis_eliminated"]);
}

enterUfoMode()
{
	if (!self.ufoEnabled)
	{
		self thread ufoMode();
		self.ufoEnabled = true;
		self enableInvulnerability();
		self DisableOffHandWeapons();
		self TakeWeapon("knife_mp");
	}
}

stopUFOMode()
{
	if (self.ufoEnabled)
	{
		self unlink();
		self thread ufoMessage1Fade();
		self thread ufoMessage2Fade();
		self thread printInfoMessageNoMenu("UFO mode ^1Disabled");
		self enableOffHandWeapons();
		if (!self.godmodeEnabled)
		{
			self disableInvulnerability();
		}

		if (!self.isInMenu)
		{
			self giveWeapon("knife_mp");
		}

		self.originObj delete();
		self.ufoEnabled = false;
		self notify("stop_ufo");
	}
}

ufoMode()
{
	self endon("disconnect");
   	self endon("stop_ufo");
   
	self.originObj = spawn("script_origin", self.origin);
	self.originObj.angles = self.angles;
	
	self linkTo(self.originObj);
	
	self thread printUFOMessage1("Hold [{+frag}] or [{+smoke}] to move");
	self thread printUFOMessage2("Press [{+melee}] to stop");
	
	for (;;)
	{
		if (self fragbuttonpressed() && !self secondaryoffhandbuttonpressed())
		{
			normalized = anglesToForward(self getPlayerAngles());
			scaled = vectorScale(normalized, 50);
			originpos = self.origin + scaled;
			self.originObj.origin = originpos;
		}

		if (self secondaryoffhandbuttonpressed() && !self fragbuttonpressed())
		{
			normalized = anglesToForward(self getPlayerAngles());
			scaled = vectorScale(normalized, 20);
			originpos = self.origin + scaled;
			self.originObj.origin = originpos;
		}

		if (self meleebuttonpressed())
		{
			self thread stopUFOMode();
		}

		wait 0.05;
	}
}

setMatchBonus()
{
	UpdateMatchBonusScores(self.pers["team"]);
}

giveEssentialPerks()
{
	if (level.azza)
	{
		//Lightweight
		self setPerk("specialty_movefaster");
		self setPerk("specialty_fallheight");
	}

	//Hardened
	self SetPerk("specialty_bulletpenetration");
	self SetPerk("specialty_armorpiercing");
	self SetPerk("specialty_bulletflinch");
	//Steady Aim
	self SetPerk("specialty_bulletaccuracy");
	self SetPerk("specialty_sprintrecovery");
	self SetPerk("specialty_fastmeleerecovery");
	//Marathon
	self SetPerk("specialty_unlimitedsprint");

	//No last stand
	if (self hasSecondChance())
	{
		self UnSetPerk("specialty_pistoldeath");
		/*Second Chance replaced by Hacker*/
		self SetPerk("specialty_detectexplosive");
		self SetPerk("specialty_showenemyequipment");
	}
	else if (self hasSecondChancePro())
	{
		self UnSetPerk("specialty_pistoldeath");
		self UnSetPerk("specialty_finalstand");
		/*Second Chance Pro replaced by Hacker*/
		self SetPerk("specialty_detectexplosive");
		self SetPerk("specialty_showenemyequipment");
	}
}

hasSecondChance()
{
	if (self HasPerk("specialty_pistoldeath") && !self HasPerk("specialty_finalstand"))
	{
		return true;
	}
	
	return false;
}

hasSecondChancePro()
{
	if (self HasPerk("specialty_pistoldeath") && self HasPerk("specialty_finalstand"))
	{
		return true;
	}

	return false;
}

toggleGodmode()
{
	if (!self.godmodeEnabled)
	{
		self EnableInvulnerability();
		self thread printInfoMessage("Godmode ^2Enabled");
		self.godmodeEnabled = true;
	}
	else
	{
		self DisableInvulnerability();
		self thread printInfoMessage("Godmode ^1Disabled");
		self.godmodeEnabled = false;
	}
}

toggleInvisible()
{
	if (!self.invisibleEnabled)
	{
		self hide();
		self setInvisibleToAll();
		self thread printInfoMessage("Invisible ^2Enabled");
		self.invisibleEnabled = true;
	}
	else
	{
		self show();
		self setVisibleToAll();
		self thread printInfoMessage("Invisible ^1Disabled");
		self.invisibleEnabled = false;
	}
}

ToggleThirdPerson()
{
	if (!self.thirdPersonEnabled)
	{
		self setClientDvar( "cg_thirdPerson", "1" );
		self.thirdPersonEnabled = true;
	}
	else
	{
		self setClientDvar( "cg_thirdPerson", "0" );
		self.thirdPersonEnabled = false;
	}
}

doSuicide()
{
	self suicide();
	self.currentMenu = "main";
}

randomCamo()
{
	numEro = randomIntRange(1, 16);
	
	weap = self getCurrentWeapon();
	
	myclip = self getWeaponAmmoClip(weap);
    mystock = self getWeaponAmmoStock(weap);
	
	self takeWeapon(weap);
	weaponOptions = self calcWeaponOptions(numEro, 0, 0, 0, 0);
	self GiveWeapon(weap, 0, weaponOptions);
	self switchToWeapon(weap);
	self setSpawnWeapon(weap);
	
	self setweaponammoclip(weap, myclip);
    self setweaponammostock(weap, mystock);
	self.camo = numEro;
}

changeCamo(num)
{
	weap = self getCurrentWeapon();
	
	myclip = self getWeaponAmmoClip(weap);
    mystock = self getWeaponAmmoStock(weap);
	
	self takeWeapon(weap);
	weaponOptions = self calcWeaponOptions(num, 0, 0, 0, 0);
	self GiveWeapon(weap, 0, weaponOptions);
	self switchToWeapon(weap);
	self setSpawnWeapon(weap);
	
	self setweaponammoclip(weap, myclip);
    self setweaponammostock(weap, mystock);
	
	self.camo = num;
}

giveUserKillstreak(killstreak)
{
	self maps\mp\gametypes\_hardpoints::giveKillstreak(killstreak);
	self thread printInfoMessage(killstreak + " ^2Given");
}

giveUserWeapon(weapon)
{
	self GiveWeapon(weapon);
	self GiveStartAmmo(weapon);
	self SwitchToWeapon(weapon);
}

takeUserWeapon()
{
	self TakeWeapon(self GetCurrentWeapon());
}

dropUserWeapon()
{
	self dropItem(self GetCurrentWeapon());
}

addMinuteToTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 1);
	self thread printInfoMessage("Minute ^2added");
}

removeMinuteFromTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit - 1);
	self thread printInfoMessage("Minute ^2removed");
}

toggleTimer()
{
	if (!level.timerPaused)
	{
		maps\mp\gametypes\_globallogic_utils::pausetimer();
		self thread printInfoMessage("Timer ^2paused");
		level.timerPaused = true;
	}
	else 
	{
		self maps\mp\gametypes\_globallogic_utils::resumetimer();
		self thread printInfoMessage("Timer ^2resumed");
		level.timerPaused = false;
	}
}

saveLoadout()
{
	self.primaryWeapons = self GetWeaponsListPrimaries();
	self.offHandWeapons = array_exclude(self GetWeaponsList(), self.primaryWeapons);
	self.offHandWeapons = array_remove(self.offHandWeapons, "knife_mp");

	self.saveLoadoutEnabled = true;

	self thread printInfoMessage("Weapons ^2saved^7.");
	wait 1.5;
	self thread printInfoMessage("You will have them next time you spawn!");
}

loadLoadout()
{
	self TakeAllWeapons();

	for (i = 0; i < self.primaryWeapons.size; i++)
	{
		if (isDefined(self.camo))
		{
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		else 
		{
			self.camo = 15;
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}

		weapon = self.primaryWeapons[i];
		
		self GiveWeapon(weapon, 0, weaponOptions);
	}

	self switchToWeapon(self.primaryWeapons[1]);
	self setSpawnWeapon(self.primaryWeapons[1]);

	for (i = 0; i < self.offHandWeapons.size; i++)
	{
		weapon = self.offHandWeapon[i];
		self GiveWeapon(weapon);
	}

	self GiveWeapon("knife_mp");

	for (i = 0; i < self.offHandWeapons.size; i++)
	{
		weapon = self.offHandWeapons[i];
		if (isHackWeapon(weapon) || isLauncherkWeapon(weapon))
		{
			continue;
		}

		switch (weapon)
		{
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock( weapon );
				if( self HasPerk( "specialty_twogrenades" ) )
					ammo = stock + 1;
				else
					ammo = stock;
				self SetWeaponAmmoStock( weapon, ammo );
				break;
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
			case "tabun_gas_mp":
			case "nightingale_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock( weapon );
				if( self HasPerk( "specialty_twogrenades" ) )
					ammo = stock + 1;
				else
					ammo = stock;
				self SetWeaponAmmoStock( weapon, ammo );
				break;
			case "willy_pete_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock( weapon );
				ammo = stock;
				self SetWeaponAmmoStock( weapon, ammo );
				break;
			default:
				break;
		}
	}

	for (i = 0; i < self.getEquipment.size; i++)
	{
		equipment = self.getEquipment[i];

		switch (equipment)
		{
			case "claymore_mp":
			case "c4_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
				self GiveWeapon(equipment);
				break;
			default:
				break;
		}
	}
}

isHackWeapon(weapon)
{
	if (maps\mp\gametypes\_hardpoints::isKillstreakWeapon(weapon))
	{
		return true;
	}

	if (weapon == "briefcase_bomb_mp")
	{
		return true;
	}

	return false;
}

isLauncherkWeapon(weapon)
{
	if (GetSubStr(weapon, 0, 2) == "gl_")
	{
		return true;
	}
	
	switch(weapon)
	{
		case "china_lake_mp":
		case "rpg_mp":
		case "strela_mp":
		case "m220_tow_mp_mp":
		case "m72_law_mp":
		case "m202_flash_mp":
			return true;
		default:
			return false;
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

	self thread printInfoMessage("Ammo ^2refilled");
}

killPlayer(player)
{
	player suicide();
	self thread printInfoMessage("^2Killed ^7" + player.name);
}

teleportSelfTo(player)
{
	self SetOrigin(player.origin);
}

teleportToSelf(player)
{
	player SetOrigin(self.origin);
}

teleportToCrosshair(player)
{
	player setOrigin(bullettrace(self gettagorigin("j_head"), self gettagorigin("j_head") + anglesToForward(self getplayerangles()) * 1000000, 0, self)["position"]);
}

toggleBackflip()
{
	if (!self.backflipEnabled)
	{
		self setclientdvar("player_view_pitch_down", "90");
		self setclientdvar("player_view_pitch_up", "90");
		self.backflipEnabled = true;
		self thread allowBackflip();
		self thread printInfoMessage("Backflip ^2Enabled");
	}
	else 
	{
		self setclientdvar("player_view_pitch_down", "85");
		self setclientdvar("player_view_pitch_up", "85");
		self.backflipEnabled = false;
		self thread printInfoMessage("Backflip ^1Disabled");
		self notify("stop_backflip");
	}
}

allowBackflip()
{
	self endon("disconnect");
	self endon("stop_backflip");
	
	for (;;)
	{
		angles = self GetPlayerAngles();
		if (angles[0] == -90)
		{
			setdvar( "controls_inversionConfig", "inversion_enabled" );
			self SetPlayerAngles(angles - (5,180,-180));
		}

		if (angles[0] == 90)
		{
			setdvar( "controls_inversionConfig", "inversion_enabled" );
			self SetPlayerAngles(angles + (5,180,-180));
		}

		setdvar( "controls_inversionConfig", "inversion_disabled" );
		wait 0.05;
	}
}

checkIfBotHasToSpawn()
{
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		if (player is_bot())
		{
			level.spawned_bots++;
		}
	}

	if (level.spawned_bots == 0)
	{
		self thread addDummies();
	}
}

addDummies()
{
	level.spawned_bots++;
	team = self.pers["team"];
	otherTeam = getOtherTeam(team);

	bot = AddTestClient();
	bot.pers["isBot"] = true;
	bot thread maps\mp\gametypes\_bot::bot_spawn_think(otherTeam);
	bot setClientDvar("UpdateGamerProfile", "1");
	bot ClearPerks();
}

changeName(input)
{
	self setClientDvar( "name", input );
	self setClientDvar("UpdateGamerProfile", "1");
}

changeClanTag(input)
{
	self setClientDvar("clanName", input);
	self setClientDvar("UpdateGamerProfile", "1");
}

freezePlayer(player)
{
	if (!player.isFrozen)
	{
		player FreezeControlsAllowLook(true);
		player.isFrozen = true;
		self printInfoMessage(player.name + " is ^2frozen");
	}
	else 
	{
		player FreezeControlsAllowLook(false);
		player.isFrozen = false;
		self printInfoMessage(player.name + " is ^2unfrozen");
	}
}

kickPlayer(player)
{
	kick(player getEntityNumber());
	if (player is_bot())
	{
		level.spawned_bots--;
	}
}

bounce()
{
	if (level.bounceSpawned == 0)
	{
		level.modelBounce = spawn( "script_model", self.origin );
		level.modelBounce setModel("mp_supplydrop_ally");
		level.bounceSpawned++;
		self thread printInfoMessage("Bounce ^2Spawned^7 on your position!");
		
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			player thread monitorTrampoline();
		}
	}
	else 
	{
		self thread printInfoMessage("Only can spawn ^1one^7 bounce");
	}
}

monitorTrampoline()
{
	self endon("disconnect");
	self endon("stop_bounce");
	
	for (;;)
	{
		if (distance(self.origin, level.modelBounce.origin) < 50) 
		{
			self thread playFxAndSound();
			
			self setVelocity(self getVelocity() + (0, 0, 999));
			x = 0;
			while (x < 8)
			{
				self setVelocity(self getVelocity() + (0, 0, 999));
				x++;
				wait 0.01;
			}
		}

		wait 0.01;
	}
}

playFxAndSound()
{
	self playLocalSound("fly_land_damage_npc");
	playFx(level._effect["footprint"], self getTagOrigin("J_Ankle_RI"));
	playFx(level._effect["footprint"], self getTagOrigin("J_Ankle_LE"));
}

deleteBounce()
{
	if (level.bounceSpawned == 1)
	{
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			player notify("stop_bounce");
		}

		level.modelBounce delete();
		self thread printInfoMessage("Bounce ^2deleted");
		level.bounceSpawned = 0;
	}
	else 
	{
		self thread printInfoMessage("^1No ^7bounce spawned");
	}
}

invisibleBounce()
{
	if (level.bounceSpawned == 1)
	{	
		if (!level.bounceInvisible)
		{
			level.modelBounce hide();
			level.bounceInvisible = true;
			self thread printInfoMessage("Bounce is now ^2Invisible");
		}
		else
		{
			level.modelBounce show();
			level.bounceInvisible = false;
			self thread printInfoMessage("Bounce is now ^2Visible");
		}
	}
	else 
	{
		self thread printInfoMessage("^1No ^7bounce spawned");
	}
}

toggleMoveBounce()
{
	if (level.bounceSpawned == 1)
	{
		if (!self.movingBounce)
		{
			self thread exitMenu();
			self thread moveBounce();
			self.movingBounce = true;
		}
		else if (self.movingBounce)
		{
			self thread ufoMessage1Fade();
			self thread ufoMessage2Fade();
			self thread ufoMessage3Fade();
			self notify("stop_moveBounce");
			self enableoffhandweapons();
			self.movingBounce = false;
		}
	}
	else 
	{
		self thread printInfoMessage("^1No ^7bounce spawned");
	}
}

moveBounce()
{
	self endon("disconnect");
	self endon("stop_moveBounce");
	
	self thread printUFOMessage1("Press [{+speed_throw}] to ^3Move the Bounce");
	self thread printUFOMessage2("Press [{+smoke}]/[{+frag}] to ^3Rotate ^7/ ^3Roll");
	self thread printUFOMessage3("Press [{+melee}] to ^1Stop ^7moving the Bounce");
	self disableoffhandweapons();
	
	for (;;)
	{
		while (self adsbuttonpressed() && !self fragbuttonpressed() && !self secondaryOffHandButtonPressed() && !self actionSlottwoButtonPressed())
		{
			level.modelBounce.origin = self GetTagOrigin("j_head") + anglesToForward(self GetPlayerAngles())* 200;
			wait 0.05;
		}

		while (self fragbuttonpressed() && !self secondaryOffHandButtonPressed() && !self actionSlottwoButtonPressed())
		{
			level.modelBounce rotateyaw(5,0.05);
			wait 0.001;
		}

		while (self secondaryoffhandbuttonpressed() && !self fragbuttonpressed() && !self actionSlottwoButtonPressed())
		{
			level.modelBounce rotateroll(5,0.05);
			wait 0.001;
		}

		if (self MeleeButtonPressed())
		{
			self thread toggleMoveBounce();
			wait 0.12;
		}

		wait 0.05;
	}
}

defaultTrickshotClass()
{	
	self ClearPerks();
	self TakeAllWeapons();

	self thread exitMenu();
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

fastLast()
{
	if (level.currentGametype == "dm")
	{
		self.kills = 29;
		self _setPlayerScore(self, 1450);
	}
	else if (level.currentGametype == "tdm")
	{
		self _setTeamScore(self.pers["team"], 7400);
	}
}

addTimeToGame()
{
	self endon("disconnect");
	
	firstTime = true;
	for (;;)
	{
		timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec
		if (timeLeft < 1500 && firstTime)
		{
			timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
			setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 2.5); //2.5 equals to 2 min ingame in this case
			firstTime = false;
		}

		wait 0.5;
	}
}

deleteClantag(player)
{
	player setClientdvar("clanName", "");
	self printInfoMessage("Clantag ^2deleted");
}

printOrigin()
{
	self iprintln(self.origin);
}

launchRocketMonitor()
{
	self endon("disconnect");
	self endon("stop_rocketMonitor");

	rocketOrigin = (1377.72, 407.272, -344.875);
	for (;;)
	{
		timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec

		if (timeLeft < 50000)
		{
			if (Distance(self.origin, rocketOrigin) < 400)
			{
				if (!self.godmodeEnabled)
				{
					self iprintln("Godmode ^2Enabled");
					self EnableInvulnerability();
					wait 10;
					self DisableInvulnerability();
					self iPrintln("Godmode ^1Disabled");
				}
			}

			self notify("stop_rocketMonitor");
		}

		wait 1;
	}
}

givePlayerPerk(perkDesk)
{
	switch (perkDesk)
	{
		case "lightweightPro":
			self thread toggleLightweightPro();
			break;
		case "flakJacketPro":
			self thread toggleFlakJacketPro();
			break;
		case "scoutPro":
			self thread toggleScoutPro();
			break;
		case "sleightOfHandPro":
			self thread toggleSleightOfHandPro();
			break;
		case "ninjaPro":
			self thread toggleNinjaPro();
			break;
		case "hackerPro":
			self thread toggleHackerPro();
			break;
		case "tacticalMaskPro":
			self thread toggleTacticalMaskPro();
			break;
		default:
			self printInfoMessage("An ^1error ^7occured");
			break;
	}
}

toggleLightweightPro()
{
	if (self HasPerk("specialty_fallheight") && self hasPerk("specialty_movefaster"))
	{
		self UnSetPerk("specialty_fallheight");
		self UnSetPerk("specialty_movefaster");
		self printInfoMessage("Lightweight Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_fallheight");
		self SetPerk("specialty_movefaster");
		self printInfoMessage("Lightweight Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_lightweight_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleFlakJacketPro()
{
	if (self HasPerk("specialty_flakjacket") && self hasPerk("specialty_fireproof") && self hasPerk("specialty_pin_back"))
	{
		self UnSetPerk("specialty_flakjacket");
		self UnSetPerk("specialty_fireproof");
		self UnSetPerk("specialty_pin_back");
		self printInfoMessage("Flak Jacket Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_flakjacket");
		self SetPerk("specialty_fireproof");
		self SetPerk("specialty_pin_back");
		self printInfoMessage("Flak Jacket Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_flak_jacket_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleScoutPro()
{
	if (self HasPerk("specialty_holdbreath") && self hasPerk("specialty_fastweaponswitch"))
	{
		self UnSetPerk("specialty_holdbreath");
		self UnSetPerk("specialty_fastweaponswitch");
		self printInfoMessage("Scout Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_holdbreath");
		self SetPerk("specialty_fastweaponswitch");
		self printInfoMessage("Scout Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_scout_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleSleightOfHandPro()
{
	if (self HasPerk("specialty_fastreload") && self hasPerk("specialty_fastads"))
	{
		self UnSetPerk("specialty_fastreload");
		self UnSetPerk("specialty_fastads");
		self printInfoMessage("Sleight of Hand Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_fastreload");
		self SetPerk("specialty_fastads");
		self printInfoMessage("Sleight of Hand Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_sleight_of_hand_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleNinjaPro()
{
	if (self HasPerk("specialty_quieter") && self hasPerk("specialty_loudenemies"))
	{
		self UnSetPerk("specialty_quieter");
		self UnSetPerk("specialty_loudenemies");
		self printInfoMessage("Ninja Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_quieter");
		self SetPerk("specialty_loudenemies");
		self printInfoMessage("Ninja Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_ninja_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleHackerPro()
{
	if (self HasPerk("specialty_detectexplosive") && self hasPerk("specialty_showenemyequipment") && self hasPerk("specialty_disarmexplosive") && self hasPerk("specialty_nomotionsensor"))
	{
		self UnSetPerk("specialty_detectexplosive");
		self UnSetPerk("specialty_showenemyequipment");
		self UnSetPerk("specialty_disarmexplosive");
		self UnSetPerk("specialty_nomotionsensor");
		self printInfoMessage("Hacker Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_detectexplosive");
		self SetPerk("specialty_showenemyequipment");
		self SetPerk("specialty_disarmexplosive");
		self SetPerk("specialty_nomotionsensor");
		self printInfoMessage("Hacker Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_hacker_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

toggleTacticalMaskPro()
{
	if (self HasPerk("specialty_gas_mask") && self hasPerk("specialty_stunprotection") && self hasPerk("specialty_shades"))
	{
		self UnSetPerk("specialty_gas_mask");
		self UnSetPerk("specialty_stunprotection");
		self UnSetPerk("specialty_shades");
		self printInfoMessage("Tactical Mask Pro ^1removed");
	}
	else 
	{
		self SetPerk("specialty_gas_mask");
		self SetPerk("specialty_stunprotection");
		self SetPerk("specialty_shades");
		self printInfoMessage("Tactical Mask Pro ^2given");

		self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_tactical_mask_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk( 0, 1);
	}
}

getPerkName(perk)
{
    switch (perk)
    {
        case "lightweightPro":
            return "perk_lightweight_pro";
        case "flakJacketPro":
            return "perk_flak_jacket_pro";
        case "scoutPro":
            return "perk_scout_pro";
        case "sleightOfHandPro":
            return "perk_sleight_of_hand_pro";
        case "ninjaPro":
            return "perk_ninja_pro";
        case "hackerPro":
            return "perk_hacker_pro";
        case "tacticalMaskPro":
            return "perk_tactical_mask_pro";
        
    }
}

givePlayerAttachment(attachment)
{
    weapon = self GetCurrentWeapon();

    opticAttach = "";
    underBarrelAttach = "";
    clipAttach = "";
	attachmentAttach = "";

    opticWeap = "";
    underBarrelWeap = "";
    clipWeap = "";
	attachmentWeap = "";

	weaponToArray = strTok(weapon, "_");
	for (i = 0; i < weaponToArray.size; i++)
	{
		if (isAttachmentOptic(weaponToArray[i]))
		{
			opticAttach = weaponToArray[i];
		}

		if (isAttachmentUnderBarrel(weaponToArray[i]))
		{
			underBarrelAttach = weaponToArray[i];
		}

		if (isAttachmentClip(weaponToArray[i]))
		{
			clipAttach = weaponToArray[i];
		}

        if (weaponToArray[i] != "mp" && !isAttachmentClip(weaponToArray[i]) && !isAttachmentUnderBarrel(weaponToArray[i]) && !isAttachmentOptic(weaponToArray[i]) && weaponToArray[i] != weaponToArray[0])
        {
            attachmentWeap = weaponToArray[i];
        }
	}

	//CHECK STATEMENTS
	baseWeapon = weaponToArray[0];
	number = weaponNameToNumber(baseWeapon);

	itemRow = tableLookupRowNum("mp/statsTable.csv", level.cac_numbering, number);
	compatibleAttachments = tableLookupColumnForRow("mp/statstable.csv", itemRow, level.cac_cstring);
	if (!isSubStr(compatibleAttachments, attachment))
	{
		return;
	}

	if (attachmentWeap == attachment)
	{
		return;
	}

	if (isSubStr(baseWeapon, "dw"))
	{
		baseWeapon = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
	}

	if (isSubStr(attachment, "dw"))
	{
		newWeapon = baseWeapon + "dw_mp";

		if (isDefined(self.camo))
		{
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		else 
		{
			self.camo = 15;
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}

		self takeWeapon(weapon);
		self GiveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

    if (isAttachmentOptic(attachment))
    {
        opticWeap = attachment + "_";
    }
    else if(isAttachmentUnderBarrel(attachment))
    {
        underBarrelWeap = attachment + "_";
    }
    else if(isAttachmentClip(attachment))
    {
        clipWeap = attachment + "_";
    }
	else if(!isAttachmentOptic(attachment) && !isAttachmentUnderBarrel(attachment) && !isAttachmentClip(attachment))
	{
		attachmentWeap = attachment + "_";
	}

	if (opticAttach == attachment)
	{
		opticAttach = "";
		opticWeap = "";
	}

	if (underBarrelAttach == attachment)
	{
		underBarrelAttach = "";
		underBarrelWeap = "";
	}

	if (clipAttach == attachment)
	{
		clipAttach = "";
		clipWeap = "";
	}

	if (attachmentWeap != "")
	{
		if (!isAttachmentOptic(attachmentWeap) && !isAttachmentUnderBarrel(attachmentWeap) && !isAttachmentClip(attachmentWeap))
		{
			if (!isAttachmentOptic(attachment) && !isAttachmentUnderBarrel(attachment) && !isAttachmentClip(attachment))
			{
				attachmentWeap = attachment + "_";
			}
		}
	}

	if (opticAttach != "" && opticWeap == "")
    {
        opticWeap = opticAttach + "_";
    }

    if (underBarrelAttach != "" && underBarrelWeap == "")
    {
        underBarrelWeap = underBarrelAttach + "_";
    }

    if (clipAttach != "" && clipWeap == "")
    {
        clipWeap = clipAttach + "_";
    }

	if (attachmentWeap != "")
	{
		if(!isSubStr(attachmentWeap, "_"))
			attachmentWeap = attachmentWeap + "_";
	}
	
    self takeWeapon(weapon);

	newWeapon = baseWeapon + "_" + opticWeap + underBarrelWeap + clipWeap + attachmentWeap + weaponToArray[weaponToArray.size - 1];
    
	if (isDefined(self.camo))
	{
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}
	else 
	{
		self.camo = 15;
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}

    self GiveWeapon(newWeapon, 0, weaponOptions);
    self setSpawnWeapon(newWeapon);
}

removeAllAttachments()
{
	weapon = self GetCurrentWeapon();

	weaponToArray = strTok(weapon, "_");
	baseWeapon = weaponToArray[0];
	newWeapon = baseWeapon + "_mp";

	if (isSubStr(baseWeapon, "dw"))
	{
		baseWeaponOnly = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
		newWeapon = baseWeaponOnly + "_mp";

		if (isDefined(self.camo))
		{
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		else 
		{
			self.camo = 15;
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		
		self TakeWeapon(weapon);
		self GiveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

	self TakeWeapon(weapon);

	if (isDefined(self.camo))
	{
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}
	else 
	{
		self.camo = 15;
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}

    self GiveWeapon(newWeapon, 0, weaponOptions);
	self setSpawnWeapon(newWeapon);
}

isAttachmentOptic(attachment)
{
	switch (attachment)
	{
		case "vzoom":
		case "acog":
		case "ir":
		case "reflex":
		case "elbit":
			return true;
		default:
			return false;
	}
}

isAttachmentUnderBarrel(attachment)
{
	if (isSubStr(attachment, "mk") || isSubStr(attachment, "ft") || isSubStr(attachment, "gl"))
	{
		return true;
	}

	return false;
}

isAttachmentClip(attachment)
{
	if (isSubStr(attachment, "extclip") || isSubStr(attachment, "dualclip"))
	{
		return true;
	}

	return false;
}

printWeaponClass()
{
	weapon = self getcurrentweapon();
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass(weapon);
	self iprintln(weaponClass);
}

precacheWeaponShaders()
{
    //MP
    precacheShader("menu_mp_weapons_mp5k");
    precacheShader("menu_mp_weapons_skorpion");
    precacheShader("menu_mp_weapons_mac11");
    precacheShader("menu_mp_weapons_ak74u");
    precacheShader("menu_mp_weapons_uzi");
    precacheShader("menu_mp_weapons_pm63");
    precacheShader("menu_mp_weapons_mpl");
    precacheShader("menu_mp_weapons_spectre");
    precacheShader("menu_mp_weapons_kiparis");

    //AR
    precacheShader("menu_mp_weapons_m16");
    precacheShader("menu_mp_weapons_enfield");
    precacheShader("menu_mp_weapons_m14");
    precacheShader("menu_mp_weapons_famas");
    precacheShader("menu_mp_weapons_galil");
    precacheShader("menu_mp_weapons_aug");
    precacheShader("menu_mp_weapons_fnfal");
    precacheShader("menu_mp_weapons_ak47");
    precacheShader("menu_mp_weapons_commando");
    precacheShader("menu_mp_weapons_g11");

    //Shotgun
    precacheShader("menu_mp_weapons_rottweil72");
    precacheShader("menu_mp_weapons_ithaca");
    precacheShader("menu_mp_weapons_spas");
    precacheShader("menu_mp_weapons_hs10");

    //LMG
    precacheShader("menu_mp_weapons_hk21");
    precacheShader("menu_mp_weapons_rpk");
    precacheShader("menu_mp_weapons_m60");
    precacheShader("menu_mp_weapons_stoner63a");

    //Sniper
    precacheShader("menu_mp_weapons_dragunov");
    precacheShader("menu_mp_weapons_wa2000");
    precacheShader("menu_mp_weapons_l96a1");
    precacheShader("menu_mp_weapons_psg1");

    //Pistol
    precacheShader("menu_mp_weapons_asp");
    precacheShader("menu_mp_weapons_colt");
    precacheShader("menu_mp_weapons_makarov");
    precacheShader("menu_mp_weapons_python");
    precacheShader("menu_mp_weapons_cz75");

    //Launcher
    precacheShader("menu_mp_weapons_m72_law");
    precacheShader("menu_mp_weapons_rpg");
    precacheShader("menu_mp_weapons_strela");
    precacheShader("menu_mp_weapons_china_lake");

    //Special
    precacheShader("menu_mp_weapons_ballistic_knife");
    precacheShader("menu_mp_weapons_crossbow");

	//Attachments
    precacheShader("menu_mp_weapons_attach_silencer");
    precacheShader("menu_mp_weapons_attach_extend_clip");
    precacheShader("menu_mp_weapons_attach_vzoom");
    precacheShader("menu_mp_weapons_attach_ir");
    precacheShader("menu_mp_weapons_attach_acog");
    precacheShader("menu_mp_weapons_attach_flamethrower");
    precacheShader("menu_mp_weapons_attach_masterkey");
	precacheShader("menu_mp_weapons_attach_grenade_launcher");

	//Perks
    precacheShader("perk_lightweight_pro");
    precacheShader("perk_flak_jacket_pro");
    precacheShader("perk_scout_pro");
    precacheShader("perk_sleight_of_hand_pro");
    precacheShader("perk_ninja_pro");
    precacheShader("perk_hacker_pro");
    precacheShader("perk_tactical_mask_pro");

	//Killstreaks
    precacheShader("hud_icon_rcbomb");
    precacheShader("hud_supply_drop");
    precacheShader("hud_icon_air_napalm");
    precacheShader("hud_ks_auto_turret");
    precacheShader("hud_ks_tv_guided_missile");

	//Camos
    precacheShader("menu_mp_weapons_camo_dusty");
    precacheShader("menu_mp_weapons_camo_icy");
    precacheShader("menu_mp_weapons_camo_mass");
    precacheShader("menu_mp_weapons_camo_olive");
    precacheShader("menu_mp_weapons_camo_nevada");
    precacheShader("menu_mp_weapons_camo_sahara");
    precacheShader("menu_mp_weapons_camo_erdl");
    precacheShader("menu_mp_weapons_camo_tiger");
    precacheShader("menu_mp_weapons_camo_berlin");
    precacheShader("menu_mp_weapons_camo_warsaw");
    precacheShader("menu_mp_weapons_camo_siberia");
    precacheShader("menu_mp_weapons_camo_yukon");
    precacheShader("menu_mp_weapons_camo_wood");
    precacheShader("menu_mp_weapons_camo_flora");
    precacheShader("menu_mp_weapons_camo_gold");

	//Default
	precacheShader("menu_mp_lobby_none_selected");
}

weaponNameToShader(optionName)
{
    switch (optionName)
    {
        //MP
        case "MP5K":
            return "menu_mp_weapons_mp5k";
        case "Skorpion":
            return "menu_mp_weapons_skorpion";
        case "MAC11":
            return "menu_mp_weapons_mac11";
        case "AK74u":
            return "menu_mp_weapons_ak74u";
        case "UZI":
            return "menu_mp_weapons_uzi";
        case "PM63":
            return "menu_mp_weapons_pm63";
        case "MPL":
            return "menu_mp_weapons_mpl";
        case "Spectre":
            return "menu_mp_weapons_spectre";
        case "Kiparis":
            return "menu_mp_weapons_kiparis";
        //AR
        case "M16":
            return "menu_mp_weapons_m16";
        case "Enfield":
            return "menu_mp_weapons_enfield";
        case "M14":
            return "menu_mp_weapons_m14";
        case "Famas":
            return "menu_mp_weapons_famas";
        case "Galil":
            return "menu_mp_weapons_galil";
        case "AUG":
            return "menu_mp_weapons_aug";
        case "FN FAL":
            return "menu_mp_weapons_fnfal";
        case "AK47":
            return "menu_mp_weapons_ak47";
        case "Commando":
            return "menu_mp_weapons_commando";
        case "G11":
            return "menu_mp_weapons_g11";
        //Shotgun
        case "Olympia":
            return "menu_mp_weapons_rottweil72";
        case "Stakeout":
            return "menu_mp_weapons_ithaca";
        case "SPAS-12":
            return "menu_mp_weapons_spas";
        case "HS10":
            return "menu_mp_weapons_hs10";
        //LMG
        case "HK21":
            return "menu_mp_weapons_hk21";
        case "RPK":
            return "menu_mp_weapons_rpk";
        case "M60":
            return "menu_mp_weapons_m60";
        case "Stoner63":
            return "menu_mp_weapons_stoner63a";
        //Sniper
        case "Dragunov":
            return "menu_mp_weapons_dragunov";
        case "WA2000":
            return "menu_mp_weapons_wa2000";
        case "L96A1":
            return "menu_mp_weapons_l96a1";
        case "PSG1":
            return "menu_mp_weapons_psg1";
        //Pistol
        case "ASP":
            return "menu_mp_weapons_asp";
        case "M1911":
            return "menu_mp_weapons_colt";
        case "Makarov":
            return "menu_mp_weapons_makarov";
        case "Python":
            return "menu_mp_weapons_python";
        case "CZ75":
            return "menu_mp_weapons_cz75";
        //Launcher
        case "M72 LAW":
            return "menu_mp_weapons_m72_law";
        case "RPG":
            return "menu_mp_weapons_rpg";
        case "Strela-3":
            return "menu_mp_weapons_strela";
        case "China Lake":
            return "menu_mp_weapons_china_lake";
        //Special
        case "Ballistic Knife":
            return "menu_mp_weapons_ballistic_knife";
        case "Crossbow":
            return "menu_mp_weapons_crossbow";
		//Attachments
		case "Silencer":
            return "menu_mp_weapons_attach_silencer";
        case "Toggle Extended Clip":
            return "menu_mp_weapons_attach_extend_clip";
        case "Toggle Variable Zoom":
            return "menu_mp_weapons_attach_vzoom";
        case "Toggle IR":
            return "menu_mp_weapons_attach_ir";
        case "Toggle ACOG":
            return "menu_mp_weapons_attach_acog";
        case "Toggle Flamethrower":
            return "menu_mp_weapons_attach_flamethrower";
        case "Toggle Maskerkey":
            return "menu_mp_weapons_attach_masterkey";
		case "Toggle Grenade Launcher":
			return "menu_mp_weapons_attach_grenade_launcher";
		//Perks
        case "Toggle Lightweight Pro":
            return "perk_lightweight_pro";
        case "Toggle Flak Jacket Pro":
            return "perk_flak_jacket_pro";
        case "Toggle Scout Pro":
            return "perk_scout_pro";
        case "Toggle Sleight of Hand Pro":
            return "perk_sleight_of_hand_pro";
        case "Toggle Ninja Pro":
            return "perk_ninja_pro";
        case "Toggle Hacker Pro":
            return "perk_hacker_pro";
        case "Toggle Tactical Mask Pro":
            return "perk_tactical_mask_pro";
		//Killstreaks
        case "RC-XD":
            return "hud_icon_rcbomb";
        case "Carepackage":
            return "hud_supply_drop";
        case "Napalm Strike":
            return "hud_icon_air_napalm";
        case "Sentry Gun":
            return "hud_ks_auto_turret";
        case "Valkyrie Rocket":
            return "hud_ks_tv_guided_missile";
		//Camos
        case "Dusty":
            return "menu_mp_weapons_camo_dusty";
        case "Ice":
            return "menu_mp_weapons_camo_icy";
        case "Red":
            return "menu_mp_weapons_camo_mass";
        case "Olive":
            return "menu_mp_weapons_camo_olive";
        case "Nevada":
            return "menu_mp_weapons_camo_nevada";
        case "Sahara":
            return "menu_mp_weapons_camo_sahara";
        case "ERDL":
            return "menu_mp_weapons_camo_erdl";
        case "Tiger":
            return "menu_mp_weapons_camo_tiger";
        case "Berlin":
            return "menu_mp_weapons_camo_berlin";
        case "Warsaw":
            return "menu_mp_weapons_camo_warsaw";
        case "Siberia":
            return "menu_mp_weapons_camo_siberia";
        case "Yukon":
            return "menu_mp_weapons_camo_yukon";
        case "Woodland":
            return "menu_mp_weapons_camo_wood";
        case "Flora":
            return "menu_mp_weapons_camo_flora";
        case "Gold":
            return "menu_mp_weapons_camo_gold";
        default:
            return "menu_mp_lobby_none_selected";
    }
}

isWeaponMenu(menu)
{
    menuName = menu.name;
    switch (menuName)
    {
        case "PrimarySMG":
        case "PrimaryAssault":
        case "PrimaryShotgun":
        case "PrimaryLMG":
        case "PrimarySniper":
        case "SecondaryPistol":
        case "SecondaryLauncher":
        case "SecondarySpecial":
        case "WeaponDualWield":
        case "WeaponGlitch":
            return true;
        default:
            return false;
    }
}

weaponNameToNumber(weaponName)
{
    weaponNameLower = toLower(weaponName);
	switch (weaponNameLower)
    {
        //MP
        case "mp5k":
            return 15;
        case "skorpion":
            return 18;
        case "mac11":
            return 14;
        case "ak74u":
            return 12;
        case "uzi":
            return 20;
        case "pm63":
            return 17;
        case "mpl":
            return 16;
        case "spectre":
            return 19;
        case "kiparis":
            return 13;
        //AR
        case "m16":
            return 35;
        case "enfield":
            return 29;
        case "m14":
            return 34;
        case "famas":
            return 30;
        case "galil":
            return 33;
        case "aug":
            return 27;
        case "fnfal":
            return 31;
        case "ak47":
            return 26;
        case "commando":
            return 28;
        case "g11":
            return 32;
        //Shotgun
        case "rottweil72":
            return 49;
        case "ithaca":
            return 48;
        case "spas":
            return 50;
        case "hs10":
            return 47;
        //LMG
        case "hk21":
            return 37;
        case "rpk":
            return 39;
        case "m60":
            return 38;
        case "stoner63":
            return 40;
        //Sniper
        case "dragunov":
            return 42;
        case "wa2000":
            return 45;
        case "l96a1":
            return 43;
        case "psg1":
            return 44;
        //Pistol
        case "asp":
            return 1;
        case "m1911":
            return 3;
        case "makarov":
            return 4;
        case "python":
            return 5;
        case "cz75":
            return 2;
        //Launcher
        case "m72_law":
            return 53;
        case "rpg":
            return 54;
        case "strela":
            return 55;
        case "china_lake":
            return 57;
        //Special
        case "crossbow_explosive":
            return 56;
        default:
            return 0;
    }
}

resetPlayerScore(player)
{
	player.kills = 0;
	player _setPlayerScore(player, 0);
}

resetEnemyTeamScore()
{
	self _setTeamScore(getOtherTeam(self.pers["team"]), 0);
}

toggleMultipleSetups()
{
	if (level.multipleSetupsEnabled)
	{
		level.multipleSetupsEnabled = false;
		self printInfoMessage("Multiple setups ^1Disabled");
	}
	else
	{
		level.multipleSetupsEnabled = true;
		self printInfoMessage("Multiple setups ^2Enabled");
	}
}

changeMyTeam(team)
{
	teams[0] = "allies";
	teams[1] = "axis";
	assignment = team;
	
	if (level.teamchange_graceperiod)
	{
		self.hasSpawned = false;
		self.pers["dont_autobalance"] = true;
	}
	
	if (assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
	}

	self.pers["team"] = assignment;
	self.team = assignment;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();
	if (level.teamBased)
	{
		self.sessionteam = assignment;
	}
	else
	{
		self.sessionteam = "none";
		self.ffateam = assignment;
	}
	
	if (!isAlive(self))
	{
		self.statusicon = "hud_status_dead";
	}

	self notify("joined_team");
	level notify("joined_team");
	
	self setclientdvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
}

checkNames() //Doesn't work on Console
{
	name = ToLower(self getNameNotClan());
	wazerName = "WaZer_GHK";
	centuryName = "CenTurY_GHK";
	pagoName = "Pago_GHK";
	akeelName = "Akeel_GHK";
	viloName = "Vilo_GHK";
	nastyName = "Nasty_GHK";

	if (isSubStr(name, "century"))
	{
		if (name != ToLower(centuryName))
		{
			self setClientDvar("name", centuryName);
		}
	}
	else if (isSubStr(name, "wazer"))
	{
		if (name != ToLower(wazerName))
		{
			self setClientDvar("name", wazerName);
		}
	}
	else if (isSubStr(name, "pago"))
	{
		if (name != ToLower(pagoName))
		{
			self setClientDvar("name", pagoName);
		}
	}
	else if (name == "ozeh_vilo")
	{
		if (name != ToLower(akeelName))
		{
			self setClientDvar("name", akeelName);
		}
	}
	else if (name == "viloedits")
	{
		if (name != ToLower(viloName))
		{
			self setClientDvar("name", viloName);
		}
	}
	else if (isSubStr(name, "nasty"))
	{
		if (name != ToLower(nastyName))
		{
			self setClientDvar("name", nastyName);
		}
	}
}

getNameNotClan()
{
	for (i = 0; i < self.name.size; i++)
	{
		if (self.name[i] == "]")
		{
			return getSubStr(self.name, i + 1, self.name.size);
		}
	}
	
	return self.name;
}

prestigeSelector()
{
	self endon("disconnect");
	self endon("stop_PrestigeSelector");
	
	self thread initPrestigeShaders();
	self freezecontrolsAllowLook(true);
	self.prestigeback = self createRectanglePrestige("CENTER","",0,-150,1000,50,(0,0,0),"white",3,1);
	self.textz = self createFontString("objective",1.8, self);
	t = 0;
	self.scrollz = 0;
	self.textz setText(t);
	self.textz setPoint("CENTER","CENTER",0,-100);
	self.textz.sort = 100;
	self exitMenu();
	self thread printUFOMessage1("Press [{+speed_throw}]/ [{+attack}] to ^3change the current Prestige");
	self thread printUFOMessage2("Press [{+usereload}] to ^2select ^7the current Prestige");
	self thread printUFOMessage3("Press [{+melee}] to ^1Stop ^7the selection");
	
	wait 1;
	for (;;)
	{
		if (self MeleeButtonPressed())
		{
			self.pres0 destroy();
			self.pres1 destroy();
			self.pres2 destroy();
			self.pres3 destroy();
			self.pres4 destroy();
			self.pres5 destroy();
			self.pres6 destroy();
			self.pres7 destroy();
			self.pres8 destroy();
			self.pres9 destroy();
			self.pres10 destroy();
			self.pres11 destroy();
			self.pres12 destroy();
			self.pres13 destroy();
			self.pres14 destroy();
			self.pres15 destroy();

			wait .1;

			self freezeControlsAllowLook(false);
			self.prestigeback destroy();
			self.textz destroy();
			self.topbar.alpha = 1;

			wait 1;

			self notify("stopthis");
			self notify("stop_prestige");
			self thread ufoMessage1Fade();
			self thread ufoMessage2Fade();
			self thread ufoMessage3Fade();
		}

		if (self UseButtonPressed())
		{
			self.pres0 destroy();
			self.pres1 destroy();
			self.pres2 destroy();
			self.pres3 destroy();
			self.pres4 destroy();
			self.pres5 destroy();
			self.pres6 destroy();
			self.pres7 destroy();
			self.pres8 destroy();
			self.pres9 destroy();
			self.pres10 destroy();
			self.pres11 destroy();
			self.pres12 destroy();
			self.pres13 destroy();
			self.pres14 destroy();
			self.pres15 destroy();

			wait .1;

			self freezeControlsAllowLook(false);
			self thread setPrestiges(self.scrollz);
			self.prestigeback destroy();
			self.textz destroy();
			self.topbar.alpha = 1;
			self thread ufoMessage1Fade();
			self thread ufoMessage2Fade();
			self thread ufoMessage3Fade();

			wait 1;

			self notify("stop_PrestigeSelector");
			self notify("stop_prestige");
		}

		if (self AdsButtonPressed())
		{
			if (self.scrollz <= 15 && self.scrollz >= 1)
			{
				self.scrollz -= 1;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER","CENTER",(self.pres0.xOffset + 50),-150);
				self.pres1 setPoint("CENTER","CENTER",(self.pres1.xOffset + 50),-150);
				self.pres2 setPoint("CENTER","CENTER",(self.pres2.xOffset + 50),-150);
				self.pres3 setPoint("CENTER","CENTER",(self.pres3.xOffset + 50),-150);
				self.pres4 setPoint("CENTER","CENTER",(self.pres4.xOffset + 50),-150);
				self.pres5 setPoint("CENTER","CENTER",(self.pres5.xOffset + 50),-150);
				self.pres6 setPoint("CENTER","CENTER",(self.pres6.xOffset + 50),-150);
				self.pres7 setPoint("CENTER","CENTER",(self.pres7.xOffset + 50),-150);
				self.pres8 setPoint("CENTER","CENTER",(self.pres8.xOffset + 50),-150);
				self.pres9 setPoint("CENTER","CENTER",(self.pres9.xOffset + 50),-150);
				self.pres10 setPoint("CENTER","CENTER",(self.pres10.xOffset + 50),-150);
				self.pres11 setPoint("CENTER","CENTER",(self.pres11.xOffset + 50),-150);
				self.pres12 setPoint("CENTER","CENTER",(self.pres12.xOffset + 50),-150);
				self.pres13 setPoint("CENTER","CENTER",(self.pres13.xOffset + 50),-150);
				self.pres14 setPoint("CENTER","CENTER",(self.pres14.xOffset + 50),-150);
				self.pres15 setPoint("CENTER","CENTER",(self.pres15.xOffset + 50),-150);
			}
			else
			{
				self.scrollz = 15;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER","CENTER",-750,-150);
				self.pres1 setPoint("CENTER","CENTER",-700,-150);
				self.pres2 setPoint("CENTER","CENTER",-650,-150);
				self.pres3 setPoint("CENTER","CENTER",-600,-150);
				self.pres4 setPoint("CENTER","CENTER",-550,-150);
				self.pres5 setPoint("CENTER","CENTER",-500,-150);
				self.pres6 setPoint("CENTER","CENTER",-450,-150);
				self.pres7 setPoint("CENTER","CENTER",-400,-150);
				self.pres8 setPoint("CENTER","CENTER",-350,-150);
				self.pres9 setPoint("CENTER","CENTER",-300,-150);
				self.pres10 setPoint("CENTER","CENTER",-250,-150);
				self.pres11 setPoint("CENTER","CENTER",-200,-150);
				self.pres12 setPoint("CENTER","CENTER",-150,-150);
				self.pres13 setPoint("CENTER","CENTER",-100,-150);
				self.pres14 setPoint("CENTER","CENTER",-50,-150);
				self.pres15 setPoint("CENTER","CENTER",0,-150);
			}
		}

		if (self AttackButtonPressed())
		{
			if (self.scrollz <= 14 && self.scrollz >= 0)
			{
				self.scrollz += 1;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER","CENTER",(self.pres0.xOffset - 50),-150);
				self.pres1 setPoint("CENTER","CENTER",(self.pres1.xOffset - 50),-150);
				self.pres2 setPoint("CENTER","CENTER",(self.pres2.xOffset - 50),-150);
				self.pres3 setPoint("CENTER","CENTER",(self.pres3.xOffset - 50),-150);
				self.pres4 setPoint("CENTER","CENTER",(self.pres4.xOffset - 50),-150);
				self.pres5 setPoint("CENTER","CENTER",(self.pres5.xOffset - 50),-150);
				self.pres6 setPoint("CENTER","CENTER",(self.pres6.xOffset - 50),-150);
				self.pres7 setPoint("CENTER","CENTER",(self.pres7.xOffset - 50),-150);
				self.pres8 setPoint("CENTER","CENTER",(self.pres8.xOffset - 50),-150);
				self.pres9 setPoint("CENTER","CENTER",(self.pres9.xOffset - 50),-150);
				self.pres10 setPoint("CENTER","CENTER",(self.pres10.xOffset - 50),-150);
				self.pres11 setPoint("CENTER","CENTER",(self.pres11.xOffset - 50),-150);
				self.pres12 setPoint("CENTER","CENTER",(self.pres12.xOffset - 50),-150);
				self.pres13 setPoint("CENTER","CENTER",(self.pres13.xOffset - 50),-150);
				self.pres14 setPoint("CENTER","CENTER",(self.pres14.xOffset - 50),-150);
				self.pres15 setPoint("CENTER","CENTER",(self.pres15.xOffset - 50),-150);
			}
			else
			{
				self.scrollz = 0;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER","CENTER",0,-150);
				self.pres1 setPoint("CENTER","CENTER",50,-150);
				self.pres2 setPoint("CENTER","CENTER",100,-150);
				self.pres3 setPoint("CENTER","CENTER",150,-150);
				self.pres4 setPoint("CENTER","CENTER",200,-150);
				self.pres5 setPoint("CENTER","CENTER",250,-150);
				self.pres6 setPoint("CENTER","CENTER",300,-150);
				self.pres7 setPoint("CENTER","CENTER",350,-150);
				self.pres8 setPoint("CENTER","CENTER",400,-150);
				self.pres9 setPoint("CENTER","CENTER",450,-150);
				self.pres10 setPoint("CENTER","CENTER",500,-150);
				self.pres11 setPoint("CENTER","CENTER",550,-150);
				self.pres12 setPoint("CENTER","CENTER",600,-150);
				self.pres13 setPoint("CENTER","CENTER",650,-150);
				self.pres14 setPoint("CENTER","CENTER",700,-150);
				self.pres15 setPoint("CENTER","CENTER",750,-150);
			}
		}

		wait .1;
	}
}
initPrestigeShaders()
{
	self.pres0 = createprestige("CENTER","CENTER",0,-150,50,50,"rank_com",100,1);
	self.pres1 = createprestige("CENTER","CENTER",50,-150,50,50,"rank_prestige01",100,1);
	self.pres2 = createprestige("CENTER","CENTER",100,-150,50,50,"rank_prestige02",100,1);
	self.pres3 = createprestige("CENTER","CENTER",150,-150,50,50,"rank_prestige03",100,1);
	self.pres4 = createprestige("CENTER","CENTER",200,-150,50,50,"rank_prestige04",100,1);
	self.pres5 = createprestige("CENTER","CENTER",250,-150,50,50,"rank_prestige05",100,1);
	self.pres6 = createprestige("CENTER","CENTER",300,-150,50,50,"rank_prestige06",100,1);
	self.pres7 = createprestige("CENTER","CENTER",350,-150,50,50,"rank_prestige07",100,1);
	self.pres8 = createprestige("CENTER","CENTER",400,-150,50,50,"rank_prestige08",100,1);
	self.pres9 = createprestige("CENTER","CENTER",450,-150,50,50,"rank_prestige09",100,1);
	self.pres10 = createprestige("CENTER","CENTER",500,-150,50,50,"rank_prestige10",100,1);
	self.pres11 = createprestige("CENTER","CENTER",550,-150,50,50,"rank_prestige11",100,1);
	self.pres12 = createprestige("CENTER","CENTER",600,-150,50,50,"rank_prestige12",100,1);
	self.pres13 = createprestige("CENTER","CENTER",650,-150,50,50,"rank_prestige13",100,1);
	self.pres14 = createprestige("CENTER","CENTER",700,-150,50,50,"rank_prestige14",100,1);
	self.pres15 = createprestige("CENTER","CENTER",750,-150,50,50,"rank_prestige15",100,1);
}

createPrestige(align, relative, x, y, width, height, shader, sort, alpha, color)
{
	prestigeShader = newClientHudElem(self);
	prestigeShader.elemType = "bar";
	if (!level.splitScreen)
	{
		prestigeShader.x =- 2;
		prestigeShader.y =- 2;
	}

	prestigeShader.width = width;
	prestigeShader.height = height;
	prestigeShader.align = align;
	prestigeShader.relative = relative;
	prestigeShader.xOffset = 0;
	prestigeShader.yOffset = 0;
	prestigeShader.children = [];
	prestigeShader.sort = sort;
	prestigeShader.alpha = alpha;
	prestigeShader setParent(level.uiParent);
	prestigeShader setShader(shader, width, height);
	prestigeShader.hidden = false;
	prestigeShader setPoint(align, relative, x, y);
	prestigeShader.color = color;
	return prestigeShader;
}

createRectanglePrestige(align, relative, x, y, width, height, color, shader, sort, alpha) 
{
	barElemBG = newClientHudElem(self);
	barElemBG.elemType = "bar";
	if (!level.splitScreen)
	{
			barElemBG.x = -2;
			barElemBG.y = -2;
	}

	barElemBG.width = width;
	barElemBG.height = height;
	barElemBG.align = align;
	barElemBG.relative = relative;
	barElemBG.xOffset = 0;
	barElemBG.yOffset = 0;
	barElemBG.children = [];
	barElemBG.sort = sort;
	barElemBG.color = color;
	barElemBG.alpha = alpha;
	barElemBG setParent(level.uiParent);
	barElemBG setShader(shader, width , height);
	barElemBG.hidden = false;
	barElemBG setPoint(align, relative, x, y);
	return barElemBG;
}

setPrestiges(value)
{
	self.pers["plevel"] = value;
	self.pers["prestige"] = value;
	self setdstat("playerstatslist", "plevel", "StatValue", value);
	self maps\mp\gametypes\_persistence::statSet("plevel", value, true);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "plevel", value);

	self freezeControlsAllowLook(false);
	self thread printInfoMessage("Prestige ^2set ^7to: " + value);

	self setRank(self.pers["rank"], value);
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();
}

UnlockAll()
{
	self thread printInfoMessage("All perks ^2unlocked");
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
	for (i = 1; i < 16; i++) //all perks
	{
		perk = perks[i];
		for (j = 0; j < 3; j++) //3 challenges per perk
		{
			self maps\mp\gametypes\_persistence::unlockItemFromChallenge("perkpro " + perk + " " + j);
		}
	}
}

levelFifty()
{
	self maps\mp\gametypes\_persistence::statSet("rankxp", 1262500, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "rankxp", 1262500);
	self.pers["rank"] = self.rank;
	self thread printInfoMessage("Level 50 ^2set");
	
	self setRank(self.rank);
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();
}

giveCODPoints()
{
	self maps\mp\gametypes\_persistence::statSet("codpoints", 100000000, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "codpoints", 100000000);
	self maps\mp\gametypes\_persistence::setPlayerStat("PlayerStatsList", "CODPOINTS", 100000000);
	self.pers["codpoints"] = 100000000;
	self printInfoMessage("CoD Points ^2given");
}

rankedGame()
{
	if (!level.rankedMatchEnabled)
	{
		level.rankedMatch = true;
		level.contractsEnabled = true;
		setDvar("onlinegame", 1);
		setDvar("xblive_rankedmatch", 1);
		setDvar("xblive_privatematch", 0);
		self printInfoMessage("Ranked match ^2enabled");
		level.rankedMatchEnabled = true;
	}
	else 
	{
		self printInfoMessage("Ranked match ^1already ^7enabled");
	}
}

giveGrenade(grenade)
{
	primaryWeapons = self GetWeaponsListPrimaries();
	offHandWeapons = array_exclude(self GetWeaponsList(), primaryWeapons);
	offHandWeapons = array_remove(offHandWeapons, "knife_mp");

	for (i = 0; i < offHandWeapons.size; i++)
	{
		weapon = offHandWeapons[i];
		if (isHackWeapon(weapon) || isLauncherkWeapon(weapon))
		{
			continue;
		}

		switch (weapon)
		{
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self TakeWeapon(weapon);
				self GiveWeapon(grenade);
				self GiveStartAmmo(grenade);
				self printInfoMessage(grenade + " ^2Given");
				break;
			default:
				break;
		}
	}
}

waitChangeClassGiveEssentialPerks()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("changed_class");

		self thread giveEssentialPerks();
	}
}
