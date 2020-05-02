package;

import pkg.Packer;
import pkg.Unpacker;
import pkg.Utils;
import js.Browser;
import js.html.Blob;
import js.html.URL;

/**
 * Пример работы упаковщика в браузере.
 * Этот код запускается в браузере для демонстрации работы упаковки/распаковки архива.
 */
class Web {
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