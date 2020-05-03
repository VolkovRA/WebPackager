package;

import js.Node; // <-- Ошибка? Смотри: build web.hxml
import js.node.Fs;
import js.node.Path;
import js.lib.Uint8Array;
import pkg.Unpacker;

/**
 * Обработчик CLI.
 * Используется для распаковки архивов WebPacker'а в локальную, файловую систему с помощью NodeJS.
 * * Этот файл является **точкой входа** для вызываемой команды: `unpack`.
 * * Этот файл компилируется отдельно и имеет собственные параметры компиляции, смотрите файл: `build unpack.hxml`.
 * 
 * Пример использования:
 * ```
 * unpack in, out
 * ```
 * Где:
 *   1. `unpack` - Команда в терминале для вызова распаковщика.
 *   2. `in` - Путь до файла, который будет распакован. (Локальная, файловая система)
 *   3. `out` - Путь до папки, в которую будет распаковано содержимое архива. (Создаётся, если такая не существует)
 */
class Unpack
{
    static private var unpacker:Unpacker = null;
    static private var pos:Int = 0;
    static private var files:Int = 0;

    static public function main() {
        if (Node.process.argv.length < 3) {
            Node.console.error('Ошибка: Передайте первым аргументом путь до файла, который будет распакован');
            Node.process.exitCode = 1;
            return;
        }
        if (Node.process.argv.length < 4) {
            Node.console.error('Ошибка: Передайте вторым аргументом путь до папки, в которую будет распаковано содержимое архива');
            Node.process.exitCode = 1;
            return;
        }
        
        // Вводные данные:
        var pin = Path.normalize(Node.process.argv[2] + '');
        var pout = Path.normalize(Node.process.argv[3] + '');
        
        // Информация:
        Node.console.log('Распаковка архива: "' + pin + '"');

        // Проверка существования архива:
        if (Fs.existsSync(pin) == false) {
            Node.console.error('Ошибка: Архив не найден: "' + Node.process.argv[2] + '"');
            Node.process.exitCode = 1;
            return;
        }

        // Проверка на файл:
        var sts = Fs.statSync(pin);
        if (sts.isFile() == false) {
            Node.console.error('Ошибка: Указанный путь ссылается не на файл: "' + Node.process.argv[2] + '"');
            Node.process.exitCode = 1;
            return;
        }

        // Создание папки вывода:
        if (Fs.existsSync(pout) == false) {
            Fs.mkdirSync(pout);
        }
        else if (Fs.statSync(pout).isDirectory() == false){
            Node.console.error('Ошибка: Указанный путь вывода уже занят: "' + Node.process.argv[3] + '"');
            Node.process.exitCode = 1;
            return;
        }

        // Читаем файл:
        unpacker = new Unpacker(new Uint8Array(Fs.readFileSync(pin)));
        while (true) {
            var file = unpacker.get();
            if (file == null)
                break;
            
            Node.console.log('Распаковка: "' + file.name + '"');
            buildPath(pout, Path.normalize(file.name));
            Fs.writeFileSync(Path.normalize(pout + Path.sep + file.name), untyped file.data);

            files ++;
        }

        // Завершено:
        Node.console.log('Завершено');
        Node.console.log('Вывод: "' + pout + '", файлов: ' + files);
    }
    static private function buildPath(pout:String, file:String) {
        var folders = Path.dirname(file).split(Path.sep);
        if (folders.length == 0 || folders[0] == ".")
            return;

        var i = 0;
        while (i < folders.length) {
            pout += Path.sep + folders[i++];

            if (Fs.existsSync(pout) == false)
                Fs.mkdirSync(pout);
        }
    }
}