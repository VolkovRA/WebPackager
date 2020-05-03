# WEB Упаковщик ресурсов для Haxe.

Описание
------------------------------

Используется для сжатия данных в один файл и обратной распаковки на стороне сервера или клиента.

Преимущества и отличия от обычного zip архива:
1. Самый минимальный размер генерируемого кода, ближайший аналог весит >300кб, против 60 WebPackager'а. (Сжатый js бинарник)
2. Самая высокая скорость работы за счёт использования pako. ([Порт](https://github.com/nodeca/pako "High speed zlib port to javascript, works in browser & node.js") с C в JS, сделанный опытными пофессионалами)
3. Кастомный, бинарный формат. Это не позволит открыть передаваемый по сети архив обычным архиватором. (Можно считать как минусом, так и плюсом)
4. Не содержит никаких зависимостей, кроме pako. (Для выполнения сжатия)
5. Не делает ничего лишнего, даже не расчитывает CRC сумму. (Избыточная проверка, лишние затраты)
6. Работает в браузере и на сервере.

Формат записи двоичных данных
------------------------------

Валидный архив WebPacker'а выглядит так:
```
id, version, [header1, file1], [header2, file2], [header3, file3]
```
Где:
 * id `unsigned Int16` - Уникальный идентификатор, обозначающий формат данных WebPackager'a.
 * version `unsigned Int8` - Версия данных. Текущая версия: `0x01`.
 * header - Заголовок описания файла, *смотрите ниже*.
 * file - Данные файла.

Формат заголовка:
```
dataLength, nameLength, name
```
Где:
 * dataLength `unsigned Int32` - Длина файла.
 * nameLength `unsigned Int16` - Длина имени файла. (Не более 65535 символов ASCII)
 * name `string ASCII` - Имя файла. Строка закодирована с помощью: `encodeURIComponent()`.

Порядок байтов: `big-endian`.

Использование в браузере
------------------------------

```
package;

import pkg.Packer;
import pkg.Unpacker;
import pkg.Utils;
import js.Browser;
import js.html.Blob;
import js.html.URL;

class Main {
    static public function main() {
        var str1 = "Hell ö € Ω 𝄞, какой сегодня `чудесный` день, не так ли, Doppelgänger?";
        var str2 = "Hi!";
        var str3 = "No compress please";
        
        // Упаковка:
        var packer = new Packer();
        packer.add(Utils.strToBytes(str1), "Hell ö € Ω 𝄞__Doppelgänger.josy", { level:5 });
        packer.add(Utils.strToBytes(str2), "Просто файл.txt", { level:5 });
        packer.add(Utils.strToBytes(str3), "Файл без компрессии.txt", { level:0 });

        // Распаковка:
        var unpacker = new Unpacker(packer.data);
        trace(Utils.bytesToStr(unpacker.get().data));
        trace(unpacker.get());
        trace(Utils.bytesToStr(unpacker.get().data));
        trace(unpacker.get());

        // Конвертация строк:
        trace(Utils.bytesToStr(Utils.strToBytes(str1)), str1 == Utils.bytesToStr(Utils.strToBytes(str1)));

        // Сохраняем сжатый файл через браузер:
        saveFile(packer.data, "File.data");
    }

    static public function saveFile(data:Any, name:String = "File", type:String = null):Void {
        var file = new Blob([data], {type: type});

        // IE10+
        if (untyped Browser.window.navigator.msSaveOrOpenBlob) {
            untyped Browser.window.navigator.msSaveOrOpenBlob(file, filename);
            return;
        }
        
        // Другие:
        var url = URL.createObjectURL(file);
        var a = Browser.document.createAnchorElement();
        a.href = url;
        a.download = name;
        Browser.document.body.appendChild(a);
        a.click();
        
        Browser.window.setTimeout(function(){
            Browser.document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }, 0);
    }
}
```

Подключение в Haxe
------------------------------

1. Установите haxelib, чтобы можно было использовать библиотеки Haxe.
2. Выполните в терминале команду, чтобы установить библиотеку WebPackager глобально себе на локальную машину:
```
haxelib git webpackager https://github.com/VolkovRA/WebPackager.git master
```
Синтаксис команды:
```
haxelib git [project-name] [git-clone-path] [branch]
haxelib git minject https://github.com/massiveinteractive/minject.git         # Use HTTP git path.
haxelib git minject git@github.com:massiveinteractive/minject.git             # Use SSH git path.
haxelib git minject git@github.com:massiveinteractive/minject.git v2          # Checkout branch or tag `v2`.
```
3. Добавьте в свой проект библиотеку WebPackager, чтобы использовать её в коде. Если вы используете HaxeDevelop, то просто добавьте в файл .hxproj запись:
```
<haxelib>
	<library name="webpackager" />
</haxelib>
```
4. Установите библиотеку для использования pako в Haxe:
[https://github.com/VolkovRA/HaxePako](https://github.com/VolkovRA/HaxePako "The Haxe high quality extern definitions for pako") 

Смотрите дополнительную информацию:
 * [GitHub HaxePako](https://github.com/VolkovRA/HaxePako "The Haxe high quality extern definitions for pako")
 * [GitHub Pako](https://github.com/nodeca/pako "High speed zlib port to javascript, works in browser & node.js")
 * [Документация Haxelib](https://lib.haxe.org/documentation/using-haxelib/ "Using Haxelib")