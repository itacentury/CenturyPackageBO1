#include maps\mp\_utility;
#include common_scripts\utility;

// Silinium variant of maps/mp/centurypackage/stubs.gsc: callkeyboard is provided by the Silinium SPRX,
// so this file only defines hasKeyboardSupport(). It must still exist because menu.gsc and self_functions.gsc include it.

hasKeyboardSupport() {
    return true;
}
