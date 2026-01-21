import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/yaklasan_odeme.dart';
import '../models/kredi.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  static bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    _initialized = true;
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlem
    print('Notification tapped: ${response.payload}');
  }
  
  // Anında bildirim göster
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nev_seracilik_channel',
      'NEV Seracılık Bildirimleri',
      channelDescription: 'Taksit hatırlatmaları ve diğer bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
  }
  
  // Zamanlanmış bildirim
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nev_seracilik_scheduled',
      'Zamanlanmış Bildirimler',
      channelDescription: 'Taksit ve ödeme hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Kredi taksit hatırlatması
  Future<void> scheduleKrediTaksitReminder({
    required int krediId,
    required String bankaAd,
    required DateTime vadeTarihi,
    required double taksitTutar,
    int gunOnce = 3,
  }) async {
    final reminderDate = vadeTarihi.subtract(Duration(days: gunOnce));
    
    // Geçmiş tarih kontrolü
    if (reminderDate.isBefore(DateTime.now())) return;
    
    await scheduleNotification(
      id: krediId * 1000 + vadeTarihi.month,
      title: '💳 Taksit Hatırlatması',
      body: '$bankaAd taksiti ${_formatCurrency(taksitTutar)} - Vade: ${_formatDate(vadeTarihi)}',
      scheduledDate: DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0),
      payload: 'kredi_$krediId',
    );
  }
  
  // Tüm bildirimleri iptal et
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
  
  // Belirli bildirimi iptal et
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
  
  String _formatCurrency(double amount) {
    return '₺${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Yaklaşan ödeme hatırlatması planla
  Future<void> scheduleOdemeHatirlatma(YaklasanOdeme odeme) async {
    if (!odeme.alarmAktif || odeme.odendi) return;
    
    final alarmGunOnce = odeme.alarmGunOnce ?? 1;
    final hatirlatmaTarihi = odeme.vadeTarihi.subtract(Duration(days: alarmGunOnce));
    
    // Geçmiş tarih kontrolü
    if (hatirlatmaTarihi.isBefore(DateTime.now())) return;
    
    // Sabah 09:00'da hatırlat
    final scheduledDate = DateTime(
      hatirlatmaTarihi.year,
      hatirlatmaTarihi.month,
      hatirlatmaTarihi.day,
      9,
      0,
    );
    
    final paraBirimiSembol = odeme.paraBirimi == 'TL' ? '₺' : 
        odeme.paraBirimi == 'EUR' ? '€' : '\$';
    
    await scheduleNotification(
      id: odeme.id! + 10000, // Unique ID
      title: '⏰ Ödeme Hatırlatması',
      body: '${odeme.alacakli} - $paraBirimiSembol${odeme.tutar.toStringAsFixed(2)}\n'
          '${alarmGunOnce == 0 ? "Bugün vadesi doluyor!" : "$alarmGunOnce gün sonra vadesi dolacak"}',
      scheduledDate: scheduledDate,
      payload: 'odeme_${odeme.id}',
    );
  }

  // Tüm bekleyen ödemeler için hatırlatmaları planla
  Future<void> scheduleAllOdemeHatirlatmalari(List<YaklasanOdeme> odemeler) async {
    // Önce mevcut vade hatırlatmalarını iptal et (10000-19999 arası)
    for (var i = 10000; i < 20000; i++) {
      await cancel(i);
    }
    
    for (var odeme in odemeler) {
      if (!odeme.odendi) {
        await scheduleOdemeHatirlatma(odeme);
      }
    }
  }

  // Tüm kredi taksitleri için hatırlatmaları planla
  Future<void> scheduleAllKrediHatirlatmalari(List<Kredi> krediler) async {
    // Önce mevcut kredi hatırlatmalarını iptal et (20000-29999 arası)
    for (var i = 20000; i < 30000; i++) {
      await cancel(i);
    }
    
    int notificationId = 20000;
    for (var kredi in krediler) {
      for (var taksit in kredi.taksitler) {
        if (!taksit.odendi) {
          final hatirlatmaTarihi = taksit.vadeTarihi.subtract(const Duration(days: 3));
          
          if (hatirlatmaTarihi.isAfter(DateTime.now())) {
            final scheduledDate = DateTime(
              hatirlatmaTarihi.year,
              hatirlatmaTarihi.month,
              hatirlatmaTarihi.day,
              9,
              0,
            );
            
            await scheduleNotification(
              id: notificationId++,
              title: '💳 Kredi Taksit Hatırlatması',
              body: '${kredi.bankaAd} - ${taksit.periyot}. Taksit\n'
                  '${_formatCurrency(taksit.toplamTaksit)} - 3 gün içinde ödenecek',
              scheduledDate: scheduledDate,
              payload: 'kredi_${kredi.id}_taksit_${taksit.id}',
            );
          }
        }
      }
    }
  }

  // Günlük özet bildirimi göster
  Future<void> showGunlukOzet({
    required int yaklasanOdemeSayisi,
    required int yaklasanTaksitSayisi,
    required double toplamBorc,
  }) async {
    if (yaklasanOdemeSayisi == 0 && yaklasanTaksitSayisi == 0) return;
    
    final body = StringBuffer();
    
    if (yaklasanOdemeSayisi > 0) {
      body.writeln('📅 $yaklasanOdemeSayisi yaklaşan ödeme');
    }
    if (yaklasanTaksitSayisi > 0) {
      body.writeln('💳 $yaklasanTaksitSayisi yaklaşan taksit');
    }
    if (toplamBorc > 0) {
      body.writeln('💰 Toplam: ${_formatCurrency(toplamBorc)}');
    }
    
    await showNotification(
      id: 1,
      title: '📊 Günlük Finansal Özet',
      body: body.toString().trim(),
      payload: 'gunluk_ozet',
    );
  }

  // Bekleyen bildirimleri say
  Future<int> getPendingNotificationCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
