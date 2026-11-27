#include maps\mp\_utility;
#include common_scripts\utility;

// Fallbacks for builtins provided by the Silinium SPRX, so PC and plain console builds compile.
// Silinium builds replace this file with silinium/maps/mp/centurypackage/stubs.gsc (see README).

callkeyboard(message, clientNum) {
    return 0;
}
