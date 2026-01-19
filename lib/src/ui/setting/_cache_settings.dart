part of 'setting_page.dart';

class CacheSettingsCard extends StatelessWidget {
  const CacheSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.fluent;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Text('模型下载目录'),
            const SizedBox(width: 12),
            SizedBox(
              width: 300,
              child: TextBox(
                controller: TextEditingController(
                  text: r'C:\Users\Administrator\Downloads',
                ),
                suffix: IconButton(
                  icon: const Icon(WindowsIcons.folder),
                  onPressed: () {
                    //
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('缓存目录'),
            const SizedBox(width: 12),
            SizedBox(
              width: 300,
              child: TextBox(
                controller: TextEditingController(
                  text: r'C:\Users\Administrator\Downloads',
                ),
                suffix: IconButton(
                  icon: const Icon(WindowsIcons.folder),
                  onPressed: () {
                    //
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
