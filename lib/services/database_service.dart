// Database service with conditional import for web/native
// Mobile uses SQLite (native), Web uses Firebase Firestore
export 'database_service_native.dart'
    if (dart.library.html) 'database_service_firebase_v2.dart';
