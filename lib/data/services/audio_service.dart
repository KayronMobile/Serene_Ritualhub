import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

/// Catálogo dos sons ambiente: nome exibido → arquivo em `assets/sounds/`.
///
/// Para adicionar um som, coloque o arquivo na pasta e registre aqui. Sons
/// sem arquivo são ignorados em silêncio (o player continua funcionando).
abstract final class AmbientSounds {
  static const assets = {
    'Chuva Suave na Floresta': 'assets/sounds/chuva_floresta.mp3',
    'Ondas do Mar': 'assets/sounds/ondas_mar.mp3',
    'Lareira ao Longe': 'assets/sounds/lareira.mp3',
    'Pássaros ao Amanhecer': 'assets/sounds/passaros.mp3',
    'Ruído Branco': 'assets/sounds/ruido_branco.wav',
  };

  static List<String> get names => assets.keys.toList();

  static const bell = 'assets/sounds/bell.wav';
}

/// Contrato do serviço de áudio (permite fakes nos testes).
abstract class AudioService {
  /// Toca [name] em loop com fade-in. Se já estiver tocando, não reinicia.
  Future<void> playAmbient(String name);

  Future<void> pauseAmbient();

  Future<void> resumeAmbient();

  Future<void> stopAmbient();

  /// Sino curto (ex.: fim do tempo de um passo).
  Future<void> playBell();

  Future<void> dispose();
}

/// Implementação com `just_audio`: um player para o som ambiente (loop) e
/// outro para o sino, para que possam soar juntos.
class JustAudioService implements AudioService {
  JustAudioService({AudioPlayer? ambient, AudioPlayer? bell})
    : _ambientPlayer = ambient ?? AudioPlayer(),
      _bellPlayer = bell ?? AudioPlayer();

  final AudioPlayer _ambientPlayer;
  final AudioPlayer _bellPlayer;
  final _log = Logger('JustAudioService');

  static const _volume = 0.6;
  static const _fadeSteps = 10;
  static const _fadeDuration = Duration(milliseconds: 800);

  String? _current;
  bool _bellLoaded = false;

  @override
  Future<void> playAmbient(String name) async {
    final asset = AmbientSounds.assets[name];
    if (asset == null) return;
    try {
      if (_current != name) {
        await _ambientPlayer.stop();
        await _ambientPlayer.setAsset(asset);
        await _ambientPlayer.setLoopMode(LoopMode.one);
        _current = name;
      }
      if (_ambientPlayer.playing) return;
      await _ambientPlayer.setVolume(0);
      // `play()` só completa quando a reprodução para — não aguardar.
      _ambientPlayer.play().ignore();
      await _fade(0, _volume);
    } catch (e) {
      _current = null;
      _log.info('Som ambiente indisponível ($asset): $e');
    }
  }

  @override
  Future<void> pauseAmbient() async {
    if (!_ambientPlayer.playing) return;
    try {
      await _fade(_ambientPlayer.volume, 0);
      await _ambientPlayer.pause();
    } catch (e) {
      _log.info('Falha ao pausar som: $e');
    }
  }

  @override
  Future<void> resumeAmbient() async {
    final name = _current;
    if (name != null) await playAmbient(name);
  }

  @override
  Future<void> stopAmbient() async {
    try {
      if (_ambientPlayer.playing) await _fade(_ambientPlayer.volume, 0);
      await _ambientPlayer.stop();
    } catch (e) {
      _log.info('Falha ao parar som: $e');
    }
    _current = null;
  }

  @override
  Future<void> playBell() async {
    try {
      if (!_bellLoaded) {
        await _bellPlayer.setAsset(AmbientSounds.bell);
        _bellLoaded = true;
      }
      await _bellPlayer.seek(Duration.zero);
      _bellPlayer.play().ignore();
    } catch (e) {
      _log.info('Sino indisponível: $e');
    }
  }

  Future<void> _fade(double from, double to) async {
    final step = _fadeDuration ~/ _fadeSteps;
    for (var i = 1; i <= _fadeSteps; i++) {
      await _ambientPlayer.setVolume(from + (to - from) * i / _fadeSteps);
      await Future<void>.delayed(step);
    }
  }

  @override
  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _bellPlayer.dispose();
  }
}
