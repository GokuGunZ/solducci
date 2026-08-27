import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/recent_markdown_service.dart';
import 'package:intl/intl.dart';

class RecentMarkdownWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const RecentMarkdownWidget({super.key, required this.def});

  @override
  State<RecentMarkdownWidget> createState() => _RecentMarkdownWidgetState();
}

class _RecentMarkdownWidgetState extends State<RecentMarkdownWidget> {
  List<RecentMarkdownFile> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final files = await RecentMarkdownService().getRecentFiles();
    if (mounted) {
      setState(() {
        _recentFiles = files;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: Color(0xFF6366F1), size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MD Recenti',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() { _isLoading = true; });
                    _loadRecentFiles();
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                : _recentFiles.isEmpty
                  ? const Center(child: Text('Nessun file recente', style: TextStyle(color: Colors.white54, fontSize: 12)))
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _recentFiles.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 8),
                      itemBuilder: (context, index) {
                        final file = _recentFiles[index];
                        return InkWell(
                          onTap: () {
                            context.push('/markdown-viewer', extra: file.path);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.feed, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name, 
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatDate(file.lastOpened),
                                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
