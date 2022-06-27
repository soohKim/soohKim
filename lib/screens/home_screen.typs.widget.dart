import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:withsum/constants/colors.dart';
import 'package:withsum/screens/product_info_screen.dart';
import 'package:withsum/utils/string.dart';

class TypesWidget extends StatefulWidget {
  const TypesWidget({Key? key}) : super(key: key);

  @override
  State<TypesWidget> createState() => _TypesWidgetState();
}

class _TypesWidgetState extends State<TypesWidget> {
  List<WiskeyTypeItem> sellers = [
    WiskeyTypeItem(wiskeyName: "싱글몰트"),
    WiskeyTypeItem(wiskeyName: "블랜디드 몰트"),
    WiskeyTypeItem(wiskeyName: "싱글몰트"),
    WiskeyTypeItem(wiskeyName: "블랜디드 몰트"),
  ];
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 8, right: 8),
      title: "위스키 종류가 궁금해요!".titleWidget,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutGrid(
              columnSizes: [1.fr, 1.fr],
              rowGap: 16,
              columnGap: 16,
              rowSizes: List<TrackSize>.filled(
                  ((sellers.length ~/ 2) + (sellers.length % 2)), auto),
              children: [
                for (var i = 0; i < sellers.length; i++) _buildList(sellers[i])
              ]),
        ),
      ],
    );
  }

  Widget _buildList(WiskeyTypeItem item) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProductInfoScreen(productName: item.wiskeyName)),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MyColors.lightGrey,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          item.wiskeyName.sellerItemTitle,
        ],
      ),
    );
  }
}

class WiskeyTypeItem {
  final String wiskeyName;
  String? url;

  WiskeyTypeItem({
    required this.wiskeyName,
    this.url,
  });

  factory WiskeyTypeItem.fromMap(Map<String, dynamic> map) {
    return WiskeyTypeItem(
      wiskeyName: map['wiskeyName'],
      url: map['url'] != null ? map['url'] : null,
    );
  }
}
