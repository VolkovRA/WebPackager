package pkg;

import js.Syntax;
import js.lib.Uint8Array;
import pako.Pako;

#if debug
import js.lib.Error;
#end

/**
 * Распаковщик.
 */
class Unpacker
{   
    /**
     * Создать распаковщик.
     * @param data Запакованные данные. (`ArrayBuffer` или `Uint8Array`)
     */
    public function new(data:Dynamic) {
        var type = Utils.getType(data);
        
        // Файл:
        if (type == "[object Uint8Array]")
            this.data = data;
        else if (type == "[object ArrayBuffer]")
            this.data = new Uint8Array(data);
        #if debug
        else
            throw new Error("Некорректный тип данных: file=" + type + ", допустимый тип значений: ArrayBuffer, Uint8Array");
        #end

        #if debug
        // Проверка формата:
        if ((data[0] != WebPackager.DATA_ID >> 8) || (data[1] != WebPackager.DATA_ID & 0xff))
            throw new Error("Переданные данные не являются корректным типом данных WebPacker'а");

        // Проверка версии:
        if (data[2] > WebPackager.DATA_VERSION)
            throw new Error("Переданные данные имеют более высокую версию, чем поддерживает текущая версия распаковщика");
        #end
    
        position = 3;
    }

    /**
     * Запакованные данные, переданные в конструктор.
     * Не может быть null.
     */
    public var data(default, null):Uint8Array = null;

    /**
     * Позиция чтения архива.
     * Это значение используется внутренним кодом для чтения файла.
     */
    private var position(default, null):Int = 0;

    /**
     * Извлечь файл из архива.
     * Распаковывает и возвращает следующий файл в архиве.
     * Этот метод возвращает null, если в архиве больше нет файлов.
     * @return File Распакованные данные файла из архива.
     */
    public function get():File {
        if (position == data.byteLength)
            return null;

        var file:File = { data:null, name:null };
        
        // Считываем заголовок:
        var dataLength  = readUInt32(data, position); position += 4;
        var nameLength  = readUInt16(data, position); position += 2;
        
        file.name   = StringTools.urlDecode(readString(data, position, nameLength)); position += nameLength;
        file.data   = Pako.inflateRaw(data.slice(position, position + dataLength)); position += dataLength;

        return file;
    }
    
    /**
     * Прочитать беззнаковое целое 16 бит. (2 Байта, big-endian)
     * @param buffer Буффер для чтения.
     * @param offset Позиция чтения.
     * @return Беззнаковое целое 16 бит.
     */
    static public function readUInt16(buffer:Uint8Array, offset:Int):Int {
        return (buffer[offset] << 8) + buffer[offset + 1];
    }
    
    /**
     * Прочитать беззнаковое целое 32 бита. (4 Байта, big-endian)
     * @param buffer Буффер для чтения.
     * @param offset Позиция чтения.
     * @return Беззнаковое целое 32 бита.
     */
    static public function readUInt32(buffer:Uint8Array, offset):Int {

        // 2^31 -1 или 2147483647 или 0x7fffffff.
        // После этого числа побитовые операторы с Int не работают в JS.

        if (buffer[offset] < 0x7f) {
            return (buffer[offset + 0] << 24) + (buffer[offset + 1] << 16) + (buffer[offset + 2] << 8) + buffer[offset + 3];
        }
        else {
            return  Syntax.code('parseInt("0x" + {0}.toString(16) + "000000", 16)', buffer[offset]) + 
                    (buffer[offset + 1] << 16) + 
                    (buffer[offset + 2] << 8) + 
                    (buffer[offset + 3]);
        }
    }

    /**
     * Прочитать строку ASCII. (Однобайтовая кодировка)
     * @param buffer Буффер для чтения.
     * @param offset Позиция чтения.
     * @param length Количество считываемых байт.
     * @return Строка с текстом.
     */
     static public function readString(buffer:Uint8Array, offset:Int, length:Int):String {
        var arr:Array<String> = Syntax.code("new Array({0});", length);
        
        while (length-- != 0)
            arr[length] = String.fromCharCode(buffer[offset + length]);

        return arr.join('');
    }
}