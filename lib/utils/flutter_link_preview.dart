import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'dart:isolate';
import 'package:charset_converter/charset_converter.dart';
import 'package:collection/collection.dart';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'network_image.dart';

part 'web_analyzer.dart';

// ignore: must_be_immutable
class FlutterLinkPreview extends StatelessWidget {
  FlutterLinkPreview({
    Key? key,
    required this.content,
    this.cache = const Duration(hours: 24),
    this.showMultimedia = false,
    this.useMultithread = false,
    this.webInfo,
  }) : super(key: key) {
    _getInfoStream();
  }

  /// Web address, HTTP and HTTPS support
  final String content;

  /// Cache result time, default cache 1 hour
  final Duration cache;

  /// Show image or video
  final bool showMultimedia;

  /// Whether to use multi-threaded analysis of web pages
  final bool useMultithread;

  final InfoBase? webInfo;

  final BehaviorSubject<InfoBase?> _stream = BehaviorSubject();

  Future<InfoBase?> _getInfo() async {
    if (content.isEmpty) {
      return null;
    }

    var exp = r'(?:(https?:\/\/|www\.))?([\w]+\.[\Sa-zA-Z0-9=]+)';
    var reg = RegExp(exp);
    if (!reg.hasMatch(content)) {
      // logger.d("Links don't start with http or https from : $content");
      return null;
    }

    var matches = reg.allMatches(content).toList();
    if (matches.isEmpty) {
      return null;
    }

    var link = content.substring(matches[0].start, matches[0].end);
    if (!link.startsWith("http")) {
      link = "http://" + link;
    }

    var info = WebAnalyzer.getInfoFromCache(link);
    if (info != null) {
      return info;
    }

    return await WebAnalyzer.getInfo(
      link,
      cache: cache,
      multimedia: showMultimedia,
      useMultithread: useMultithread,
    );
  }

  static String linkNormalize(String raw) {
    var exp = r'(?:(https?:\/\/|www\.))?([\w]+\.[\Sa-zA-Z0-9=]+)';
    var reg = RegExp(exp);
    if (!reg.hasMatch(raw)) {
      // logger.d("Links don't start with http or https from : $content");
      return "";
    }

    var matches = reg.allMatches(raw).toList();
    if (matches.isEmpty) {
      return "";
    }

    var link = raw.substring(matches[0].start, matches[0].end);
    if (!link.startsWith("http")) {
      link = "http://" + link;
    }
    return link;
  }

  void _getInfoStream() async {
    if (content.isEmpty) {
      return null;
    }

    var link = linkNormalize(content);

    var webInfoCache = WebAnalyzer.getInfoFromCache(link);
    _stream.add(webInfoCache);

    var webInfo = await WebAnalyzer.getInfo(
      link,
      cache: cache,
      multimedia: showMultimedia,
      useMultithread: useMultithread,
    );

    _stream.add(webInfo);
  }

  void _launchURL(url) async {
    var isMatchecd = RegExp(r'^http(s)?').hasMatch(url);
    var fixedLink = url;
    if (!isMatchecd) {
      fixedLink = "http://" + fixedLink;
    }
    //DuChat.current?.launch?.call(url);
  }

  Widget? defaultLoadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return Container();
      case LoadState.completed:
        return null;
      case LoadState.failed:
        return const Icon(Icons.error);
      // return Container();
      // return Image.asset('assets/images/png/failed_load.jpg');
      default:
        return null;
    }
    // return null;
  }

  Widget _buildWebInfo(WebInfo webInfo) {
    if (!WebAnalyzer.isNotEmpty(webInfo.title)) {
      return Container(
        height: 200,
        color: Colors.cyan,
      );
    }
    // var width = constraints.maxWidth;
    // var height = 9 * width / 16;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      // height: 200,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          color: Colors.white,
          width: double.infinity,
          child: InkWell(
            onTap: () => _launchURL(webInfo.link),
            child: Column(
              children: [
                if (webInfo.image != null)
                  Container(
                    height: 200,
                    constraints: const BoxConstraints(maxHeight: 116),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return ExNetworkImage(
                        webInfo.image ?? "",
                        fit: BoxFit.contain,
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        loadStateChanged: defaultLoadStateChanged,
                      );
                    }),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleContainer(webInfo.title),
                      if (WebAnalyzer.isNotEmpty(webInfo.description))
                        _buildBodyContainer(webInfo.description!),
                      const SizedBox(height: 5),
                      Text(
                        webInfo.link ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromRGBO(183, 183, 183, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (webInfo != null) {
      return _build(webInfo);
    }
    return StreamBuilder(
      stream: _stream,
      builder: (BuildContext context, AsyncSnapshot<InfoBase?> snapShot) {
        final InfoBase? info = snapShot.data;
        return _build(info);
      },
    );
  }

  Widget _build(InfoBase? info) {
    if (info is WebInfo) {
      return _buildWebInfo(info);
    } else if (info is WebImageInfo) {
      return InkWell(
        onTap: () => _launchURL(info.image),
        child: ExNetworkImage(
          info.image ?? "",
          fit: BoxFit.cover,
          loadStateChanged: defaultLoadStateChanged,
        ),
      );
    } else if (info is WebVideoInfo) {
      return InkWell(
        onTap: () => _launchURL(info.video),
        child: Stack(
          children: const [
            //Image.file(File(info.thumnail), fit: BoxFit.cover),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),
            )
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget build2(BuildContext context) {
    return FutureBuilder(
      future: _getInfo(),
      builder: (BuildContext context, AsyncSnapshot snapShot) {
        if (snapShot.data == null) {
          return const SizedBox();
        }

        final InfoBase? info = snapShot.data;

        if (info == null || info is EmptyInfo) {
          return const SizedBox();
        } else if (info is WebImageInfo) {
          return InkWell(
            onTap: () => _launchURL(info.image),
            child: ExNetworkImage(
              info.image ?? "",
              fit: BoxFit.cover,
              loadStateChanged: defaultLoadStateChanged,
            ),
          );
        } else if (info is WebVideoInfo) {
          return InkWell(
            onTap: () => _launchURL(info.video),
            child: Stack(
              children: const [
                //Image.file(File(info.thumnail), fit: BoxFit.cover),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 50),
                  ),
                )
              ],
            ),
          );
        } else if (info is WebInfo) {
          return _buildWebInfo(info);
        }
        return Container();
      },
    );
  }

  Widget _buildTitleContainer(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildBodyContainer(String description) {
    return Text(
      description,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
