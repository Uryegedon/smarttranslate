import 'dart:async';

import 'package:flutter/services.dart';

class NativeSpeechEvent {
  const NativeSpeechEvent({
    required this.type,
    this.text,
    this.isFinal = false,
    this.value,
    this.message,
  });

  final String type;
  final String? text;
  final bool isFinal;
  final String? value;
  final String? message;

  factory NativeSpeechEvent.fromMap(Map<dynamic, dynamic> map) {
    return NativeSpeechEvent(
      type: map['type'] as String? ?? 'status',
      text: map['text'] as String?,
      isFinal: map['final'] as bool? ?? false,
      value: map['value'] as String?,
      message: map['message'] as String?,
    );
  }
}

class NativeOnDeviceSpeechService {
  static const MethodChannel _methodChannel = MethodChannel(
    'smarttranslate/native_speech',
  );
  static const EventChannel _eventChannel = EventChannel(
    'smarttranslate/native_speech/events',
  );

  static Stream<NativeSpeechEvent> events() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return NativeSpeechEvent.fromMap(
        Map<dynamic, dynamic>.from(event as Map),
      );
    });
  }

  static Future<bool> isAvailable() async {
    try {
      return await _methodChannel.invokeMethod<bool>(
            'isOnDeviceRecognitionAvailable',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> start({required String localeId}) async {
    try {
      return await _methodChannel.invokeMethod<bool>(
            'startOnDeviceRecognition',
            {'localeId': localeId},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<void>('stopOnDeviceRecognition');
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> cancel() async {
    try {
      await _methodChannel.invokeMethod<void>('cancelOnDeviceRecognition');
    } on MissingPluginException {
      return;
    }
  }
}
