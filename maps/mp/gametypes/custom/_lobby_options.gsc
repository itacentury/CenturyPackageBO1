#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

addMinuteToTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 1);
}

removeMinuteFromTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit - 1);
}

toggleTimer()
{
	if (!level.timerPaused)
	{
		maps\mp\gametypes\_globallogic_utils::pausetimer();
		level.timerPaused = true;
	}
	else 
	{
		self maps\mp\gametypes\_globallogic_utils::resumetimer();
		level.timerPaused = false;
	}
}

toggleMultipleSetups()
{
	if (level.multipleSetupsEnabled)
	{
		level.multipleSetupsEnabled = false;
		self maps\mp\gametypes\_clientids::printInfoMessage("Multiple setups ^1Disabled");
	}
	else
	{
		level.multipleSetupsEnabled = true;
		self maps\mp\gametypes\_clientids::printInfoMessage("Multiple setups ^2Enabled");
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
	bot ClearPerks();
}

toggleAzza()
{
	if (getDvar("isAzza") == "1")
	{
		level.azza = false;
		setDvar("isAzza", "0");

		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			if (!player.isAdmin)
			{
				if (player.isInMenu)
				{
					player ClearAllTextAfterHudelem();
					player maps\mp\gametypes\_clientids::exitMenu();
				}
			}
		}

		self maps\mp\gametypes\_clientids::printInfoMessage("Azza ^1disabled");
	}
	else
	{
		level.rankedMatch = true;
		level.contractsEnabled = true;
		level.azza = true;
		setDvar("isAzza", "1");
		self maps\mp\gametypes\_clientids::printInfoMessage("Azza ^2enabled");

		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			if (player != getHostPlayer())
			{
				player maps\mp\gametypes\_clientids::runController();
				player maps\mp\gametypes\_clientids::buildMenu();
				player maps\mp\gametypes\_clientids::drawMessages();
			}

			if (player isHost())
			{
				player maps\mp\gametypes\_clientids::addTimeToGame();
			}

			if (!player is_bot())
			{
				if (player.pers["team"] != "allies")
				{
					player maps\mp\gametypes\_clientids::changeMyTeam("allies");
				}
			}
			else
			{
				if (player.pers["team"] != "axis")
				{
					player maps\mp\gametypes\_clientids::changeMyTeam("axis");
				}
			}

			player maps\mp\gametypes\_clientids::setMatchBonus();
		}

	}
}

toggleBomb()
{
	if (getDvar("bombEnabled") == "0")
	{
		setDvar("bombEnabled", "1");
		level.bombEnabled = true;
		self maps\mp\gametypes\_clientids::printInfoMessage("Bomb ^2enabled");
	}
	else 
	{
		setDvar("bombEnabled", "0");
		level.bombEnabled = false;
		self maps\mp\gametypes\_clientids::printInfoMessage("Bomb ^1disabled");
	}
}

precamOTS()
{
	if (getDvar("cg_nopredict") == "0")
	{
		setDvar("cg_nopredict", "1");
		level.precam = true;
		self maps\mp\gametypes\_clientids::printInfoMessage("Precam ^2enabled");
	}
	else if (getDvar("cg_nopredict") == "1")
	{
		setDvar("cg_nopredict", "0");
		level.precam = false;
		self maps\mp\gametypes\_clientids::printInfoMessage("Precam ^1disabled");
	}
}

togglePlayercard()
{
	if (getDvar("killcam_final") != "1")
	{
		setDvar("killcam_final", "1");
		level.playercard = true;
		self maps\mp\gametypes\_clientids::printInfoMessage("Own playercard ^2visible ^7in killcam");
	}
	else 
	{
		setDvar("killcam_final", "0");
		level.playercard = false;
		self maps\mp\gametypes\_clientids::printInfoMessage("Own playercard ^1not visible ^7in killcam");
	}
}

toggleOPStreaks()
{
	if (getDvar("OPStreaksEnabled") != "0")
	{
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			player OPStreaks();
		}

		setDvar("OPStreaksEnabled", "0");
		level.opStreaks = false;
		self maps\mp\gametypes\_clientids::printInfoMessage("OP streaks ^1disabled");
	}
	else
	{
		setDvar("OPStreaksEnabled", "1");
		level.opStreaks = true;
		self maps\mp\gametypes\_clientids::printInfoMessage("OP streaks ^2enabled");
	}
}

OPStreaks()
{
	for (i = 0; i < self.killstreak.size; i++)
	{
		if (isForbiddenStreak(self.killstreak[i]))
		{
			self.killstreak[i] = "killstreak_null";
		}
	}
}

isForbiddenStreak(streak)
{
	switch (streak)
	{
		case "killstreak_helicopter_comlink":
		case "killstreak_helicopter_gunner":
		case "killstreak_dogs":
		case "killstreak_helicopter_player_firstperson":
			return true;
		default:
			return false;
	}
}
