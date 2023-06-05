#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_globallogic_score;
//Custom files
#include maps\mp\gametypes\century\_dev_options;
#include maps\mp\gametypes\century\_self_options;
#include maps\mp\gametypes\century\_class_options;
#include maps\mp\gametypes\century\_lobby_options;
#include maps\mp\gametypes\century\_player_menu;

init()
{
	level.clientid = 0;
	level.menuName = "Century Package";
	level.currentVersion = "2.2";
	level.currentGametype = getDvar("g_gametype");
	level.currentMapName = getDvar("mapName");
	setDvar("OPStreaksEnabled", "0"); //OP Streaks
	setDvar("killcam_final", "1"); //Playercard in Killcam
	setDvar("bombEnabled", "0"); //Bomb in SnD
	if (level.console)
	{
		level.yAxis = 150;
		level.yAxisMenuBorder = 163;
		level.yAxisControlsBackground = -25;
	}
	else 
	{
		level.yAxis = 200;
		level.yAxisMenuBorder = 200;
		level.yAxisControlsBackground = 5;
	}

	level.xAxis = 0;
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
		{
			setDvar("scr_" + level.currentGametype + "_timelimit", "10");
		}
			break;
		case "sd":
		{
			setDvar("scr_" + level.currentGametype + "_timelimit", "2.5");
		}
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

	if (level.currentGametype == "sd" || level.currentGametype == "dm")
	{
		level.tdmUnlimitedDmg = true;
	}
	else 
	{
		level.tdmUnlimitedDmg = false;
	}

	level.defaultClass = "CLASS_SMG";
	modifyDefaultLoadout("CLASS_ASSAULT", "enfield_mp", "m1911_mp", "frag_grenade_mp", "tabun_gas_mp", "", "specialty_flakjacket", "specialty_bulletaccuracy", "specialty_gas_mask");
	maps\mp\gametypes\_class::cac_init();
	maps\mp\gametypes\_class::getCacDataGroup(5, 10);
	precacheShader("score_bar_bg");
	precacheModel("t5_weapon_cz75_dw_lh_world");
	level.firstTime = true;
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
		player.unlimDamageEnabled = false;
		if (player getPlayerCustomDvar("hasReviveAbility") == "1")
		{
			player.hasReviveAbility = true;
		}
		else 
		{
			player.hasReviveAbility = false;
		}

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

		if (isDefined(player getPlayerCustomDvar("camo")))
		{
			player.camo = int(player getPlayerCustomDvar("camo"));
		}

		if (getDvar("killcam_final") == "1")
		{
			player SetClientDvar("killcam_final", "1");
		}

		if (player checkIfUnwantedPlayers())
		{
			ban(player getEntityNumber(), 1);
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
				if (level.currentGametype == "sd")
				{
					self iPrintln("Century Package loaded");
					self FreezeControls(false);
				}

				self buildMenu();
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

			self thread runController();
			firstSpawn = false;
		}

		if (self.isAdmin)
		{
			if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1")
			{
				self loadLoadout();
			}
		}

		if (getDvar("OPStreaksEnabled") == "0")
		{
			self thread OPStreaks();
		}

		if (self GetCurrentWeapon() == "china_lake_mp")
		{
			self GiveMaxAmmo("china_lake_mp");
		}

		self checkGivenPerks();
		self giveEssentialPerks();
		self thread waitChangeClassGiveEssentialPerks();
	}
}

runController()
{
	self endon("disconnect");

	for(;;)
	{
		if (self isAdmin() || self isHost() || self isCreator())
		{
			if (self.isInMenu)
			{
				if (self jumpbuttonpressed())
				{
					self select();
					wait 0.25;
				}

				if (self meleebuttonpressed())
				{
					self closeMenu();
					wait 0.25;
				}

				if (self actionslottwobuttonpressed())
				{
					self scrollDown();
				}

				if (self actionslotonebuttonpressed())
				{
					self scrollUp();
				}
			}
			else
			{
				if (self adsbuttonpressed() && self actionslottwobuttonpressed() && !self isMantling())
				{
					self openMenu(self.currentMenu);
					if (self allowedToSeeInfo())
					{
						self updateInfoText();
					}
					
					wait 0.25;
				}

				if (self actionSlotTwoButtonPressed() && self GetStance() == "crouch" && self isCreator())
				{
					self enterUfoMode();
					wait .12;
				}
			}
		}

		if (self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm")
		{
			if (self actionslotthreebuttonpressed())
			{
				self toggleUnlimDamage();
			}
		}

		if (level.currentGametype == "sd")
		{
			if (self.hasReviveAbility)
			{
				if (self actionSlotThreeButtonPressed() && self GetStance() == "crouch")
				{
					self reviveTeam();
					wait .12;
				}
			}

			timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec
			if (timeLeft < 1500 && level.firstTime)
			{
				timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
				setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 2.5); //2.5 equals to 2 min ingame in this case for some reason
				level.firstTime = false;
			}
		}

		if (level.gameForfeited)
		{
			level.gameForfeited = false;
			level notify("abort forfeit");
		}
		
		wait 0.05;
	}
}

