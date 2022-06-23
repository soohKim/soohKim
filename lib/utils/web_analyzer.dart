part of 'flutter_link_preview.dart';

abstract class InfoBase {
  late DateTime _timeout;
}

/// Web Information
class WebInfo extends InfoBase {
  final String title;
  final String? icon;
  final String? description;
  final String? image;
  final String? redirectUrl;
  final String? link;

  WebInfo({
    required this.title,
    this.icon,
    this.description,
    this.image,
    this.redirectUrl,
    this.link,
  });

  @override
  String toString() {
    return "InfoBase($title $image $icon)";
  }
}

class EmptyInfo extends InfoBase {}

/// Image Information
class WebImageInfo extends InfoBase {
  final String? image;

  WebImageInfo({this.image});
}

/// Video Information
class WebVideoInfo extends InfoBase {
  final String? video;
  String? thumnail;

  WebVideoInfo({this.video, this.thumnail});
}

/// Web analyzer
class WebAnalyzer {
  static final Map<String, InfoBase> _map = {};
  static final RegExp _bodyReg =
      RegExp(r"<body[^>]*>([\s\S]*?)<\/body>", caseSensitive: false);
  static final RegExp _htmlReg = RegExp(
      r"(<head[^>]*>([\s\S]*?)<\/head>)|(<script[^>]*>([\s\S]*?)<\/script>)|(<style[^>]*>([\s\S]*?)<\/style>)|(<[^>]+>)|(<link[^>]*>([\s\S]*?)<\/link>)|(<[^>]+>)",
      caseSensitive: false);
  static final RegExp _metaReg = RegExp(
      r"<(meta|link)(.*?)\/?>|<title(.*?)</title>",
      caseSensitive: false,
      dotAll: true);
  static final RegExp _titleReg =
      RegExp("(title|icon|description|image)", caseSensitive: false);
  static final RegExp _lineReg = RegExp(r"[\n\r]|&nbsp;|&gt;");
  static final RegExp _spaceReg = RegExp(r"\s+");

