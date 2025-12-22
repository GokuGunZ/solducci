import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Showcase page for Glass Morphism effects
///
/// Tests different glass morphism configurations to understand
/// transparency and blur behavior with various backgrounds
class GlassMorphismShowcasePage extends StatefulWidget {
  const GlassMorphismShowcasePage({super.key});

  @override
  State<GlassMorphismShowcasePage> createState() => _GlassMorphismShowcasePageState();
}

class _GlassMorphismShowcasePageState extends State<GlassMorphismShowcasePage> {
  double _opacity = 0.13;
  double _blur = 10.0;
  Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same background as DocumentsHomeView
          Positioned.fill(
            child: TodoTheme.customBackgroundGradient,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(),

                // Controls
                _buildControls(),

                // Glass tiles grid
                Expanded(
                  child: _buildGlassTilesGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: TodoTheme.glassAppBarDecoration(),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: TodoTheme.primaryPurple),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Glass Morphism Showcase',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Controls:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Opacity slider
          Row(
            children: [
              const Text('Opacity: ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.01,
                  max: 1.0,
                  divisions: 100,
                  label: _opacity.toStringAsFixed(2),
                  onChanged: (value) => setState(() => _opacity = value),
                ),
              ),
              Text(_opacity.toStringAsFixed(2), style: const TextStyle(fontSize: 12)),
            ],
          ),

          // Blur slider
          Row(
            children: [
              const Text('Blur: ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _blur,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  label: _blur.toStringAsFixed(0),
                  onChanged: (value) => setState(() => _blur = value),
                ),
              ),
              Text(_blur.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
            ],
          ),

          // Background color selector
          const Text('Background Color: ', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorButton(Colors.white, 'White'),
              const SizedBox(width: 8),
              _buildColorButton(Colors.purple[100]!, 'Purple'),
              const SizedBox(width: 8),
              _buildColorButton(Colors.blue[100]!, 'Blue'),
              const SizedBox(width: 8),
              _buildColorButton(Colors.green[100]!, 'Green'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, String label) {
    final isSelected = _backgroundColor == color;
    return InkWell(
      onTap: () => setState(() => _backgroundColor = color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTilesGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Basic glass tiles
          const Text(
            '1. Basic Glass Tiles (White)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGlassTile('Opacity 0.05', 0.05)),
              const SizedBox(width: 8),
              Expanded(child: _buildGlassTile('Opacity 0.13', 0.13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildGlassTile('Opacity 0.25', 0.25)),
              const SizedBox(width: 8),
              Expanded(child: _buildGlassTile('Opacity 0.50', 0.50)),
            ],
          ),

          const SizedBox(height: 24),

          // Section 2: Colored glass tiles
          const Text(
            '2. Colored Glass Tiles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildColoredGlassTile('Purple', Colors.purple)),
              const SizedBox(width: 8),
              Expanded(child: _buildColoredGlassTile('Blue', Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildColoredGlassTile('Green', Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildColoredGlassTile('Orange', Colors.orange)),
            ],
          ),

          const SizedBox(height: 24),

          // Section 3: Complex glass tiles (like TaskTile)
          const Text(
            '3. Complex Tiles (TaskTile Style)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildComplexTaskTile('Simple Task', false),
          const SizedBox(height: 8),
          _buildComplexTaskTile('Task with Container', true),

          const SizedBox(height: 24),

          // Section 4: Layer tests
          const Text(
            '4. Layer Tests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildLayerTest(),
        ],
      ),
    );
  }

  /// Basic glass tile with white background
  Widget _buildGlassTile(String label, double opacity) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _backgroundColor.withValues(alpha: opacity * 1.2),
                _backgroundColor.withValues(alpha: opacity * 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blur: ${_blur.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Colored glass tile
  Widget _buildColoredGlassTile(String label, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: _opacity * 1.2),
                color.withValues(alpha: _opacity * 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Complex task tile style (simulating TaskListItem)
  Widget _buildComplexTaskTile(String label, bool withInnerContainer) {
    return Container(
      color: Colors.transparent, // Outer container
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColor.withValues(alpha: _opacity * 1.2),
                  _backgroundColor.withValues(alpha: _opacity * 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (withInnerContainer)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inner container with semi-transparent background',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                else
                  Container(
                    color: Colors.transparent, // Transparent inner container
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'Inner container with transparent background',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Layer test to identify rendering issues
  Widget _buildLayerTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test A: Only BackdropFilter + Decoration',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _backgroundColor.withValues(alpha: _opacity * 1.2),
                    _backgroundColor.withValues(alpha: _opacity * 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'Pure Glass - No children',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Test B: With Padding + Column',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _backgroundColor.withValues(alpha: _opacity * 1.2),
                    _backgroundColor.withValues(alpha: _opacity * 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'With Padding + Column',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.transparent,
                    child: const Text('Transparent container child'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Test C: With InkWell (transparent splash)',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _backgroundColor.withValues(alpha: _opacity * 1.2),
                    _backgroundColor.withValues(alpha: _opacity * 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: () {},
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Tap me - InkWell with transparent splash',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
