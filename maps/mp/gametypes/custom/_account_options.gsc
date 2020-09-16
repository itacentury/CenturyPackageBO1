#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

levelFifty()
{
	if (level.players.size > 1)
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1Too many ^7players in your game!");
		return;
	}

	self maps\mp\gametypes\_persistence::statSet("rankxp", 1262500, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "rankxp", 1262500);
	self.pers["rank"] = 49;
	
	self setRank(49);
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();
}

prestigeSelector()
{
	if (level.players.size > 1)
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1Too many ^7players in your game!");
		return;
	}
	
	self endon("disconnect");
	self endon("stop_PrestigeSelector");
	
	self thread initPrestigeShaders();
	self freezecontrolsAllowLook(true);
	self.prestigeback = self createRectanglePrestige("CENTER", "", 0, -150, 1000, 50, (0, 0, 0), "white", 3, 1);
	self.textz = self createFontString("objective", 1.8, self);
	t = 0;
	self.scrollz = 0;
	self.textz setText(t);
	self.textz setPoint("CENTER", "CENTER", 0, -100);
	self.textz.sort = 100;
	self maps\mp\gametypes\_clientids::exitMenu();
	self maps\mp\gametypes\_clientids::printUFOMessage1("Press [{+speed_throw}]/ [{+attack}] to ^3change the current Prestige");
	self maps\mp\gametypes\_clientids::printUFOMessage2("Press [{+usereload}] to ^2select ^7the current Prestige");
	self maps\mp\gametypes\_clientids::printUFOMessage3("Press [{+melee}] to ^1Stop ^7the selection");
	
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

			self maps\mp\gametypes\_clientids::ufoMessage1Fade();
			self maps\mp\gametypes\_clientids::ufoMessage2Fade();
			self maps\mp\gametypes\_clientids::ufoMessage3Fade();
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
			self maps\mp\gametypes\_clientids::ufoMessage1Fade();
			self maps\mp\gametypes\_clientids::ufoMessage2Fade();
			self maps\mp\gametypes\_clientids::ufoMessage3Fade();

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
				self.pres0 setPoint("CENTER", "CENTER", (self.pres0.xOffset + 50), -150);
				self.pres1 setPoint("CENTER", "CENTER", (self.pres1.xOffset + 50), -150);
				self.pres2 setPoint("CENTER", "CENTER", (self.pres2.xOffset + 50), -150);
				self.pres3 setPoint("CENTER", "CENTER", (self.pres3.xOffset + 50), -150);
				self.pres4 setPoint("CENTER", "CENTER", (self.pres4.xOffset + 50), -150);
				self.pres5 setPoint("CENTER", "CENTER", (self.pres5.xOffset + 50), -150);
				self.pres6 setPoint("CENTER", "CENTER", (self.pres6.xOffset + 50), -150);
				self.pres7 setPoint("CENTER", "CENTER", (self.pres7.xOffset + 50), -150);
				self.pres8 setPoint("CENTER", "CENTER", (self.pres8.xOffset + 50), -150);
				self.pres9 setPoint("CENTER", "CENTER", (self.pres9.xOffset + 50), -150);
				self.pres10 setPoint("CENTER", "CENTER", (self.pres10.xOffset + 50), -150);
				self.pres11 setPoint("CENTER", "CENTER", (self.pres11.xOffset + 50), -150);
				self.pres12 setPoint("CENTER", "CENTER", (self.pres12.xOffset + 50), -150);
				self.pres13 setPoint("CENTER", "CENTER", (self.pres13.xOffset + 50), -150);
				self.pres14 setPoint("CENTER", "CENTER", (self.pres14.xOffset + 50), -150);
				self.pres15 setPoint("CENTER", "CENTER", (self.pres15.xOffset + 50), -150);
			}
			else
			{
				self.scrollz = 15;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER", "CENTER", -750, -150);
				self.pres1 setPoint("CENTER", "CENTER", -700, -150);
				self.pres2 setPoint("CENTER", "CENTER", -650, -150);
				self.pres3 setPoint("CENTER", "CENTER", -600, -150);
				self.pres4 setPoint("CENTER", "CENTER", -550, -150);
				self.pres5 setPoint("CENTER", "CENTER", -500, -150);
				self.pres6 setPoint("CENTER", "CENTER", -450, -150);
				self.pres7 setPoint("CENTER", "CENTER", -400, -150);
				self.pres8 setPoint("CENTER", "CENTER", -350, -150);
				self.pres9 setPoint("CENTER", "CENTER", -300, -150);
				self.pres10 setPoint("CENTER", "CENTER", -250, -150);
				self.pres11 setPoint("CENTER", "CENTER", -200, -150);
				self.pres12 setPoint("CENTER", "CENTER", -150, -150);
				self.pres13 setPoint("CENTER", "CENTER", -100, -150);
				self.pres14 setPoint("CENTER", "CENTER", -50, -150);
				self.pres15 setPoint("CENTER", "CENTER", 0, -150);
			}
		}

		if (self AttackButtonPressed())
		{
			if (self.scrollz <= 14 && self.scrollz >= 0)
			{
				self.scrollz += 1;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER", "CENTER", (self.pres0.xOffset - 50), -150);
				self.pres1 setPoint("CENTER", "CENTER", (self.pres1.xOffset - 50), -150);
				self.pres2 setPoint("CENTER", "CENTER", (self.pres2.xOffset - 50), -150);
				self.pres3 setPoint("CENTER", "CENTER", (self.pres3.xOffset - 50), -150);
				self.pres4 setPoint("CENTER", "CENTER", (self.pres4.xOffset - 50), -150);
				self.pres5 setPoint("CENTER", "CENTER", (self.pres5.xOffset - 50), -150);
				self.pres6 setPoint("CENTER", "CENTER", (self.pres6.xOffset - 50), -150);
				self.pres7 setPoint("CENTER", "CENTER", (self.pres7.xOffset - 50), -150);
				self.pres8 setPoint("CENTER", "CENTER", (self.pres8.xOffset - 50), -150);
				self.pres9 setPoint("CENTER", "CENTER", (self.pres9.xOffset - 50), -150);
				self.pres10 setPoint("CENTER", "CENTER", (self.pres10.xOffset - 50), -150);
				self.pres11 setPoint("CENTER", "CENTER", (self.pres11.xOffset - 50), -150);
				self.pres12 setPoint("CENTER", "CENTER", (self.pres12.xOffset - 50), -150);
				self.pres13 setPoint("CENTER", "CENTER", (self.pres13.xOffset - 50), -150);
				self.pres14 setPoint("CENTER", "CENTER", (self.pres14.xOffset - 50), -150);
				self.pres15 setPoint("CENTER", "CENTER", (self.pres15.xOffset - 50), -150);
			}
			else
			{
				self.scrollz = 0;

				wait .1;

				self.textz setText(self.scrollz);
				self.pres0 setPoint("CENTER", "CENTER", 0, -150);
				self.pres1 setPoint("CENTER", "CENTER", 50, -150);
				self.pres2 setPoint("CENTER", "CENTER", 100, -150);
				self.pres3 setPoint("CENTER", "CENTER", 150, -150);
				self.pres4 setPoint("CENTER", "CENTER", 200, -150);
				self.pres5 setPoint("CENTER", "CENTER", 250, -150);
				self.pres6 setPoint("CENTER", "CENTER", 300, -150);
				self.pres7 setPoint("CENTER", "CENTER", 350, -150);
				self.pres8 setPoint("CENTER", "CENTER", 400, -150);
				self.pres9 setPoint("CENTER", "CENTER", 450, -150);
				self.pres10 setPoint("CENTER", "CENTER", 500, -150);
				self.pres11 setPoint("CENTER", "CENTER", 550, -150);
				self.pres12 setPoint("CENTER", "CENTER", 600, -150);
				self.pres13 setPoint("CENTER", "CENTER", 650, -150);
				self.pres14 setPoint("CENTER", "CENTER", 700, -150);
				self.pres15 setPoint("CENTER", "CENTER", 750, -150);
			}
		}

		wait .1;
	}
}
initPrestigeShaders()
{
	self.pres0 = createprestige("CENTER", "CENTER", 0, -150, 50, 50, "rank_com", 100, 1);
	self.pres1 = createprestige("CENTER", "CENTER", 50, -150, 50, 50, "rank_prestige01", 100, 1);
	self.pres2 = createprestige("CENTER", "CENTER", 100, -150, 50, 50, "rank_prestige02", 100, 1);
	self.pres3 = createprestige("CENTER", "CENTER", 150, -150, 50, 50, "rank_prestige03", 100, 1);
	self.pres4 = createprestige("CENTER", "CENTER", 200, -150, 50, 50, "rank_prestige04", 100, 1);
	self.pres5 = createprestige("CENTER", "CENTER", 250, -150, 50, 50, "rank_prestige05", 100, 1);
	self.pres6 = createprestige("CENTER", "CENTER", 300, -150, 50, 50, "rank_prestige06", 100, 1);
	self.pres7 = createprestige("CENTER", "CENTER", 350, -150, 50, 50, "rank_prestige07", 100, 1);
	self.pres8 = createprestige("CENTER", "CENTER", 400, -150, 50, 50, "rank_prestige08", 100, 1);
	self.pres9 = createprestige("CENTER", "CENTER", 450, -150, 50, 50, "rank_prestige09", 100, 1);
	self.pres10 = createprestige("CENTER", "CENTER", 500, -150, 50, 50, "rank_prestige10", 100, 1);
	self.pres11 = createprestige("CENTER", "CENTER", 550, -150, 50, 50, "rank_prestige11", 100, 1);
	self.pres12 = createprestige("CENTER", "CENTER", 600, -150, 50, 50, "rank_prestige12", 100, 1);
	self.pres13 = createprestige("CENTER", "CENTER", 650, -150, 50, 50, "rank_prestige13", 100, 1);
	self.pres14 = createprestige("CENTER", "CENTER", 700, -150, 50, 50, "rank_prestige14", 100, 1);
	self.pres15 = createprestige("CENTER", "CENTER", 750, -150, 50, 50, "rank_prestige15", 100, 1);
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

	self setRank(self.pers["rank"], value);
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();

	self freezeControlsAllowLook(false);
}

UnlockAll()
{
	if (level.players.size > 1)
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1Too many ^7players in your game!");
		return;
	}

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

	setDvar("allItemsUnlocked", "1");
	setDvar("allEmblemsUnlocked", "1");

	self maps\mp\gametypes\_clientids::printInfoMessage("All perks ^2unlocked");
}

giveCODPoints()
{
	if (level.players.size > 1)
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("^1Too many ^7players in your game!");
		return;
	}
	
	self maps\mp\gametypes\_persistence::statSet("codpoints", 100000000, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "codpoints", 100000000);
	self maps\mp\gametypes\_persistence::setPlayerStat("PlayerStatsList", "CODPOINTS", 100000000);
	self.pers["codpoints"] = 100000000;
	self maps\mp\gametypes\_clientids::printInfoMessage("CoD Points ^2given");
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
		self maps\mp\gametypes\_clientids::printInfoMessage("Ranked match ^2enabled");
		level.rankedMatchEnabled = true;
	}
	else 
	{
		self maps\mp\gametypes\_clientids::printInfoMessage("Ranked match ^1already ^7enabled");
	}
}