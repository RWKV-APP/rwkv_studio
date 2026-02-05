import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';

const nodeHeaderHeight = 18.0;
const nodeSocketSize = 16.0;
const nodeSocketSpacing = 8.0;
const nodeCardCornerRadius = 5.0;
const nodeConstControlsHeight = 40.0;

const nodeCardHeaderPadding = EdgeInsets.symmetric(horizontal: 12);

const nodeCardHeaderDecoration = BoxDecoration(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(nodeCardCornerRadius),
    topRight: Radius.circular(nodeCardCornerRadius),
  ),
  color: Colors.green,
);

const nodeCardHeaderTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 12,
  fontWeight: FontWeight.w500,
);

final nodeCardBodyDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(nodeCardCornerRadius),
  color: Colors.grey.shade800,
);

final dataType2color = {
  NodeDataType.int: Colors.red.shade800,
  NodeDataType.double: Colors.blueGrey.shade700,
  NodeDataType.float: Colors.blue.shade800,
  NodeDataType.string: Colors.green.shade800,
  NodeDataType.bool: Colors.yellow.shade800,
  NodeDataType.list: Colors.purple.shade800,
  NodeDataType.map: Colors.orange.shade800,
  NodeDataType.any: Colors.white,
  NodeDataType.void_: Colors.grey.shade600,
};
