import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class DecodeParamPresetButton extends StatelessWidget {
  final menuController = FlyoutController();
  final ValueChanged<String> onChange;
  final String currentId;

  DecodeParamPresetButton({
    super.key,
    required this.onChange,
    required this.currentId,
  });

  void onAddTap() async {
    menuController.close();
    await Future.delayed(const Duration(milliseconds: 100));
    menuController.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.topCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        return FlyoutContent(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('预设名称'),
              const SizedBox(height: 12.0),
              TextBox(
                maxLines: 1,
                maxLength: 20,
                placeholder: '名称需唯一, 回车保存',
                onSubmitted: (v) {
                  if (context.rwkvState.decodeParams.containsKey(v.trim())) {
                    context.toast('名称已存在');
                  } else {
                    context.rwkv.setOrPutDecodeParam(
                      v.trim(),
                      DecodeParam.initial(),
                    );
                    onChange(v.trim());
                    menuController.close();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showPresetMenu(BuildContext context) {
    final presets = context.rwkvState.decodeParams;

    menuController.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.topCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        return MenuFlyout(
          items: [
            for (final entry in presets.entries)
              MenuFlyoutItem(
                leading: currentId == entry.key
                    ? const Icon(FluentIcons.check_mark)
                    : null,
                text: Text(entry.key),
                trailing: (presets.length <= 1 || entry.key == 'default')
                    ? null
                    : IconButton(
                        icon: const Icon(FluentIcons.delete),
                        onPressed: () {
                          context.rwkv.deleteDecodeParam(entry.key);
                          if (currentId == entry.key) {
                            onChange(presets.keys.first);
                          }
                          menuController.close();
                        },
                      ),
                onPressed: () {
                  onChange(entry.key);
                },
              ),
            const MenuFlyoutSeparator(),
            MenuFlyoutItem(
              text: const Text('新增预设'),
              onPressed: () async {
                onAddTap();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: menuController,
      child: Button(
        child: Text(currentId.isEmpty ? '默认' : currentId),
        onPressed: () => showPresetMenu(context),
      ),
    );
  }
}
