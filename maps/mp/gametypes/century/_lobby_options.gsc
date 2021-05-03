#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

toggleBomb()
{
	if (getDvar("bombEnabled") == "0")
	{
		setDvar("bombEnabled", "1");
		level.bombEnabled = true;
		self iprintln("Bomb ^2enabled");
	}
	else 
	{
		setDvar("bombEnabled", "0");
		level.bombEnabled = false;
		self iprintln("Bomb ^1disabled");
	}

	if (self maps\mp\gametypes\_clientids::allowedToSeeInfo())
	{
		self maps\mp\gametypes\_clientids::updateInfoTextAllPlayers();
	}
}

precamOTS()
{
	if (getDvar("cg_nopredict") == "0")
	{
		setDvar("cg_nopredict", "1");
		level.precam = true;
		self iprintln("Precam ^2enabled");
	}
	else if (getDvar("cg_nopredict") == "1")
	{
		setDvar("cg_nopredict", "0");
		level.precam = false;
		self iprintln("Precam ^1disabled");
	}

	if (self maps\mp\gametypes\_clientids::allowedToSeeInfo())
	{
		self maps\mp\gametypes\_clientids::updateInfoTextAllPlayers();
	}
}

togglePlayercard()
{
	if (getDvar("killcam_final") != "1")
	{
		setDvar("killcam_final", "1");
		level.playercard = true;
		self iprintln("Own playercard ^2visible ^7in killcam");
		for (i = 0; i < level.players.size; i++)
		{
			level.players[i] setClientDvar("killcam_final", "1");
		}
	}
	else 
	{
		setDvar("killcam_final", "0");
		level.playercard = false;
		self iprintln("Own playercard ^1not visible ^7in killcam");
		for (i = 0; i < level.players.size; i++)
		{
			level.players[i] setClientDvar("killcam_final", "0");
		}
	}

	if (self maps\mp\gametypes\_clientids::allowedToSeeInfo())
	{
		self maps\mp\gametypes\_clientids::updateInfoTextAllPlayers();
	}
}

toggleOPStreaks()
{
	if (getDvar("OPStreaksEnabled") != "0")
	{
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			player thread OPStreaks();
		}

		setDvar("OPStreaksEnabled", "0");
		level.opStreaks = false;
		self iprintln("OP streaks ^1disabled");
	}
	else
	{
		setDvar("OPStreaksEnabled", "1");
		level.opStreaks = true;
		self iprintln("OP streaks ^2enabled");
	}

	if (level.currentGametype != "dom")
	{
		self maps\mp\gametypes\_clientids::updateInfoTextAllPlayers();
	}
}

OPStreaks()
{
	for (i = 0; i < self.killstreak.size; i++)
	{
		if (isForbiddenStreak(self.killstreak[i]))
		{
			if (isDefined(self.killstreak[i]))
			{
				self.killstreak[i] = "killstreak_null";
			}
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

toggleUnlimitedSniperDmg()
{
	if (!level.tdmUnlimitedDmg)
	{
		level.tdmUnlimitedDmg = true;
		self iprintln("Unlimited sniper damage ^2enabled");
	}
	else 
	{
		level.tdmUnlimitedDmg = false;
		self iprintln("Unlimited sniper damage ^1disabled");
	}

	if (self maps\mp\gametypes\_clientids::allowedToSeeInfo())
	{
		self maps\mp\gametypes\_clientids::updateInfoTextAllPlayers();
	}
}
