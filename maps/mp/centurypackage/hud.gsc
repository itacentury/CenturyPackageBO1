#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\centurypackage\menu;
#include maps\mp\centurypackage\overflow;
#include maps\mp\centurypackage\string_utils;

drawShaders() {
    self.menuBackground1 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 180, 230, 1, "black", true);
    self.menuBackground1 setColor(0, 0, 0, 0.3);
    self.menuBackground2 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 160, 210, 2, "black", true);
    self.menuBackground2 setColor(0, 0, 0, 0.4);
    self.menuScrollbar = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis, 180, 15, 3, "white", true);
    self.menuScrollbar setColor(0.4549, 0.7765, 0.9882, 0.75);
    self.dividerBar1 = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis - 20, 180, 1, 3, "white", true);
    self.dividerBar1 setColor(0.9882, 0.6667, 0.4549, 0.75);
    self.dividerBar2 = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis + 120, 180, 1, 3, "white", true);
    self.dividerBar2 setColor(0.9882, 0.6667, 0.4549, 0.75);

    self moveScrollbar();
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
    if (self.isOverlayDrawn) {
        return;
    }

    if (level.currentGametype != "sd") {
        return;
    }

    if (!self.overlayEnabled) {
        return;
    }

    self.overlay = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 100, false, true, getOverlayText());
    self.overlay setColor(1, 1, 1, 0.8);

    self.isOverlayDrawn = true;
}

getOverlayText() {
    return "Press [{+speed_throw}] + [{+actionslot 2}] for " + level.menuName;
}

destroyOverlay() {
    if (!self.isOverlayDrawn) {
        return;
    }

    self.overlay destroy();
    self.isOverlayDrawn = false;
}

