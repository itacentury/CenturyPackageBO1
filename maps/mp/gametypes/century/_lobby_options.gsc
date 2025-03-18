#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

toggleBomb() {
	if (getDvarInt("bombEnabled") != 0) {
		setDvar("bombEnabled", "0");
		level.bombEnabled = false;
		self iPrintLn("Bomb ^2disabled");
	}
	else {
		setDvar("bombEnabled", "1");
		level.bombEnabled = true;
		self iPrintLn("Bomb ^1enabled");
	}

    self maps\mp\gametypes\_clientids::updateInfoText();
}

togglePrecamAnims() {
	if (getDvar("cg_nopredict") == "0") {
		setDvar("cg_nopredict", "1");
		level.precam = true;
		self iPrintLn("Precam ^2enabled");
	}
	else if (getDvar("cg_nopredict") == "1") {
		setDvar("cg_nopredict", "0");
		level.precam = false;
		self iPrintLn("Precam ^1disabled");
	}

    self maps\mp\gametypes\_clientids::updateInfoText();
}

toggleUnfairStreaks() {
	if (getDvar("UnfairStreaksEnabled") != "0") {
		for (i = 0; i < level.players.size; i++) {
			player = level.players[i];
            if (!isAlive(player)) {
                continue;
            }
            
			player unsetUnfairStreaks();
		}

		setDvar("UnfairStreaksEnabled", "0");
		level.unfairStreaks = false;
		self iPrintLn("Unfair streaks ^2disabled");
	}
	else {
		setDvar("UnfairStreaksEnabled", "1");
		level.unfairStreaks = true;
		self iPrintLn("Unfair streaks ^1enabled");
	}

    self maps\mp\gametypes\_clientids::updateInfoText();
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

toggleUnlimitedSniperDmg() {
	if (!level.unlimitedSniperDmg) {
		level.unlimitedSniperDmg = true;
		self iPrintLn("Unlimited sniper damage ^2enabled");
	}
	else {
		level.unlimitedSniperDmg = false;
		self iPrintLn("Unlimited sniper damage ^1disabled");
	}

    self maps\mp\gametypes\_clientids::updateInfoText();
}

toggleTime() {
	if (getDvar("timeExtensionEnabled") == "0") {
		setDvar("timeExtensionEnabled", "1");
		level.timeExtensionEnabled = true;
		self iPrintLn("Automatic time extension ^2enabled");
	}
	else {
		setDvar("timeExtensionEnabled", "0");
		level.timeExtensionEnabled = false;
		self iPrintLn("Automatic time extension ^1disabled");
	}

    self maps\mp\gametypes\_clientids::updateInfoText();
}
