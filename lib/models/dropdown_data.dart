// Gider Data-(Dropdown) ve Kredi Data-(Dropdown) sheet'lerinden gelen sabit veriler

class GiderKategorileri {
  static const List<String> aciklama = [
    'Akaryakıt Alımı',
    'Akaryakıt (Mazot)',
    'Avans',
    'Çekilen Kredi',
    'Damla sulama',
    'Diğer',
    'Elektrik Faturası',
    'Fide Alımı',
    'Gübre Alımı',
    'Hammadde',
    'İlaç Alımı',
    'İş Makinası Kiralama',
    'İşçi Avansı',
    'İşçi Maaşı',
    'İşçi Sigorta',
    'Kargo',
    'Kasa Bağışı',
    'Komisyon Ödemesi',
    'Kredi Avans',
    'Kredi Ödemesi',
    'Nakit Giriş',
    'Nakliye',
    'Ortaklık Hissesi',
    'Sabit Gider',
    'Satış Geliri',
    'SGK Prim Ödemesi',
    'Su Faturası',
    'Tarımsal Destek',
    'Telefon Faturası',
    'Toprak Düzeltici',
    'Tohum Alımı',
    'Yemek',
    'Zirai İlaç',
  ];
  
  static const List<String> islemTipi = [
    'Giriş',
    'Çıkış',
  ];
  
  static const List<String> odemeBicimi = [
    'Nakit',
    'Havale/EFT',
    'Kredi Kartı',
    'Çek',
    'Senet',
    'Diğer',
  ];
  
  static const List<String> kasa = [
    'Mert Anter',
    'Necati Özdere',
    'NEV Seracılık',
    'AveA Sağlık',
  ];
  
  static const List<String> sahis = [
    'Mert Anter',
    'Necati Özdere',
    'Şirket',
  ];
}

class KrediKategorileri {
  static const List<String> bankalar = [
    'Akbank',
    'DenizBank',
    'Garanti BBVA',
    'Halkbank',
    'İş Bankası',
    'QNB Finansbank',
    'TEB',
    'Vakıfbank',
    'Yapı Kredi',
    'Ziraat Bankası',
  ];
  
  static const List<String> taksitTipi = [
    'Eşit Taksit',
    'Eşit Anapara',
    'Balon Ödemeli',
  ];
  
  static const List<String> faizGirisiTuru = [
    'Yıllık',
    'Aylık',
  ];
  
  static const List<String> paraBirimi = [
    'TL',
    'USD',
    'EUR',
  ];
}
