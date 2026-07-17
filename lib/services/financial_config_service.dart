// File: lib/services/financial_config_service.dart
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/financial_config.dart';
import 'default_config.dart';

class FinancialConfigService {
  static final FinancialConfigService _instance = FinancialConfigService._internal();
  factory FinancialConfigService() => _instance;
  FinancialConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  FinancialConfig? _currentConfig;
  SharedPreferences? _prefs;

  static const String _cacheKey = 'financial_config_cache';
  static const String _versionKey = 'financial_config_version';
  static const int _cacheValidityDays = 7;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setDefaults({
        'financial_config_json': '{}',
        'config_version': '1.0.0',
        'min_cache_hours': '12',
      });
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
    } catch (e) {
      debugPrint('⚠️ Firebase Remote Config not available: $e');
      _remoteConfig = null;
    }
  }

  // ==================== GET CONFIG ====================

  Future<FinancialConfig> getConfig() async {
    // Return cached if already loaded
    if (_currentConfig != null && !_currentConfig!.isExpired) {
      return _currentConfig!;
    }

    // Layer 2: Try local cache
    final cached = await _loadFromCache();
    if (cached != null && !cached.isExpired) {
      _currentConfig = cached;
      // Background refresh
      _refreshInBackground();
      return cached;
    }

    // Layer 3: Try remote fetch
    final remote = await _fetchFromRemote();
    if (remote != null) {
      _currentConfig = remote;
      await _saveToCache(remote);
      return remote;
    }

    // Layer 1: Use defaults
    debugPrint('⚠️ Using hardcoded default config');
    _currentConfig = DefaultConfig.defaultConfig;
    return _currentConfig!;
  }

  // ==================== FORCE REFRESH ====================

  Future<FinancialConfig?> forceRefresh() async {
    debugPrint('🔄 Force refreshing financial config...');
    
    final remote = await _fetchFromRemote(forceFetch: true);
    if (remote != null) {
      _currentConfig = remote;
      await _saveToCache(remote);
      return remote;
    }
    
    return null;
  }

  // ==================== LAYER 2: LOCAL CACHE ====================

  Future<FinancialConfig?> _loadFromCache() async {
    try {
      final jsonStr = _prefs?.getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final json = jsonDecode(jsonStr);
      final config = FinancialConfig.fromJson(json, source: 'cache');
      
      debugPrint('📦 Loaded config from cache (v${config.version})');
      return config;
    } catch (e) {
      debugPrint('❌ Cache load error: $e');
      return null;
    }
  }

  Future<void> _saveToCache(FinancialConfig config) async {
    try {
      await _prefs?.setString(_cacheKey, jsonEncode(config.toJson()));
      await _prefs?.setString(_versionKey, config.version);
      debugPrint('💾 Config saved to cache (v${config.version})');
    } catch (e) {
      debugPrint('❌ Cache save error: $e');
    }
  }

  // ==================== LAYER 3: REMOTE FETCH ====================

  Future<FinancialConfig?> _fetchFromRemote({bool forceFetch = false}) async {
    if (_remoteConfig == null) {
      debugPrint('⚠️ Remote config not available');
      return null;
    }

    try {
      if (forceFetch) {
        await _remoteConfig!.fetchAndActivate();
      } else {
        // Check if we need to fetch
        final lastFetch = _remoteConfig!.lastFetchTime;
        final lastFetchStatus = _remoteConfig!.lastFetchStatus;
        
        if (lastFetchStatus == RemoteConfigFetchStatus.success &&
            DateTime.now().difference(lastFetch).inHours < 6) {
          debugPrint('⏭️ Skipping fetch - last fetch was ${DateTime.now().difference(lastFetch).inMinutes}m ago');
        } else {
          await _remoteConfig!.fetchAndActivate();
        }
      }

      final jsonStr = _remoteConfig!.getString('financial_config_json');
      
      if (jsonStr.isEmpty || jsonStr == '{}') {
        debugPrint('⚠️ Remote config is empty');
        return null;
      }

      final json = jsonDecode(jsonStr);
      final config = FinancialConfig.fromJson(json, source: 'remote');
      
      debugPrint('☁️ Fetched config from remote (v${config.version})');
      return config;
    } catch (e) {
      debugPrint('❌ Remote fetch error: $e');
      return null;
    }
  }

  // ==================== BACKGROUND REFRESH ====================

  void _refreshInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      final remote = await _fetchFromRemote();
      if (remote != null && (_currentConfig == null || remote.version != _currentConfig!.version)) {
        _currentConfig = remote;
        await _saveToCache(remote);
        debugPrint('🔄 Background refresh: Config updated to v${remote.version}');
      }
    });
  }

  // ==================== UTILITY ====================

  String get currentVersion => _currentConfig?.version ?? 'unknown';
  String get currentSource => _currentConfig?.sourceLabel ?? 'not loaded';
  
  bool get isUsingDefaults => _currentConfig?.isDefault ?? false;
  bool get isUsingRemote => _currentConfig?.isRemote ?? false;

  Future<void> clearCache() async {
    await _prefs?.remove(_cacheKey);
    await _prefs?.remove(_versionKey);
    _currentConfig = null;
    debugPrint('🧹 Config cache cleared');
  }
}