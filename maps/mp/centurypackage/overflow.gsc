#include maps\mp\centurypackage\hud;

/*
    Localized strings (setText) live in a server configstring table that is never freed.
    clearAllTextAfterHudElem empties every string created after the anchor's text. Configstrings
    dedupe identical text, so a temporary elem with the anchor text always resolves to the same
    index and no hudelem slot has to stay occupied for it.
    Each cleared string costs one reliable command per client (buffer of 128), hence the
    threshold.
*/
initOverflowFix() {
    level.overflowStrings = [];
    level.overflowCount = 0;
    level.overflowThreshold = 40;
    level.isClearingOverflow = false;

    // Configstrings survive SD round restarts, so drop the strings of the previous round
    // before the stock scripts re-precache theirs.
    if (isDefined(game["overflowAnchorRegistered"])) {
        clearStringsAfterAnchor();
        return;
    }

    game["overflowAnchorRegistered"] = true;
    level thread registerAnchorAfterPrecache();
}

// The stock inits threaded after _clientids::init precache their strings in this frame;
// the anchor must come after them or every clear would wipe them as well.
registerAnchorAfterPrecache() {
    waittillframeend;
    clearStringsAfterAnchor();
}

setSafeText(text) {
    self setText(text);

    if (text == "" || isDefined(level.overflowStrings[text])) {
        return;
    }

    level.overflowStrings[text] = true;
    level.overflowCount++;

    if (level.overflowCount >= level.overflowThreshold && !level.isClearingOverflow) {
        level thread clearOverflow();
    }
}

clearOverflow() {
    level.isClearingOverflow = true;
    waittillframeend;

    clearStringsAfterAnchor();
    level.overflowStrings = [];

    level notify("overflow_cleared");

    // The redraw re-registers the visible strings; they must neither start a new clear
    // nor count toward the next one.
    waittillframeend;
    level.overflowCount = 0;
    level.isClearingOverflow = false;
}

clearStringsAfterAnchor() {
    anchor = newHudElem();
    anchor.alpha = 0;
    anchor setText("overflow_anchor");
    anchor clearAllTextAfterHudElem();
    anchor destroy();
}

redrawOnOverflow() {
    self endon("disconnect");

    for (;;) {
        level waittill("overflow_cleared");

        if (self.isInMenu) {
            self updateText();
            self updateInfoText();
        }

        if (self.isOverlayDrawn) {
            self destroyOverlay();
            self drawOverlay();
        }
    }
}