drawText() {
    self.menuTitle = self createText("extrabig", 1.3, "CENTER", "TOP", level.xAxis, level.yAxis - 50, 4, true, false, "");
    self.menuTitle setColor(0.9882, 0.6667, 0.4549, 1);
    self.subTitle = self createText("small", 1, "CENTER", "TOP", level.xAxis, level.yAxis - 35, 4, true, false, "");
    self.subTitle setColor(1, 1, 1, 1);
    // Numbers via setValue use no configstring, unlike a "3/13" text.
    self.subPosition = self createText("small", 1, "RIGHT", "TOP", level.xAxis - 4, level.yAxis - 35, 4, true, true, "");
    self.subPosition setColor(1, 1, 1, 0);
    self.subTotal = self createText("small", 1, "LEFT", "TOP", level.xAxis + 4, level.yAxis - 35, 4, true, true, "");
    self.subTotal setColor(1, 1, 1, 0);
    if (self allowedToSeeInfo()) {
        self.infoText = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 4, true, false, "");
        self.infoText setColor(1, 1, 1, 0.8);
    }

    for (i = 0; i < level.visibleOptions; i++) {
        self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", level.xAxis, level.yAxis + (15 * i), 4, true, false, "");
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
    self.subPosition destroy();
    self.subTotal destroy();
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

    self.menuTitle setSafeText(toUpper(self.menus[self.currentMenu].title));

    self.subTitle setSafeText("");
    self.subPosition.alpha = 0;
    self.subTotal.alpha = 0;
    if (total > visible) {
        self.subTitle setSafeText("/");
        self.subPosition setValue(currentMenu.position + 1);
        self.subPosition.alpha = 1;
        self.subTotal setValue(total);
        self.subTotal.alpha = 1;
    } else if (self.menus[self.currentMenu].name == "main") {
        self.subTitle setSafeText(level.twitterHandle);
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
        self.menuOptions[i] setSafeText("");
        if (optionIndex >= total) {
            continue;
        }

        func = currentMenu.options[optionIndex].function;
        if (func == ::openMenu || func == ::openPlayerMenu) {
            self.menuOptions[i] setColor(0.2588, 0.6980, 0.9843, 1);
            self.menuOptions[i] setSafeText(currentMenu.options[optionIndex].label);
        } else {
            self.menuOptions[i] setColor(1, 1, 1, 1);
            self.menuOptions[i] setSafeText(toLower(currentMenu.options[optionIndex].label));
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

    self.infoText setSafeText(bombText + " | " + precamText + " | " + timeExtensionEnabledText + " | " + unfairStreaksText + " | " + unlimSnipDmgText);
}

// Non-archived elems are hidden from killcam and spectators, but the engine sends at most 31
// archived and 31 non-archived elems per player; stock scripts already use ~12 non-archived ones.
createText(font, fontScale, point, relative, xOffset, yOffset, sort, hideWhenInMenu, archived, text) {
    textElem = createFontString(font, fontScale);
    textElem setSafeText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    textElem.archived = archived;
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

// Rebuild of the stock "KillstreakPopUp" from ui_mp/hud_popups.menu. The engine only shows it
// through displayKillstreak(), which needs a killstreakTable row the cut streaks lack.
showKillstreakPopup(title, icon) {
    self endon("disconnect");

    while (isDefined(self.ksPopupActive)) {
        self waittill("ks_popup_done");
    }

    self.ksPopupActive = true;

    // Same coordinates, sizes and timing as the menu: slide in from x-500 over 200 ms,
    // hold 2000 + 100 ms, then slide out to the right.
    elems = [];
    elems[0] = self createKillstreakPopupElem(8, 2, 1);
    elems[0] setShader(icon, 50, 50);
    elems[1] = self createKillstreakPopupElem(10, 1, 0.5);
    // COLOR_RED in the menu is NEW_FRAME_RED_RGB (ui/framestyle.inc).
    elems[1].color = (0.73, 0.19, 0.19);
    elems[1] setShader("hud_notification_ks_backing", 192, 128);
    // The menu's text y is the baseline.
    elems[2] = self createKillstreakPopupElem(84, 3, 1);
    elems[2].font = "default";
    elems[2].fontScale = 2.8;
    elems[2].alignY = "bottom";
    elems[2] setSafeText(title);
    elems[3] = self createKillstreakPopupElem(100, 3, 1);
    elems[3].font = "default";
    elems[3].fontScale = 1.35;
    elems[3].alignY = "bottom";
    elems[3] setSafeText(getKillstreakPopupHint());

    self thread killstreakPopupOverflowRelay(elems[2], elems[3], title);
    for (i = 0; i < elems.size; i++) {
        elems[i] moveOverTime(0.2);
        elems[i].x = 0;
        elems[i] fadeOverTime(0.2);
        elems[i].alpha = elems[i].targetAlpha;
    }

    wait 2.1; // display 2000 ms + pause 100 ms

    // Slide out to x+600 while fading, like the menu's "Hide" state.
    for (i = 0; i < elems.size; i++) {
        elems[i] moveOverTime(0.2);
        elems[i].x = 600;
        elems[i] fadeOverTime(0.2);
        elems[i].alpha = 0;
    }

    wait 0.2;

    self notify("ks_popup_destroyed");
    for (i = 0; i < elems.size; i++) {
        elems[i] destroy();
    }

    self.ksPopupActive = undefined;
    self notify("ks_popup_done");
}

createKillstreakPopupElem(y, sort, targetAlpha) {
    elem = newClientHudElem(self);
    elem.horzAlign = "user_center";
    elem.vertAlign = "user_top";
    elem.alignX = "center";
    elem.alignY = "top";
    elem.x = -500;
    elem.y = y;
    elem.sort = sort;
    elem.alpha = 0;
    elem.targetAlpha = targetAlpha;
    elem.foreground = true;
    elem.hideWhenInMenu = true;
    // The non-archived pool (31 elems) is nearly full while the mod menu is open,
    // which dropped the last elem (the hint line).
    elem.archived = true;
    return elem;
}

getKillstreakPopupHint() {
    return "[{+actionslot 4}] to activate";
}

// Redraw after the overflow fix wiped all script strings.
killstreakPopupOverflowRelay(titleElem, hintElem, title) {
    self endon("disconnect");
    self endon("ks_popup_destroyed");

    for (;;) {
        level waittill("overflow_cleared");
        titleElem setSafeText(title);
        hintElem setSafeText(getKillstreakPopupHint());
    }
}