/*MENU*/
buildMenu()
{
	self.menus = [];
	m = "main";
	//start main
	self addMenu("", m, "Century Package " + level.currentVersion);
	self addOption(m, "Refill Ammo", ::refillAmmo);
	self addMenu(m, "MainSelf", "^5Self Options");
	if (self isCreator() && !level.console)
	{
		self addMenu(m, "MainDev", "^5Dev Options");
	}

	self addMenu(m, "MainClass", "^5Class Options");
	if (self isHost() || self isCreator())
	{
		self addMenu(m, "MainLobby", "^5Lobby Options");
	}

	if ((self isHost() || self isCreator() || self isTrustedUser()) && level.currentGametype == "sd")
	{
		self addMenu(m, "MainTeam", "^5Team Options");
	}

	m = "MainSelf";
	self addOption(m, "Suicide", ::doSuicide);
	self addOption(m, "Third Person", ::ToggleThirdPerson);
	if (level.currentGametype == "dm" && (self isHost() || self isCreator() || self isTrustedUser()))
	{		
		self addOption(m, "Fast last", ::fastLast);
	}
	
	if (level.currentGametype != "sd")
	{
		self addMenu(m, "SelfLocation", "^5Location Options");
	}

	self addMenu(m, "SelfLoadout", "^5Loadout Options");
	if (self isHost() || self isCreator())
	{
		if (level.currentGametype == "sd")
		{
			self addOption(m, "inform team about revive team bind", ::customSayTeam, "^2Crouch ^7& ^2press ^5DPAD Left ^7to revive your team!");
		}
		if (level.players.size == 1)
		{
			self addOption(m, "Give unlock all", ::giveUnlockAll);
		}
	}

	m = "SelfLocation";
	self addOption(m, "Save location for spawn", ::saveLocationForSpawn);
	self addOption(m, "Delete location for spawn", ::stopLocationForSpawn);
	m = "SelfLoadout";
	self addOption(m, "Give default ts loadout", ::defaultTrickshotClass);
	self addOption(m, "Save Loadout", ::saveLoadout);
	self addOption(m, "Delete saved loadout", ::deleteLoadout);
	m = "MainDev";
	self addOption(m, "Print origin", ::printOrigin);
	self addOption(m, "Print weapon class", ::printWeaponClass);
	self addOption(m, "Print weapon", ::printWeapon);
	self addOption(m, "Print weapon loop", ::printWeaponLoop);
	self addOption(m, "Print offhand weapons", ::printOffHandWeapons);
	self addOption(m, "Print XUID", ::printOwnXUID);
	self addOption(m, "Fast restart test", ::testFastRestart);
	m = "MainClass";
	self addMenu(m, "ClassWeapon", "^5Weapon Selector");
	self addMenu(m, "ClassGrenades", "^5Grenade Selector");
	self addMenu(m, "ClassCamo", "^5Camo Selector");
	self addMenu(m, "ClassPerk", "^5Perk Selector");
	self addMenu(m, "ClassEquipment", "^5Equipment Selector");
	self addMenu(m, "ClassTacticals", "^5Tacticals Selector");
	self addMenu(m, "ClassKillstreaks", "^5Killstreak Menu");
	self buildWeaponMenu();
	self buildClassMenu();
	m = "MainLobby";
	if (level.currentGametype == "tdm")
	{
		self addOption(m, "Fast last my team", ::fastLast);
		self addOption(m, "Toggle unlimited sniper damage", ::toggleUnlimitedSniperDmg);
	}
	else if (level.currentGametype == "sd")
	{
		self addOption(m, "Toggle Bomb", ::toggleBomb);
	}

	self addOption(m, "Pre-cam weapon animations", ::precamOTS);
	self addOption(m, "Toggle own player card in killcam", ::togglePlayercard);
	self addOption(m, "Toggle OP Streaks", ::toggleOPStreaks);
	m = "MainTeam";
	self addOption(m, "Revive whole team", ::reviveTeam);
	self addOption(m, "Kill whole team", ::killTeam);
	m = "main";
	if (self isHost() || self isCreator() || self isTrustedUser())
	{
		self addMenu(m, "MainPlayers", "^5Players Menu");
	}

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

			self addOption(player_name, "Kick Player", ::kickPlayer, player);
			self addOption(player_name, "Ban Player", ::banPlayer, player);
			if (level.currentGametype == "sd" || level.currentGametype == "tdm" || level.currentGametype == "dm")
			{
				self addOption(player_name, "Teleport player to crosshair", ::teleportToCrosshair, player);
			}

			if (level.currentGametype == "dm")
			{
				self addOption(player_name, "Give fast last", ::givePlayerFastLast, player);
			}

			if (!player isHost() && !player isCreator() && (self isHost() || self isCreator()))
			{
				self addMenu(player_name, "PlayersAccess", "^5Players Access Menu");
				m = "PlayersAccess";
				self addOption(m, "Toggle revive ability", ::toggleReviveAbility, player);
				self addOption(m, "Toggle menu access", ::toggleAdminAccess, player);
				self addOption(m, "Toggle full menu access", ::toggleIsTrusted, player);
			}
		}
	}
	else if (level.teamBased)
	{
		myTeam = self.pers["team"];
		otherTeam = getOtherTeam(myTeam);
		self addMenu(m, "PlayerFriendly", "^5Friendly players");
		self addMenu(m, "PlayerEnemy", "^5Enemy players");
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
			
			self addOption(player_name, "Kick Player", ::kickPlayer, player);
			self addOption(player_name, "print xuid", ::printXUID, player);
			self addOption(player_name, "Ban Player", ::banPlayer, player);
			self addOption(player_name, "Change Team", ::changePlayerTeam, player);
			if (level.currentGametype == "sd" || level.currentGametype == "tdm" || level.currentGametype == "dm")
			{
				self addOption(player_name, "Teleport player to crosshair", ::teleportToCrosshair, player);
			}

			if (!player isHost() && !player isCreator() && (self isHost() || self isCreator()))
			{
				self addMenu(player_name, "PlayersAccess", "^5Players Access Menu");
				m = "PlayersAccess";
				self addOption(m, "Toggle revive ability", ::toggleReviveAbility, player);
				self addOption(m, "Toggle menu access", ::toggleAdminAccess, player);
				self addOption(m, "Toggle full menu access", ::toggleIsTrusted, player);
			}

			if (level.currentGametype == "sd")
			{
				self addOption(player_name, "Remove Ghost", ::removeGhost, player);
				self addOption(player_name, "Revive player", ::revivePlayer, player, false);
			}
		}
	}
	//end players
}

