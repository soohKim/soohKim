// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:withsum/constants/constant.dart';
import 'package:withsum/utils/string.dart';

import 'home_screen.caculator.widget.dart';
import 'home_screen.sellers.widget.dart';
import 'home_screen.typs.widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // ignore: prefer_const_literals_to_create_immutables
          children: [
            SizedBox(
              height: 41,
            ),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: "위스키 관세 계산기".titleWidget,
            ),
            const Calculator(),
            SizedBox(
              height: 53,
            ),
            const SellersWidget(),
            SizedBox(
              height: 40,
            ),
            const TypesWidget(),
          ],
        ),
      ),
    );
  }
}
