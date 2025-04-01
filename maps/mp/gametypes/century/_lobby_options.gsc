#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

toggleBomb() {
	if (getDvarInt("bombEnabled") == 0 || getDvar("bombEnabled") == "") {
		setDvar("bombEnabled", 1);
		level.bombEnabled = true;
		self iPrintLn("Bomb ^1enabled");
	}
	else {
		setDvar("bombEnabled", 0);
		level.bombEnabled = false;
		self iPrintLn("Bomb ^2disabled");
	}

    self maps\mp\gametypes\century\_menu::updateInfoText();
}

togglePrecamAnims() {
	if (getDvarInt("cg_nopredict") == 0 || getDvar("cg_nopredict") == "") {
		setDvar("cg_nopredict", 1);
		level.precam = true;
		self iPrintLn("Precam ^2enabled");
	}
	else {
		setDvar("cg_nopredict", 0);
		level.precam = false;
		self iPrintLn("Precam ^1disabled");
	}

    self maps\mp\gametypes\century\_menu::updateInfoText();
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
		level.unfairStreaks = false;
		self iPrintLn("Unfair streaks ^2disabled");
	}
	else {
		setDvar("UnfairStreaksEnabled", 1);
		level.unfairStreaks = true;
		self iPrintLn("Unfair streaks ^1enabled");
	}

    self maps\mp\gametypes\century\_menu::updateInfoText();
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

toggleUnlimitedSniperDamage() {
	if (!level.unlimitedSniperDmg) {
		level.unlimitedSniperDmg = true;
		self iPrintLn("Unlimited sniper damage ^2enabled");
	}
	else {
		level.unlimitedSniperDmg = false;
		self iPrintLn("Unlimited sniper damage ^1disabled");
	}

    self maps\mp\gametypes\century\_menu::updateInfoText();
}

toggleTimeExtension() {
	if (getDvarInt("timeExtensionEnabled") == 0 || getDvar("timeExtensionEnabled") == "") {
		setDvar("timeExtensionEnabled", 1);
		level.timeExtensionEnabled = true;
		self iPrintLn("Automatic time extension ^2enabled");
	}
	else {
		setDvar("timeExtensionEnabled", 0);
		level.timeExtensionEnabled = false;
		self iPrintLn("Automatic time extension ^1disabled");
	}

    self maps\mp\gametypes\century\_menu::updateInfoText();
}
