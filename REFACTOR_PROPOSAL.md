# Proposta di Refactoring per DocumentsHomeView

## Problema Attuale

Il `PageView` con array statico di `children` causa problemi quando:
1. I tags cambiano → L'array viene ricreato → PageView si confonde
2. AutomaticKeepAliveClientMixin non funziona bene con array dinamici
3. Ogni rebuild ricrea tutti i widget anche se non necessario

## Soluzione Proposta: PageView.builder

### Vantaggi
1. **Lazy loading**: Crea le pagine solo quando necessarie
2. **Stato stabile**: Non ricrea tutte le pagine ad ogni cambio di tags
3. **Performance**: Migliori performance con molti tag
4. **Più semplice**: Meno codice, meno bug

### Implementazione

```dart
class _PageViewContentState extends State<_PageViewContent> {
  final _tagService = TagService();
  List<Tag> _tags = [];
  bool _isLoading = true;
  StreamSubscription<List<Tag>>? _tagsSubscription;

  @override
  void initState() {
    super.initState();
    _tagsSubscription = _tagService.stream.listen((tags) {
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tagsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalPages = 2 + _tags.length; // All Tasks + Tags + Completed

    return Column(
      children: [
        _buildPageIndicator(totalPages),
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            itemCount: totalPages,
            itemBuilder: (context, index) {
              // Page 0: All Tasks
              if (index == 0) {
                return AllTasksView(document: widget.document);
              }

              // Pages 1 to N-1: Tag Views
              if (index <= _tags.length) {
                final tag = _tags[index - 1];
                return TagView(
                  document: widget.document,
                  tag: tag,
                );
              }

              // Last page: Completed Tasks
              return CompletedTasksView(document: widget.document);
            },
          ),
        ),
      ],
    );
  }
}
```

### Modifiche Necessarie

1. **Rimuovere AutomaticKeepAliveClientMixin** dalle view singole
   - Non più necessario con PageView.builder
   - Il builder gestisce già il caching automaticamente

2. **Semplificare le view**
   - AllTasksView, TagView, CompletedTasksView tornano Stateless
   - Stream/Future creati direttamente nel build (va bene con builder)

3. **Gestione subscription corretta**
   - Usare StreamSubscription e dispose correttamente
   - Cancellare la subscription quando il widget viene distrutto

### Perché Questo Funziona

1. **PageView.builder non ricrea le pagine**
   - Chiama `itemBuilder` solo quando una pagina diventa visibile
   - Mantiene in cache le pagine già costruite
   - Non si confonde quando itemCount cambia

2. **StreamSubscription esplicita**
   - Più controllo sul lifecycle
   - Nessun rebuild inaspettato
   - Cancellazione pulita in dispose

3. **Meno complessità**
   - Nessun AutomaticKeepAliveClientMixin
   - Nessun super.build(context)
   - Nessuna gestione manuale dello stato delle view

## Piano di Implementazione

1. Modificare `_PageViewContent` per usare PageView.builder
2. Rimuovere AutomaticKeepAliveClientMixin da tutte le view
3. Riportare AllTasksView, TagView, CompletedTasksView a StatelessWidget
4. Testare navigazione e swipe
5. Verificare che i dati si aggiornino correttamente

## Rischi e Mitigazioni

**Rischio**: Le view potrebbero ricaricare i dati ogni volta che diventano visibili
**Mitigazione**: I servizi sono singleton, gli stream sono cachati da Supabase

**Rischio**: Performance con molti tag
**Mitigazione**: PageView.builder è ottimizzato per liste grandi

**Rischio**: Stato perso durante lo swipe
**Mitigazione**: PageView.builder mantiene automaticamente le pagine in cache