  /// Is it an empty string
  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty;
  }

  /// Get web information
  /// return [InfoBase]
  static InfoBase? getInfoFromCache(String url) {
    final InfoBase? info = _map[url];
    if (info != null && info is WebInfo) {
      if (!info._timeout.isAfter(DateTime.now())) {
        _map.remove(url);
      }
    }
    return info;
  }

  /// Get web information
  /// return [InfoBase]
  static Future<InfoBase?> getInfo(
    String url, {
    Duration cache = const Duration(hours: 24),
    bool multimedia = true,
    bool useMultithread = false,
  }) async {
    InfoBase? info = getInfoFromCache(url);
    if (info != null) return info;

    try {
      if (useMultithread) {
        info = await _getInfoByIsolate(url, multimedia);
      } else {
        info = await _getInfo(url, multimedia);
      }

      if (info != null) {
        info._timeout = DateTime.now().add(cache);
        _map[url] = info;
      }
    } catch (e) {
      // debugPrint("Get web error:$url, Error:$e");
      return null;
    }

    return info;
  }

  static Future<InfoBase?> _getInfo(String url, bool multimedia) async {
    final response = await _requestUrl(url);

    if (response == null) {
      throw ("response empty");
    }

    if (multimedia) {
      final contentType = response.headers["content-type"];
      if (contentType != null) {
        if (contentType.contains("image/")) {
          return WebImageInfo(image: url);
        } //else if (contentType.contains("video/")) {
        // final thumbnailPath = await VideoThumbnail.thumbnailFile(
        //   video: url,
        //   thumbnailPath: (await getTemporaryDirectory()).path,
        //   imageFormat: ImageFormat.WEBP,
        // );
        // return WebVideoInfo(video: url, thumnail: thumbnailPath);
        //}
      }
    }

    return _getWebInfo(response, url, multimedia);
  }

  static Future<InfoBase> _getInfoByIsolate(String url, bool multimedia) async {
    final sender = ReceivePort();
    final Isolate isolate = await Isolate.spawn(_isolate, sender.sendPort);
    final sendPort = await sender.first as SendPort;
    final answer = ReceivePort();

    sendPort.send([answer.sendPort, url, multimedia]);
    final List<String>? res = await answer.first;

    late InfoBase info;
    if (res != null) {
      if (res[0] == "0") {
        info = WebInfo(
          title: res[1],
          description: res[2],
          icon: res[3],
          image: res[4],
          link: url,
        );
      } else if (res[0] == "1") {
        info = WebVideoInfo(video: res[1]);
      } else if (res[0] == "2") {
        info = WebImageInfo(image: res[1]);
      }
    }

    sender.close();
    answer.close();
    isolate.kill(priority: Isolate.immediate);

    return info;
  }

  static void _isolate(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    port.listen((message) async {
      final SendPort sender = message[0];
      final String url = message[1];
      final bool multimedia = message[2];

      final info = await _getInfo(url, multimedia);

      if (info is WebInfo) {
        sender.send(["0", info.title, info.description, info.icon, info.image]);
      } else if (info is WebVideoInfo) {
        sender.send(["1", info.video]);
      } else if (info is WebImageInfo) {
        sender.send(["2", info.image]);
      } else {
        sender.send(null);
      }
      port.close();
    });
  }

  // static final Map<String, String> _cookies = {
  //   "weibo.com":
  //       "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ"
  // };

  static bool _certificateCheck(X509Certificate cert, String host, int port) =>
      true;

  static Future<Response?> _requestUrl(
    String url, {
    int count = 0,
    String? cookie,
    useDesktopAgent = true,
  }) async {
    Response? res;
    final uri = Uri.parse(url);
    final ioClient = HttpClient()..badCertificateCallback = _certificateCheck;
    final client = IOClient(ioClient);
    final request = Request('GET', uri)
      ..followRedirects = false
      ..headers["User-Agent"] = useDesktopAgent
          ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
      ..headers["cache-control"] = "no-cache"
      // ..headers["Cookie"] = cookie ?? _cookies[uri.host]
      ..headers["accept"] = "*/*";
    try {
      ioClient.connectionTimeout = const Duration(seconds: 5);

      final stream = await client.send(request);
      if (stream.statusCode == HttpStatus.movedTemporarily ||
          stream.statusCode == HttpStatus.movedPermanently ||
          stream.statusCode == HttpStatus.temporaryRedirect ||
          stream.statusCode == HttpStatus.seeOther ||
          stream.statusCode == HttpStatus.useProxy) {
        if (stream.isRedirect && count < 6) {
          final location = stream.headers['location'];
          if (location != null) {
            url = location;
            if (location.startsWith("/")) {
              url = uri.origin + location;
            }
          }
          if (stream.headers['set-cookie'] != null) {
            cookie = stream.headers['set-cookie'];
          }
          count++;
          client.close();
          return _requestUrl(url, count: count, cookie: cookie);
        }
      } else if (stream.statusCode == HttpStatus.ok) {
        res = await Response.fromStream(stream);
      }
      client.close();
      if (res == null) debugPrint("Get web info empty($url)");
      return res;
    } catch (e) {
      return null;
    }
  }

  static Future<InfoBase?> _getWebInfo(
    Response response,
    String url,
    bool multimedia,
  ) async {
    if (response.statusCode == HttpStatus.ok) {
      var html;
      try {
        html = utf8.decode(response.bodyBytes);
      } catch (e) {
        try {
          html = await CharsetConverter.decode('cp949', response.bodyBytes);
        } catch (e) {
          html = response.body;
        }
      }

      final headHtml = _getHeadHtml(html);
      final document = parser.parse(headHtml);
      final uri = Uri.parse(url);

      // get image or video
      if (multimedia) {
        final gif = _analyzeGif(document, uri);
        if (gif != null) return gif;

        // final video = _analyzeVideo(document, uri);
        // if (video != null) {
        //   final thumbnailPath =
        //       await VideoThumbnail.thumbnailFile(video: url);
        //   debugPrint("thumbnail file is located: $thumbnailPath");
        //   if (video is WebVideoInfo) {
        //     video.thumnail = thumbnailPath;
        //   }
        //   // final file = File(thumbnailPath);
        //   return video;
        // }
      }

      String title = _analyzeTitle(document);
      var description =
          _analyzeDescription(document, html)?.replaceAll(r"\x0a", " ");
      if (!isNotEmpty(title) && description != null) {
        title = description;
        description = null;
      }

      final info = WebInfo(
        title: title,
        icon: _analyzeIcon(document, uri),
        description: description,
        image: _analyzeImage(document, uri) ?? getBodyImage(html),
        redirectUrl: response.request?.url.toString(),
        link: url,
      );
      return info;
    }
    return null;
  }

  static String _getHeadHtml(String html) {
    html = html.replaceFirst(_bodyReg, "<body></body>");
    final matchs = _metaReg.allMatches(html);
    final StringBuffer head = StringBuffer("<html><head>");

    for (var element in matchs) {
      final str = element.group(0);
      if (str != null) {
        if (str.contains(_titleReg)) head.writeln(str);
      }
    }
    head.writeln("</head></html>");
    return head.toString();
  }

  static InfoBase? _analyzeGif(dom.Document document, Uri uri) {
    if (_getMetaContent(document, "property", "og:image:type") == "image/gif") {
      final gif = _getMetaContent(document, "property", "og:image");
      if (gif != null) return WebImageInfo(image: _handleUrl(uri, gif));
    }
    return null;
  }

  // static InfoBase? _analyzeVideo(dom.Document document, Uri uri) {
  //   final video = _getMetaContent(document, "property", "og:video");
  //   if (video != null) {
  //     return WebVideoInfo(video: _handleUrl(uri, video));
  //   }
  //   return null;
  // }

  static String? _getMetaContent(
    dom.Document document,
    String property,
    String propertyValue,
  ) {
    final meta = document.head?.getElementsByTagName("meta");
    if (meta == null) {
      return null;
    }
    final ele =
        meta.firstWhereOrNull((e) => e.attributes[property] == propertyValue);
    return ele?.attributes["content"]?.trim();
  }

  static String _analyzeTitle(dom.Document document) {
    final title = _getMetaContent(document, "property", "og:title");
    if (title != null) return title;
    final list = document.head?.getElementsByTagName("title");
    if (list != null && list.isNotEmpty) {
      final tagTitle = list.first.text;
      var title = tagTitle.trim();
      // try {
      //   title = cp949.decode(title.codeUnits);
      // } catch (e) {
      //   //
      // }
      return title;
    }
    return "";
  }

  static String? _analyzeDescription(dom.Document document, String html) {
    final desc = _getMetaContent(document, "property", "og:description");
    if (desc != null) return desc;

    final description = _getMetaContent(document, "name", "description") ??
        _getMetaContent(document, "name", "Description");
    if (!isNotEmpty(description)) {
      // final DateTime start = DateTime.now();
      String body = html.replaceAll(_htmlReg, "");
      body = body.trim().replaceAll(_lineReg, " ").replaceAll(_spaceReg, " ");
      if (body.length > 300) {
        body = body.substring(0, 300);
      }
      return body;
    }
    return description;
  }

  static String? _analyzeIcon(dom.Document document, Uri uri) {
    final meta = document.head?.getElementsByTagName("link");
    if (meta == null) {
      return null;
    }
    String icon = "";
    // get icon first
    var metaIcon = meta.firstWhereOrNull((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
      if (rel == "icon") {
        icon = e.attributes["href"] ?? "";
        if (icon.isNotEmpty && !icon.toLowerCase().contains(".svg")) {
          return true;
        }
      }
      return false;
    });

    metaIcon ??= meta.firstWhereOrNull((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
      if (rel == "shortcut icon") {
        var _icon = e.attributes["href"];
        if (_icon != null) {
          icon = _icon;
        }
        if (!icon.toLowerCase().contains(".svg")) {
          return true;
        }
      }
      return false;
    });

    if (metaIcon != null) {
      var href = metaIcon.attributes["href"];
      if (href != null) {
        icon = href;
      }
    } else {
      return "${uri.origin}/favicon.ico";
    }

    return _handleUrl(uri, icon);
  }

  static String? _analyzeImage(dom.Document document, Uri uri) {
    final image = _getMetaContent(document, "property", "og:image");
    if (image != null) {
      return _handleUrl(uri, image);
    }
    return null;
  }

  static String? getBodyImage(String html) {
    String? imageLink;
    try {
      dom.Document document = parser.parse(html);
      dom.Element? link = document.querySelector('img');

      imageLink = link != null ? link.attributes['src'] : null;
      debugPrint(imageLink);
      return imageLink;
    } catch (e) {
      return null;
    }
  }

  static String _handleUrl(Uri uri, String source) {
    if (isNotEmpty(source) && !source.startsWith("http")) {
      if (source.startsWith("//")) {
        source = "${uri.scheme}:$source";
      } else {
        if (source.startsWith("/")) {
          source = "${uri.origin}$source";
        } else {
          source = "${uri.origin}/$source";
        }
      }
    }
    return source;
  }
}
