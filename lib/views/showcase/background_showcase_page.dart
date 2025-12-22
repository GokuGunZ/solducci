import 'dart:ui' show ImageFilter;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Showcase page for exploring different background styles and customization options
///
/// Features:
/// - Multiple background types: linear gradients, radial gradients, geometric patterns, complex gradients
/// - Composable layers: stack multiple backgrounds on top of each other
/// - Live customization with sliders and color pickers
/// - Advanced pattern controls: size, spacing, shape variations
/// - Preview of how backgrounds look with actual content
class BackgroundShowcasePage extends StatefulWidget {
  const BackgroundShowcasePage({super.key});

  @override
  State<BackgroundShowcasePage> createState() => _BackgroundShowcasePageState();
}

class _BackgroundShowcasePageState extends State<BackgroundShowcasePage> {
  // Layer system
  final List<BackgroundLayer> _layers = [
    BackgroundLayer(type: BackgroundType.linearGradient, enabled: true),
  ];

  int _selectedLayerIndex = 0;

  // Blur effect (applies to entire composition)
  bool _enableBlur = false;
  double _blurIntensity = 5.0;

  BackgroundLayer get _selectedLayer => _layers[_selectedLayerIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Showcase'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Layer manager
          _buildLayerManager(),

          // Preview area with controls
          Expanded(
            child: Row(
              children: [
                // Left side: Background preview
                Expanded(flex: 2, child: _buildBackgroundPreview()),

                // Right side: Controls panel
                Expanded(flex: 1, child: _buildControlsPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerManager() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Layer Composizione',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.purple),
                onPressed: _addLayer,
                tooltip: 'Aggiungi Layer',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _layers.length,
              itemBuilder: (context, index) {
                final layer = _layers[index];
                final isSelected = index == _selectedLayerIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildLayerCard(layer, index, isSelected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerCard(BackgroundLayer layer, int index, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedLayerIndex = index),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: layer.enabled,
                  onChanged: (value) {
                    setState(() {
                      layer.enabled = value ?? false;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: Text(
                    'Layer ${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_layers.length > 1)
                  InkWell(
                    onTap: () => _removeLayer(index),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
              ],
            ),
            Text(
              _getTypeLabel(layer.type),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _addLayer() {
    setState(() {
      _layers.add(
        BackgroundLayer(type: BackgroundType.geometricPattern, enabled: true),
      );
      _selectedLayerIndex = _layers.length - 1;
    });
  }

  void _removeLayer(int index) {
    if (_layers.length > 1) {
      setState(() {
        _layers.removeAt(index);
        if (_selectedLayerIndex >= _layers.length) {
          _selectedLayerIndex = _layers.length - 1;
        }
      });
    }
  }

  Widget _buildBackgroundPreview() {
    Widget preview = Container(
      color: Colors.white,
      child: Stack(
        children: [
          // All background layers
          for (int i = 0; i < _layers.length; i++)
            if (_layers[i].enabled)
              Positioned.fill(child: _buildLayerBackground(_layers[i])),

          // Sample content overlay
          Positioned.fill(child: _buildSampleContent()),
        ],
      ),
    );

    // Apply blur if enabled
    if (_enableBlur) {
      preview = Stack(
        children: [
          preview,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurIntensity,
                sigmaY: _blurIntensity,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      );
    }

    return preview;
  }

  Widget _buildLayerBackground(BackgroundLayer layer) {
    Widget background;
    switch (layer.type) {
      case BackgroundType.linearGradient:
        background = _buildLinearGradient(layer);
        break;
      case BackgroundType.radialGradient:
        background = _buildRadialGradient(layer);
        break;
      case BackgroundType.sweepGradient:
        background = _buildSweepGradient(layer);
        break;
      case BackgroundType.geometricPattern:
        background = _buildGeometricPattern(layer);
        break;
      case BackgroundType.complexGradient:
        background = _buildComplexGradient(layer);
        break;
    }

    // Apply blend mode if not default
    if (layer.blendMode != BlendMode.srcOver) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.transparent,
          layer.blendMode,
        ),
        child: background,
      );
    }
    return background;
  }

  Widget _buildLinearGradient(BackgroundLayer layer) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: layer.linearBegin,
          end: layer.linearEnd,
          colors: [
            layer.color1.withValues(alpha: layer.opacity),
            layer.color2.withValues(alpha: layer.opacity * 0.7),
            layer.color3,
          ],
        ),
      ),
    );
  }

  Widget _buildRadialGradient(BackgroundLayer layer) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: layer.radialCenter,
          radius: layer.radialRadius,
          colors: [
            layer.color1.withValues(alpha: layer.opacity),
            layer.color2.withValues(alpha: layer.opacity * 0.7),
            layer.color3,
          ],
          tileMode: layer.radialTileMode,
          focal: layer.radialFocal,
          focalRadius: layer.radialFocalRadius,
        ),
      ),
    );
  }

  Widget _buildSweepGradient(BackgroundLayer layer) {
    return Container(
      decoration: BoxDecoration(
        gradient: SweepGradient(
          center: layer.sweepCenter,
          startAngle: layer.sweepStartAngle * math.pi / 180,
          endAngle: layer.sweepEndAngle * math.pi / 180,
          colors: [
            layer.color1.withValues(alpha: layer.opacity),
            layer.color2.withValues(alpha: layer.opacity * 0.7),
            layer.color3,
          ],
        ),
      ),
    );
  }

  Widget _buildGeometricPattern(BackgroundLayer layer) {
    return Transform.translate(
      offset: Offset(layer.patternOffsetX, layer.patternOffsetY),
      child: Transform.rotate(
        angle: layer.patternRotation * math.pi / 180,
        child: Transform.scale(
          scale: layer.patternScale,
          child: CustomPaint(
            painter: _getPatternPainter(layer),
            child: Container(),
          ),
        ),
      ),
    );
  }

  CustomPainter _getPatternPainter(BackgroundLayer layer) {
    final color = layer.color1.withValues(alpha: layer.opacity);
    switch (layer.patternType) {
      case PatternType.dots:
        return DotsPatternPainter(
          color: color,
          spacing: layer.patternSpacing,
          dotRadius: layer.patternSize,
        );
      case PatternType.grid:
        return GridPatternPainter(
          color: color,
          spacing: layer.patternSpacing,
          strokeWidth: layer.patternStrokeWidth,
        );
      case PatternType.waves:
        return WavesPatternPainter(
          color: color,
          waveHeight: layer.patternSize,
          waveWidth: layer.patternSpacing,
        );
      case PatternType.diagonal:
        return DiagonalLinesPatternPainter(
          color: color,
          spacing: layer.patternSpacing,
          strokeWidth: layer.patternStrokeWidth,
        );
      case PatternType.hexagons:
        return HexagonPatternPainter(color: color, size: layer.patternSize);
      case PatternType.circles:
        return CirclesPatternPainter(
          color: color,
          spacing: layer.patternSpacing,
          radius: layer.patternSize,
          strokeWidth: layer.patternStrokeWidth,
        );
    }
  }

  Widget _buildComplexGradient(BackgroundLayer layer) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: layer.complexColors
              .map((c) => c.withValues(alpha: layer.opacity))
              .toList(),
          stops: _generateStops(layer.complexColors.length),
        ),
      ),
    );
  }

  List<double> _generateStops(int count) {
    if (count <= 1) return [0.0];
    return List.generate(count, (i) => i / (count - 1));
  }

  Widget _buildSampleContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Task di Esempio',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSampleTaskCard('Completare documentazione', true),
        _buildSampleTaskCard('Rivedere design UI', false),
        _buildSampleTaskCard('Implementare nuove features', false),
        const SizedBox(height: 24),
        const Text(
          'Anteprima dello sfondo con contenuti reali. I layer vengono sovrapposti dal basso verso l\'alto.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSampleTaskCard(String title, bool completed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          completed ? Icons.check_circle : Icons.circle_outlined,
          color: completed ? Colors.green : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                'Controlli Layer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_selectedLayerIndex + 1}/${_layers.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Background type selector for selected layer
          const Text(
            'Tipo Background:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...BackgroundType.values.map((type) {
            return RadioListTile<BackgroundType>(
              title: Text(
                _getTypeLabel(type),
                style: const TextStyle(fontSize: 13),
              ),
              value: type,
              groupValue: _selectedLayer.type,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLayer.type = value);
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),

          const SizedBox(height: 16),
          const Divider(),

          // Type-specific controls
          ..._buildTypeSpecificControls(),

          const SizedBox(height: 24),
          const Divider(),

          // Blur effect (applies to entire composition)
          _buildSwitchControl(
            'Effetto Blur (Globale)',
            _enableBlur,
            (value) => setState(() => _enableBlur = value),
          ),
          if (_enableBlur) ...[
            const SizedBox(height: 8),
            _buildSliderControl(
              'Intensità Blur',
              _blurIntensity,
              0,
              20,
              (value) => setState(() => _blurIntensity = value),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificControls() {
    final controls = <Widget>[];

    switch (_selectedLayer.type) {
      case BackgroundType.linearGradient:
        controls.addAll(_buildLinearGradientControls());
        break;
      case BackgroundType.radialGradient:
        controls.addAll(_buildRadialGradientControls());
        break;
      case BackgroundType.sweepGradient:
        controls.addAll(_buildSweepGradientControls());
        break;
      case BackgroundType.geometricPattern:
        controls.addAll(_buildPatternControls());
        break;
      case BackgroundType.complexGradient:
        controls.addAll(_buildComplexGradientControls());
        break;
    }

    // Add blend mode control for all types
    controls.addAll([
      const SizedBox(height: 16),
      const Divider(),
      const Text('Blend Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildBlendModeSelector(),
    ]);

    return controls;
  }

  List<Widget> _buildLinearGradientControls() {
    return [
      _buildSliderControl(
        'Opacità',
        _selectedLayer.opacity,
        0.01,
        1.0,
        (value) => setState(() => _selectedLayer.opacity = value),
      ),
      const SizedBox(height: 16),

      const Text('Direzione:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildAlignmentSelector(
        'Inizio',
        _selectedLayer.linearBegin,
        (value) => setState(() => _selectedLayer.linearBegin = value),
      ),
      const SizedBox(height: 8),
      _buildAlignmentSelector(
        'Fine',
        _selectedLayer.linearEnd,
        (value) => setState(() => _selectedLayer.linearEnd = value),
      ),
      const SizedBox(height: 16),

      const Text('Colori:', style: TextStyle(fontWeight: FontWeight.bold)),
      _buildColorPicker(
        'Colore 1',
        _selectedLayer.color1,
        (c) => setState(() => _selectedLayer.color1 = c),
      ),
      _buildColorPicker(
        'Colore 2',
        _selectedLayer.color2,
        (c) => setState(() => _selectedLayer.color2 = c),
      ),
      _buildColorPicker(
        'Colore 3',
        _selectedLayer.color3,
        (c) => setState(() => _selectedLayer.color3 = c),
      ),
    ];
  }

  List<Widget> _buildRadialGradientControls() {
    return [
      _buildSliderControl(
        'Opacità',
        _selectedLayer.opacity,
        0.01,
        1.0,
        (value) => setState(() => _selectedLayer.opacity = value),
      ),
      const SizedBox(height: 16),

      _buildSliderControl(
        'Raggio',
        _selectedLayer.radialRadius,
        0.1,
        2.0,
        (value) => setState(() => _selectedLayer.radialRadius = value),
      ),
      const SizedBox(height: 16),

      const Text('Centro:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildAlignmentSelector(
        'Posizione',
        _selectedLayer.radialCenter as Alignment,
        (value) => setState(() => _selectedLayer.radialCenter = value),
      ),
      const SizedBox(height: 16),

      const Text('Colori:', style: TextStyle(fontWeight: FontWeight.bold)),
      _buildColorPicker(
        'Colore 1',
        _selectedLayer.color1,
        (c) => setState(() => _selectedLayer.color1 = c),
      ),
      _buildColorPicker(
        'Colore 2',
        _selectedLayer.color2,
        (c) => setState(() => _selectedLayer.color2 = c),
      ),
      _buildColorPicker(
        'Colore 3',
        _selectedLayer.color3,
        (c) => setState(() => _selectedLayer.color3 = c),
      ),
    ];
  }

  List<Widget> _buildSweepGradientControls() {
    return [
      _buildSliderControl(
        'Opacità',
        _selectedLayer.opacity,
        0.01,
        1.0,
        (value) => setState(() => _selectedLayer.opacity = value),
      ),
      const SizedBox(height: 16),

      const Text('Centro:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildAlignmentSelector(
        'Posizione',
        _selectedLayer.sweepCenter as Alignment,
        (value) => setState(() => _selectedLayer.sweepCenter = value),
      ),
      const SizedBox(height: 16),

      _buildSliderControl(
        'Angolo Inizio (°)',
        _selectedLayer.sweepStartAngle,
        0,
        360,
        (value) => setState(() => _selectedLayer.sweepStartAngle = value),
      ),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Angolo Fine (°)',
        _selectedLayer.sweepEndAngle,
        0,
        360,
        (value) => setState(() => _selectedLayer.sweepEndAngle = value),
      ),
      const SizedBox(height: 16),

      const Text('Colori:', style: TextStyle(fontWeight: FontWeight.bold)),
      _buildColorPicker('Colore 1', _selectedLayer.color1, (c) => setState(() => _selectedLayer.color1 = c)),
      _buildColorPicker('Colore 2', _selectedLayer.color2, (c) => setState(() => _selectedLayer.color2 = c)),
      _buildColorPicker('Colore 3', _selectedLayer.color3, (c) => setState(() => _selectedLayer.color3 = c)),
    ];
  }

  List<Widget> _buildPatternControls() {
    return [
      _buildSliderControl(
        'Opacità',
        _selectedLayer.opacity,
        0.01,
        1.0,
        (value) => setState(() => _selectedLayer.opacity = value),
      ),
      const SizedBox(height: 16),

      const Text(
        'Tipo Pattern:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...PatternType.values.map((type) {
        return RadioListTile<PatternType>(
          title: Text(
            _getPatternLabel(type),
            style: const TextStyle(fontSize: 12),
          ),
          value: type,
          groupValue: _selectedLayer.patternType,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLayer.patternType = value);
            }
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }),
      const SizedBox(height: 16),

      _buildSliderControl(
        'Dimensione',
        _selectedLayer.patternSize,
        1.0,
        30.0,
        (value) => setState(() => _selectedLayer.patternSize = value),
      ),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Spaziatura',
        _selectedLayer.patternSpacing,
        10.0,
        100.0,
        (value) => setState(() => _selectedLayer.patternSpacing = value),
      ),
      const SizedBox(height: 8),

      if (_selectedLayer.patternType == PatternType.grid ||
          _selectedLayer.patternType == PatternType.diagonal ||
          _selectedLayer.patternType == PatternType.circles)
        _buildSliderControl(
          'Spessore Linea',
          _selectedLayer.patternStrokeWidth,
          0.5,
          5.0,
          (value) => setState(() => _selectedLayer.patternStrokeWidth = value),
        ),
      const SizedBox(height: 16),

      // Trasformazioni
      const Text('Trasformazioni:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Rotazione (°)',
        _selectedLayer.patternRotation,
        0,
        360,
        (value) => setState(() => _selectedLayer.patternRotation = value),
      ),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Scala',
        _selectedLayer.patternScale,
        0.1,
        3.0,
        (value) => setState(() => _selectedLayer.patternScale = value),
      ),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Offset X',
        _selectedLayer.patternOffsetX,
        -100,
        100,
        (value) => setState(() => _selectedLayer.patternOffsetX = value),
      ),
      const SizedBox(height: 8),

      _buildSliderControl(
        'Offset Y',
        _selectedLayer.patternOffsetY,
        -100,
        100,
        (value) => setState(() => _selectedLayer.patternOffsetY = value),
      ),
      const SizedBox(height: 16),

      const Text('Colore:', style: TextStyle(fontWeight: FontWeight.bold)),
      _buildColorPicker(
        'Colore Pattern',
        _selectedLayer.color1,
        (c) => setState(() => _selectedLayer.color1 = c),
      ),
    ];
  }

  List<Widget> _buildComplexGradientControls() {
    return [
      _buildSliderControl(
        'Opacità',
        _selectedLayer.opacity,
        0.01,
        1.0,
        (value) => setState(() => _selectedLayer.opacity = value),
      ),
      const SizedBox(height: 16),

      Row(
        children: [
          const Text('Colori:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 20, color: Colors.purple),
            onPressed: () {
              if (_selectedLayer.complexColors.length < 6) {
                setState(() => _selectedLayer.complexColors.add(Colors.blue));
              }
            },
            tooltip: 'Aggiungi colore',
          ),
        ],
      ),
      for (int i = 0; i < _selectedLayer.complexColors.length; i++)
        Row(
          children: [
            Expanded(
              child: _buildColorPicker(
                'Colore ${i + 1}',
                _selectedLayer.complexColors[i],
                (c) => setState(() => _selectedLayer.complexColors[i] = c),
              ),
            ),
            if (_selectedLayer.complexColors.length > 2)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() => _selectedLayer.complexColors.removeAt(i));
                },
              ),
          ],
        ),
    ];
  }

  Widget _buildBlendModeSelector() {
    final commonBlendModes = [
      BlendMode.srcOver,
      BlendMode.multiply,
      BlendMode.screen,
      BlendMode.overlay,
      BlendMode.darken,
      BlendMode.lighten,
      BlendMode.colorDodge,
      BlendMode.colorBurn,
      BlendMode.hardLight,
      BlendMode.softLight,
      BlendMode.difference,
      BlendMode.exclusion,
    ];

    return DropdownButtonFormField<BlendMode>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: _selectedLayer.blendMode,
      style: const TextStyle(fontSize: 11, color: Colors.black),
      items: commonBlendModes.map((mode) {
        return DropdownMenuItem(
          value: mode,
          child: Text(_getBlendModeLabel(mode)),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _selectedLayer.blendMode = newValue);
        }
      },
    );
  }

  String _getBlendModeLabel(BlendMode mode) {
    switch (mode) {
      case BlendMode.srcOver:
        return 'Normale';
      case BlendMode.multiply:
        return 'Moltiplica';
      case BlendMode.screen:
        return 'Scolora';
      case BlendMode.overlay:
        return 'Sovrapponi';
      case BlendMode.darken:
        return 'Scurisci';
      case BlendMode.lighten:
        return 'Schiarisci';
      case BlendMode.colorDodge:
        return 'Scherma';
      case BlendMode.colorBurn:
        return 'Brucia';
      case BlendMode.hardLight:
        return 'Luce Forte';
      case BlendMode.softLight:
        return 'Luce Soffusa';
      case BlendMode.difference:
        return 'Differenza';
      case BlendMode.exclusion:
        return 'Esclusione';
      default:
        return mode.toString().split('.').last;
    }
  }

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.purple,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchControl(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.purple,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAlignmentSelector(
    String label,
    Alignment value,
    ValueChanged<Alignment> onChanged,
  ) {
    final alignments = {
      'Top Left': Alignment.topLeft,
      'Top Center': Alignment.topCenter,
      'Top Right': Alignment.topRight,
      'Center Left': Alignment.centerLeft,
      'Center': Alignment.center,
      'Center Right': Alignment.centerRight,
      'Bottom Left': Alignment.bottomLeft,
      'Bottom Center': Alignment.bottomCenter,
      'Bottom Right': Alignment.bottomRight,
    };

    return DropdownButtonFormField<Alignment>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      style: const TextStyle(fontSize: 11, color: Colors.black),
      items: alignments.entries.map((entry) {
        return DropdownMenuItem(value: entry.value, child: Text(entry.key));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildColorPicker(
    String label,
    Color color,
    ValueChanged<Color> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showColorPicker(context, color, onChanged),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    ValueChanged<Color> onChanged,
  ) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.white,
      Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Colore'),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            children: colors.map((color) {
              return InkWell(
                onTap: () {
                  onChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: color == currentColor
                          ? Colors.black
                          : Colors.grey[300]!,
                      width: color == currentColor ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BackgroundType type) {
    switch (type) {
      case BackgroundType.linearGradient:
        return 'Gradient Lineare';
      case BackgroundType.radialGradient:
        return 'Gradient Radiale';
      case BackgroundType.sweepGradient:
        return 'Gradient Conico';
      case BackgroundType.geometricPattern:
        return 'Pattern Geometrico';
      case BackgroundType.complexGradient:
        return 'Gradient Complesso';
    }
  }

  String _getPatternLabel(PatternType type) {
    switch (type) {
      case PatternType.dots:
        return 'Puntini';
      case PatternType.grid:
        return 'Griglia';
      case PatternType.waves:
        return 'Onde';
      case PatternType.diagonal:
        return 'Linee Diagonali';
      case PatternType.hexagons:
        return 'Esagoni';
      case PatternType.circles:
        return 'Cerchi';
    }
  }
}

// Models
enum BackgroundType {
  linearGradient,
  radialGradient,
  sweepGradient,
  geometricPattern,
  complexGradient,
}

enum PatternType { dots, grid, waves, diagonal, hexagons, circles }

class BackgroundLayer {
  BackgroundType type;
  bool enabled;

  // Common properties
  double opacity;
  Color color1;
  Color color2;
  Color color3;
  BlendMode blendMode;

  // Linear gradient
  Alignment linearBegin;
  Alignment linearEnd;
  TileMode linearTileMode;

  // Radial gradient
  AlignmentGeometry radialCenter;
  double radialRadius;
  TileMode radialTileMode;
  Alignment? radialFocal;
  double radialFocalRadius;

  // Sweep gradient
  AlignmentGeometry sweepCenter;
  double sweepStartAngle;
  double sweepEndAngle;

  // Pattern
  PatternType patternType;
  double patternSize;
  double patternSpacing;
  double patternStrokeWidth;
  double patternRotation;
  double patternOffsetX;
  double patternOffsetY;
  double patternScale;

  // Complex gradient
  List<Color> complexColors;
  List<double>? complexStops;
  bool useCustomStops;

  BackgroundLayer({
    required this.type,
    this.enabled = true,
    this.opacity = 0.05,
    this.color1 = Colors.purple,
    this.color2 = Colors.blue,
    this.color3 = Colors.white,
    this.blendMode = BlendMode.srcOver,
    this.linearBegin = Alignment.topCenter,
    this.linearEnd = Alignment.bottomCenter,
    this.linearTileMode = TileMode.clamp,
    this.radialCenter = Alignment.center,
    this.radialRadius = 1.0,
    this.radialTileMode = TileMode.clamp,
    this.radialFocal,
    this.radialFocalRadius = 0.0,
    this.sweepCenter = Alignment.center,
    this.sweepStartAngle = 0.0,
    this.sweepEndAngle = 360.0,
    this.patternType = PatternType.dots,
    this.patternSize = 2.0,
    this.patternSpacing = 30.0,
    this.patternStrokeWidth = 1.0,
    this.patternRotation = 0.0,
    this.patternOffsetX = 0.0,
    this.patternOffsetY = 0.0,
    this.patternScale = 1.0,
    List<Color>? complexColors,
    this.complexStops,
    this.useCustomStops = false,
  }) : complexColors =
           complexColors ??
           [Colors.purple, Colors.blue, Colors.cyan, Colors.white];
}

// Custom Painters for Geometric Patterns
class DotsPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotRadius;

  DotsPatternPainter({
    required this.color,
    this.spacing = 30,
    this.dotRadius = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotsPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius;
  }
}

class GridPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double strokeWidth;

  GridPatternPainter({
    required this.color,
    this.spacing = 30,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class WavesPatternPainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double waveWidth;

  WavesPatternPainter({
    required this.color,
    this.waveHeight = 20,
    this.waveWidth = 60,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw multiple wave lines
    for (double y = 0; y < size.height; y += waveHeight * 3) {
      path.reset();
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += waveWidth) {
        path.quadraticBezierTo(
          x + waveWidth / 4,
          y - waveHeight,
          x + waveWidth / 2,
          y,
        );
        path.quadraticBezierTo(
          x + 3 * waveWidth / 4,
          y + waveHeight,
          x + waveWidth,
          y,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavesPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.waveHeight != waveHeight ||
        oldDelegate.waveWidth != waveWidth;
  }
}

class DiagonalLinesPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double strokeWidth;

  DiagonalLinesPatternPainter({
    required this.color,
    this.spacing = 30,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Diagonal lines from top-left to bottom-right
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DiagonalLinesPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class HexagonPatternPainter extends CustomPainter {
  final Color color;
  final double size;

  HexagonPatternPainter({required this.color, this.size = 20});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final hexHeight = size * 2;
    final hexWidth = (size * 1.732); // sqrt(3) * size
    final vertSpacing = hexHeight * 0.75;

    for (double y = 0; y < canvasSize.height + hexHeight; y += vertSpacing) {
      for (double x = 0; x < canvasSize.width + hexWidth; x += hexWidth) {
        final offset = (y / vertSpacing).floor() % 2 == 1 ? hexWidth / 2 : 0;
        _drawHexagon(canvas, Offset(x + offset, y), size, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexagonPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.size != size;
  }
}

class CirclesPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;
  final double strokeWidth;

  CirclesPatternPainter({
    required this.color,
    this.spacing = 40,
    this.radius = 15,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CirclesPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
