import 'package:flutter/material.dart';

class SwipeableBentoStack<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) builder;
  final bool showIndicators;

  const SwipeableBentoStack({
    super.key,
    required this.items,
    required this.builder,
    this.showIndicators = true,
  });

  @override
  State<SwipeableBentoStack<T>> createState() => _SwipeableBentoStackState<T>();
}

class _SwipeableBentoStackState<T> extends State<SwipeableBentoStack<T>> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return widget.builder(context, widget.items[index], index);
          },
        ),
        if (widget.showIndicators && widget.items.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  width: _currentPage == index ? 12 : 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
