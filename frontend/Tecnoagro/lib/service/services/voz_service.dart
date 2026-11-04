import 'package:speech_to_text/speech_to_text.dart' as stt;

class VozService {
  final _voz = stt.SpeechToText();
  bool _lista = false;

  /// Empieza a escuchar. Devuelve false si no hay micrófono o permiso.
  Future<bool> escuchar(void Function(String texto, bool fin) alTexto, void Function() alTerminar) async {
    _lista = _lista ||
        await _voz.initialize(onStatus: (s) => s == 'done' ? alTerminar() : null, onError: (_) => alTerminar());
    if (!_lista) return false;
    final es = (await _voz.locales()).map((l) => l.localeId).where((l) => l.toLowerCase().startsWith('es'));
    await _voz.listen(
      localeId: es.contains('es_CO') ? 'es_CO' : es.firstOrNull,
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (r) => alTexto(r.recognizedWords, r.finalResult),
    );
    return true;
  }

  Future<void> detener() => _voz.stop();
  void cancelar() => _voz.cancel();
}