// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'package:withsum/constants/colors.dart';
import 'package:withsum/constants/enums.dart';
import 'package:withsum/models/whiskey_info_model.dart';
import 'package:withsum/utils/num.dart';
import 'package:withsum/utils/string.dart';
import '../widgets/choice_button.dart';

class ProductInfoScreen extends StatefulWidget {
  final String productName;

  const ProductInfoScreen({Key? key, required this.productName})
      : super(key: key);

  @override
  State<ProductInfoScreen> createState() => _ProductInfoScreenState();
}

class _ProductInfoScreenState extends State<ProductInfoScreen> {
  late ValueNotifier<PriceCategory> _filterNotifier;
  List<whiskeyInfo> _listData = [
    whiskeyInfo(name: "맥켈란 12y sherry", price: 120000),
    whiskeyInfo(name: "맥켈란 12y double", price: 400000),
    whiskeyInfo(name: "발베니 12y", price: 250000),
    whiskeyInfo(name: "글렌드록낙 12y", price: 150000),
    whiskeyInfo(name: "발렌타인 18y", price: 90000),
  ];

  @override
  void initState() {
    super.initState();
    _filterNotifier = ValueNotifier<PriceCategory>(PriceCategory.zeroToTen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
      ),
      body: _bodyDrawer(),
    );
  }

  Widget _bodyDrawer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
        ),
        Center(
          child: Container(
              alignment: Alignment.center,
              width: 326,
              height: 288,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: MyColors.lightGrey,
              )),
        ),
        _drawFilter(),
        _drawList(),
      ],
    );
  }

  Widget _drawFilter() {
    return Column(
      children: [
        16.hBox,
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChoiceButton<PriceCategory>(
              minCount: 1,
              useAllButton: false,
              useMultiSelection: false,
              initChoiceIndexs: [0],
              onChanged: (indexList, valueList, index) {
                _filterNotifier.value = valueList[0];
              },
              buttonList: PriceCategory.values,
              enumStrList: PriceCategory.values.map((e) => e.title).toList(),
            )),
        18.hBox
      ],
    );
  }

  Widget _drawList() {
    return ValueListenableBuilder<PriceCategory>(
        valueListenable: _filterNotifier,
        builder: (ctx, data, widget) {
          List<whiskeyInfo> _resultList = _makeListData(data);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                "${data.title}대 추천!".titleWidget,
                18.hBox,
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultList.length,
                  itemBuilder: (context, index) {
                    return _whiskeyItemTile(_resultList[index]);
                  },
                ),
              ]);
        });
  }

  Widget _whiskeyItemTile(whiskeyInfo info) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                color: MyColors.lightGrey,
                borderRadius: BorderRadius.circular(8)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info.name.listItemTitle,
              16.hBox,
              "알콜 정보 ${info.alcholInfo ?? ""}".listsubItemTitle,
              "한줄평 ${info.desc ?? ""}".listsubItemTitle,
              "위스키 베이스 점수 ${info.baseRating ?? ""}".listsubItemTitle,
            ],
          ),
        ],
      ),
    );
  }

  List<whiskeyInfo> _makeListData(PriceCategory priceCategory) {
    int min;
    int max;

    List<whiskeyInfo> _resultList = [];

    switch (priceCategory) {
      case PriceCategory.zeroToTen:
        min = 0;
        max = 100000;
        break;
      case PriceCategory.tenToTwenty:
        min = 100000;
        max = 200000;
        break;
      case PriceCategory.twentyToThirty:
        min = 200000;
        max = 300000;
        break;
      case PriceCategory.moreThirty:
        min = 400000;
        max = 0;
        break;
    }
    _resultList = _listData.where((element) {
      if (PriceCategory.moreThirty == priceCategory && element.price >= min) {
        return true;
      } else if (element.price >= min && element.price <= max) {
        return true;
      }
      return false;
    }).toList();

    return _resultList;
  }
}
