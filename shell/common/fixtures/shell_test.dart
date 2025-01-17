// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

void main() {}

void nativeReportTimingsCallback(List<int> timings) native 'NativeReportTimingsCallback';
void nativeOnBeginFrame(int microseconds) native 'NativeOnBeginFrame';

@pragma('vm:entry-point')
void reportTimingsMain() {
  window.onReportTimings = (List<FrameTiming> timings) {
    List<int> timestamps = [];
    for (FrameTiming t in timings) {
      for (FramePhase phase in FramePhase.values) {
        timestamps.add(t.timestampInMicroseconds(phase));
      }
    }
    nativeReportTimingsCallback(timestamps);
  };
}

@pragma('vm:entry-point')
void onBeginFrameMain() {
  window.onBeginFrame = (Duration beginTime) {
    nativeOnBeginFrame(beginTime.inMicroseconds);
  };
}

@pragma('vm:entry-point')
void emptyMain() {}

@pragma('vm:entry-point')
void dummyReportTimingsMain() {
  window.onReportTimings = (List<FrameTiming> timings) {};
}

@pragma('vm:entry-point')
void fixturesAreFunctionalMain() {
  sayHiFromFixturesAreFunctionalMain();
}

void sayHiFromFixturesAreFunctionalMain() native 'SayHiFromFixturesAreFunctionalMain';

void notifyNative() native 'NotifyNative';

void secondaryIsolateMain(String message) {
  print('Secondary isolate got message: ' + message);
  notifyNative();
}

@pragma('vm:entry-point')
void testCanLaunchSecondaryIsolate() {
  Isolate.spawn(secondaryIsolateMain, 'Hello from root isolate.');
  notifyNative();
}

@pragma('vm:entry-point')
void testSkiaResourceCacheSendsResponse() {
  final PlatformMessageResponseCallback callback = (ByteData data) {
    if (data == null) {
      throw 'Response must not be null.';
    }
    notifyNative();
  };
  const String json = '''{
                            "method": "Skia.setResourceCacheMaxBytes",
                            "args": 10000
                          }''';
  window.sendPlatformMessage(
    'flutter/skia',
    Uint8List.fromList(utf8.encode(json)).buffer.asByteData(),
    callback,
  );
}

void notifyWidthHeight(int width, int height) native 'NotifyWidthHeight';

@pragma('vm:entry-point')
void canCreateImageFromDecompressedData() {
  const int imageWidth = 10;
  const int imageHeight = 10;
  final Uint8List pixels = Uint8List.fromList(List<int>.generate(
    imageWidth * imageHeight * 4,
    (int i) => i % 4 < 2 ? 0x00 : 0xFF,
  ));


  decodeImageFromPixels(
      pixels, imageWidth, imageHeight, PixelFormat.rgba8888,
      (Image image) {
    notifyWidthHeight(image.width, image.height);
  });
}
