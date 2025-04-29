#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_globallogic_score;

fastLastTDM() {
    self _setTeamScore(self.pers["team"], 7400);
}

toggleUnlimitedSniperDamage() {
	if (!level.unlimitedSniperDmg) {
		level.unlimitedSniperDmg = true;
		self iPrintLn("Unlimited sniper damage ^2enabled");
	}
	else {
		level.unlimitedSniperDmg = false;
		self iPrintLn("Unlimited sniper damage ^1disabled");
	}

    self maps\mp\mod\hud::updateInfoText();
}

toggleBomb() {
	if (getDvarInt("bombEnabled") == 0 || getDvar("bombEnabled") == "") {
        restoreBombTriggers();

		setDvar("bombEnabled", 1);
		self iPrintLn("Bomb ^1enabled");
	}
	else {
        removeBombTriggers();

		setDvar("bombEnabled", 0);
		self iPrintLn("Bomb ^2disabled");
	}

    self maps\mp\mod\hud::updateInfoText();
}

toggleTimeExtension() {
	if (getDvarInt("timeExtensionEnabled") == 0 || getDvar("timeExtensionEnabled") == "") {
		setDvar("timeExtensionEnabled", 1);
		self iPrintLn("Automatic time extension ^2enabled");
	}
	else {
		setDvar("timeExtensionEnabled", 0);
		self iPrintLn("Automatic time extension ^1disabled");
	}

    self maps\mp\mod\hud::updateInfoText();
}

togglePrecamAnims() {
	if (getDvarInt("cg_nopredict") == 0 || getDvar("cg_nopredict") == "") {
		setDvar("cg_nopredict", 1);
		self iPrintLn("Precam ^2enabled");
	}
	else {
		setDvar("cg_nopredict", 0);
		self iPrintLn("Precam ^1disabled");
	}

    self maps\mp\mod\hud::updateInfoText();
}

toggleUnfairStreaks() {
	if (getDvarInt("UnfairStreaksEnabled") == 1 || getDvar("UnfairStreaksEnabled") == "") {
		for (i = 0; i < level.players.size; i++) {
			player = level.players[i];
            if (!isAlive(player)) {
                continue;
            }
            
			player unsetUnfairStreaks();
		}

		setDvar("UnfairStreaksEnabled", 0);
		self iPrintLn("Unfair streaks ^2disabled");
	}
	else {
		setDvar("UnfairStreaksEnabled", 1);
		self iPrintLn("Unfair streaks ^1enabled");
	}

    self maps\mp\mod\hud::updateInfoText();
}

unsetUnfairStreaks() {
	for (i = 0; i < self.killstreak.size; i++) {
        if (!isDefined(self.killstreak[i])) {
            continue;
        }
        
		if (!isUnfairStreak(self.killstreak[i])) {
            continue;
        }

        self.killstreak[i] = "killstreak_null";
	}
}

isUnfairStreak(streak) {
	switch (streak) {
		case "killstreak_helicopter_comlink":
		case "killstreak_helicopter_gunner":
		case "killstreak_dogs":
		case "killstreak_helicopter_player_firstperson":
			return true;
		default:
			return false;
	}
}

restoreBombTriggers() {
    for (i = 0; i < level.bombZones.size; i++) {
        level.bombZones[i].trigger triggerOn();
    }
}

removeBombTriggers() {
    for (i = 0; i < level.bombZones.size; i++) {
        level.bombZones[i].trigger triggerOff();
    }
}