buildWeaponMenu()
{
	m = "ClassWeapon";
	self addMenu(m, "WeaponPrimary", "^5Primary");
	self addMenu(m, "WeaponSecondary", "^5Secondary");
	if (self isHost() || self isCreator() || self isTrustedUser())
	{
		self addMenu(m, "WeaponGlitch", "^5Glitch");
		self addMenu(m, "WeaponMisc", "^5Misc");
	}

	self addMenu(m ,"WeaponAttachment", "^5Attachment Selector");
	self addOption(m, "Take Weapon", ::takeUserWeapon);
	self addOption(m, "Drop Weapon", ::dropUserWeapon);
	m = "WeaponPrimary";
	self addMenu(m, "PrimarySMG", "^5SMG");
	self addMenu(m, "PrimaryAssault", "^5Assault");
	self addMenu(m, "PrimaryShotgun", "^5Shotgun");
	self addMenu(m, "PrimaryLMG", "^5LMG");
	self addMenu(m, "PrimarySniper", "^5Sniper");
	m = "PrimarySMG";
	self addOption(m, "MP5K", ::giveUserWeapon, "mp5k_mp");
	self addOption(m, "AK74u", ::giveUserWeapon, "ak74u_mp");
	self addOption(m, "UZI", ::giveUserWeapon, "uzi_mp");
	self addOption(m, "PM63", ::giveUserWeapon, "pm63_mp");
	self addOption(m, "MPL", ::giveUserWeapon, "mpl_mp");
	self addOption(m, "Spectre", ::giveUserWeapon, "spectre_mp");
	self addOption(m, "Kiparis", ::giveUserWeapon, "kiparis_mp");
	m = "PrimaryAssault";
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
	self addMenu(m, "SecondaryPistol", "^5Pistol");
	self addMenu(m, "SecondaryLauncher", "^5Launcher");
	self addMenu(m, "SecondarySpecial", "^5Special");
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
	m = "WeaponGlitch";
	self addOption(m, "ASP", ::giveUserWeapon, "asplh_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911lh_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarovlh_mp");
	self addOption(m, "Python", ::giveUserWeapon, "pythonlh_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75lh_mp");
	self addOption(m, "Default weapon", ::giveUserWeapon, "defaultweapon_mp");
	m = "WeaponMisc";
	self addOption(m, "Syrette", ::giveUserWeapon, "syrette_mp");
	self addOption(m, "Briefcase Bomb", ::giveUserWeapon, "briefcase_bomb_mp");
	self addOption(m, "Autoturret", ::giveUserWeapon, "autoturret_mp");
	m = "WeaponAttachment";
	self addMenu(m, "AttachOptic", "^5Optics");
	self addMenu(m, "AttachMag", "^5Mags");
	self addMenu(m, "AttachUnderBarrel", "^5Underbarrel");
	self addMenu(m, "AttachOther", "^5Other");
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
}

