// Database service stub for conditional imports
export 'database_service_native.dart'
    if (dart.library.html) 'database_service_web.dart';
