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

    /**
	 * Получить строковое представление объёма информации.
	 * Возвращает строковое описание количества байт, кб, мб и т.д.
	 * @param	length Объём информации. (Байт)
	 * @return	Строковое представление.
	 */
	static public function getBytesSize(length:Int):String {
		
		// Таблица измерения количества информации:
		// https://ru.wikipedia.org/wiki/%D0%9C%D0%B5%D0%B3%D0%B0%D0%B1%D0%B0%D0%B9%D1%82
		// 	
		// +------------------------------+
		// |        ГОСТ 8.417—2002       |            
		// | Название Обозначение Степень |	
		// +------------------------------+
		// | байт        Б         10^0   |
		// | килобайт    Кбайт     10^3   |
		// | мегабайт    Мбайт     10^6   |
		// | гигабайт    Гбайт     10^9   |
		// | терабайт    Тбайт     10^12  |
		// | петабайт    Пбайт     10^15  |
		// | эксабайт    Эбайт     10^18  |
		// | зеттабайт   Збайт     10^21  |
		// | йоттабайт   Ибайт     10^24  |
		// +------------------------------+
		
        if (length < 1e3)		return length + " byte";
		if (length < 1e6)		return untyped Math.trunc(length / 1e1) / 1e2 + " KB";
		if (length < 1e9)		return untyped Math.trunc(length / 1e4) / 1e2 + " MB";
		if (length < 1e12)		return untyped Math.trunc(length / 1e7) / 1e2 + " GB";
		if (length < 1e15)		return untyped Math.trunc(length / 1e10) / 1e2 + " TB";
		if (length < 1e18)		return untyped Math.trunc(length / 1e13) / 1e2 + " PB";
		if (length < 1e21)		return untyped Math.trunc(length / 1e16) / 1e2 + " EB";
		if (length < 1e24)		return untyped Math.trunc(length / 1e19) / 1e2 + " ZB";
		
		return untyped Math.trunc(length / 1e22) / 1e2 + " YB";
    }
}