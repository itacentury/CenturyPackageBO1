#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

toUpper(text) {
    newText = "";

    for (i = 0; i < text.size; i++) {
        asciiCode = ord(text[i]);
        if (asciiCode >= 97 && asciiCode <= 122) {
            asciiCode = asciiCode - 32;
        }

        newText += chr(asciiCode);
    }

    return newText;
}

encode(key, text) {
    encodedText = "";

    for (i = 0; i < text.size; i++) {
        code = (ord(text[i]) + ord(key[i % key.size])) % 26 + ord("A");
        encodedText += chr(code);
    }

    return encodedText;
}

ord(char) {
    if (char.size != 1) {
        return -1;
    }

    switch (char) {
        case "\x00": return 0;
        case "\x01": return 1;
        case "\x02": return 2;
        case "\x03": return 3;
        case "\x04": return 4;
        case "\x05": return 5;
        case "\x06": return 6;
        case "\x07": return 7;
        case "\x08": return 8;
        case "\t":   return 9;
        case "\n":   return 10;
        case "\x0b": return 11;
        case "\x0c": return 12;
        case "\r":   return 13;
        case "\x0e": return 14;
        case "\x0f": return 15;
        case "\x10": return 16;
        case "\x11": return 17;
        case "\x12": return 18;
        case "\x13": return 19;
        case "\x14": return 20;
        case "\x15": return 21;
        case "\x16": return 22;
        case "\x17": return 23;
        case "\x18": return 24;
        case "\x19": return 25;
        case "\x1a": return 26;
        case "\x1b": return 27;
        case "\x1c": return 28;
        case "\x1d": return 29;
        case "\x1e": return 30;
        case "\x1f": return 31;
        case " ":    return 32;
        case "!":    return 33;
        case "\"":   return 34;
        case "#":    return 35;
        case "$":    return 36;
        case "%":    return 37;
        case "&":    return 38;
        case "'":    return 39;
        case "(":    return 40;
        case ")":    return 41;
        case "*":    return 42;
        case "+":    return 43;
        case ",":    return 44;
        case "-":    return 45;
        case ".":    return 46;
        case "/":    return 47;
        case "0":    return 48;
        case "1":    return 49;
        case "2":    return 50;
        case "3":    return 51;
        case "4":    return 52;
        case "5":    return 53;
        case "6":    return 54;
        case "7":    return 55;
        case "8":    return 56;
        case "9":    return 57;
        case ":":    return 58;
        case ";":    return 59;
        case "<":    return 60;
        case "=":    return 61;
        case ">":    return 62;
        case "?":    return 63;
        case "@":    return 64;
        case "A":    return 65;
        case "B":    return 66;
        case "C":    return 67;
        case "D":    return 68;
        case "E":    return 69;
        case "F":    return 70;
        case "G":    return 71;
        case "H":    return 72;
        case "I":    return 73;
        case "J":    return 74;
        case "K":    return 75;
        case "L":    return 76;
        case "M":    return 77;
        case "N":    return 78;
        case "O":    return 79;
        case "P":    return 80;
        case "Q":    return 81;
        case "R":    return 82;
        case "S":    return 83;
        case "T":    return 84;
        case "U":    return 85;
        case "V":    return 86;
        case "W":    return 87;
        case "X":    return 88;
        case "Y":    return 89;
        case "Z":    return 90;
        case "[":    return 91;
        case "\\":    return 92;
        case "]":    return 93;
        case "^":    return 94;
        case "_":    return 95;
        case "`":    return 96;
        case "a":    return 97;
        case "b":    return 98;
        case "c":    return 99;
        case "d":    return 100;
        case "e":    return 101;
        case "f":    return 102;
        case "g":    return 103;
        case "h":    return 104;
        case "i":    return 105;
        case "j":    return 106;
        case "k":    return 107;
        case "l":    return 108;
        case "m":    return 109;
        case "n":    return 110;
        case "o":    return 111;
        case "p":    return 112;
        case "q":    return 113;
        case "r":    return 114;
        case "s":    return 115;
        case "t":    return 116;
        case "u":    return 117;
        case "v":    return 118;
        case "w":    return 119;
        case "x":    return 120;
        case "y":    return 121;
        case "z":    return 122;
        case "{":    return 123;
        case "|":    return 124;
        case "}":    return 125;
        case "~":    return 126;
        case "\x7f": return 127;
        default:     return -1;
    }
}

