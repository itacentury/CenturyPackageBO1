#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\menu;
#include maps\mp\mod\string_utils;

drawShaders() {
	self.menuBackground1 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 180, 230, 1, "black", true);
	self.menuBackground1 setColor(0, 0, 0, 0.3);
	self.menuBackground2 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 160, 210, 2, "black", true);
	self.menuBackground2 setColor(0, 0, 0, 0.4);
	self.menuScrollbar = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis + (15 * self.currentMenuPosition), 180, 15, 3, "white", true);
	self.menuScrollbar setColor(0.4549, 0.7765, 0.9882, 0.75);
	self.dividerBar1 = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis - 20, 180, 1, 3, "white", true);
	self.dividerBar1 setColor(0.9882, 0.6667, 0.4549, 0.75);
	self.dividerBar2 = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis + 120, 180, 1, 3, "white", true);
	self.dividerBar2 setColor(0.9882, 0.6667, 0.4549, 0.75);

	self.areShadersDrawn = true;
}

destroyShaders() {
    if (!self.areShadersDrawn) {
        return;
    }

	self.menuBackground1 destroy();
	self.menuBackground2 destroy();
	self.dividerBar1 destroy();
	self.dividerBar2 destroy();
	self.menuTitleDivider destroy();
	self.menuScrollbar destroy();

	self.areShadersDrawn = false;
}

drawOverlay() {
    if (level.currentGametype != "sd") {
        return;
    }

    if (!self.overlayEnabled) {
        return;
    }

    self.overlay = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 100, false, "Press [{+speed_throw}] + [{+actionslot 2}] for Century Package");
    self.overlay setColor(1, 1, 1, 0.8);

    self.isOverlayDrawn = true;
}

destroyOverlay() {
    if (level.currentGametype != "sd") {
        return;
    }

    if (!self.overlayEnabled) {
        return;
    }

    self.overlay destroy();
    self.isOverlayDrawn = false;
}

manageReticle() {
    switch (self.menus[self.currentMenu].name) {
        case "WeaponOptionLens":
        case "WeaponOptionReticle":
        case "WeaponOptionReticleColor":
            self drawReticle();
            break;
        default:
            self destroyReticle();
            break;
    }
}

drawReticle() {
	if (self.isReticleDrawn) {
        self destroyReticle();
    }
    
    self.highlight = createRectangle("CENTER", "TOP", level.xAxis + 55, level.yAxis - 42, 30, 30, 99, "menu_mp_weapons_lens_hilight", true);
	self.highlight setColor(1, 1, 1, 1);
	self.lens = createRectangle("CENTER", "TOP", level.xAxis + 55, level.yAxis - 42, 30, 30, 98, "menu_mp_weapons_color_lens", true);
    lensColor = strTok(self.lensColor, ",");
	self.lens setColor(float(lensColor[0]), float(lensColor[1]), float(lensColor[2]), float(lensColor[3]));
	self.reticle = createRectangle("CENTER", "TOP", level.xAxis + 55, level.yAxis - 42, 20, 20, 100, self.reticleShader, true);
    reticleColor = strTok(self.reticleColor, ",");
	self.reticle setColor(float(reticleColor[0]), float(reticleColor[1]), float(reticleColor[2]), float(reticleColor[3]));

    self.isReticleDrawn = true;
}

destroyReticle() {
    if (!self.isReticleDrawn) {
        return;
    }

    self.highlight destroy();
    self.lens destroy();
    self.reticle destroy();

    self.isReticleDrawn = false;
}

drawText() {
	self.menuTitle = self createText("extrabig", 1.3, "CENTER", "TOP", level.xAxis, level.yAxis - 50, 4, true, "");
	self.menuTitle setColor(0.9882, 0.6667, 0.4549, 1);
    self.subTitle = self createText("small", 1, "CENTER", "TOP", level.xAxis, level.yAxis - 35, 4, true, "");
	self.subTitle setColor(1, 1, 1, 1);
	if (self allowedToSeeInfo()) {
		self.infoText = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 4, true, "");
		self.infoText setColor(1, 1, 1, 0.8);
	}

	for (i = 0; i < level.visibleOptions; i++) {
		self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", level.xAxis, level.yAxis + (15 * i), 4, true, "");
	}

	self updateText();

	self.isTextDrawn = true;
}

