import 'package:hive_flutter/hive_flutter.dart';

class RecentMarkdownFile {
  final String path;
  final String name;
  final DateTime lastOpened;

  RecentMarkdownFile({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  factory RecentMarkdownFile.fromMap(Map<dynamic, dynamic> map) {
    return RecentMarkdownFile(
      path: map['path'] as String,
      name: map['name'] as String,
      lastOpened: DateTime.parse(map['lastOpened'] as String),
    );
  }
}

class RecentMarkdownService {
  static const String _boxName = 'recent_markdowns';
  static final RecentMarkdownService _instance = RecentMarkdownService._internal();

  factory RecentMarkdownService() {
    return _instance;
  }

  RecentMarkdownService._internal();

  Box<dynamic>? _box;

  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
  }

  Future<List<RecentMarkdownFile>> getRecentFiles() async {
    await init();
    if (_box == null) return [];
    
    final rawList = _box!.get('files', defaultValue: <dynamic>[]);
    if (rawList is List) {
      final list = rawList.map((e) => RecentMarkdownFile.fromMap(Map<dynamic, dynamic>.from(e))).toList();
      list.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      return list;
    }
    return [];
  }

  Future<void> addFile(String path, String name) async {
    await init();
    final files = await getRecentFiles();
    
    // Remove if already exists to update its position
    files.removeWhere((file) => file.path == path);
    
    // Add to the top
    files.insert(0, RecentMarkdownFile(
      path: path,
      name: name,
      lastOpened: DateTime.now(),
    ));

    // Keep only last 5
    if (files.length > 5) {
      files.removeRange(5, files.length);
    }

    await _box!.put('files', files.map((f) => f.toMap()).toList());
  }
}
