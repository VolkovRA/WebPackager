package pkg;

import js.lib.Uint8Array;

/**
 * Файл.
 */
typedef File = 
{
    /**
     * Имя файла.
     */
    var name:String;

    /**
     * Содержимое файла.
     */
    var data:Uint8Array;
}