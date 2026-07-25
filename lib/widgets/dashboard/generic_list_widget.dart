import 'package:flutter/material.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/data_source_switcher_header.dart';

class GenericListWidget<T> extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onExpand;
  final String currentSource;
  final Color color;
  final IconData icon;
  final VoidCallback onPreviousSource;
  final VoidCallback onNextSource;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String emptyMessage;

  const GenericListWidget({
    super.key,
    this.isLoading = false,
    this.onExpand,
    required this.currentSource,
    required this.color,
    required this.icon,
    required this.onPreviousSource,
    required this.onNextSource,
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      isLoading: isLoading,
      onExpand: onExpand,
      child: Stack(
        children: [
          // Background Gradient (optional, but looks good for generic lists)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DataSourceSwitcherHeader(
                  title: currentSource,
                  color: color,
                  icon: icon,
                  onPrevious: onPreviousSource,
                  onNext: onNextSource,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            emptyMessage,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, index) => itemBuilder(context, items[index], index),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
