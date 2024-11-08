@JS()
library wasm_bindgen;

import 'dart:js_interop_unsafe';
import 'dart:ui_web';
import 'package:flutter_avif_platform_interface/flutter_avif_platform_interface.dart';

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' hide Uint32List;

Completer? _scriptLoaderCompleter;

bool get isScriptLoaded =>
    _scriptLoaderCompleter != null && _scriptLoaderCompleter!.isCompleted;

Future<void> loadScript() async {
  if (_scriptLoaderCompleter != null) {
    return _scriptLoaderCompleter!.future;
  }

  _scriptLoaderCompleter = Completer();

  final assetManager = AssetManager();
  final script = document.createElement('script') as HTMLScriptElement;
  script.src = assetManager
      .getAssetUrl('packages/flutter_avif_web/web/avif_encoder.loader.js');
  // Using dart:web's querySelector instead of direct head access
  final head = document.querySelector('head');
  if (head != null) {
    head.appendChild(script);
  } else {
    throw Exception('Head element not found in document');
  }
  await script.onLoad.first;

  final initBindgen = (_initBindgen(assetManager
      .getAssetUrl('packages/flutter_avif_web/web/avif_encoder.worker.js'))).toDart;
  await initBindgen;

  _scriptLoaderCompleter!.complete();
}

Future<Uint8List> encodeAvif({
  required Uint8List pixels,
  required Uint8List durations,
  required int width,
  required int height,
  required int speed,
  required int maxThreads,
  required int timescale,
  required int maxQuantizer,
  required int minQuantizer,
  required int maxQuantizerAlpha,
  required int minQuantizerAlpha,
  required Uint8List exifData,
}) async {
  final options = Uint32List.fromList([
    width,
    height,
    speed,
    maxThreads,
    timescale,
    maxQuantizer,
    minQuantizer,
    maxQuantizerAlpha,
    minQuantizerAlpha,
  ]);
  final jsAnyResult = await _encode(
    pixels.toJS,
    durations.toJS,
    options.toJS,
    exifData.toJS,
  ).toDart;
  if (jsAnyResult == null) {
    throw Exception('Failed to encode image');
  }
  final result = jsAnyResult as JSUint8Array;
  return result.toDart;
}

Future<DecodeData> decode(Uint8List data, int orientation) async {
  final decoded = await (_decode(data.toJS, orientation).toDart);
  if (decoded == null || decoded is! JSObject) {
    throw Exception('Failed to decode image');
  }
  final rgbaData = decoded.getProperty('data'.toJS) as List<dynamic>;
  final durations = decoded.getProperty('durations'.toJS) as List<dynamic>;

  return DecodeData(
    data: Uint8List.fromList(rgbaData.cast<int>()),
    durations: Uint32List.fromList(durations.cast<int>()),
    width: decoded.getProperty('width'.toJS) as int,
    height: decoded.getProperty('height'.toJS) as int,
  );
}

@JS('window.avifEncoderLoad')
external JSPromise _initBindgen(String workerPath);

@JS('window.avif_encoder.encode')
external JSPromise _encode(
  JSUint8Array pixels,
  JSUint8Array durations,
  JSUint32Array options,
  JSUint8Array exifData,
);

@JS('window.avif_encoder.decode')
external JSPromise _decode(
  JSUint8Array data,
  int orientation,
);
