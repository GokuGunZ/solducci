import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Preview page showing different task tile design options
class TaskTileDesignPreview extends StatelessWidget {
  const TaskTileDesignPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample task for preview
    final sampleTask = Task(
      id: '1',
      documentId: 'doc1',
      title: 'Completare il report mensile',
      description: 'Aggiungere grafici e conclusioni finali',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      tShirtSize: TShirtSize.m,
      position: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Task Tile Design - Proposte'),
        backgroundColor: TodoTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('1. Design Attuale (Riferimento)'),
          _buildCurrentDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('2. Material Design 3 - Elevated'),
          _buildMaterial3Design(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('3. Flat Modern - Minimal Shadow'),
          _buildFlatModernDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('4. Glassmorphism - Frosted Glass'),
          _buildGlassmorphismDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('5. Neumorphism - Soft Shadow'),
          _buildNeumorphismDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('6. Gradient Card - Colorful'),
          _buildGradientDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('7. Border Accent - Left Side'),
          _buildBorderAccentDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('8. iOS Style - System Card'),
          _buildIOSStyleDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('9. Dark Modern - High Contrast'),
          _buildDarkModernDesign(sampleTask),
          const SizedBox(height: 32),

          _buildSectionHeader('10. Rounded Minimal - Soft Edges'),
          _buildRoundedMinimalDesign(sampleTask),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: TodoTheme.primaryPurple,
        ),
      ),
    );
  }

  // 1. Current Design (Reference)
  Widget _buildCurrentDesign(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 2. Material Design 3 - Elevated
  Widget _buildMaterial3Design(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      surfaceTintColor: TodoTheme.primaryPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 3. Flat Modern - Minimal Shadow
  Widget _buildFlatModernDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 4. Glassmorphism - Frosted Glass
  Widget _buildGlassmorphismDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: TodoTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _buildTaskContent(task),
          ),
        ),
      ),
    );
  }

  // 5. Neumorphism - Soft Shadow
  Widget _buildNeumorphismDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 6. Gradient Card - Colorful
  Widget _buildGradientDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TodoTheme.primaryPurple.withOpacity(0.05),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TodoTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TodoTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 7. Border Accent - Left Side
  Widget _buildBorderAccentDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(task.priority),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 8. iOS Style - System Card
  Widget _buildIOSStyleDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildTaskContent(task),
      ),
    );
  }

  // 9. Dark Modern - High Contrast
  Widget _buildDarkModernDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TodoTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TodoTheme.primaryPurple.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _buildTaskContent(task, isDark: true),
      ),
    );
  }

  // 10. Rounded Minimal - Soft Edges
  Widget _buildRoundedMinimalDesign(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildTaskContent(task),
      ),
    );
  }

  Widget _buildTaskContent(Task task, {bool isDark = false}) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white70 : Colors.grey[700];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: false,
              onChanged: null,
              activeColor: Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Row(
            children: [
              _buildPropertyChip(
                icon: Icons.flag_outlined,
                label: task.priority?.label ?? '',
                color: task.priority?.color ?? Colors.grey,
              ),
              const SizedBox(width: 8),
              _buildPropertyChip(
                icon: Icons.calendar_today_outlined,
                label: 'Tra 2gg',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildPropertyChip(
                icon: Icons.straighten,
                label: task.tShirtSize?.label ?? '',
                color: TodoTheme.primaryPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority? priority) {
    if (priority == null) return Colors.grey;
    return priority.color;
  }
}
