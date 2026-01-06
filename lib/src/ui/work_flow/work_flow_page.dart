import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';

class WorkFlowPage extends StatelessWidget {
  const WorkFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey, child: _Editor());
  }
}

class _Editor extends StatelessWidget {
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: BlocProvider<NodeEditorCubit>(
        create: (context) => NodeEditorCubit(),
        child: NodeEditor(),
      ),
    );
  }
}
