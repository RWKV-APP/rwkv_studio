part of 'app_cubit.dart';

enum NavBarItemType {
  chat(title: '对话'),
  batchInfer(title: '并行'),
  textGeneration(title: '文本生成'),
  modelManage(title: '模型管理'),
  musicGeneration(title: '音乐生成'),
  imageGeneration(title: '图片生成'),
  workFlow(title: '工作流'),
  tools(title: '工具'),
  fineTuning(title: '微调'),
  convert(title: '转换'),

  /// footer
  downloadTask(title: '下载任务', footer: true, hasBody: false),
  settings(title: '设置', footer: true);

  final String title;
  final bool footer;
  final bool hasBody;

  const NavBarItemType({
    required this.title,
    this.footer = false,
    this.hasBody = true,
  });
}

class NavBarItem {
  final NavBarItemType type;
  final List<NavBarItem>? subitems;

  static List<NavBarItem> defaultNavItems() => kIsWeb
      ? defaultNavItemsWeb()
      : [
          NavBarItem(type: NavBarItemType.chat),
          NavBarItem(type: NavBarItemType.textGeneration),
          NavBarItem(type: NavBarItemType.batchInfer),
          NavBarItem(type: NavBarItemType.modelManage),
          NavBarItem(type: NavBarItemType.downloadTask),
          NavBarItem(type: NavBarItemType.settings),
        ];

  static List<NavBarItem> defaultNavItemsWeb() => [
    NavBarItem(type: NavBarItemType.chat),
    NavBarItem(type: NavBarItemType.textGeneration),
    NavBarItem(type: NavBarItemType.batchInfer),
    NavBarItem(type: NavBarItemType.settings),
  ];

  static List<NavBarItem> devNavItems() => [
    NavBarItem(type: NavBarItemType.chat),
    NavBarItem(type: NavBarItemType.textGeneration),
    NavBarItem(type: NavBarItemType.batchInfer),
    NavBarItem(type: NavBarItemType.modelManage),
    NavBarItem(type: NavBarItemType.musicGeneration),
    NavBarItem(type: NavBarItemType.workFlow),
    NavBarItem(
      type: NavBarItemType.tools,
      subitems: [
        NavBarItem(type: NavBarItemType.fineTuning),
        NavBarItem(type: NavBarItemType.convert),
      ],
    ),
    NavBarItem(type: NavBarItemType.downloadTask),
    NavBarItem(type: NavBarItemType.settings),
  ];

  NavBarItem({required this.type, this.subitems});

  factory NavBarItem.fromMap(dynamic map) {
    return NavBarItem(
      type: NavBarItemType.values.firstWhere(
        (item) => item.name == map['type'],
      ),
      subitems: map['subitems']
          ?.map((item) => NavBarItem.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'subitems': subitems?.map((item) => item.toMap()).toList(),
    };
  }
}

class AppState {
  final int pane;
  final String selectedPythonId;
  final String albatrossPath;
  final List<NavBarItem> navBarItems;
  final bool fullScreen;
  final bool showNavBar;
  final RwkvHttpApiService rwkvModelService;
  final List<String> ipAddresses;
  final Map<String, RemoteServiceStatus> remoteServiceStatuses;

  List<NavBarItem> expandedItems() {
    return navBarItems
        .flatten((e) => <NavBarItem>[e, ...(e.subitems ?? [])])
        .toList();
  }

  AppState({
    required this.pane,
    required this.selectedPythonId,
    required this.albatrossPath,
    required this.navBarItems,
    required this.fullScreen,
    required this.showNavBar,
    required this.rwkvModelService,
    required this.ipAddresses,
    required this.remoteServiceStatuses,
  });

  factory AppState.initial() {
    return AppState(
      pane: -1,
      selectedPythonId: '',
      albatrossPath: 'app.py',
      navBarItems: NavBarItem.defaultNavItems(),
      fullScreen: false,
      showNavBar: true,
      rwkvModelService: RwkvHttpApiService(),
      ipAddresses: [],
      remoteServiceStatuses: const {},
    );
  }

  AppState copyWith({
    int? pane,
    String? selectedPythonId,
    String? albatrossPath,
    List<NavBarItem>? navBarItems,
    bool? fullScreen,
    bool? showNavBar,
    RwkvHttpApiService? rwkvModelService,
    List<String>? ipAddresses,
    Map<String, RemoteServiceStatus>? remoteServiceStatuses,
  }) {
    return AppState(
      pane: pane ?? this.pane,
      selectedPythonId: selectedPythonId ?? this.selectedPythonId,
      albatrossPath: albatrossPath ?? this.albatrossPath,
      navBarItems: navBarItems ?? this.navBarItems,
      fullScreen: fullScreen ?? this.fullScreen,
      showNavBar: showNavBar ?? this.showNavBar,
      rwkvModelService: rwkvModelService ?? this.rwkvModelService,
      ipAddresses: ipAddresses ?? this.ipAddresses,
      remoteServiceStatuses:
          remoteServiceStatuses ?? this.remoteServiceStatuses,
    );
  }
}
