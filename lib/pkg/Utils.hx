package pkg;

import js.Syntax;
import js.lib.Uint8Array;

/**
 * Вспомогательные утилиты упаковщика.
 * Статический класс.
 */
class Utils
{
    /**
     * Получить строковое представление типа объекта в JS.
     * Безопасно использует нативный метод toString().
     * @param value Значение, тип которого нужно получить.
     * @return Строковое описание типа в JavaScript.
     */
    static public inline function getType(value:Any):String {
        return Syntax.code("toString.call({0})", value);
    }

    /**
     * Преобразовать строку в байты.
     * Метод использует нативную JS функцию `encodeURIComponent()` для перевода символов в ASCII.
     * Затем однобайтовая кодировка легко помещается в бинарный массив.
     * @param str Исходная строка.
     * @return Байтовый массив с содержимым строки.
     * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
     */
    static public function strToBytes(str:String):Uint8Array {
        str = StringTools.urlEncode(str);

        var len = str.length;
        var bytes = new Uint8Array(len);
        while (len-- != 0)
            bytes[len] = str.charCodeAt(len);
        
        return bytes;
    }

    /**
     * Функция выполняет обратное преобразование, полученное в результате вызова: `Utils.strToBytes()`.
     * @param bytes Байтовый массив с содержимым строки.
     * @return Исходная строка.
     */
    static public function bytesToStr(bytes:Uint8Array):String {
        var len = bytes.length;
        var arr:Array<String> = Syntax.code("new Array({0});", len);
        
        while (len-- != 0)
            arr[len] = String.fromCharCode(bytes[len]);

        return StringTools.urlDecode(arr.join(''));
    }
}