destroyText() {
    if (!self.isTextDrawn) {
        return;
    }

	self.menuTitle destroy();
	self.subTitle destroy();
    self.infoText destroy();
	
	for (i = 0; i < self.menuOptions.size; i++) {
		self.menuOptions[i] destroy();
	}

	self.isTextDrawn = false;
}

updateText() {
    currentMenu = self getCurrentMenu();
    total = currentMenu.options.size;
    visible = level.visibleOptions;
    anchor = visible / 2;
    
    self.menuTitle setText(toUpper(self.menus[self.currentMenu].title));

    self.subTitle setText("");
    if (total > visible) {
        self.subTitle setText((currentMenu.position + 1) + "/" + total);
    } else if (self.menus[self.currentMenu].name == "main") {
        self.subTitle setText(level.twitterHandle);
    }
    
    if (total <= visible) {
        offset = 0;
    } else if (currentMenu.position <= anchor) {
        offset = 0;
    } else if (currentMenu.position >= total - (visible - anchor)) {
        offset = total - visible;
    } else {
        offset = currentMenu.position - anchor;
    }

    for (i = 0; i < visible; i++) {
        optionIndex = int(offset + i);
        self.menuOptions[i] setText("");
        
        if (optionIndex > total) {
            continue;
        }

        if (currentMenu.options[optionIndex].function == ::openMenu) {
            self.menuOptions[i] setColor(0.2588, 0.6980, 0.9843, 1);
            self.menuOptions[i] setText(currentMenu.options[optionIndex].label);
        } else {
            self.menuOptions[i] setColor(1, 1, 1, 1);
            self.menuOptions[i] setText(toLower(currentMenu.options[optionIndex].label));
        }
    }
}

updateInfoText() {
    if (!self allowedToSeeInfo()) {
        return;
    }

    bombText = "Bomb: ^2disabled^7";
	if (getDvarInt("bombEnabled") == 1) {
		bombText = "Bomb: ^1enabled^7";
	}

    precamText = "Pre-cam anims: ^1disabled^7";
	if (getDvarInt("cg_nopredict") == 1) {
		precamText = "Pre-cam anims: ^2enabled^7";
	}

    timeExtensionEnabledText = "Time extension: ^1disabled^7";
	if (getDvarInt("timeExtensionEnabled") == 1) {
		timeExtensionEnabledText = "Time extension: ^2enabled^7";
	}

    unfairStreaksText = "Unfair streaks: ^2disabled^7";
	if (getDvarInt("UnfairStreaksEnabled") == 1) {
		unfairStreaksText = "Unfair streaks: ^1enabled^7";
	}

    unlimSnipDmgText = "Sniper damage: ^1normal^7";
	if (level.unlimitedSniperDmg) {
		unlimSnipDmgText = "Sniper damage: ^2unlimited^7";
	}
	
	self.infoText setText(bombText + " | " + precamText + " | " + timeExtensionEnabledText + " | " + unfairStreaksText + " | " + unlimSnipDmgText);
}

createText(font, fontScale, point, relative, xOffset, yOffset, sort, hideWhenInMenu, text) {
    textElem = createFontString(font, fontScale);
    textElem setText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    return textElem;
}

createRectangle(align, relative, x, y, width, height, sort, shader, hideWhenInMenu) {
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG setParent(level.uiParent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = false;
    barElemBG setPoint(align, relative, x, y);
    barElemBG.hideWhenInMenu = hideWhenInMenu;
    return barElemBG;
}

setColor(r, g, b, a) {
	self.color = (r, g, b);
	self.alpha = a;
}

setGlow(r, g, b, a) {
	self.glowColor = (r, g, b);
	self.glowAlpha = a;
}

elemFade(time, alpha) {
    self fadeOverTime(time);
    self.alpha = alpha;
}
