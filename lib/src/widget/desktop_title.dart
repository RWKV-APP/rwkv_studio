import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DesktopTitle extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DesktopTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        WindowManager.instance.startDragging();
      },
      child: Material(
        color: Colors.white60,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(color: Colors.black87)),
              const Spacer(),
              InkWell(
                onTap: () => WindowManager.instance.minimize(),
                child: const Icon(Icons.minimize),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => WindowManager.instance.maximize(),
                child: const Icon(Icons.crop_landscape_sharp),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
