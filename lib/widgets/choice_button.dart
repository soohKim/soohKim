// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:withsum/constants/colors.dart';
import 'package:withsum/utils/list.dart';

class ChoiceButton<T> extends StatefulWidget {
  const ChoiceButton({
    Key? key,
    this.initChoiceIndexs,
    required this.buttonList,
    this.enumStrList = const [],
    required this.onChanged,
    this.spacing = 8,
    this.runSpacing = 8,
    this.useAllButton = false,
    this.useMultiSelection = false,
    this.returnAllValueList = false,
    this.minCount,
  }) : super(key: key);

  /// 초기값 인덱스 리스트
  final List<int>? initChoiceIndexs;

  /// 사용 할 버튼데이터 (indexList)
  final List<T> buttonList;

  /// Enum자료형인 경우 번역할 데이터
  final List<String> enumStrList;

  /// 데이터 변경 시 콜백함수
  final Function(List<int> indexList, List<T> valueList, int index) onChanged;

  /// 위젯간 가로 간격
  final double spacing;

  /// 위젯간 세로 간격
  final double runSpacing;

  /// 전체버튼 사용 여부
  final bool useAllButton;

  /// 다중선택 사용 여부
  final bool useMultiSelection;

  /// 전체선택 시 값 전체반화여부
  final bool returnAllValueList;

  /// 최소 선택 카운트
  final int? minCount;

  @override
  State<ChoiceButton<T>> createState() => _ChoiceButtonState<T>();
}

class _ChoiceButtonState<T> extends State<ChoiceButton<T>> {
  late List<int> checkList;
  late List<String> buttonTitleList;

  @override
  void initState() {
    super.initState();

    buttonTitleList = widget.buttonList
        .mapWithIndex((e, index) => getTitleString(e, index))
        .toList();

    checkList = widget.initChoiceIndexs ?? [];

    if (checkList.length < widget.minCount!.toInt()) {
      if (widget.useAllButton) {
        checkList = List.generate(widget.buttonList.length, (index) => index);
      } else {
        checkList = List.generate(widget.minCount!.toInt(), (index) => index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: [
        if (widget.useAllButton) ...[
          isAllCheck ? buildOnButton(-1, '전체') : buildOffButton(-1, '전체'),
        ],
        ...buttonTitleList
            .mapWithIndex(
              (title, index) => getButtonWidget(title, index),
            )
            .toList(),
      ],
    );
  }

  onChanged(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.returnAllValueList) {
      return widget.onChanged(
          checkList, widget.buttonList.toIndexList(checkList), index);
    } else {
      if (widget.buttonList.length == checkList.length) {
        return widget.onChanged(checkList, [], index);
      } else {
        return widget.onChanged(
            checkList, widget.buttonList.toIndexList(checkList), index);
      }
    }
  }

  String getTitleString<T>(T title, int index) {
    if (title is Enum) {
      if (widget.buttonList.length == widget.enumStrList.length) {
        return widget.enumStrList[index];
      } else {
        return title.name;
      }
    } else {
      return title.toString();
    }
  }

  Widget getButtonWidget(String title, int index) {
    if (widget.useAllButton && isAllCheck) {
      return buildOffButton(index, title);
    }

    return checkList.contains(index)
        ? buildOnButton(index, title)
        : buildOffButton(index, title);
  }

  bool get isAllCheck => widget.buttonList.length == checkList.length;

  InkWell buildOffButton(int index, String title) {
    return InkWell(
      onTap: () {
        if (index == -1) {
          addAllUpdateList(index); //전체버튼클릭
        } else {
          if (widget.useAllButton) {
            if (isAllCheck && widget.useMultiSelection) {
              checkList.clear();
              addUpdateList(index);
            } else if (!widget.useMultiSelection) {
              checkList.clear();
              addUpdateList(index);
            } else {
              addUpdateList(index);
            }
          } else {
            if (widget.useMultiSelection) {
              addUpdateList(index);
            } else {
              checkList.clear();
              addUpdateList(index);
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: MyColors.filterGrey,
        ),
        constraints: BoxConstraints(minHeight: 34, minWidth: 42),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(fontSize: 14, color: MyColors.textGrey)),
          ],
        ),
      ),
    );
  }

  InkWell buildOnButton(int index, String title) {
    return InkWell(
      onTap: () {
        if (checkList.length == widget.minCount ||
            (isAllCheck &&
                widget.minCount != null &&
                widget.useMultiSelection == false)) {
          return;
        }
        if (index == -1) {
          return removeAllUpdateList(index);
        } else {
          return removeUpdateList(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: MyColors.subBlue,
        ),
        constraints: BoxConstraints(minHeight: 34, minWidth: 42),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  removeUpdateList(int index) {
    setState(() {
      checkList.remove(index);
    });
    checkList.sort();
    return onChanged(index);
  }

  removeAllUpdateList(int index) {
    setState(() {
      checkList.clear();
    });
    checkList.sort();
    return onChanged(index);
  }

  addUpdateList(int index) {
    setState(() {
      checkList.add(index);
    });
    checkList.sort();
    return onChanged(index);
  }

  addAllUpdateList(int index) {
    setState(() {
      checkList =
          List.generate(widget.buttonList.length, (index) => index).toList();
    });
    checkList.sort();
    return onChanged(index);
  }
}
