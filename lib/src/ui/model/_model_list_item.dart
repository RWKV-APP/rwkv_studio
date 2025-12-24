import 'package:flutter/material.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/widget/app_button.dart';

class ModelListItem extends StatelessWidget {
  final ModelInfo model;
  final VoidCallback? onTap;

  const ModelListItem({super.key, required this.model, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapGestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Text(model.name, style: AppTextTheme.bodyBold),
            const Spacer(),
            if (model.localPath.isNotEmpty)
              Icon(
                Icons.check_circle_outline,
                color: context.theme.colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );

    return ListTile(
      onTap: onTap,
      title: Text(model.name, style: AppTextTheme.bodyBold),
      // subtitle: Row(
      //   children: [
      //     for (final tag in model.tags)
      //       Container(
      //         margin: const EdgeInsets.only(right: 4, top: 4),
      //         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      //         decoration: BoxDecoration(
      //           borderRadius: BorderRadius.circular(4),
      //           color: context.theme.colorScheme.secondaryContainer,
      //         ),
      //         child: Text(tag.toUpperCase(), style: AppTextTheme.caption),
      //       ),
      //   ],
      // ),
      trailing: model.localPath.isEmpty
          ? null
          : Icon(
              Icons.check_circle_outline,
              color: context.theme.colorScheme.onSurface,
            ),
    );
  }
}
