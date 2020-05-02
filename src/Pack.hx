package;

import js.Node;

/**
 * Обработчик CLI.
 * Используется для упаковки папок в локальной, файловой системе в корректный архив WebPackager'a, с помощью NodeJS.
 * * Этот файл является **точкой входа** для вызываемой команды: `pack`.
 * * Этот файл компилируется отдельно и имеет собственные параметры компиляции, смотрите файл: `build pack.hxml`.
 */
class Pack
{
    static public function main() {
        trace("pack args:", Node.process.argv);
    }
}