buildClassMenu()
{
	m = "ClassGrenades";
	self addOption(m, "Frag", ::giveGrenade, "frag_grenade_mp");
	self addOption(m, "Semtex", ::giveGrenade, "sticky_grenade_mp");
	self addOption(m, "Tomahawk", ::giveGrenade, "hatchet_mp");
    m = "ClassCamo";
	self addMenu(m, "CamoOne", "^5Camos Part 1");
	self addMenu(m, "CamoTwo", "^5Camos Part 2");
	self addMenu(m, "CamoThree", "^5Camos Part 3");
	self addOption(m, "Random Camo", ::randomCamo);
	m = "CamoOne";
	self addOption(m, "None", ::changeCamo, 0);
	self addOption(m, "Dusty", ::changeCamo, 1);
	self addOption(m, "Ice", ::changeCamo, 2);
	self addOption(m, "Red", ::changeCamo, 3);
	self addOption(m, "Olive", ::changeCamo, 4);
	m = "CamoTwo";
	self addOption(m, "Nevada", ::changeCamo, 5);
	self addOption(m, "Sahara", ::changeCamo, 6);
	self addOption(m, "ERDL", ::changeCamo, 7);
	self addOption(m, "Tiger", ::changeCamo, 8);
	self addOption(m, "Berlin", ::changeCamo, 9);
	m = "CamoThree";
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
	self addOption(m, "Toggle Steady Aim Pro", ::givePlayerPerk, "steadyAimPro");
	self addOption(m, "Toggle Sleight of Hand Pro", ::givePlayerPerk, "sleightOfHandPro");
	self addOption(m, "Toggle Ninja Pro", ::givePlayerPerk, "ninjaPro");
	self addOption(m, "Toggle Tactical Mask Pro", ::givePlayerPerk, "tacticalMaskPro");
	m = "ClassKillstreaks";
	self addMenu(m, "KillstreaksSupport", "^5Support");
	self addMenu(m, "KillstreaksLethal", "^5Lethal");
	m = "KillstreaksSupport";
	self addOption(m, "Spy Plane", ::giveUserKillstreak, "radar_mp");
	self addOption(m, "Sam Turret", ::giveUserKillstreak, "tow_turret_drop_mp");
	self addOption(m, "Carepackage", ::giveUserKillstreak, "supply_drop_mp");
	self addOption(m, "Blackbird", ::giveUserKillstreak, "radardirection_mp");
	m = "KillstreaksLethal";
	self addOption(m, "RC-XD", ::giveUserKillstreak, "rcbomb_mp");
	self addOption(m, "Napalm Strike", ::giveUserKillstreak, "napalm_mp");
	self addOption(m, "Sentry Gun", ::giveUserKillstreak, "autoturret_mp");
	self addOption(m, "Valkyrie Rocket", ::giveUserKillstreak, "m220_tow_mp");
	self addOption(m, "Grim Reaper", ::giveUserKillstreak, "m202_flash_mp");
	self addOption(m, "Minigun", ::giveUserKillstreak, "minigun_mp");
	m = "ClassEquipment";
	self addOption(m, "Camera Spike", ::giveUserEquipment, "camera_spike_mp");
	self addOption(m, "C4", ::giveUserEquipment, "satchel_charge_mp");
	self addOption(m, "Jammer", ::giveUserEquipment, "scrambler_mp");
	self addOption(m, "Motion Sensor", ::giveUserEquipment, "acoustic_sensor_mp");
	self addOption(m, "Claymore", ::giveUserEquipment, "claymore_mp");
	m = "ClassTacticals";
	self addOption(m, "Willy Pete", ::giveUserTacticals, "willy_pete_mp");
	self addOption(m, "Nova Gas", ::giveUserTacticals, "tabun_gas_mp");
	self addOption(m, "Flashbang", ::giveUserTacticals, "flash_grenade_mp");
	self addOption(m, "Concussion", ::giveUserTacticals, "concussion_grenade_mp");
	self addOption(m, "Decoy", ::giveUserTacticals, "nightingale_mp");
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
	switch (xuid)
	{
		case "11000010d1c86bb": //Century Steam
		case "8776e339aad3f92e": //Century PS3 Online
		case "248d65be0fe005": //Century PS3 Offline
		case "826daf78fe8586d3": //zuckerschlecken psn
			return true;
		default:
			return false;
	}
}

