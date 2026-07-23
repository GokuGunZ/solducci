import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class FocusTasksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const FocusTasksWidget({super.key, required this.def});

  @override
  State<FocusTasksWidget> createState() => _FocusTasksWidgetState();
}

class _FocusTasksWidgetState extends State<FocusTasksWidget> {
  bool _isLoading = true;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock tasks for focus today
    if (mounted) {
      setState(() {
        _tasks = [
          Task.create(documentId: '1', title: 'Pagare affitto', priority: TaskPriority.urgent),
          Task.create(documentId: '1', title: 'Fare la spesa', priority: TaskPriority.high),
          Task.create(documentId: '1', title: 'Chiamare idraulico', priority: TaskPriority.medium),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      isLoading: _isLoading,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  'FOCUS OGGI',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return _buildTaskRow(task);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Simulate check
              setState(() {
                _tasks.remove(task);
              });
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.priority != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: task.priority!.color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
