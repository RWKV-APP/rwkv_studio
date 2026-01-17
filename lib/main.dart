import 'main.dart'
    if (dart.library.io) 'desktop/main.dart'
    if (dart.library.html) 'web/main.dart'
    as entry;

void main() => entry.main();
