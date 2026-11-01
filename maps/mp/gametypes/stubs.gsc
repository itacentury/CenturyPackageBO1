#include maps\mp\_utility;
#include common_scripts\utility;

// stubs to avoid "unknown function" error on pc or on console without Silinium mod
// when using Silinium mod: comment out the includes ("#include maps\mp\gametypes\stubs;") in self_functions.gsc and utils.gsc

setMemory(offset, bytes) {
}

callkeyboard(message, clientNum) {
    return 0;
}
