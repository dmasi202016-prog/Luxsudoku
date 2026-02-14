import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  AudioService._();
  
  static final AudioService instance = AudioService._();
  
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    debugPrint('[AudioService] initialize() called, _isInitialized=$_isInitialized');
    
    if (_isInitialized) return;
    
    try {
      debugPrint('[AudioService] Before setAsset');
      await _bgPlayer.setAsset('assets/audio/piano_background.mp3');
      debugPrint('[AudioService] After setAsset - success');
      // Set loop mode to repeat indefinitely
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(0.3);
      _isInitialized = true;
      debugPrint('[AudioService] initialize() completed successfully, loop mode: ${_bgPlayer.loopMode}');
    } catch (e) {
      debugPrint('[AudioService] initialize() caught exception: $e');
      // If audio file not found, silently fail
      _isInitialized = false;
    }
  }

  Future<void> playBackground({bool enabled = true}) async {
    debugPrint('[AudioService] playBackground() called, enabled=$enabled, _isInitialized=$_isInitialized');
    if (!enabled) {
      debugPrint('[AudioService] Sound disabled, stopping playback');
      await stopBackground();
      return;
    }
    if (!_isInitialized) await initialize();
    debugPrint('[AudioService] After initialize check, _isInitialized=$_isInitialized');
    try {
      debugPrint('[AudioService] Before play(), playing=${_bgPlayer.playing}');
      await _bgPlayer.play();
      debugPrint('[AudioService] After play() - success, playing=${_bgPlayer.playing}');
    } catch (e) {
      debugPrint('[AudioService] playBackground() caught exception: $e');
      // Silently fail if audio not available
    }
  }

  Future<void> pauseBackground() async {
    try {
      await _bgPlayer.pause();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> stopBackground() async {
    try {
      await _bgPlayer.stop();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> playFinishSound({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await _sfxPlayer.setAsset('assets/audio/finish.mp3');
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play();
    } catch (e) {
      // Silently fail if audio not available
    }
  }

  Future<void> stopFinishSound() async {
    try {
      await _sfxPlayer.stop();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _bgPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      // Silently fail
    }
  }

  void dispose() {
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
