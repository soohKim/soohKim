import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:withsum/utils/flutter_link_preview.dart';
import 'package:withsum/utils/string.dart';
import 'package:withsum/utils/num.dart';

class SellersWidget extends StatefulWidget {
  const SellersWidget({Key? key}) : super(key: key);

  @override
  State<SellersWidget> createState() => _SellersWidgetState();
}

class _SellersWidgetState extends State<SellersWidget> {
  List<SellerItem> sellers = [
    SellerItem(
        sellerName: "Master of malt", url: "https://www.masterofmalt.com"),
    SellerItem(
        sellerName: "Whisky base(us)", url: "https://shop.whiskybase.com/us"),
    SellerItem(sellerName: "SMWS", url: "https://smws.com"),
    SellerItem(
        sellerName: "the whisky barrel",
        url: "https://www.thewhiskybarrel.com"),
    SellerItem(
        sellerName: "whiskey exclusive(eu)",
        url: "https://whiskyexclusive.eu/?v=796834e7a283"),
    SellerItem(
        sellerName: "the whisky exchange",
        url: "https://thewhiskyexchange.com"),
    SellerItem(
        sellerName: "the whisky exchange", url: "https://thereverseland.com"),
  ];
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 8, right: 8),
      title: "위스키 직구는 어디서?".titleWidget,
      children: [
        LayoutGrid(
            columnSizes: [1.fr, 1.fr],
            rowSizes: List<TrackSize>.filled(
                ((sellers.length ~/ 2) + (sellers.length % 2)), auto),
            children: [
              for (var i = 0; i < sellers.length; i++) _buildList(sellers[i], i)
            ]),

        // GridView.builder(
        //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //       crossAxisCount: 2,
        //       crossAxisSpacing: 16,
        //       mainAxisSpacing: 4,
        //       childAspectRatio: 0.8),
        //   padding: EdgeInsets.all(8),
        //   shrinkWrap: true,
        //   physics: ClampingScrollPhysics(),
        //   itemCount: sellers.length,
        //   itemBuilder: (context, index) {
        //     return _buildList(sellers[index], index);
        //   },
        // ),
      ],
    );
  }

  Widget _buildList(SellerItem item, int index) {
    return InkWell(
      onTap: () {
        if (item.url.isNotNullEmpty)
          launchUrl(
            Uri.parse(item.url!),
          );
      },
      child: _link(item),
    );
  }

  Widget _link(SellerItem item) => FutureBuilder<Widget>(
        builder: (_, widget) => widget.data ?? const SizedBox.shrink(),
        future: _buildLink(item),
      );

  Future<Widget> _buildLink(SellerItem item) async {
    var webInfo = await WebAnalyzer.getInfo(
      item.url!,
      cache: const Duration(hours: 24),
      useMultithread: false,
      multimedia: false,
    );
    if (webInfo == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: MediaQuery.of(context).size.width * 0.65,
          child: FlutterLinkPreview(
            webInfo: webInfo,
            content: "",
            useMultithread: false,
            showMultimedia: false,
          ),
        ),
        8.hBox,
        item.sellerName.listItemTitle,
      ],
    );
  }
}

class SellerItem {
  final String sellerName;
  String? url;
  String? preview;

  SellerItem({required this.sellerName, this.url, this.preview});

  factory SellerItem.fromMap(Map<String, dynamic> map) {
    return SellerItem(
      sellerName: map['sellerName'],
      url: map['url'] != null ? map['url'] : null,
    );
  }
}
