import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

// ignore: constant_identifier_names
const Duration DEFAULT_TIME_RETRY = Duration(milliseconds: 100);
// ignore: constant_identifier_names
const int DEFAULT_RETRIES = 3;

class ExNetworkImageProvider extends ImageProvider<ExtendedNetworkImageProvider>
    with ExtendedImageProvider<ExtendedNetworkImageProvider>
    implements ExtendedNetworkImageProvider {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  ExNetworkImageProvider(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.cache = false,
    this.retries = DEFAULT_RETRIES,
    this.timeLimit,
    this.timeRetry = DEFAULT_TIME_RETRY,
    this.cacheKey,
    this.printError = true,
    this.cacheRawData = false,
    this.cancelToken,
    this.imageCacheName,
    this.cacheMaxAge,
  });

  /// The name of [ImageCache], you can define custom [ImageCache] to store this provider.
  @override
  final String? imageCacheName;

  /// Whether cache raw data if you need to get raw data directly.
  /// For example, we need raw image data to edit,
  /// but [ui.Image.toByteData()] is very slow. So we cache the image
  /// data here.
  @override
  final bool cacheRawData;

  /// The time limit to request image
  @override
  final Duration? timeLimit;

  /// The time to retry to request
  @override
  final int retries;

  /// The time duration to retry to request
  @override
  final Duration timeRetry;

  /// Whether cache image to local
  @override
  final bool cache;

  /// The URL from which the image will be fetched.
  @override
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  @override
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  @override
  final Map<String, String>? headers;

  /// The token to cancel network request
  @override
  final CancellationToken? cancelToken;

  /// Custom cache key
  @override
  final String? cacheKey;

  /// print error
  @override
  final bool printError;

  /// The max duration to cahce image.
  /// After this time the cache is expired and the image is reloaded.
  @override
  final Duration? cacheMaxAge;

  @override
  ImageStreamCompleter load(ExtendedNetworkImageProvider key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(
        key as ExNetworkImageProvider,
        chunkEvents,
        decode,
      ),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<ExtendedNetworkImageProvider>('Image key', key),
        ];
      },
    );
  }

  @override
  Future<ExNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ExNetworkImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(
    ExNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) async {
    assert(key == this);
    final String md5Key = cacheKey ?? keyToMd5(key.url);
    ui.Codec? result;
    if (cache) {
      try {
        final Uint8List? data = await _loadCache(
          key,
          chunkEvents,
          md5Key,
        );
        if (data != null) {
          result = await instantiateImageCodec(data, decode);
        }
      } catch (e) {
        if (printError) {
          debugPrint(e.toString());
        }
      }
    }

    if (result == null) {
      try {
        final Uint8List? data = await _loadNetwork(
          key.url,
          chunkEvents: chunkEvents,
          headers: headers,
          timeLimit: timeLimit,
          cancelToken: cancelToken,
          timeRetry: timeRetry,
          retries: retries,
          printError: printError,
        );
        if (data != null) {
          result = await instantiateImageCodec(data, decode);
        }
      } catch (e) {
        if (printError) {
          debugPrint(e.toString());
        }
      }
    }

    //Failed to load
    if (result == null) {
      //result = await ui.instantiateImageCodec(kTransparentImage);

      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }

    return result;
  }

  static late Directory _cacheImagesDirectory;

  static void initialize() {
    path_provider.getTemporaryDirectory().then((dir) {
      _cacheImagesDirectory = Directory(path.join(dir.path, "dingdongu", "cache_image"));
      if (!_cacheImagesDirectory.existsSync()) {
        _cacheImagesDirectory.createSync(recursive: true);
      }
    });
  }

  static Future<void> precache(
    String url, {
    String? cacheKey,
    Uint8List? data,
  }) async {
    final String md5Key = cacheKey ?? keyToMd5(url);
    data ??= await _loadNetwork(
      url,
      timeRetry: DEFAULT_TIME_RETRY,
      retries: DEFAULT_RETRIES,
    );
    if (data != null) {
      // cache image file
      await File(path.join(_cacheImagesDirectory.path, md5Key)).writeAsBytes(data);
    }
  }

  /// Get the image from cache folder
  /// If there were no cache image, load from network [_loadNetwork] and cache result
  Future<Uint8List?> _loadCache(
    ExNetworkImageProvider key,
    StreamController<ImageChunkEvent>? chunkEvents,
    String md5Key,
  ) async {
    Uint8List? data;
    // exist, try to find cache image file
    final File cacheFile = File(path.join(_cacheImagesDirectory.path, md5Key));
    if (cacheFile.existsSync()) {
      // remove cache images by compared to cacheMaxAge
      if (key.cacheMaxAge != null) {
        final DateTime now = DateTime.now();
        final FileStat fs = cacheFile.statSync();
        if (now.subtract(key.cacheMaxAge!).isAfter(fs.changed)) {
          cacheFile.deleteSync(recursive: true);
        } else {
          data = await cacheFile.readAsBytes();
        }
      } else {
        data = await cacheFile.readAsBytes();
      }
    }
    // load from network
    if (data == null) {
      data = await _loadNetwork(
        key.url,
        chunkEvents: chunkEvents,
        headers: headers,
        timeLimit: timeLimit,
        cancelToken: cancelToken,
        timeRetry: timeRetry,
        retries: retries,
        printError: printError,
      );
      if (data != null) {
        // cache image file
        if (!cacheFile.existsSync()) {
          cacheFile.createSync();
        }
        await File(path.join(_cacheImagesDirectory.path, md5Key)).writeAsBytes(data);
      }
    }

    return data;
  }

  /// Get the image from network.
  static Future<Uint8List?> _loadNetwork(
    String url, {
    StreamController<ImageChunkEvent>? chunkEvents,
    Map<String, String>? headers,
    Duration? timeLimit,
    CancellationToken? cancelToken,
    required Duration timeRetry,
    required int retries,
    bool printError = false,
  }) async {
    try {
      final Uri resolved = Uri.base.resolve(url);
      final HttpClientResponse? response = await _tryGetResponse(
        resolved,
        headers: headers,
        timeLimit: timeLimit,
        cancelToken: cancelToken,
        timeRetry: timeRetry,
        retries: retries,
      );
      if (response == null || response.statusCode != HttpStatus.ok) {
        return null;
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: chunkEvents != null
            ? (int cumulative, int? total) {
                chunkEvents.add(ImageChunkEvent(
                  cumulativeBytesLoaded: cumulative,
                  expectedTotalBytes: total,
                ));
              }
            : null,
      );
      if (bytes.lengthInBytes == 0) {
        return Future<Uint8List>.error(StateError('NetworkImage is an empty file: $resolved'));
      }

      return bytes;
    } on OperationCanceledError catch (_) {
      if (printError) {
        debugPrint('User cancel request $url.');
      }
      return Future<Uint8List>.error(StateError('User cancel request $url.'));
    } catch (e) {
      if (printError) {
        debugPrint(e.toString());
      }
    } finally {
      await chunkEvents?.close();
    }
    return null;
  }

  static Future<HttpClientResponse> _getResponse(
    Uri resolved, {
    Map<String, String>? headers,
    Duration? timeLimit,
  }) async {
    final HttpClientRequest request = await httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final HttpClientResponse response = await request.close();
    if (timeLimit != null) {
      response.timeout(
        timeLimit,
      );
    }
    return response;
  }

  // Http get with cancel, delay try again
  static Future<HttpClientResponse?> _tryGetResponse(
    Uri resolved, {
    Map<String, String>? headers,
    Duration? timeLimit,
    CancellationToken? cancelToken,
    required Duration timeRetry,
    required int retries,
  }) async {
    cancelToken?.throwIfCancellationRequested();
    return await RetryHelper.tryRun<HttpClientResponse>(
      () {
        return CancellationTokenSource.register(
          cancelToken,
          _getResponse(resolved, headers: headers, timeLimit: timeLimit),
        );
      },
      cancelToken: cancelToken,
      timeRetry: timeRetry,
      retries: retries,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ExNetworkImageProvider &&
        url == other.url &&
        scale == other.scale &&
        cacheRawData == other.cacheRawData &&
        timeLimit == other.timeLimit &&
        cancelToken == other.cancelToken &&
        timeRetry == other.timeRetry &&
        cache == other.cache &&
        cacheKey == other.cacheKey &&
        headers == other.headers &&
        retries == other.retries &&
        imageCacheName == other.imageCacheName &&
        cacheMaxAge == other.cacheMaxAge;
  }

  @override
  int get hashCode => hashValues(
        url,
        scale,
        cacheRawData,
        timeLimit,
        cancelToken,
        timeRetry,
        cache,
        cacheKey,
        headers,
        retries,
        imageCacheName,
        cacheMaxAge,
      );

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';

  /// Get network image data from cached
  @override
  Future<Uint8List?> getNetworkImageData({
    StreamController<ImageChunkEvent>? chunkEvents,
  }) async {
    final String uId = cacheKey ?? keyToMd5(url);

    if (cache) {
      return await _loadCache(this, chunkEvents, uId);
    }

    return await _loadNetwork(
      url,
      chunkEvents: chunkEvents,
      headers: headers,
      timeLimit: timeLimit,
      cancelToken: cancelToken,
      timeRetry: timeRetry,
      retries: retries,
      printError: printError,
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

  static HttpClient get httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }
}

class ExNetworkImage extends StatelessWidget {
  const ExNetworkImage(
    this.url, {
    Key? key,
    this.width,
    this.height,
    this.fit,
    this.mode = ExtendedImageMode.none,
    this.initGestureConfigHandler,
    this.constraints,
    this.loadStateChanged = _defaultLoadStateChanged,
    this.borderRadius,
    this.failedImage,
    this.extendedImageGestureKey,
  }) : super(key: key);

  final String url;
  final LoadStateChanged loadStateChanged;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ExtendedImageMode mode;
  final InitGestureConfigHandler? initGestureConfigHandler;
  final BoxConstraints? constraints;
  final BorderRadius? borderRadius;
  final Image? failedImage;
  final Key? extendedImageGestureKey;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }
    if (!url.startsWith('http')) {
      return ExtendedImage.file(
        File(url),
        loadStateChanged: loadStateChanged,
        width: width,
        height: height,
        fit: fit,
        mode: mode,
        initGestureConfigHandler: initGestureConfigHandler,
        constraints: constraints,
        shape: BoxShape.rectangle,
        borderRadius: borderRadius,
        clearMemoryCacheWhenDispose: true,
      );
    }
    return ExtendedImage(
      image: ExtendedResizeImage.resizeIfNeeded(
        provider: ExNetworkImageProvider(url.replaceAll("https", "http"), cache: true),
      ),
      loadStateChanged: loadStateChanged,
      width: width,
      height: height,
      fit: fit,
      mode: mode,
      initGestureConfigHandler: initGestureConfigHandler,
      constraints: constraints,
      shape: BoxShape.rectangle,
      borderRadius: borderRadius,
      clearMemoryCacheWhenDispose: true,
    );
  }
}

Widget? _defaultLoadStateChanged(ExtendedImageState state) {
  switch (state.extendedImageLoadState) {
    case LoadState.loading:
      return const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
      );
    case LoadState.completed:
      return null;
    case LoadState.failed:
      return const Icon(Icons.error);
  }
}
