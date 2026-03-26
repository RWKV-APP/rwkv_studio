import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/batch_infer/batch_infer_page.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/flow/flow_page.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_page.dart';
import 'package:rwkv_studio/src/ui/mcp/mcp_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

part '_download_flyout.dart';
part '_navigation_panel_items.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static final isWindows = !kIsWeb && Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    final dark = context.fluent.brightness == Brightness.dark;
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (p, c) =>
          p.pane != c.pane ||
          p.navBarItems != c.navBarItems ||
          p.showNavBar != c.showNavBar,
      builder: (context, state) {
        return Column(
          children: [
            if (isWindows) const SizedBox(height: 12),
            Expanded(child: _buildContent(context, dark, state)),
            // const BottomBar(),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool dark, AppState state) {
    return NavigationView(
      paneBodyBuilder: (item, child) {
        return KeyedSubtree(
          key: ValueKey<int>(state.pane),
          child: ColoredBox(
            color: dark
                ? Colors.black.withAlpha(180)
                : Colors.white.withAlpha(180),
            child: child ?? const SizedBox(),
          ),
        );
      },
      contentShape: isWindows ? null : const BeveledRectangleBorder(),
      pane: NavigationPane(
        size: const NavigationPaneSize(openWidth: 160, openMinWidth: 120),
        selected: state.pane.clamp(0, state.expandedItems().length),
        customPane: !state.showNavBar ? _HiddenNavPane() : null,
        displayMode: PaneDisplayMode.compact,
        acrylicDisabled: false,
        onItemPressed: (i) {
          final flatten = state.expandedItems();
          // logd('onItemPressed: ${flatten[i].type}');
          if (flatten[i].subitems != null || !flatten[i].type.hasBody) {
            return;
          }
          context.app.setPane(i);
        },
        items: buildNavItems(context, state),
        footerItems: buildNavFooterItems(context, state),
      ),
    );
  }
}

class _HiddenNavPane extends NavigationPaneWidget {
  @override
  Widget build(BuildContext context, NavigationPaneWidgetData data) {
    return data.content;
  }
}