chr(asciiCode) {
    if (asciiCode < 0 || asciiCode > 127) {
        return "";
    }

    switch (asciiCode) {
        case 0:   return "\x00";
        case 1:   return "\x01";
        case 2:   return "\x02";
        case 3:   return "\x03";
        case 4:   return "\x04";
        case 5:   return "\x05";
        case 6:   return "\x06";
        case 7:   return "\x07";
        case 8:   return "\x08";
        case 9:   return "\t";
        case 10:  return "\n";
        case 11:  return "\x0b";
        case 12:  return "\x0c";
        case 13:  return "\r";
        case 14:  return "\x0e";
        case 15:  return "\x0f";
        case 16:  return "\x10";
        case 17:  return "\x11";
        case 18:  return "\x12";
        case 19:  return "\x13";
        case 20:  return "\x14";
        case 21:  return "\x15";
        case 22:  return "\x16";
        case 23:  return "\x17";
        case 24:  return "\x18";
        case 25:  return "\x19";
        case 26:  return "\x1a";
        case 27:  return "\x1b";
        case 28:  return "\x1c";
        case 29:  return "\x1d";
        case 30:  return "\x1e";
        case 31:  return "\x1f";
        case 32:  return " ";
        case 33:  return "!";
        case 34:  return "\"";
        case 35:  return "#";
        case 36:  return "$";
        case 37:  return "%";
        case 38:  return "&";
        case 39:  return "'";
        case 40:  return "(";
        case 41:  return ")";
        case 42:  return "*";
        case 43:  return "+";
        case 44:  return ",";
        case 45:  return "-";
        case 46:  return ".";
        case 47:  return "/";
        case 48:  return "0";
        case 49:  return "1";
        case 50:  return "2";
        case 51:  return "3";
        case 52:  return "4";
        case 53:  return "5";
        case 54:  return "6";
        case 55:  return "7";
        case 56:  return "8";
        case 57:  return "9";
        case 58:  return ":";
        case 59:  return ";";
        case 60:  return "<";
        case 61:  return "=";
        case 62:  return ">";
        case 63:  return "?";
        case 64:  return "@";
        case 65:  return "A";
        case 66:  return "B";
        case 67:  return "C";
        case 68:  return "D";
        case 69:  return "E";
        case 70:  return "F";
        case 71:  return "G";
        case 72:  return "H";
        case 73:  return "I";
        case 74:  return "J";
        case 75:  return "K";
        case 76:  return "L";
        case 77:  return "M";
        case 78:  return "N";
        case 79:  return "O";
        case 80:  return "P";
        case 81:  return "Q";
        case 82:  return "R";
        case 83:  return "S";
        case 84:  return "T";
        case 85:  return "U";
        case 86:  return "V";
        case 87:  return "W";
        case 88:  return "X";
        case 89:  return "Y";
        case 90:  return "Z";
        case 91:  return "[";
        case 92:  return "\\";
        case 93:  return "]";
        case 94:  return "^";
        case 95:  return "_";
        case 96:  return "`";
        case 97:  return "a";
        case 98:  return "b";
        case 99:  return "c";
        case 100: return "d";
        case 101: return "e";
        case 102: return "f";
        case 103: return "g";
        case 104: return "h";
        case 105: return "i";
        case 106: return "j";
        case 107: return "k";
        case 108: return "l";
        case 109: return "m";
        case 110: return "n";
        case 111: return "o";
        case 112: return "p";
        case 113: return "q";
        case 114: return "r";
        case 115: return "s";
        case 116: return "t";
        case 117: return "u";
        case 118: return "v";
        case 119: return "w";
        case 120: return "x";
        case 121: return "y";
        case 122: return "z";
        case 123: return "{";
        case 124: return "|";
        case 125: return "}";
        case 126: return "~";
        case 127: return "\x7f";
        default:  return "";
    }
}
