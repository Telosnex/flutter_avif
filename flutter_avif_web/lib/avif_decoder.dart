@JS()
library MODULE;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web';

import 'package:flutter_avif_platform_interface/flutter_avif_platform_interface.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:web/web.dart';

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
      .getAssetUrl('packages/flutter_avif_web/web/avif_decoder.loader.js');
  
  // Using dart:web's querySelector instead of direct head access
  final head = document.querySelector('head');
  if (head != null) {
    head.appendChild(script);
  } else {
    throw Exception('Head element not found in document');
  }

  final initBindgen = _initBindgen(assetManager
      .getAssetUrl('packages/flutter_avif_web/web/avif_decoder.worker.js')).toDart;
  await initBindgen;

  _scriptLoaderCompleter!.complete();
}

Future<Frame> decodeSingleFrameImage(Uint8List data) async {
  final  decoded = await (_decodeSingleFrameImage(data).toDart);
  if (decoded is! JSObject) {
    throw Exception('Failed to decode image');
  }

  return Frame(
    data: decoded.getProperty('data'.toJS) as Uint8List,
    duration: decoded.getProperty('duration'.toJS) as double,
    width: decoded.getProperty('width'.toJS) as int,
    height: decoded.getProperty('height'.toJS) as int,
  );
}

Future<AvifInfo> initMemoryDecoder(String key, Uint8List data) async {
  final decoded = await (_initMemoryDecoder(key, data)).toDart;
  if (decoded is! JSObject) {
    throw Exception('Failed to initialize decoder');
  }

  return AvifInfo(
    width: decoded.getProperty('width'.toJS) as int,
    height: decoded.getProperty('height'.toJS) as int,
    imageCount: decoded.getProperty('imageCount'.toJS) as int,
    duration: decoded.getProperty('duration'.toJS) as double,
  );
}

Future<Frame> getNextFrame(String key) async {
  final  decoded = await (_getNextFrame(key)).toDart;
  if (decoded is! JSObject) {
    throw Exception('Failed to get next frame');
  }

  return Frame(
    data: decoded.getProperty('data'.toJS) as Uint8List,
    duration: decoded.getProperty('duration'.toJS) as double,
    width: decoded.getProperty('width'.toJS) as int,
    height: decoded.getProperty('height'.toJS) as int,
  );
}

Future<bool> resetDecoder(String key) async {
  await _resetDecoder(key).toDart;
  return true;
}

Future<bool> disposeDecoder(String key) async {
  await _disposeDecoder(key).toDart;
  return true;
}

@JS('window.avifDecoderLoad')
external JSPromise _initBindgen(String workerPath);

@JS('window.avif_decoder.decodeSingleFrameImage')
external JSPromise _decodeSingleFrameImage(Uint8List data);

@JS('window.avif_decoder.initMemoryDecoder')
external JSPromise _initMemoryDecoder(String key, Uint8List data);

@JS('window.avif_decoder.getNextFrame')
external JSPromise _getNextFrame(String key);

@JS('window.avif_decoder.resetDecoder')
external JSPromise _resetDecoder(String key);

@JS('window.avif_decoder.disposeDecoder')
external JSPromise _disposeDecoder(String key);
