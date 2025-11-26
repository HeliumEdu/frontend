// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

const Color primaryColor = Color(0xff428bca);
const Color textColor = Color(0xff333333);
const Color transparentColor = Colors.transparent;
const Color darkBlueColor = Color(0xff282aa9);
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color greenColor = Color(0xff82af6f);
const Color redColor = Color(0xffd15b47);
const Color yellowColor = Color(0xffffb752);
const Color softGrey = Color(0xFFF7F7F7);
const Color greyColor = Colors.grey;

const List<Color> preferredColors = [
  Color(0xffec6f92),
  Color(0xffe74674),
  Color(0xffe21d55),
  Color(0xffb91846),
  Color(0xff901336),
  Color(0xff5e0c23),
  Color(0xffdc7d50),
  Color(0xffd5602a),
  Color(0xffaf4f23),
  Color(0xff7b3718),
  Color(0xff622c13),
  Color(0xff3c1b0c),
  Color(0xffcfa25e),
  Color(0xffc48d3b),
  Color(0xffa17430),
  Color(0xff7e5a26),
  Color(0xff5a411b),
  Color(0xff372810),
  Color(0xff33fabe),
  Color(0xff06f9b0),
  Color(0xff05cc90),
  Color(0xff049f71),
  Color(0xff037251),
  Color(0xff024b35),
  Color(0xff5658d7),
  Color(0xff3033cf),
  Color(0xff282aa9),
  Color(0xff1f2184),
  Color(0xff16175f),
  Color(0xff0d0e38),
  Color(0xffc964b5),
  Color(0xffbd42a4),
  Color(0xff9b3687),
  Color(0xff792a69),
  Color(0xff571e4c),
  Color(0xff3c1534),
  Color(0xffc09bc0),
  Color(0xffae7eae),
  Color(0xff9d629d),
  Color(0xff815181),
  Color(0xff643f64),
  Color(0xff553555),
];

Color parseColor(String hex) {
  String h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  return Color(int.parse('ff$h', radix: 16));
}

String colorToHex(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0');
  return '#${value.substring(2)}';
}