isHomie()
{
	xuid = self getXUID();
	switch (xuid)
	{
		case "11000010d1c86bb": //Century Steam
		case "826daf78fe8586d3": //zuckerschlecken psn
		case "c3bc5605a98a57c1": //vinouhde psn
		case "4ed1357230e78979": //papalachtdichaus psn
		case "3c9c9a43bf28e8d9": //BreadMio
			return true;
		default:
			return false;
	}
}

isTrustedUser()
{
	if (self.isTrusted)
	{
		return true;
	}

	return false;
}

closeMenuOnDeath()
{
	self endon("exit_menu");

	self waittill("death");
	self ClearAllTextAfterHudelem();
	self exitMenu();
}

openMenu(menu)
{
	self.getEquipment = self GetWeaponsList();
	self.getEquipment = array_remove(self.getEquipment, "knife_mp");
	self.isInMenu = true;
	self.currentMenu = menu;
	currentMenu = self getCurrentMenu();
	switch (self.currentMenu)
	{
		case "MainPlayers":
		case "PlayerFriendly":
		case "PlayerEnemy":
			self buildMenu();
			break;
		default:
			break;
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

	self drawMenu(currentMenu);
}

closeMenu()
{
	currentMenu = self getCurrentMenu();
	if (currentMenu.parent == "" || !isDefined(currentMenu.parent))
	{
		self exitMenu();
	}
	else
	{
		self openMenu(currentMenu.parent);
	}
}

exitMenu()
{
	self.isInMenu = false;
	self destroyMenu();
	self GiveWeapon("knife_mp");
	self AllowJump(true);
	self EnableOffHandWeapons();
	if (isDefined(self.myEquipment))
	{
		self GiveWeapon(self.myEquipment);
		self GiveStartAmmo(self.myEquipment);
		self SetActionSlot(1, "weapon", self.myEquipment);
	}

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
	self scroll(-1);
}

scrollDown()
{
	self scroll(1);
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
	self moveScrollbar();
}

moveScrollbar()
{
	self.menuScrollbar1.y = level.yAxis + (self.currentMenuPosition * 15);
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
		self moveScrollbar();
	}
	else
	{
		self drawShaders();
	}

	if (self.textDrawn)
	{
		self updateText();
	}
	else
	{
		self drawText();
	}
}

