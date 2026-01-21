import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _cacheKey = 'cached_rates';
  static const String _cacheTimeKey = 'cached_rates_time';
  static const Duration _cacheExpiry = Duration(hours: 1);

  Map<String, double> _rates = {};
  DateTime? _lastFetch;

  Future<Map<String, double>> getRates() async {
    // Önce memory cache'e bak
    if (_rates.isNotEmpty && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
        return _rates;
      }
    }

    // Persistent cache'den yükle
    final cached = await _loadFromCache();
    if (cached != null) {
      _rates = cached;
      return _rates;
    }

    // API'den çek
    return await fetchRates();
  }

  Future<Map<String, double>> fetchRates() async {
    // Farklı API'leri dene
    Map<String, double>? rates;
    
    // 1. TCMB XML API (en güvenilir)
    rates = await _fetchFromTCMB();
    if (rates != null) return rates;
    
    // 2. ExchangeRate API
    rates = await _fetchFromExchangeRateApi();
    if (rates != null) return rates;
    
    // 3. Open Exchange Rates
    rates = await _fetchFromOpenER();
    if (rates != null) return rates;

    // Tüm API'ler başarısız, cache'den dön
    final cached = await _loadFromCache();
    if (cached != null) return cached;

    // Son çare: güncel fallback değerler
    return _getFallbackRates();
  }
  
  /// TCMB XML verilerinden kur çekme
  Future<Map<String, double>?> _fetchFromTCMB() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.tcmb.gov.tr/kurlar/today.xml'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final body = response.body;
        
        // USD kurunu bul
        final usdMatch = RegExp(r'<Currency.*?Kod="USD".*?>.*?<ForexSelling>([\d.,]+)</ForexSelling>', dotAll: true)
            .firstMatch(body);
        final eurMatch = RegExp(r'<Currency.*?Kod="EUR".*?>.*?<ForexSelling>([\d.,]+)</ForexSelling>', dotAll: true)
            .firstMatch(body);
        
        if (usdMatch != null && eurMatch != null) {
          final usdTry = double.tryParse(usdMatch.group(1)!.replaceAll(',', '.'));
          final eurTry = double.tryParse(eurMatch.group(1)!.replaceAll(',', '.'));
          
          if (usdTry != null && eurTry != null && usdTry > 0 && eurTry > 0) {
            _rates = {
              'EUR_TRY': eurTry,
              'USD_TRY': usdTry,
              'EUR_USD': eurTry / usdTry,
            };
            _lastFetch = DateTime.now();
            await _saveToCache(_rates);
            return _rates;
          }
        }
      }
    } catch (e) {
      print('TCMB API error: $e');
    }
    return null;
  }
  
  /// ExchangeRate API
  Future<Map<String, double>?> _fetchFromExchangeRateApi() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/TRY'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>?;
        
        if (rates != null) {
          final eurRate = rates['EUR']?.toDouble();
          final usdRate = rates['USD']?.toDouble();
          
          if (eurRate != null && usdRate != null && eurRate > 0 && usdRate > 0) {
            _rates = {
              'EUR_TRY': 1 / eurRate,
              'USD_TRY': 1 / usdRate,
              'EUR_USD': usdRate / eurRate,
            };
            _lastFetch = DateTime.now();
            await _saveToCache(_rates);
            return _rates;
          }
        }
      }
    } catch (e) {
      print('ExchangeRate API error: $e');
    }
    return null;
  }
  
  /// Open Exchange Rates API
  Future<Map<String, double>?> _fetchFromOpenER() async {
    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/TRY'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>?;
        
        if (rates != null) {
          final eurRate = rates['EUR']?.toDouble();
          final usdRate = rates['USD']?.toDouble();
          
          if (eurRate != null && usdRate != null && eurRate > 0 && usdRate > 0) {
            _rates = {
              'EUR_TRY': 1 / eurRate,
              'USD_TRY': 1 / usdRate,
              'EUR_USD': usdRate / eurRate,
            };
            _lastFetch = DateTime.now();
            await _saveToCache(_rates);
            return _rates;
          }
        }
      }
    } catch (e) {
      print('Open ER API error: $e');
    }
    return null;
  }

  Map<String, double> _getFallbackRates() {
    // Ocak 2026 güncel yaklaşık değerler
    return {
      'EUR_TRY': 37.80,
      'EUR_USD': 1.04,
      'USD_TRY': 36.35,
    };
  }

  Future<void> _saveToCache(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(rates));
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, double>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getInt(_cacheTimeKey);

    if (cachedTime != null) {
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cachedTime),
      );

      if (cacheAge < _cacheExpiry) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          final decoded = json.decode(cached) as Map<String, dynamic>;
          _rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTime);
          return _rates;
        }
      }
    }
    return null;
  }

  double convertEurToTry(double eurAmount) {
    return eurAmount * (_rates['EUR_TRY'] ?? 38.0);
  }

  double convertTryToEur(double tryAmount) {
    final rate = _rates['EUR_TRY'] ?? 38.0;
    return rate > 0 ? tryAmount / rate : 0;
  }

  double get eurTryRate => _rates['EUR_TRY'] ?? 38.0;
  double get usdTryRate => _rates['USD_TRY'] ?? 35.0;
}
