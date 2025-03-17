#include maps\mp\_utility;
#include common_scripts\utility;

iPrintList(list) {
    text = "";
    for (i = 0; i < list.size; i++) {
        text += list[i] + ",";
    }

    self iPrintLn(getSubStr(text, 0, text.size - 1)); 
}

arrayRemoveItem(array, index) {
    newArray = [];
    j = 0;
    for (i = 0; i < array.size; i++) {
        if (i == index) {
            i++;
        }

        newArray[j] = array[i];
        j++;
    }

    return newArray;
}
