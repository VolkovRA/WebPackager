package;

import js.Node;

/**
 * Обработчик CLI.
 * Используется для упаковки папок в локальной, файловой системе в корректный архив WebPackager'a, с помощью NodeJS.
 * * Этот файл является **точкой входа** для вызываемой команды: `unpack`.
 * * Этот файл компилируется отдельно и имеет собственные параметры компиляции, смотрите файл: `build unpack.hxml`.
 */
class Unpack
{
    static public function main() {
        trace("unpack args:", Node.process.argv);
    }
}