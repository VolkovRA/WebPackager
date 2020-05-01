package pkg;

import js.Syntax;
import js.lib.Uint8Array;
import pako.Options;
import pako.Pako;

#if debug
import js.lib.Error;
#end

/**
 * Упаковщик.
 */
class Packer
{
    /**
     * Создать упаковщик.
     */
    public function new() {
        data = new Uint8Array(2 + 1); // id, version

        // id:
        data[0] = WebPackager.DATA_ID >> 8;
        data[1] = WebPackager.DATA_ID & 0xff;
        
        // version:
        data[2] = WebPackager.DATA_VERSION;
    }

    /**
     * Запакованные данные.
     * В этот массив записываются данные по мере вызовов метода: `Packer.add()`.
     * Вы не должны хранить ссыку на этот объект, так-как при добавлений новых
     * файлов он заменяется на новый. 
     * 
     * По умолчанию содержит пустой архив. (Не может быть null)
     */
    public var data(default, null):Uint8Array;

    /**
     * Упаковать файл.
     * @param file Содержимое файла. (`ArrayBuffer` или `Uint8Array`)
     * @param name Имя файла.
     * @param options Параметры упаковки.
     */
    public function add(file:Dynamic, name:String, options:Options = null) {
        var type = Utils.getType(file);
        var fileData:Uint8Array = null;
        
        // Файл:
        if (type == "[object Uint8Array]")
            fileData = file;
        else if (type == "[object ArrayBuffer]")
            fileData = new Uint8Array(file);
        #if debug
        else
            throw new Error("Некорректный тип данных: file=" + type + ", допустимый тип значений: ArrayBuffer, Uint8Array");
        #end

        // Имя файла:
        var nameEnc = StringTools.urlEncode(name);
        var nameLen = nameEnc.length;
        if (nameLen > 0xffff) {
            #if debug
            throw new Error('Превышение лимита длины имени файла в 2 байта: name="' + name + '"');
            #end
            nameEnc = nameEnc.substring(0, 0xffff);
        }
        
        // Сжатие:
        fileData = Pako.deflateRaw(fileData, options);
        
        #if debug
        // Размер файла:
        if (fileData.byteLength > 4294967295)
            throw new Error('Размер сжатого файла: name="' + name + '" (' + fileData.byteLength + ' байт) превышает максимальный допустимый размер в 4294967295 байт. (Примерно 4 ГБ)');
        #end
        
        // Новый буффер:
        var dataNew = new Uint8Array(data.byteLength + fileData.byteLength + (4 + 2) + nameLen); // 4+2+len - Длина заголовка.
        dataNew.set(data);
        
        // Заголовок:
        var pos:Int = data.byteLength;
        writeUInt32(fileData.byteLength, dataNew, pos); pos += 4;           // dataLength
        writeUInt16(nameLen, dataNew, pos);             pos += 2;           // nameLength
        writeString(nameEnc, dataNew, pos);             pos += nameLen;     // name
        
        // Копируем файл:
        dataNew.set(fileData, pos);

        // Удаляем старый массив:
        data = dataNew;
    }

    /**
     * Записать беззнаковое целое 16 бит. (2 Байта, big-endian)
     * @param value  Значение.
     * @param buffer Буффер для записи.
     * @param offset Позиция записи.
     */
     static public function writeUInt16(value:Int, buffer:Uint8Array, offset:Int):Void {
        if (value > 0xffff) {
            buffer[offset + 0] = 255;
            buffer[offset + 1] = 255;

            #if debug
            throw new Error("Попытка записи некорректного UInt16 значения: value=" + value + " (Превышение диапазона)");
            #end
        }
        else if (value > 0) {
            buffer[offset + 0] = value >>> 8;
            buffer[offset + 1] = value & 0xff;
        }
        else {
            buffer[offset + 0] = 0;
            buffer[offset + 1] = 0;
            
            #if debug
            if (value != 0) // null, NaN и т.п.
                throw new Error("Попытка записи некорректного UInt16 значения: value=" + value);
            #end
        }
    }

    /**
     * Записать беззнаковое целое 32 бита. (4 Байта, big-endian)
     * @param value  Значение.
     * @param buffer Буффер для записи.
     * @param offset Позиция записи.
     */
    static public function writeUInt32(value:Int, buffer:Uint8Array, offset:Int):Void {
        if (value > 4294967295) {
            buffer[offset + 0] = 255;
            buffer[offset + 1] = 255;
            buffer[offset + 2] = 255;
            buffer[offset + 3] = 255;

            #if debug
            throw new Error("Попытка записи некорректного UInt32 значения: value=" + value + " (Превышение диапазона)");
            #end
        }
        else if (value > 2147483647) {

            // 2^31 -1 или 2147483647 или 0x7fffffff.
            // После этого числа побитовые операторы с Int не работают в JS.

            var str:String = Syntax.code('{0}.toString(16);', value);
            buffer[offset + 0] = Syntax.code('parseInt("0x" + {0}.substring(0, 2), 16);', str);
            buffer[offset + 1] = Syntax.code('parseInt("0x" + {0}.substring(2, 4), 16);', str);
            buffer[offset + 2] = Syntax.code('parseInt("0x" + {0}.substring(4, 6), 16);', str);
            buffer[offset + 3] = Syntax.code('parseInt("0x" + {0}.substring(6, 8), 16);', str);
        }
        else if (value > 0) {
            buffer[offset + 0] = value >>> 24;
            buffer[offset + 1] = value >>> 16 & 0xff;
            buffer[offset + 2] = value >>> 8 & 0xff;
            buffer[offset + 3] = value & 0xff;
        }
        else {
            buffer[offset + 0] = 0;
            buffer[offset + 1] = 0;
            buffer[offset + 2] = 0;
            buffer[offset + 3] = 0;
            
            #if debug
            if (value != 0) // null, NaN и т.п.
                throw new Error("Попытка записи некорректного UInt32 значения: value=" + value);
            #end
        }
    }

    /**
     * Записать строку.
     * Строка **должна** содержать только символы ASCII. (Однобайтовая кодировка)
     * @param str    Строка ASCII.
     * @param buffer Буффер для записи.
     * @param offset Позиция записи.
     */
    static public function writeString(str:String, buffer:Uint8Array, offset:Int):Void {
        var len = str.length;
        while (len-- != 0)
            buffer[offset + len] = Syntax.code("{0}.charCodeAt({1});", str, len);
    }
}