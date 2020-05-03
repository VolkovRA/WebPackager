package;

import js.Node; // <-- Ошибка? Смотри: build web.hxml
import js.node.Fs;
import js.node.Path;
import pkg.Packer;
import pkg.Utils;
import pako.Options;

/**
 * Обработчик CLI.
 * Используется для упаковки папок в локальной, файловой системе в корректный архив WebPackager'a, с помощью NodeJS.
 * * Этот файл является **точкой входа** для вызываемой команды: `pack`.
 * * Этот файл компилируется отдельно и имеет собственные параметры компиляции, смотрите файл: `build pack.hxml`.
 * 
 * Пример использования:
 * ```
 * pack in, out, level
 * ```
 * Где:
 *   1. `pack` - Команда в терминале для вызова упаковщика.
 *   2. `in` - Путь до **существующей** папки, которая будет упакована. (Локальная, файловая система)
 *   3. `out` - Путь вывода файла, включая его имя. (Локальная, файловая система)
 *   4. `level` - (Опционально) Уровень сжатия данных. Число от 0 до 9, где: `0` - без сжатия, `9` - максимальное сжатие.
 */
class Pack
{
    static private var packer = new Packer();
    static private var pos = 0;

    static public function main() {
        if (Node.process.argv.length < 3) {
            Node.console.error('Ошибка: Передайте первым аргументом путь до папки, которую вы хотите упаковать');
            Node.process.exitCode = 1;
            return;
        }
        if (Node.process.argv.length < 4) {
            Node.console.error('Ошибка: Передайте вторым аргументом путь для записи архива');
            Node.process.exitCode = 1;
            return;
        }
        
        // Вводные данные:
        var pin = Path.normalize(Node.process.argv[2] + '');
        var pout = Path.normalize(Node.process.argv[3] + '');
        var opt:Options =  Node.process.argv.length < 4 ? null : { level:Std.parseInt(Node.process.argv[4] + '') };
        
        // Информация:
        Node.console.log(   'Упаковка папки: "' + pin + '", ' +
                            'уровень сжатия: ' + (opt == null ? "Стандартное" : (opt.level == 0 ? "Без сжатия" : untyped opt.level))
        
        );

        // Проверка существования папки:
        if (Fs.existsSync(pin) == false) {
            Node.console.error('Ошибка: Каталог не существует: "' + Node.process.argv[2] + '"');
            Node.process.exitCode = 1;
            return;
        }

        // Проверка типа папки:
        var sts = Fs.statSync(pin);
        if (sts.isDirectory() == false) {
            Node.console.error('Ошибка: Указанный путь не является каталогом: "' + Node.process.argv[2] + '"');
            Node.process.exitCode = 1;
            return;
        }

        // Файл вывода и упаковщик:
        var fd = Fs.openSync(pout, FsOpenFlag.WriteCreate);
        
        // Пишем шапку файла:
        Fs.writeFileSync(untyped fd, untyped packer.data.slice(pos)); pos = packer.data.byteLength;

        // Пишем рекурсивно все файлы в фархив:
        pack(fd, pin, opt);

        // Завершено:
        Node.console.log('Завершено');
        Node.console.log('Вывод: "' + pout + '", размер: ' + Utils.getBytesSize(packer.data.byteLength) + ' (' + packer.data.byteLength + ' bytes)');
    }
    static private function pack(fd:Int, path:String, opt:Options, file:String = "") {
        var sts = Fs.statSync(path + file);
        if (sts.isDirectory()) {
            var list = Fs.readdirSync(path + file);
            var len = list.length;
            var i = 0;

            while (i < len)
                pack(fd, path, opt, file + "/" + list[i++]);

            return;
        }
        if (sts.isFile()) {
            Node.console.log('Упаковка: "' + file.substring(1) + '"');
            
            packer.add(Fs.readFileSync(path + file), file.substring(1), opt);
            Fs.writeFileSync(untyped fd, untyped packer.data.slice(pos)); pos = packer.data.byteLength;

            return;
        }
    }
}