drawShaders()
{
	self.menuBackground = createRectangle("CENTER", "CENTER", level.xAxis, 0, 200, 250, 1, "black");
	self.menuBackground setColor(0, 0, 0, 0.5);
	self.menuScrollbar1 = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis + (15 * self.currentMenuPosition), 200, 35, 2, "score_bar_bg");
	self.menuScrollbar1 setColor(0.08, 0.78, 0.83, 1);
	self.dividerBar = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis - 20, 200, 1, 2, "white");
	self.dividerBar setColor(0.08, 0.78, 0.83, 1);
	self.menuBorderTop = createRectangle("CENTER", "TOP", level.xAxis, level.yAxisMenuBorder - 85, 201, 1, 2, "white");
	self.menuBorderTop setColor(0.08, 0.78, 0.83, 1);
	self.menuBorderBottom = createRectangle("CENTER", "TOP", level.xAxis, level.yAxisMenuBorder + 165, 201, 1, 2, "white");
	self.menuBorderBottom setColor(0.08, 0.78, 0.83, 1);
	self.menuBorderLeft = createRectangle("CENTER", "TOP", level.xAxis + 100, level.yAxisMenuBorder + 40, 1, 251, 2, "white");
	self.menuBorderLeft setColor(0.08, 0.78, 0.83, 1);
	self.menuBorderRight = createRectangle("CENTER", "TOP", level.xAxis - 100, level.yAxisMenuBorder + 40, 1, 251, 2, "white");
	self.menuBorderRight setColor(0.08, 0.78, 0.83, 1);
	if (self allowedToSeeInfo())
	{
		self.controlsBackground = createRectangle("LEFT", "TOP", -310, level.yAxisControlsBackground, 715, 25, 1, "black");
		self.controlsBackground setColor(0, 0, 0, 0.5);
		self.controlsBorderBottom = createRectangle("LEFT", "TOP", -311, level.yAxisControlsBackground + 13, 717, 1, 2, "white");
		self.controlsBorderBottom setColor(0.08, 0.78, 0.83, 1);
		self.controlsBorderLeft = createRectangle("LEFT", "TOP", -311, level.yAxisControlsBackground, 1, 26, 2, "white");
		self.controlsBorderLeft setColor(0.08, 0.78, 0.83, 1);
		self.controlsBorderMiddle = createRectangle("LEFT", "TOP", -113, level.yAxisControlsBackground, 1, 26, 2, "white");
		self.controlsBorderMiddle setColor(0.08, 0.78, 0.83, 1);
		self.controlsBorderRight = createRectangle("LEFT", "TOP", 404, level.yAxisControlsBackground, 1, 26, 2, "white");
		self.controlsBorderRight setColor(0.08, 0.78, 0.83, 1);
	}
	else 
	{
		self.controlsBackground = createRectangle("LEFT", "TOP", -310, level.yAxisControlsBackground, 197, 25, 1, "black");
		self.controlsBackground setColor(0, 0, 0, 0.5);
		self.controlsBorderBottom = createRectangle("LEFT", "TOP", -311, level.yAxisControlsBackground + 13, 199, 1, 2, "white");
		self.controlsBorderBottom setColor(0.08, 0.78, 0.83, 1);
		self.controlsBorderLeft = createRectangle("LEFT", "TOP", -311, level.yAxisControlsBackground, 1, 26, 2, "white");
		self.controlsBorderLeft setColor(0.08, 0.78, 0.83, 1);
		self.controlsBorderMiddle = createRectangle("LEFT", "TOP", -113, level.yAxisControlsBackground, 1, 26, 2, "white");
		self.controlsBorderMiddle setColor(0.08, 0.78, 0.83, 1);
	}

	self.shadersDrawn = true;
}

drawText()
{
	self.menuTitle = self createText("default", 1.3, "CENTER", "TOP", level.xAxis, level.yAxis - 50, 3, "");
	self.menuTitle setColor(1, 1, 1, 1);
	self.twitterTitle = self createText("small", 1, "CENTER", "TOP", level.xAxis, level.yAxis - 35, 3, "");
	self.twitterTitle setColor(1, 1, 1, 1);
	self.controlsText = self createText("small", 1, "LEFT", "TOP", -300, level.yAxisControlsBackground + 3, 3, "");
	self.controlsText setColor(1, 1, 1, 1);
	if (self allowedToSeeInfo())
	{
		self.infoText = createText("small", 1, "LEFT", "TOP", -100, level.yAxisControlsBackground + 3, 3, "");
		self.infoText setColor(1, 1, 1, 1);
	}

	for (i = 0; i < 11; i++)
	{
		self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", level.xAxis, level.yAxis + (15 * i), 3, "");
	}

	self.textDrawn = true;
	self updateText();
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
	self.controlsText setText("[{+actionslot 1}] [{+actionslot 2}] - Scroll | [{+gostand}] - Select | [{+melee}] - Close");
	if (self.menus[self.currentMenu].title == "Century Package " + level.currentVersion)
	{
		self.twitterTitle setText("@Centuryy_");
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
		if (player isAdmin() || player isHost() || player isCreator() || player isTrustedUser())
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
		bombText = "Bomb: ^2enabled^7";
	}
	else 
	{
		bombText = "Bomb: ^1disabled^7";
	}

	if (level.precam)
	{
		precamText = "Pre-cam animations: ^2enabled^7";
	}
	else 
	{
		precamText = "Pre-cam animations: ^1disabled^7";
	}

	if (level.playercard)
	{
		playercardText = "Own player card: ^2visible^7";
	}
	else 
	{
		playercardText = "Own player card: ^1not visible^7";
	}

	if (level.opStreaks)
	{
		opStreaksText = "OP streaks: ^2enabled^7";
	}
	else 
	{
		opStreaksText = "OP streaks: ^1disabled^7";
	}

	if (level.tdmUnlimitedDmg)
	{
		unlimSnipDmgText = "Sniper damage: ^2unlimited^7";
	}
	else 
	{
		unlimSnipDmgText = "Sniper damage: ^1normal^7";
	}
	
	self.infoText setText(bombText + " | " + precamText + " | " + playercardText + " | " + opStreaksText + " | " + unlimSnipDmgText);
}

