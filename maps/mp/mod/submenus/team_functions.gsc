#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

customSayTeam(msg) {
	self sayTeam(msg);
}

reviveTeam() {
	for (i = 0; i < level.players.size; i++) {
		player = level.players[i];
		
        if (self.pers["team"] != player.pers["team"]) {
            continue;
        }

        if (isAlive(player)) {
            continue;
        }
        
        self maps\mp\mod\submenus\player_functions::revivePlayer(player, true);
	}
}

killTeam() {
	for (i = 0; i < level.players.size; i++) {
		player = level.players[i];

        if (self.pers["team"] != player.pers["team"]) {
            continue;
        }

        if (!isAlive(player)) {
            continue;
        }
        
        player suicide();
	}
}
