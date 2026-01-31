import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/import_model_area.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/ui/common/theme_preview_page.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/ui/work_flow/work_flow_page.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

part '_download_flyout.dart';
part 'navigation_panel_items.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.fluent.brightness == Brightness.dark;
    return ImportModelDropArea(
      child: BlocBuilder<AppCubit, AppState>(
        buildWhen: (p, c) => p.pane != c.pane,
        builder: (context, state) {
          return _buildContent(context, dark, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool dark, AppState state) {
    return NavigationView(
      appBar: NavigationAppBar(
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('RWKV Studio', style: context.typography.bodyStrong),
        ),
        actions: SizedBox(
          height: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(FluentIcons.print),
                onPressed: () {
                  LogcatPanel.attachToRootOverlay(context);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      paneBodyBuilder: (item, child) {
        return ColoredBox(
          color: dark
              ? Colors.black.withAlpha(100)
              : Colors.white.withAlpha(100),
          child: child ?? const SizedBox(),
        );
      },
      pane: NavigationPane(
        // header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 220, openMinWidth: 120),
        selected: state.pane,
        displayMode: PaneDisplayMode.compact,
        onItemPressed: (i) {
          if ({12, 7, 1}.contains(i)) {
            return;
          }
          context.app.setPane(i);
        },
        items: buildNavItems(context),
        footerItems: buildNavFooterItems(context),
      ),
    );
  }
}
