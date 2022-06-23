import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/enums.dart';
import '../models/calculator_model.dart';
import '../utils/formatters.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  late _CaculatorNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = _CaculatorNotifier(type: WhereBuy.none);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: MyColors.lightGrey,
          borderRadius: BorderRadius.all(Radius.circular(8))),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          AnimatedBuilder(
              animation: _notifier,
              builder: (ctx, child) => _notifier.getWidget()),
        ],
      ),
    );
  }
}

class _CaculatorNotifier extends CalculatorModel with ChangeNotifier {
  _CaculatorNotifier({required WhereBuy type}) : super(type: type);

  var changeController = StreamController<CalculatorModel>();
  Stream<CalculatorModel> get onChanged => changeController.stream;

  void changeWhereBuy(WhereBuy type) {
    this.type = type;
    //changeController.add(this);
    notify();
  }

  void notify() {
    notifyListeners();
  }

  Widget getWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalculatorItem(
            title: "구매처",
            widget: DropdownButton<WhereBuy>(
              value: type,
              items: WhereBuy.values
                  .map((e) => DropdownMenuItem(
                        child: Text(e.title),
                        value: e,
                      ))
                  .toList(),
              onChanged: (value) {
                changeWhereBuy(value!);
              },
            )),
        type == WhereBuy.none
            ? Container()
            : Column(
                children: [
                  CalculatorItem(
                      title: "배송비(usd)",
                      widget: TextFormField(
                        decoration: const InputDecoration(suffixText: "\$"),
                        inputFormatters: [
                          DecimalTextInputFormatter(decimalRange: 2)
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          deliveryFee = int.tryParse(value);
                          notify();
                        },
                      )),
                  CalculatorItem(
                      title: "수량",
                      widget: TextFormField(
                        decoration: const InputDecoration(suffixText: "개"),
                        onChanged: (value) {
                          amount = int.tryParse(value);
                          notify();
                        },
                      )),
                  CalculatorItem(
                      title: "물품가(usd)",
                      widget: TextFormField(
                        decoration: const InputDecoration(suffixText: "\$"),
                        onChanged: (value) {
                          price = int.tryParse(value);
                          notify();
                        },
                      )),
                ],
              ),
        _infoWidget(),
        _resultWidget(),
      ],
    );
  }

  Widget _infoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // ignore: prefer_const_literals_to_create_immutables
      children: [
        const SizedBox(
          height: 10,
        ),
        const Text("해당 계산기는 위스키 관세만을 계산합니다."),
        const Text(
            "윗썸의 계산기는 참고용으로 정확한 금액을 알고싶으신 경우\n관련 자료를 구비하시어 통관지 세관에 문의하여 주시기 바랍니다."),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _resultWidget() {
    if (deliveryFee != null && amount != null && price != null) {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.all(8),
        child: Wrap(
          // ignore: prefer_const_literals_to_create_immutables
          children: [
            CalculatorItem(
                title: "총 금액(krw)",
                widget: Text(
                  "100,000원",
                  textAlign: TextAlign.right,
                )),
            CalculatorItem(
                title: "기준환율",
                isGrey: true,
                widget: Text("1\$ = 1205",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey))),
            CalculatorItem(
                title: "물품가",
                isGrey: true,
                widget: Text("000,000원",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey))),
            CalculatorItem(
                title: "과세금액",
                isGrey: true,
                widget: Text("000,000원",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey))),
            CalculatorItem(
                title: "기준용량",
                isGrey: true,
                widget: Text("1 bottle = 750ml",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }
    return Container();
  }
}

class CalculatorItem extends StatefulWidget {
  final String title;
  final dynamic widget;
  final bool? isGrey;

  const CalculatorItem(
      {Key? key,
      required this.title,
      required this.widget,
      this.isGrey = false})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return CalculatorItemState();
  }
}

class CalculatorItemState extends State<CalculatorItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.title,
                style: TextStyle(
                    color: widget.isGrey! ? Colors.grey : Colors.black)),
            flex: 4,
          ),
          Expanded(
            flex: 6,
            child: widget.widget,
          ),
        ],
      ),
    );
  }
}
