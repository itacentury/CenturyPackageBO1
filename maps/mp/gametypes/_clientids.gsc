#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_globallogic_score;
//Custom files
#include maps\mp\gametypes\custom\_dev_options;
#include maps\mp\gametypes\custom\_self_options;
#include maps\mp\gametypes\custom\_account_options;
#include maps\mp\gametypes\custom\_class_options;
#include maps\mp\gametypes\custom\_lobby_options;

init()
{
	level.clientid = 0;

	level.currentVersion = "v1.7 BETA";
	level.currentGametype = getDvar("g_gametype");
	level.currentMapName = getDvar("mapName");

	switch (level.currentGametype)
	{
		case "dm":
		{
			if (getDvar("scr_disable_tacinsert") == "1")
			{
				setDvar("scr_disable_tacinsert", "0");
			}

			if (level.disable_tacinsert)
			{
				level.disable_tacinsert = false;
			}

			setDvar("scr_" + level.currentGametype + "_timelimit", "10");
		}
		break;
		case "tdm":
			setDvar("scr_" + level.currentGametype + "_timelimit", "10");
			break;
		case "sd":
			setDvar("scr_" + level.currentGametype + "_timelimit", "2.5");
			break;
		default:
			break;
	}

	if (getDvar("bombEnabled") == "0")
	{
		level.bomb = false;
	}
	else 
	{
		level.bomb = true;
	}

	if (getDvar("cg_nopredict") == "1")
	{
		level.precam = true;
	}
	else 
	{
		level.precam = false;
	}

	if (getDvar("killcam_final") == "1")
	{
		level.playercard = true;
	}
	else 
	{
		level.playercard = false;
	}

	if (getDvar("OPStreaksEnabled") == "0")
	{
		level.opStreaks = false;
	}
	else 
	{
		level.opStreaks = true;
	}

	level.spawned_bots = 0;
	level.multipleSetupsEnabled = false;
	precacheShader("score_bar_bg");
	precacheModel("t5_weapon_cz75_dw_lh_world");

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

		player.isInMenu = false;
		player.currentMenu = "main";
		player.textDrawn = false;
		player.shadersDrawn = false;
		player.saveLoadoutEnabled = false;
		player.ufoEnabled = false;
		player.isFrozen = false;

		if (player getPlayerCustomDvar("isAdmin") == "1")
		{
			player.isAdmin = true;
		}
		else 
		{
			player.isAdmin = false;
		}

		if (player getPlayerCustomDvar("isTrusted") == "1")
		{
			player.isTrusted = true;
		}
		else 
		{
			player.isTrusted = false;
		}

		if (isDefined(player getPlayerCustomDvar("positionMap")))
		{
			if (player getPlayerCustomDvar("positionMap") != level.currentMapName)
			{
				player setPlayerCustomDvar("positionSaved", "0");
			}
			
			if (player getPlayerCustomDvar("positionMap") == level.currentMapName && isDefined(player getPlayerCustomDvar("position0")))
			{
				player setPlayerCustomDvar("positionSaved", "1");
			}
		}

		if (isDefined(player getPlayerCustomDvar("camo")))
		{
			player.camo = int(player getPlayerCustomDvar("camo"));
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
		self waittill("spawned_player");

		if (firstSpawn)
		{
			if (self isHost() || self isAdmin() || self isCreator())
			{
				self iPrintln("gsc.cty loaded");
				self FreezeControls(false);
				
				self thread runController();
				self thread buildMenu();
				self thread drawMessages();
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

			if (self isHost() || self isCreator())
			{
				if (!self.isAdmin)
				{
					self.isAdmin = true;
				}
				
				if (level.currentGametype == "sd")
				{
					level.gracePeriod = 5;
				}
			}

			if (self checkIfUnwantedPlayers())
			{
				ban(self getEntityNumber(), 1);
			}

			firstSpawn = false;
		}

		self.weaponShaders.alpha = 1;
		if (self.isAdmin)
		{
			if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1")
			{
				self thread loadLoadout();
			}
		}

		if (getDvar("OPStreaksEnabled") == "0")
		{
			self thread OPStreaks();
		}

		self thread checkGivenPerks();
		self thread giveEssentialPerks();
		self thread waitChangeClassGiveEssentialPerks();
	}
}

runController()
{
	self endon("disconnect");

	firstTime = true;

	for(;;)
	{
		if (self isAdmin())
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
					self updateInfoText();
					wait 0.25;
				}

				//UFO mode
				if (self actionSlotTwoButtonPressed() && self GetStance() == "crouch" && self isCreator())
				{
					self thread enterUfoMode();
					wait .12;
				}
			}
		}

		if (self.pers["team"] == getHostPlayer().pers["team"])
		{
			if (self actionSlotThreeButtonPressed() && self GetStance() == "crouch")
			{
				self reviveTeam();
				wait .12;
			}
		}

		if (self isHost() && level.gameForfeited)
		{
			level.gameForfeited = false;
			level notify("abort forfeit");
		}

		if (self isHost() && level.currentGametype == "sd")
		{
			timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec
			if (timeLeft < 1500 && firstTime)
			{
				timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
				setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 2.5); //2.5 equals to 2 min ingame in this case for some reason
				firstTime = false;
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
	self addMenu("", m, "gsc.cty " + level.currentVersion);
	self addOption(m, "Refill Ammo", ::refillAmmo);
	if (level.currentGametype == "sd")
	{
		self addOption(m, "Revive whole team", ::reviveTeam);
	}

	self addMenu(m, "MainSelf", "^9Self Options");
	if (self isCreator() && !level.console)
	{
		self addMenu(m, "MainDev", "^9Dev Options");
	}

	if (self isHost() && level.players.size == 1)
	{
		self addMenu(m, "MainAccount", "^9Account Options");
	}

	self addMenu(m, "MainClass", "^9Class Options");
	if (self isHost() || self isCreator())
	{
		self addMenu(m, "MainLobby", "^9Lobby Options");
	}

	m = "MainDev";
	self addOption(m, "Print origin", ::printOrigin);
	self addOption(m, "Print weapon class", ::printWeaponClass);
	self addOption(m, "Print weapon", ::printWeapon);
	self addOption(m, "Print weapon loop", ::printWeaponLoop);
	self addOption(m, "Print offhand weapons", ::printOffHandWeapons);
	self addOption(m, "Print XUID", ::printXUID);
	self addOption(m, "Fast restart test", ::testFastRestart);

	m = "MainSelf";
	self addOption(m, "Suicide", ::doSuicide);
	self addOption(m, "Third Person", ::ToggleThirdPerson);
	self addOption(m, "Give default ts loadout", ::defaultTrickshotClass);
	self addOption(m, "Save Loadout", ::saveLoadout);
	self addOption(m, "Delete saved loadout", ::deleteLoadout);
	if (level.currentGametype != "sd")
	{
		self addOption(m, "Save location for spawn", ::saveLocationForSpawn);
		self addOption(m, "Delete location for spawn", ::stopLocationForSpawn);
	}

	if (level.currentGametype == "dm")
	{		
		self addOption(m, "Fast last", ::fastLast);
	}

	if (self isHost() || self isCreator())
	{
		self addMenu(m, "SelfSayAll", "^9Say All Menu");
	}

	m = "SelfSayAll";
	self addOption(m, "No setup", ::customSayAll, "No setup please");
	self addOption(m, "Centurys twitter", ::customSayAll, "Twitter: @CenturyMD");
	self addOption(m, "don't kill yourself", ::customSayAll, "don't kill yourself");
	self addOption(m, "thanks", ::customSayAll, "thanks");
	self addOption(m, "try to kill us", ::customSayAll, "try to kill us");
	self addOption(m, "please", ::customSayAll, "please");
	self addOption(m, "inform team about revive team bind", ::customSayTeam, "^2Crouch ^7& ^2press ^5DPAD Left ^7to revive your team!");

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
	self addMenu(m, "ClassEquipment", "^9Equipment Selector");
	self addMenu(m, "ClassTacticals", "^9Tacticals Selector");
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
	self addOption(m, "None", ::changeCamo, 0);
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
	self addOption(m, "Toggle Ghost Pro", ::givePlayerPerk, "ghostPro");
	self addOption(m, "Toggle Flak Jacket Pro", ::givePlayerPerk, "flakJacketPro");
	self addOption(m, "Toggle Scout Pro", ::givePlayerPerk, "scoutPro");
	self addOption(m, "Toggle Sleight of Hand Pro", ::givePlayerPerk, "sleightOfHandPro");
	self addOption(m, "Toggle Ninja Pro", ::givePlayerPerk, "ninjaPro");
	self addOption(m, "Toggle Hacker Pro", ::givePlayerPerk, "hackerPro");
	self addOption(m, "Toggle Tactical Mask Pro", ::givePlayerPerk, "tacticalMaskPro");

	m = "ClassAttachment";
	self addMenu(m, "AttachOptic", "^9Optics");
	self addMenu(m, "AttachMag", "^9Mags");
	self addMenu(m, "AttachUnderBarrel", "^9Underbarrel");
	self addMenu(m, "AttachOther", "^9Other");
	self addOption(m, "Remove all attachments", ::removeAllAttachments);

	m = "AttachOptic";
	self addOption(m, "Toggle Reflex", ::givePlayerAttachment, "reflex");
	self addOption(m, "Toggle Red Dot", ::givePlayerAttachment, "elbit");
	self addOption(m, "Toggle Variable Zoom", ::givePlayerAttachment, "vzoom");
	self addOption(m, "Toggle IR", ::givePlayerAttachment, "ir");
	self addOption(m, "Toggle ACOG", ::givePlayerAttachment, "acog");
	self addOption(m, "Toggle Upgraded Sight", ::givePlayerAttachment, "upgradesight");
	self addOption(m, "Toggle Low Power Scope", ::givePlayerAttachment, "lps");

	m = "AttachMag";
	self addOption(m, "Toggle Extended Clip", ::givePlayerAttachment, "extclip");
	self addOption(m, "Toggle Dual Mag", ::givePlayerAttachment, "dualclip");
	self addOption(m, "Toggle Speed Loader", ::givePlayerAttachment, "speed");

	m = "AttachUnderBarrel";
	self addOption(m, "Toggle Flamethrower", ::givePlayerAttachment, "ft");
	self addOption(m, "Toggle Masterkey", ::givePlayerAttachment, "mk");
	self addOption(m, "Toggle Grenade Launcher", ::givePlayerAttachment, "gl");
	self addOption(m, "Toggle Grip", ::givePlayerAttachment, "grip");

	m = "AttachOther";
	self addOption(m, "Give Silencer", ::givePlayerAttachment, "silencer");
	self addOption(m, "Give Snub Nose", ::givePlayerAttachment, "snub");
	self addOption(m, "Toggle Dual Wield", ::givePlayerAttachment, "dw");

	m = "ClassKillstreaks";
	self addOption(m, "Spy Plane", ::giveUserKillstreak, "radar_mp");
	self addOption(m, "RC-XD", ::giveUserKillstreak, "rcbomb_mp");
	self addOption(m, "Counter-Spy Plane", ::giveUserKillstreak, "counteruav_mp");
	self addOption(m, "Sam Turret", ::giveUserKillstreak, "tow_turret_drop_mp");
	self addOption(m, "Carepackage", ::giveUserKillstreak, "supply_drop_mp");
	self addOption(m, "Napalm Strike", ::giveUserKillstreak, "napalm_mp");
	self addOption(m, "Sentry Gun", ::giveUserKillstreak, "autoturret_mp");
	self addOption(m, "Mortar Team", ::giveUserKillstreak, "mortar_mp");
	self addOption(m, "Valkyrie Rocket", ::giveUserKillstreak, "m220_tow_mp");
	self addOption(m, "Blackbird", ::giveUserKillstreak, "radardirection_mp");
	self addOption(m, "Minigun", ::giveUserKillstreak, "minigun_mp");
    
	m = "ClassEquipment";
	self addOption(m, "Camera Spike", ::giveUserEquipment, "camera_spike_mp");
	self addOption(m, "C4", ::giveUserEquipment, "satchel_charge_mp");
	self addOption(m, "Tactical Insertion", ::giveUserEquipment, "tactical_insertion_mp");
	self addOption(m, "Jammer", ::giveUserEquipment, "scrambler_mp");
	self addOption(m, "Motion Sensor", ::giveUserEquipment, "acoustic_sensor_mp");
	self addOption(m, "Claymore", ::giveUserEquipment, "claymore_mp");

	m = "ClassTacticals";
	self addOption(m, "Willy Pete", ::giveUserTacticals, "willy_pete_mp");
	self addOption(m, "Nova Gas", ::giveUserTacticals, "tabun_gas_mp");
	self addOption(m, "Flashbang", ::giveUserTacticals, "flash_grenade_mp");
	self addOption(m, "Concussion", ::giveUserTacticals, "concussion_grenade_mp");
	self addOption(m, "Decoy", ::giveUserTacticals, "nightingale_mp");

	m = "MainLobby";
	if (level.currentGametype == "tdm")
	{
		self addOption(m, "Fast last my team", ::fastLast);
		self addOption(m, "Reset enemy team score", ::resetEnemyTeamScore);
	}
	else if (level.currentGametype == "sd")
	{
		self addOption(m, "Toggle Bomb", ::toggleBomb);
	}

	self addOption(m, "Pre-cam weapon animations", ::precamOTS);
	self addOption(m, "Toggle own player card in killcam", ::togglePlayercard);
	self addOption(m, "Toggle OP Streaks", ::toggleOPStreaks);

	self addMenu("main", "MainPlayers", "^9Players Menu");
	m = "MainPlayers";
	if (!level.teamBased)
	{
		for (p = 0; p < level.players.size; p++)
		{
			player = level.players[p];
			name = player.name;
			player_name = "player_" + name;

			if (isAlive(player))
			{
				self addMenu(m, player_name, name + " (Alive)");
			}
			else if (!isAlive(player))
			{
				self addMenu(m, player_name, name + " (Dead)");
			}

			self addOption(player_name, "Teleport player to crosshair", ::teleportToCrosshair, player);
			self addOption(player_name, "Teleport myself to player", ::teleportSelfTo, player);
			if (self isHost() || self isCreator() || self isTrustedUser())
			{
				self addOption(player_name, "Kick Player", ::kickPlayer, player);
				self addOption(player_name, "Ban Player", ::banPlayer, player);
			}

			if (level.currentGametype == "dm")
			{
				self addOption(player_name, "Give fast last", ::givePlayerFastLast, player);
				self addOption(player_name, "Reset score", ::resetPlayerScore, player);
			}

			if (!player isHost() && !player isCreator() && (self isHost() || self isCreator()))
			{
				self addOption(player_name, "Toggle menu access", ::toggleAdminAccess, player);
				self addOption(player_name, "Toggle full menu access", ::toggleIsTrusted, player);
			}

			if (self isCreator())
			{
				self addOption(player_name, "Print XUID", ::printPlayerXUID, player);
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

			if (player.pers["team"] == myTeam)
			{
				m = "PlayerFriendly";

				if (isAlive(player))
				{
					self addMenu(m, player_name, name + " (Alive)");
				}
				else if (!isAlive(player))
				{
					self addMenu(m, player_name, name + " (Dead)");
				}
			}
			else if (player.pers["team"] == otherTeam)
			{
				m = "PlayerEnemy";

				if (isAlive(player))
				{
					self addMenu(m, player_name, name + " (Alive)");
				}
				else if (!isAlive(player))
				{
					self addMenu(m, player_name, name + " (Dead)");
				}
			}
			
			if (self isHost() || self isCreator() || self isTrustedUser())
			{
				self addOption(player_name, "Kick Player", ::kickPlayer, player);
				self addOption(player_name, "Ban Player", ::banPlayer, player);
				self addOption(player_name, "Change Team", ::changePlayerTeam, player);
				self addOption(player_name, "Teleport player to crosshair", ::teleportToCrosshair, player);
				self addOption(player_name, "Teleport myself to player", ::teleportSelfTo, player);
			}

			if (!player isHost() && !player isCreator() && (self isHost() || self isCreator()))
			{
				self addOption(player_name, "Toggle menu access", ::toggleAdminAccess, player);
				self addOption(player_name, "Toggle full menu access", ::toggleIsTrusted, player);
			}

			if (self isCreator())
			{
				self addOption(player_name, "Print XUID", ::printPlayerXUID, player);
			}

			if (level.currentGametype == "sd")
			{
				self addOption(player_name, "Remove Ghost", ::removeGhost, player);
				self addOption(player_name, "Revive player", ::revivePlayer, player, false);
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
	self addOption(m, "Default weapon", ::giveUserWeapon, "defaultweapon_mp");
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

isCreator()
{
	xuid = self getXUID();
	if (xuid == "11000010d1c86bb"/*PC*/ || xuid == "8776e339aad3f92e"/*PS3 Online*/ || xuid == "248d65be0fe005"/*PS3 Offline*/)
	{
		return true;
	}

	return false;
}

isTrustedUser()
{
	if (self.isTrusted)
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
		player setPlayerCustomDvar("isAdmin", "1");
		
		player thread runController();
		player thread buildMenu();
		player thread drawMessages();
		
		player iPrintln("Menu access ^2Given");
		player iPrintln("Open with [{+speed_throw}] & [{+actionslot 2}]");
		self printInfoMessage("Menu access ^2Given ^7to " + player.name);
	}
	else 
	{
		player.isAdmin = false;
		player setPlayerCustomDvar("isAdmin", "0");
		player iPrintln("Menu access ^1Removed");
		self printInfoMessage("Menu access ^1Removed ^7from " + player.name);
		if (player.isInMenu)
		{
			player ClearAllTextAfterHudelem();
			player thread exitMenu();
		}
	}
}

toggleIsTrusted(player)
{
	if (player.isAdmin)
	{
		if (!player.isTrusted)
		{
			player.isTrusted = true;
			player setPlayerCustomDvar("isTrusted", "1");
			self printinfomessage("Player is ^2trusted");
			player iPrintln("You are now ^2trusted");
		}
		else
		{
			player.isTrusted = false;
			player setPlayerCustomDvar("isTrusted", "0");
			self printinfomessage("Player is ^1not ^7trusted anymore");
			player iPrintln("You are ^1not ^7trusted anymore");
		}
	}
	else 
	{
		self printinfomessage("You have to give normal menu access first");
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
	self.getEquipment = self GetWeaponsList();
	self.getEquipment = array_remove(self.getEquipment, "knife_mp");
	
	self.isInMenu = true;
	self.currentMenu = menu;
	currentMenu = self getCurrentMenu();

	mainPlayers = self.menus["MainPlayers"];
	playerFriendly = self.menus["PlayerFriendly"];
	playerEnemy = self.menus["PlayerEnemy"];
	if (currentMenu == mainPlayers || currentMenu == playerFriendly || currentMenu == playerEnemy)
	{
		self buildMenu();
	}

	self.currentMenuPosition = currentMenu.position;
	self thread closeMenuOnDeath();
	self TakeWeapon("knife_mp");
	self AllowJump(false);
	self DisableOffHandWeapons();

	for (i = 0; i < self.getEquipment.size; i++)
	{
		self.curEquipment = self.getEquipment[i];

		switch (self.curEquipment)
		{
			case "claymore_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
			case "camera_spike_mp":
			case "acoustic_sensor_mp":
				self TakeWeapon(self.curEquipment);
				self.myEquipment = self.curEquipment;
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
}

exitMenu()
{
	self.isInMenu = false;
	
	self thread destroyMenu();
	
	self GiveWeapon("knife_mp");
	self AllowJump(true);
	self EnableOffHandWeapons();
	if (isDefined(self.myEquipment))
	{
		self GiveWeapon(self.myEquipment);
		self GiveStartAmmo(self.myEquipment);
		self SetActionSlot(1, "weapon", self.myEquipment);
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
	self.infoBackground = createRectangle("CENTER", "CENTER", -225, -180, 150, 100, 1, "black");
	self.infoBackground setColor(1, 1, 1, 1);

	self.shadersDrawn = true;
}

drawMessages()
{
	self.infoMessage = self createText2("default", 1, " ", "CENTER", "CENTER", -250, 100, 3, 0, (1, 1, 1));
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
	self.twitterTitle = self createText("small", 1, "CENTER", "TOP", -250, self.yAxis - 35, 3, "");
	self.twitterTitle setColor(1, 1, 1, 1);

	for (i = 0; i < 11; i++)
	{
		self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", -250, self.yAxis + (15 * i), 3, "");
	}

	for (i = 0; i < 4; i++)
	{
		self.infoText[i] = self createText("objective", 1, "LEFT", "TOP", -290, (self.yAxis - 170) + (15 * i), 3, "");
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
	if (self.menus[self.currentMenu].title == "gsc.cty " + level.currentVersion)
	{
		self.twitterTitle setText("@CenturyMD");
	}
	else 
	{
		self.twitterTitle setText("");
	}

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

updateInfoTextAllPlayers()
{
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];

		if (player isAdmin())
		{
			if (player.isInMenu)
			{
				player updateInfoText();
			}
		}
	}
}

updateInfoText()
{
	if (level.bomb)
	{
		bombText = "Bomb: ^2enabled";
	}
	else 
	{
		bombText = "Bomb: ^1disabled";
	}

	if (level.precam)
	{
		precamText = "Pre-cam animations: ^2enabled";
	}
	else 
	{
		precamText = "Pre-cam animations: ^1disabled";
	}

	if (level.playercard)
	{
		playercardText = "Own player card: ^2visible";
	}
	else 
	{
		playercardText = "Own player card: ^1not visible";
	}

	if (level.opStreaks)
	{
		opStreaksText = "OP streaks: ^2enabled";
	}
	else 
	{
		opStreaksText = "OP streaks: ^1disabled";
	}
	
	for (i = 0; i < self.infoText.size; i++)
	{
		self.infoText[0] setText(bombText);
		self.infoText[1] setText(precamText);
		self.infoText[2] setText(playercardText);
		self.infoText[3] setText(opStreaksText);
	}
}

destroyMenu()
{
	self thread destroyShaders();
	self thread destroyText();
}

destroyShaders()
{
	self.menuBackground destroy();
	self.infoBackground destroy();
	self.menuTitleDivider destroy();
	self.menuScrollbar1 destroy();
	
	self.shadersDrawn = false;
}

destroyText()
{
	self.menuTitle destroy();
	self.twitterTitle destroy();
	for (o = 0; o < self.menuOptions.size; o++)
	{
		self.menuOptions[o] destroy();
	}

	for(o = 0; o < self.infoText.size; o++)
	{
		self.infoText[o] destroy();
	}

	self.textDrawn = false;
}

createText(font, fontScale, point, relative, xOffset, yOffset, sort, hideWhenInMenu, text)
{
    textElem = createFontString(font, fontScale);
    textElem setText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    return textElem;
}

createText2(font, fontScale, text, point, relative, xOffset, yOffset, sort, alpha, color)
{
    textElem = createFontString(font, fontScale);
    textElem setText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.alpha = alpha;
    textElem.color = color;
    return textElem;
}

createRectangle(align, relative, x, y, width, height, sort, shader)
{
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG setParent(level.uiParent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = false;
    barElemBG setPoint(align, relative, x, y);
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

	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE") 
	{
		if (maps\mp\gametypes\_missions::getWeaponClass( sWeapon ) == "weapon_sniper")
		{
			if (level.currentGametype == "sd" || level.currentGametype == "dm")
			{
				iDamage = 10000000;
			}
			else
			{
				iDamage += 8;
			}
		}
		else 
		{
			iDamage -= 5;

			if (sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH")
			{
				iDamage = 1;
			}
		}
	}
	
	if (sMeansOfDeath != "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath != "MOD_FALLING" || eattacker.classname == "trigger_hurt") 
	{
		self.attackers = undefined;
	}

	[[level.onPlayerDamageStub]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
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

giveEssentialPerks()
{
	if (level.currentGametype == "sd")
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

saveLoadout()
{
	self.primaryWeapons = self GetWeaponsListPrimaries();
	self.offHandWeapons = array_exclude(self GetWeaponsList(), self.primaryWeapons);
	self.offHandWeapons = array_remove(self.offHandWeapons, "knife_mp");
	if (isDefined(self.myEquipment))
	{
		self.offHandWeapons[self.offHandWeapons.size] = self.myEquipment;
	}

	self.saveLoadoutEnabled = true;

	for (i = 0; i < self.primaryWeapons.size; i++)
	{
		self setPlayerCustomDvar("primary" + i, self.primaryWeapons[i]);
	}

	for (i = 0; i < self.offHandWeapons.size; i++)
	{
		self setPlayerCustomDvar("secondary" + i, self.offHandWeapons[i]);
	}

	self setPlayerCustomDvar("primaryCount", self.primaryWeapons.size);
	self setPlayerCustomDvar("secondaryCount", self.offHandWeapons.size);
	self setPlayerCustomDvar("loadoutSaved", "1");

	self thread printInfoMessage("Weapons ^2saved");
}

deleteLoadout()
{
	if (self.saveLoadoutEnabled)
	{
		self.saveLoadoutEnabled = false;
		self printInfoMessage("Saved weapons ^2deleted");
	}

	if (self getPlayerCustomDvar("loadoutSaved") == "1")
	{
		self setPlayerCustomDvar("loadoutSaved", "0");
		self printInfoMessage("Saved weapons ^2deleted");
	}
}

loadLoadout()
{
	self TakeAllWeapons();

	if (!isDefined(self.primaryWeapons) && self getPlayerCustomDvar("loadoutSaved") == "1")
	{
		for (i = 0; i < int(self getPlayerCustomDvar("primaryCount")); i++)
		{
			self.primaryWeapons[i] = self getPlayerCustomDvar("primary" + i);
		}

		for (i = 0; i < int(self getPlayerCustomDvar("secondaryCount")); i++)
		{
			self.offHandWeapons[i] = self getPlayerCustomDvar("secondary" + i);
		}
	}

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

	self GiveWeapon("knife_mp");

	for (i = 0; i < self.offHandWeapons.size; i++)
	{
		weapon = self.offHandWeapons[i];
		if (isHackWeapon(weapon) || isLauncherWeapon(weapon))
		{
			continue;
		}

		switch (weapon)
		{
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock(weapon);
				if (self HasPerk("specialty_twogrenades"))
					ammo = stock + 1;
				else
					ammo = stock;
				self SetWeaponAmmoStock(weapon, ammo);
				break;
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
			case "tabun_gas_mp":
			case "nightingale_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock(weapon);
				if (self HasPerk("specialty_twogrenades"))
					ammo = stock + 1;
				else
					ammo = stock;
				self SetWeaponAmmoStock(weapon, ammo);
				break;
			case "willy_pete_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock(weapon);
				ammo = stock;
				self SetWeaponAmmoStock(weapon, ammo);
				break;
			case "claymore_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
			case "camera_spike_mp":
			case "acoustic_sensor_mp":
				self GiveWeapon(weapon);
				self GiveStartAmmo(weapon);
				self SetActionSlot(1, "weapon", weapon);
				break;
			default:
				self GiveWeapon(weapon);
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

isLauncherWeapon(weapon)
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

teleportSelfTo(player)
{
	if (isAlive(player))
	{
		self SetOrigin(player.origin);
	}
}

teleportToCrosshair(player)
{
	if (isAlive(player))
	{
		player setOrigin(bullettrace(self gettagorigin("j_head"), self gettagorigin("j_head") + anglesToForward(self getplayerangles()) * 1000000, 0, self)["position"]);
	}
}

kickPlayer(player)
{
	if (!player isCreator() && player != self)
	{
		kick(player getEntityNumber(), "For support contact @CenturyMD on Twitter");
		if (player is_bot())
		{
			level.spawned_bots--;
		}
	}
}

fastLast()
{
	if (level.currentGametype == "dm")
	{
		self.kills = 29;
		self.pers["kills"] = 29;
		self _setPlayerScore(self, 1450);
	}
	else if (level.currentGametype == "tdm")
	{
		self _setTeamScore(self.pers["team"], 7400);
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

changeMyTeam(team)
{
	assignment = team;

	self.pers["team"] = assignment;
	self.team = assignment;
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

waitChangeClassGiveEssentialPerks()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("changed_class");

		self giveEssentialPerks();
		self checkGivenPerks();
	}
}

changePlayerTeam(player)
{
	player changeMyTeam(getOtherTeam(player.pers["team"]));
	self printInfoMessage(player.name + " ^2changed ^7team");
	player iPrintln("Team ^2changed ^7to " + player.pers["team"]);
}

revivePlayer(player, isTeam)
{
	if (!isAlive(player))
	{
		if (!maps\mp\gametypes\_globallogic_utils::isValidClass(self.pers["class"]) || self.pers["class"] == undefined)
		{
			self.pers["class"] = "CLASS_CUSTOM1";
			self.class = self.pers["class"];
		}
		
		if (player.hasSpawned)
		{
			player.pers["lives"]++;
		}
		else 
		{
			player.hasSpawned = true;
		}

		if (player.sessionstate != "playing")
		{
			player.sessionstate = "playing";
		}
		
		player thread [[level.spawnClient]]();

		if (!isTeam)
		{
			self printInfoMessage(player.name + " ^2revived");
		}
		player iprintln("Revived by " + self.name);
	}
}

banPlayer(player)
{
	if (!player isCreator() && player != self)
	{
		ban(player getEntityNumber(), 1);
		self iprintln(player.name + " ^2banned");
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

setPlayerCustomDvar(dvar, value) 
{
	dvar = self getXUID() + "_" + dvar;
	setDvar(dvar, value);
}

getPlayerCustomDvar(dvar) 
{
	dvar = self getXUID() + "_" + dvar;
	return getDvar(dvar);
}

saveLocationForSpawn()
{
	self.spawnLocation = self.origin;
	self.spawnAngles = self.angles;
	self printInfoMessage("Location ^2saved ^7for spawn");
	self monitorLocationForSpawn();
}

stopLocationForSpawn()
{
	self.spawnLocation = undefined;
	self printInfoMessage("Location for spawn ^1deleted");
	self notify("stop_locationForSpawn");
}

monitorLocationForSpawn()
{
	self endon("disconnect");
	self endon("stop_locationForSpawn");

	for (;;)
	{
		self waittill("spawned_player");

		self SetOrigin(self.spawnLocation);
		self EnableInvulnerability();

		wait 5;

		self DisableInvulnerability();
	}
}

removeGhost(player)
{
	if(player hasGhost())
	{
		player UnSetPerk("specialty_gpsjammer");
		self printinfomessage("Ghost ^2removed");
	}
	else if(player hasGhostPro())
	{
		player UnSetPerk("specialty_gpsjammer");
		player UnSetPerk("specialty_notargetedbyai");
		player UnSetPerk("specialty_noname");
		self printinfomessage("Ghost Pro ^2removed");
	}
}

hasGhost()
{
	if(self hasPerk("specialty_gpsjammer") && !self HasPerk("specialty_notargetedbyai") && !self HasPerk("specialty_noname")) //Ghost
	{ 
		return true;
	}
	return false;
}

hasGhostPro()
{
	if(self hasPerk("specialty_gpsjammer") && self HasPerk("specialty_notargetedbyai") && self HasPerk("specialty_noname")) //Ghost pro
	{
		return true;
	}
	return false;
}

customSayAll(msg)
{
	self sayAll(msg);
}

customSayTeam(msg)
{
	self sayTeam(msg);
}

printPlayerXUID(player)
{
	xuid = player getXUID();
	self iprintln(player.name + " XUID:");
	self iprintln(xuid);
}

givePlayerFastLast(player)
{
	player.kills = 29;
	player.pers["kills"] = 29;
	player _setPlayerScore(player, 1450);
}

checkIfUnwantedPlayers()
{
	xuid = self getXUID();

	if (xuid == "f44d8ea93332fc96" /*PS3 Pellum*/)
	{
		return true;
	}

	return false;
}