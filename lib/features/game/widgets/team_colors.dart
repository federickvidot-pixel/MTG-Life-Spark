import 'package:flutter/material.dart';

const _teamColors = <int, Color>{
  1: Color(0xFF4FC3F7),
  2: Color(0xFFF48FB1),
  3: Color(0xFFA5D6A7),
  4: Color(0xFFFFCC80),
};

Color teamColor(int teamIndex) => _teamColors[teamIndex] ?? Colors.transparent;
