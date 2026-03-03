import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/batch_infer/batch_infer_page.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/import_model_area.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_page.dart';
import 'package:rwkv_studio/src/ui/main/_bottom_bar.dart';
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
        buildWhen: (p, c) =>
            p.pane != c.pane ||
            p.navBarItems != c.navBarItems ||
            p.showNavBar != c.showNavBar,
        builder: (context, state) {
          return _buildContent(context, dark, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool dark, AppState state) {
    return NavigationView(
      paneBodyBuilder: (item, child) {
        return Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: dark
                    ? Colors.black.withAlpha(100)
                    : Colors.white.withAlpha(100),
                child: child ?? const SizedBox(),
              ),
            ),
            const BottomBar(),
          ],
        );
      },
      pane: NavigationPane(
        // header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 160, openMinWidth: 120),
        selected: state.pane,
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
