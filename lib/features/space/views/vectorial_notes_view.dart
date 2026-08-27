import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';

class VectorialNotesView extends StatefulWidget {
  final List<Document> documents;
  final Color themeColor;

  const VectorialNotesView({
    super.key,
    required this.documents,
    required this.themeColor,
  });

  @override
  State<VectorialNotesView> createState() => _VectorialNotesViewState();
}

class _VectorialNotesViewState extends State<VectorialNotesView> with TickerProviderStateMixin {
  Document? _zoomedDoc;
  late AnimationController _zoomController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 6.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOutExpo)
    );
  }
  
  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _zoomInto(Document doc) {
    setState(() {
      _zoomedDoc = doc;
    });
    _zoomController.forward();
  }

  void _zoomOut() {
    _zoomController.reverse().then((_) {
      setState(() {
        _zoomedDoc = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _zoomController,
      builder: (context, child) {
        return GestureDetector(
          onScaleUpdate: (details) {
            // Seleziona pinch out per uscire dal tunnel
            if (details.scale < 0.8 && _zoomedDoc != null && !_zoomController.isAnimating) {
              _zoomOut();
            }
          },
          child: Stack(
            children: [
              // Griglia di Nodi (Il "Tunnel" iniziale)
              GridView.builder(
                padding: const EdgeInsets.all(32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 32,
                ),
                itemCount: widget.documents.length,
                itemBuilder: (context, index) {
                  final doc = widget.documents[index];
                  final isTarget = doc.id == _zoomedDoc?.id;
                  
                  // L'animazione Hero dell'asse Z
                  final scale = _zoomedDoc == null ? 1.0 : (isTarget ? _scaleAnimation.value : (1.0 - _zoomController.value));
                  final opacity = _zoomedDoc == null ? 1.0 : (isTarget ? (1.0 - (_zoomController.value * 0.5)) : (1.0 - _zoomController.value * 2).clamp(0.0, 1.0));
                  
                  // I fratelli sfuggono lateralmente ("volano via")
                  Offset offset = Offset.zero;
                  if (_zoomedDoc != null && !isTarget) {
                    final isLeft = index % 2 == 0;
                    offset = Offset((isLeft ? -400.0 : 400.0) * _zoomController.value, 0);
                  }

                  return Transform.translate(
                    offset: offset,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onDoubleTap: () {
                            if (_zoomedDoc == null) _zoomInto(doc);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: widget.themeColor.withValues(alpha: 0.8), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.themeColor.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                            child: Center(
                              child: Text(
                                doc.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Contenuto "Dentro" la nota (Materializza dopo lo zoom)
              if (_zoomedDoc != null)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _zoomController.value < 0.8,
                    child: Opacity(
                      // Dissolvenza incrociata in ritardo
                      opacity: _zoomController.value > 0.6 ? (_zoomController.value - 0.6) * 2.5 : 0.0,
                      child: Container(
                        color: const Color(0xFF09090B),
                        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: _zoomOut,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_zoomedDoc!.title, style: TextStyle(fontSize: 28, color: widget.themeColor, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  'Contenuto della nota vettoriale.\n\nQui apparirà l\'editor di testo avanzato.\n\nPuoi uscire facendo un Pinch-Out con due dita o premendo la X.', 
                                  style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 18, height: 1.5)
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}
