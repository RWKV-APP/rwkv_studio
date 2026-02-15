import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/ui/common/import_model_dialog.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ImportModelDropArea extends StatelessWidget {
  final Widget child;

  static bool _importing = false;

  const ImportModelDropArea({super.key, required this.child});

  void onDragDone(BuildContext context, DropDoneDetails details) async {
    if (_importing) {
      return;
    }
    final acceptedExtensions = [
      '.gguf',
      '.ggml',
      '.bin',
      '.prefab',
      '.st',
      '.pth',
      '.zip',
      '.rmpack',
    ];
    final files = details.files
        .map((e) {
          final ext = e.path.split('.').last.toLowerCase();
          if (acceptedExtensions.contains('.$ext')) {
            return e.path;
          }
          return null;
        })
        .nonNulls
        .toSet();
    if (files.isEmpty) {
      context.toast('不支持的文件类型');
      return;
    }

    _importing = true;
    final model = await ImportModelDialog.show(context, files.first);
    _importing = false;

    if (model == null || !context.mounted) {
      return;
    }
    context.modelManage
        .onImportModel(model)
        .withToast(context, success: '导入成功');
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: true,
      onDragDone: (details) {
        onDragDone(context, details);
      },
      child: child,
    );
  }
}
