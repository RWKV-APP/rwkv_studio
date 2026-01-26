import 'package:fluent_ui/fluent_ui.dart';

class BehaviorSetting extends StatelessWidget {
  const BehaviorSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: Text('应用行为'),
      content: Column(
        children: [
          Row(
            children: [
              Text('切换页面后暂停生成'),
              Spacer(),
              ToggleSwitch(checked: true, onChanged: null),
            ],
          ),
          const SizedBox(height: 12),
          Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('记住页面/对话选择的模型'),
              Spacer(),
              ToggleSwitch(checked: false, onChanged: null),
            ],
          ),
          const SizedBox(height: 12),
          Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('不同对话使用不同解码参数'),
              Spacer(),
              ToggleSwitch(checked: false, onChanged: null),
            ],
          ),
        ],
      ),
    );
  }
}