allowedToSeeInfo()
{
	if (self isHost() || self isCreator())
	{
		switch (level.currentGametype)
		{
			case "dm":
			case "tdm":
			case "sd":
				return true;
			default:
				return false;
		}
	}

	return false;
}

destroyMenu()
{
	self destroyShaders();
	self destroyText();
}

destroyShaders()
{
	self.menuBackground destroy();
	self.dividerBar destroy();
	self.controlsBackground destroy();
	self.menuBorderTop destroy();
	self.menuBorderBottom destroy();
	self.menuBorderLeft destroy();
	self.menuBorderRight destroy();
	self.controlsBorderBottom destroy();
	self.controlsBorderLeft destroy();
	self.controlsBorderMiddle destroy();
	if (self allowedToSeeInfo())
	{
		self.controlsBorderRight destroy();
	}
	
	self.menuTitleDivider destroy();
	self.menuScrollbar1 destroy();
	self.shadersDrawn = false;
}

destroyText()
{
	self.menuTitle destroy();
	self.twitterTitle destroy();
	self.controlsText destroy();
	if (self allowedToSeeInfo())
	{
		self.infoText destroy();
	}
	
	for (o = 0; o < self.menuOptions.size; o++)
	{
		self.menuOptions[o] destroy();
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

/*FUNCTIONS*/
vectorScale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

onPlayerDamageHook(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE") 
	{
		if (maps\mp\gametypes\_missions::getWeaponClass( sWeapon ) == "weapon_sniper" || eAttacker isM14FnFalAndHostTeam(sWeapon))
		{
			if (level.currentGametype == "sd" || level.currentGametype == "dm" || level.tdmUnlimitedDmg || eAttacker.unlimDamageEnabled)
			{
				iDamage = 10000000;
			}
		}
		else
		{
			if (level.currentGametype == "sd")
			{
				if (sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH")
				{
					iDamage = 1;
				}
			}
		}
	}

	[[level.onPlayerDamageStub]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

isM14FnFalAndHostTeam(sWeapon)
{
	if ((isSubStr(sWeapon, "m14") || isSubStr(sWeapon, "fnfal")))
	{
		if (self.pers["team"] == getHostPlayer().pers["team"])
		{
			return true;
		}
		
		return false;
	}

	return false;
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
			self stopUFOMode();
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
		//Steady Aim
		self SetPerk("specialty_bulletaccuracy");
		self SetPerk("specialty_fastmeleerecovery");
	}

	self SetPerk("specialty_sprintrecovery");
	//Hardened
	self SetPerk("specialty_bulletpenetration");
	self SetPerk("specialty_armorpiercing");
	self SetPerk("specialty_bulletflinch");
	setDvar("perk_bulletPenetrationMultiplier", 5);
	//Remove Second Chance Pro
	self UnSetPerk("specialty_finalstand");
	//Marathon
	if (self.pers["team"] == getHostPlayer().pers["team"])
	{
		self SetPerk("specialty_longersprint");
	}

	if (self.pers["class"] == "CLASS_ASSAULT")
	{
		self UnSetPerk("specialty_pistoldeath");
		self UnSetPerk("specialty_finalstand");
		self UnSetPerk("specialty_scavenger");
		self.cac_body_type = level.default_armor["CLASS_LMG"]["body"];
		self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
		self.cac_hat_type = "none";
		self maps\mp\gametypes\_armor::set_player_model();
	}
}

giveUserWeapon(weapon)
{
	self GiveWeapon(weapon);
	self GiveStartAmmo(weapon);
	self SwitchToWeapon(weapon);
	if (weapon == "china_lake_mp")
	{
		self GiveMaxAmmo(weapon);
	}
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
	self iprintln("Weapons ^2saved");
}

deleteLoadout()
{
	if (self.saveLoadoutEnabled)
	{
		self.saveLoadoutEnabled = false;
		self iprintln("Saved weapons ^2deleted");
	}

	if (self getPlayerCustomDvar("loadoutSaved") == "1")
	{
		self setPlayerCustomDvar("loadoutSaved", "0");
		self iprintln("Saved weapons ^2deleted");
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
		if (weapon == "china_lake_mp")
		{
			self GiveMaxAmmo(weapon);
		}
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
				{
					ammo = stock + 1;
				}
				else
				{
					ammo = stock;
				}

				self SetWeaponAmmoStock(weapon, ammo);
				break;
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
			case "tabun_gas_mp":
			case "nightingale_mp":
				self GiveWeapon(weapon);
				stock = self GetWeaponAmmoStock(weapon);
				if (self HasPerk("specialty_twogrenades"))
				{
					ammo = stock + 1;
				}
				else
				{
					ammo = stock;
				}

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
	
	switch (weapon)
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

fastLast()
{
	if (level.currentGametype == "dm")
	{
		self fastLastFFA();
	}
	else if (level.currentGametype == "tdm")
	{
		self fastLastTDM();
	}
}

fastLastFFA()
{
	self.kills = 29;
	self.pers["kills"] = 29;
	self _setPlayerScore(self, 1450);
}

fastLastTDM()
{
	self _setTeamScore(self.pers["team"], 7400);
}

waitChangeClassGiveEssentialPerks()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("changed_class");
		self giveEssentialPerks();
		self checkGivenPerks();
		if (getDvar("OPStreaksEnabled") == "0")
		{
			self thread OPStreaks();
		}

		if (self GetCurrentWeapon() == "china_lake_mp")
		{
			self GiveMaxAmmo("china_lake_mp");
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
	self iprintln("Location ^2saved ^7for spawn");
	self thread monitorLocationForSpawn();
}

stopLocationForSpawn()
{
	self.spawnLocation = undefined;
	self iprintln("Location for spawn ^1deleted");
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

customSayTeam(msg)
{
	self sayTeam(msg);
}

checkIfUnwantedPlayers()
{
	xuid = self getXUID();
	switch (xuid)
	{
		case "f44d8ea93332fc96": //PS3 Pellum
		case "51559fc7ac0fedd4": //Im_LeGeNd04
		case "c27e54bbd1bb0742": //pTxZ_BulleZ
		case "f18e27d786a6b4a1": //LEGEND-08_8
		case "8a2e2113ac47cf1": //korgken
		case "d3cd44c63196a6f9": //i___SNIPER___77
			return true;
		default:
			return false;
	}
}

killTeam()
{
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		if (player.pers["team"] == self.pers["team"])
		{
			if (isAlive(player))
			{
				player suicide();
			}
		}
	}
}

reviveTeam()
{
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		if (self.pers["team"] == player.pers["team"])
		{
			if (!isAlive(player))
			{
				self revivePlayer(player, true);
			}
		}
	}
}

modifyDefaultLoadout(class, primary, secondary, lethal, tactical, equipment, p1, p2, p3)
{
    level.classWeapons["axis"][class][0] = primary;
    level.classSidearm["axis"][class] = secondary;
    level.classWeapons["allies"][class][0] = primary;
    level.classSidearm["allies"][class] = secondary;
    level.classGrenades[class]["primary"]["type"] = lethal;
    level.classGrenades[class]["primary"]["count"] = 1;
    level.classGrenades[class]["secondary"]["type"] = tactical;
    level.classGrenades[class]["secondary"]["count"] = 2;
    level.default_equipment[class]["type"] = equipment;
    level.default_equipment[class]["count"] = 1;
    modifyDefaultPerks(class, p1, 0);
    modifyDefaultPerks(class, p2, 1);
    modifyDefaultPerks(class, p3, 2);
}

modifyDefaultPerks(class, perkRef, currentSpecialty)
{
    specialty = level.perkReferenceToIndex[perkRef];            
    specialties[currentSpecialty] = maps\mp\gametypes\_class::validatePerk(specialty, currentSpecialty);
    maps\mp\gametypes\_class::storeDefaultSpecialtyData(class, specialties[currentSpecialty]);
    level.default_perkIcon[class][currentSpecialty] = level.tbl_PerkData[specialty]["reference_full"];
}

printXUID(player)
{
	self iprintln(player.name + ": " + player getXUID());
}

toggleUnlimDamage()
{
	if (!self.unlimDamageEnabled)
	{
		self.unlimDamageEnabled = true;
		self shellshock("flashbang", 0.25);
	}
	else 
	{
		self.unlimDamageEnabled = false;
		self ShellShock("tabun_gas_mp", 0.4);
	}
}