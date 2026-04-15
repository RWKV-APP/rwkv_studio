import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class AppTableMd extends BlockMd {
  @override
  String get expString =>
      (r"(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?)\ *)(\n\ *(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?))\ *)+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final List<Map<int, String>> value = text
        .split('\n')
        .map<Map<int, String>>(
          (e) => e
              .trim()
              .split('|')
              .where((element) => element.isNotEmpty)
              .toList()
              .asMap(),
        )
        .toList();

    // Check if table has a header and separator row
    bool hasHeader = value.length >= 2;
    List<TextAlign> columnAlignments = [];

    if (hasHeader) {
      // Parse alignment from the separator row (second row)
      var separatorRow = value[1];
      columnAlignments = List.generate(separatorRow.length, (index) {
        String separator = separatorRow[index] ?? "";
        separator = separator.trim();

        // Check for alignment indicators
        bool hasLeftColon = separator.startsWith(':');
        bool hasRightColon = separator.endsWith(':');

        if (hasLeftColon && hasRightColon) {
          return TextAlign.center;
        } else if (hasRightColon) {
          return TextAlign.right;
        } else if (hasLeftColon) {
          return TextAlign.left;
        } else {
          return TextAlign.left; // Default alignment
        }
      });
    }

    int maxCol = 0;
    for (final each in value) {
      if (maxCol < each.keys.length) {
        maxCol = each.keys.length;
      }
    }

    if (maxCol == 0) {
      return Text("", style: config.style);
    }

    // Ensure we have alignment for all columns
    while (columnAlignments.length < maxCol) {
      columnAlignments.add(TextAlign.left);
    }

    var tableBuilder = config.tableBuilder;

    if (tableBuilder != null) {
      var customTable = List<CustomTableRow?>.generate(value.length, (index) {
        var isHeader = index == 0;
        var row = value[index];
        if (row.isEmpty) {
          return null;
        }
        if (index == 1) {
          return null;
        }
        var fields = List<CustomTableField>.generate(maxCol, (index) {
          var field = row[index];
          return CustomTableField(
            data: field ?? "",
            alignment: columnAlignments[index],
          );
        });
        return CustomTableRow(isHeader: isHeader, fields: fields);
      }).nonNulls.toList();
      return tableBuilder(
        context,
        customTable,
        config.style ?? const TextStyle(),
        config,
      );
    }

    final borderColor = context.fluent.inactiveBackgroundColor;
    final rowColor = context.fluent.inactiveBackgroundColor.withAlpha(60);
    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Table(
          textDirection: config.textDirection,
          defaultColumnWidth: CustomTableColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(width: 1, color: borderColor),
          children: value
              .asMap()
              .entries
              .where((entry) {
                // Skip the separator row (second row) from rendering
                if (hasHeader && entry.key == 1) {
                  return false;
                }
                return true;
              })
              .map<TableRow>(
                (entry) => TableRow(
                  decoration: (hasHeader && entry.key == 0)
                      ? BoxDecoration(color: rowColor)
                      : null,
                  children: List.generate(maxCol, (index) {
                    var e = entry.value;
                    String data = e[index] ?? "";
                    if (RegExp(r"^:?--+:?$").hasMatch(data.trim()) ||
                        data.trim().isEmpty) {
                      return const SizedBox();
                    }

                    // Apply alignment based on column alignment
                    Widget content = Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: MdWidget(
                        context,
                        (e[index] ?? "").trim(),
                        false,
                        config: config,
                      ),
                    );

                    // Wrap with alignment widget
                    switch (columnAlignments[index]) {
                      case TextAlign.center:
                        content = Center(child: content);
                        break;
                      case TextAlign.right:
                        content = Align(
                          alignment: Alignment.centerRight,
                          child: content,
                        );
                        break;
                      case TextAlign.left:
                      default:
                        content = Align(
                          alignment: Alignment.centerLeft,
                          child: content,
                        );
                        break;
                    }

                    return content;
                  }),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
