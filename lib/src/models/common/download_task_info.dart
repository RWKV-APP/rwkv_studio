import 'package:rwkv_downloader/rwkv_downloader.dart';

enum DownloadTaskType { component, app, other }

class DownloadTaskInfo {
  final String id;
  final String name;
  final DownloadTaskType type;
  final String url;
  final String path;
  final TaskUpdate status;

  const DownloadTaskInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.status,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'path': path,
      'status': status.toMap(),
      'type': type.name,
    };
  }

  factory DownloadTaskInfo.fromMap(Map<String, dynamic> map) {
    return DownloadTaskInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      path: map['path'] as String,
      status: TaskUpdate.fromMap(
        map['status'],
      ).copyWith(state: TaskState.stopped),
      type:
          DownloadTaskType.values
              .where((e) => e.name == map['type'])
              .firstOrNull ??
          DownloadTaskType.other,
    );
  }

  DownloadTaskInfo copyWith({
    String? id,
    String? name,
    DownloadTaskType? type,
    String? url,
    String? path,
    TaskUpdate? status,
  }) {
    return DownloadTaskInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      path: path ?? this.path,
      status: status ?? this.status,
    );
  }
}
