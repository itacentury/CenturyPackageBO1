#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

addMinuteToTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit + 1);
	self maps\mp\gametypes\_clientids::printInfoMessage("Minute ^2added");
}

removeMinuteFromTimer()
{
	timeLimit = getDvarInt("scr_" + level.currentGametype + "_timelimit");
	setDvar("scr_" + level.currentGametype + "_timelimit", timelimit - 1);
	self maps\mp\gametypes\_clientids::printInfoMessage("Minute ^2removed");
}

toggleTimer()
{
	if (!level.timerPaused)
	{
		maps\mp\gametypes\_globallogic_utils::pausetimer();
		self maps\mp\gametypes\_clientids::printInfoMessage("Timer ^2paused");
		level.timerPaused = true;
	}
	else 
	{
		self maps\mp\gametypes\_globallogic_utils::resumetimer();
		self maps\mp\gametypes\_clientids::printInfoMessage("Timer ^2resumed");
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

		self maps\mp\gametypes\_clientids::printInfoMessage("Azza ^2enabled");
	}
}

toggleBomb()
{
	if (getDvar("bombEnabled") == "0")
	{
		setDvar("bombEnabled", "1");
		self maps\mp\gametypes\_clientids::printInfoMessage("Bomb ^2enabled");
	}
	else 
	{
		setDvar("bombEnabled", "0");
		self maps\mp\gametypes\_clientids::printInfoMessage("Bomb ^1disabled");
	}
}

precamOTS()
{
	if (getDvar("cg_nopredict") == "0")
	{
		setDvar("cg_nopredict", "1");
		self maps\mp\gametypes\_clientids::printInfoMessage("Precam ^2enabled");
	}
	else if (getDvar("cg_nopredict") == "1")
	{
		setDvar("cg_nopredict", "0");
		self maps\mp\gametypes\_clientids::printInfoMessage("Precam ^1disabled");
	}
}

togglePlayercard()
{
	if (getDvar("killcam_final") != "1")
	{
		setDvar("killcam_final", "1");
		self maps\mp\gametypes\_clientids::printInfoMessage("Own playercard ^2visible ^7in killcam");
	}
	else 
	{
		setDvar("killcam_final", "0");
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
			player thread OPStreaks();
		}

		setDvar("OPStreaksEnabled", "0");
		self maps\mp\gametypes\_clientids::printInfoMessage("OP streaks ^1disabled");
	}
	else
	{
		setDvar("OPStreaksEnabled", "1");
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

bounce()
{
	if (level.bounceSpawned == 0)
	{
		level.modelBounce = spawn( "script_model", self.origin );
		level.modelBounce setModel("mp_supplydrop_ally");
		level.bounceSpawned++;
		self maps\mp\gametypes\_clientids::printInfoMessage("Bounce ^2Spawned ^7on your position!");
		
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			player thread monitorTrampoline();
		}
	}
	else 
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("Only can spawn ^1one^7 bounce");
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
		self maps\mp\gametypes\_clientids::printInfoMessage("Bounce ^2deleted");
		level.bounceSpawned = 0;
	}
	else 
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1No ^7bounce spawned");
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
			self maps\mp\gametypes\_clientids::printInfoMessage("Bounce is now ^2Invisible");
		}
		else
		{
			level.modelBounce show();
			level.bounceInvisible = false;
			self maps\mp\gametypes\_clientids::printInfoMessage("Bounce is now ^2Visible");
		}
	}
	else 
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1No ^7bounce spawned");
	}
}

toggleMoveBounce()
{
	if (level.bounceSpawned == 1)
	{
		if (!self.movingBounce)
		{
			self maps\mp\gametypes\_clientids::exitMenu();
			self thread moveBounce();
			self.movingBounce = true;
		}
		else if (self.movingBounce)
		{
			self maps\mp\gametypes\_clientids::ufoMessage1Fade();
			self maps\mp\gametypes\_clientids::ufoMessage2Fade();
			self maps\mp\gametypes\_clientids::ufoMessage3Fade();
			self notify("stop_moveBounce");
			self enableoffhandweapons();
			self.movingBounce = false;
		}
	}
	else 
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1No ^7bounce spawned");
	}
}

moveBounce()
{
	self endon("disconnect");
	self endon("stop_moveBounce");
	
	self maps\mp\gametypes\_clientids::printUFOMessage1("Press [{+speed_throw}] to ^3Move the Bounce");
	self maps\mp\gametypes\_clientids::printUFOMessage2("Press [{+smoke}]/[{+frag}] to ^3Rotate ^7/ ^3Roll");
	self maps\mp\gametypes\_clientids::printUFOMessage3("Press [{+melee}] to ^1Stop ^7moving the Bounce");
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