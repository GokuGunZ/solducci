import 'package:flutter/material.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/theme/todo_theme.dart';

/// Preview page showing different dropdown selector designs for filters
class DropdownSelectorPreview extends StatefulWidget {
  const DropdownSelectorPreview({super.key});

  @override
  State<DropdownSelectorPreview> createState() => _DropdownSelectorPreviewState();
}

class _DropdownSelectorPreviewState extends State<DropdownSelectorPreview> {
  // State for each solution
  Set<TaskPriority> _selectedPriorities1 = {};
  Set<TaskPriority> _selectedPriorities2 = {};
  Set<TaskPriority> _selectedPriorities3 = {};
  Set<TaskPriority> _selectedPriorities4 = {};
  Set<TaskPriority> _selectedPriorities5 = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropdown Selector Solutions'),
        backgroundColor: TodoTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Selettori Dropdown per Filtri'),
          const SizedBox(height: 8),
          Text(
            'Diverse soluzioni di dropdown animati che appaiono come menu a tendina dal filtro cliccato, non come modal dialog.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Solution 1: Slide Down Dropdown
          _buildSolutionCard(
            title: 'Soluzione 1: Slide Down Classic',
            description: 'Pro: Animazione fluida slide-down, semplice e pulito\nContro: Può coprire contenuto sottostante',
            impact: 'UX: 4/5 | Animazione: Slide down | Performance: Ottima',
            child: _buildSolution1(),
          ),

          // Solution 2: Fade + Scale Dropdown
          _buildSolutionCard(
            title: 'Soluzione 2: Fade & Scale (Material 3)',
            description: 'Pro: Effetto elegante con fade e scale, molto moderno\nContro: Animazione più complessa',
            impact: 'UX: 5/5 | Animazione: Fade + Scale | Performance: Buona',
            child: _buildSolution2(),
          ),

          // Solution 3: Expand with Blur Background
          _buildSolutionCard(
            title: 'Soluzione 3: Expand Premium con Blur',
            description: 'Pro: Sfondo blur, aspetto premium, focus sul dropdown\nContro: Più pesante per performance',
            impact: 'UX: 5/5 | Animazione: Expand + Blur | Performance: Media',
            child: _buildSolution3(),
          ),

          // Solution 4: Side Slide (Lateral)
          _buildSolutionCard(
            title: 'Soluzione 4: Slide Laterale',
            description: 'Pro: Non copre contenuto verticale, slide orizzontale elegante\nContro: Può uscire dai bordi su schermi piccoli',
            impact: 'UX: 4/5 | Animazione: Slide horizontal | Performance: Ottima',
            child: _buildSolution4(),
          ),

          // Solution 5: Morphing Card (Advanced)
          _buildSolutionCard(
            title: 'Soluzione 5: Morphing Card ⭐',
            description: 'Pro: Il chip si trasforma nel dropdown, transizione fluida\nContro: Complesso da implementare',
            impact: 'UX: 5/5 | Animazione: Morph | Performance: Buona',
            child: _buildSolution5(),
          ),

          const SizedBox(height: 40),
          _buildRecommendation(),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: TodoTheme.primaryPurple,
      ),
    );
  }

  Widget _buildSolutionCard({
    required String title,
    required String description,
    required String impact,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TodoTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                impact,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // Solution 1: Classic Slide Down Dropdown
  Widget _buildSolution1() {
    return _DropdownButton1(
      selectedPriorities: _selectedPriorities1,
      onChanged: (newSet) {
        setState(() {
          _selectedPriorities1 = newSet;
        });
      },
    );
  }

  // Solution 2: Fade + Scale Dropdown (Material 3 style)
  Widget _buildSolution2() {
    return _DropdownButton2(
      selectedPriorities: _selectedPriorities2,
      onChanged: (newSet) {
        setState(() {
          _selectedPriorities2 = newSet;
        });
      },
    );
  }

  // Solution 3: Expand with Blur Background
  Widget _buildSolution3() {
    return _DropdownButton3(
      selectedPriorities: _selectedPriorities3,
      onChanged: (newSet) {
        setState(() {
          _selectedPriorities3 = newSet;
        });
      },
    );
  }

  // Solution 4: Side Slide Dropdown
  Widget _buildSolution4() {
    return _DropdownButton4(
      selectedPriorities: _selectedPriorities4,
      onChanged: (newSet) {
        setState(() {
          _selectedPriorities4 = newSet;
        });
      },
    );
  }

  // Solution 5: Morphing Card
  Widget _buildSolution5() {
    return _DropdownButton5(
      selectedPriorities: _selectedPriorities5,
      onChanged: (newSet) {
        setState(() {
          _selectedPriorities5 = newSet;
        });
      },
    );
  }

  Widget _buildRecommendation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TodoTheme.primaryPurple.withValues(alpha: 0.1),
            TodoTheme.lightPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TodoTheme.primaryPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend, color: TodoTheme.primaryPurple, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Raccomandazioni',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TodoTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recommendation 1 - Solution 5 (Morphing)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.2),
                  Colors.orange.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🏆 CONSIGLIATA: Soluzione 5 (Morphing Card)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'L\'esperienza più fluida e premium! Il chip si trasforma direttamente '
                  'nel dropdown con una transizione morphing elegante. Feedback visivo '
                  'eccellente e sensazione di continuità perfetta.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '✓ Transizione morphing fluida\n'
                  '✓ Sensazione di continuità\n'
                  '✓ Aspetto moderno e premium\n'
                  '✓ Non copre contenuto in modo brusco\n'
                  '✓ Animazione naturale e intuitiva',
                  style: TextStyle(fontSize: 12, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Recommendation 2 - Solution 2
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌟 Alternativa: Soluzione 2 (Fade & Scale)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se preferisci un\'animazione più semplice ma comunque elegante, in stile Material 3.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== SOLUTION 1: Classic Slide Down ==========
class _DropdownButton1 extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _DropdownButton1({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_DropdownButton1> createState() => _DropdownButton1State();
}

class _DropdownButton1State extends State<_DropdownButton1> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: 250,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 50),
                child: _SlideDownMenu(
                  selectedPriorities: widget.selectedPriorities,
                  onChanged: (newSet) {
                    widget.onChanged(newSet);
                  },
                  onClose: _closeDropdown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selectedPriorities.isEmpty
                ? Colors.grey[200]
                : Colors.deepPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selectedPriorities.isEmpty
                  ? Colors.grey[300]!
                  : Colors.deepPurple,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 18,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                widget.selectedPriorities.isEmpty
                    ? 'Priorità'
                    : '${widget.selectedPriorities.length} selezionate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedPriorities.isEmpty
                      ? Colors.grey[700]
                      : Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideDownMenu extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;
  final VoidCallback onClose;

  const _SlideDownMenu({
    required this.selectedPriorities,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_SlideDownMenu> createState() => _SlideDownMenuState();
}

class _SlideDownMenuState extends State<_SlideDownMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(_animation),
      child: FadeTransition(
        opacity: _animation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: TaskPriority.values.map((priority) {
                final isSelected = widget.selectedPriorities.contains(priority);
                return InkWell(
                  onTap: () {
                    final newSet = Set<TaskPriority>.from(widget.selectedPriorities);
                    if (isSelected) {
                      newSet.remove(priority);
                    } else {
                      newSet.add(priority);
                    }
                    widget.onChanged(newSet);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? priority.color : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          priority.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? priority.color : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== SOLUTION 2: Fade + Scale (Material 3) ==========
class _DropdownButton2 extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _DropdownButton2({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_DropdownButton2> createState() => _DropdownButton2State();
}

class _DropdownButton2State extends State<_DropdownButton2> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: 250,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 50),
                child: _FadeScaleMenu(
                  selectedPriorities: widget.selectedPriorities,
                  onChanged: (newSet) {
                    widget.onChanged(newSet);
                  },
                  onClose: _closeDropdown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selectedPriorities.isEmpty
                ? Colors.grey[200]
                : Colors.deepPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selectedPriorities.isEmpty
                  ? Colors.grey[300]!
                  : Colors.deepPurple,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 18,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                widget.selectedPriorities.isEmpty
                    ? 'Priorità'
                    : '${widget.selectedPriorities.length} selezionate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedPriorities.isEmpty
                      ? Colors.grey[700]
                      : Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeScaleMenu extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;
  final VoidCallback onClose;

  const _FadeScaleMenu({
    required this.selectedPriorities,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_FadeScaleMenu> createState() => _FadeScaleMenuState();
}

class _FadeScaleMenuState extends State<_FadeScaleMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.topCenter,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.deepPurple.withValues(alpha: 0.3),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.purple.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: TaskPriority.values.map((priority) {
                final isSelected = widget.selectedPriorities.contains(priority);
                return InkWell(
                  onTap: () {
                    final newSet = Set<TaskPriority>.from(widget.selectedPriorities);
                    if (isSelected) {
                      newSet.remove(priority);
                    } else {
                      newSet.add(priority);
                    }
                    widget.onChanged(newSet);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priority.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? priority.color
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? priority.color : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          priority.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? priority.color : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== SOLUTION 3: Expand with Blur ==========
class _DropdownButton3 extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _DropdownButton3({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_DropdownButton3> createState() => _DropdownButton3State();
}

class _DropdownButton3State extends State<_DropdownButton3> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Blur background
          GestureDetector(
            onTap: _closeDropdown,
            child: _BlurBackground(),
          ),
          // Menu
          Positioned(
            width: 250,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: _ExpandBlurMenu(
                selectedPriorities: widget.selectedPriorities,
                onChanged: (newSet) {
                  widget.onChanged(newSet);
                },
                onClose: _closeDropdown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selectedPriorities.isEmpty
                ? Colors.grey[200]
                : Colors.deepPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selectedPriorities.isEmpty
                  ? Colors.grey[300]!
                  : Colors.deepPurple,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 18,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                widget.selectedPriorities.isEmpty
                    ? 'Priorità'
                    : '${widget.selectedPriorities.length} selezionate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedPriorities.isEmpty
                      ? Colors.grey[700]
                      : Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurBackground extends StatefulWidget {
  @override
  State<_BlurBackground> createState() => _BlurBackgroundState();
}

class _BlurBackgroundState extends State<_BlurBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ExpandBlurMenu extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;
  final VoidCallback onClose;

  const _ExpandBlurMenu({
    required this.selectedPriorities,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_ExpandBlurMenu> createState() => _ExpandBlurMenuState();
}

class _ExpandBlurMenuState extends State<_ExpandBlurMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _expandAnimation,
        axisAlignment: -1.0,
        child: Material(
          elevation: 16,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.deepPurple.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.purple.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: TaskPriority.values.map((priority) {
                final isSelected = widget.selectedPriorities.contains(priority);
                return InkWell(
                  onTap: () {
                    final newSet = Set<TaskPriority>.from(widget.selectedPriorities);
                    if (isSelected) {
                      newSet.remove(priority);
                    } else {
                      newSet.add(priority);
                    }
                    widget.onChanged(newSet);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                priority.color.withValues(alpha: 0.15),
                                priority.color.withValues(alpha: 0.05),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: priority.color.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? priority.color : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          priority.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? priority.color : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== SOLUTION 4: Side Slide ==========
class _DropdownButton4 extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _DropdownButton4({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_DropdownButton4> createState() => _DropdownButton4State();
}

class _DropdownButton4State extends State<_DropdownButton4> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: 250,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(80, 0),
                child: _SideSlideMenu(
                  selectedPriorities: widget.selectedPriorities,
                  onChanged: (newSet) {
                    widget.onChanged(newSet);
                  },
                  onClose: _closeDropdown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selectedPriorities.isEmpty
                ? Colors.grey[200]
                : Colors.deepPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selectedPriorities.isEmpty
                  ? Colors.grey[300]!
                  : Colors.deepPurple,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 18,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                widget.selectedPriorities.isEmpty
                    ? 'Priorità'
                    : '${widget.selectedPriorities.length} selezionate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedPriorities.isEmpty
                      ? Colors.grey[700]
                      : Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[600]
                    : Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideSlideMenu extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;
  final VoidCallback onClose;

  const _SideSlideMenu({
    required this.selectedPriorities,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_SideSlideMenu> createState() => _SideSlideMenuState();
}

class _SideSlideMenuState extends State<_SideSlideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: TaskPriority.values.map((priority) {
                final isSelected = widget.selectedPriorities.contains(priority);
                return InkWell(
                  onTap: () {
                    final newSet = Set<TaskPriority>.from(widget.selectedPriorities);
                    if (isSelected) {
                      newSet.remove(priority);
                    } else {
                      newSet.add(priority);
                    }
                    widget.onChanged(newSet);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priority.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? priority.color : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          priority.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? priority.color : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== SOLUTION 5: Morphing Card ==========
class _DropdownButton5 extends StatefulWidget {
  final Set<TaskPriority> selectedPriorities;
  final ValueChanged<Set<TaskPriority>> onChanged;

  const _DropdownButton5({
    required this.selectedPriorities,
    required this.onChanged,
  });

  @override
  State<_DropdownButton5> createState() => _DropdownButton5State();
}

class _DropdownButton5State extends State<_DropdownButton5>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _elevationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _borderRadiusAnimation = Tween<double>(begin: 16.0, end: 16.0).animate(_controller);
    _elevationAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          elevation: _elevationAnimation.value,
          borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
          shadowColor: Colors.deepPurple.withValues(alpha: 0.3),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.selectedPriorities.isEmpty
                    ? [Colors.grey[200]!, Colors.grey[100]!]
                    : [
                        Colors.deepPurple.withValues(alpha: 0.15),
                        Colors.deepPurple.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              border: Border.all(
                color: widget.selectedPriorities.isEmpty
                    ? Colors.grey[300]!
                    : Colors.deepPurple.withValues(alpha: 0.5),
                width: _isOpen ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Button header
                InkWell(
                  onTap: _toggleDropdown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 18,
                        color: widget.selectedPriorities.isEmpty
                            ? Colors.grey[600]
                            : Colors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.selectedPriorities.isEmpty
                            ? 'Priorità'
                            : '${widget.selectedPriorities.length} selezionate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.selectedPriorities.isEmpty
                              ? Colors.grey[700]
                              : Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 20,
                        color: widget.selectedPriorities.isEmpty
                            ? Colors.grey[600]
                            : Colors.deepPurple,
                      ),
                    ],
                  ),
                ),
                // Morphing menu items
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: TaskPriority.values.map((priority) {
                        final isSelected = widget.selectedPriorities.contains(priority);
                        return InkWell(
                          onTap: () {
                            final newSet = Set<TaskPriority>.from(widget.selectedPriorities);
                            if (isSelected) {
                              newSet.remove(priority);
                            } else {
                              newSet.add(priority);
                            }
                            widget.onChanged(newSet);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        priority.color.withValues(alpha: 0.2),
                                        priority.color.withValues(alpha: 0.1),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: priority.color.withValues(alpha: 0.4))
                                  : Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected ? priority.color : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? priority.color : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  priority.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? priority.color : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
