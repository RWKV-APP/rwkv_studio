import 'package:rwkv_studio/src/utils/logger.dart';

import 'main.dart'
    if (dart.library.io) 'desktop/main.dart'
    if (dart.library.html) 'web/main.dart'
    as entry;

void main() => AppLog.captureZone(() => entry.main());
