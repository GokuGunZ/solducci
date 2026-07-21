import 'package:solducci/core/templates/resource_template.dart';

class CanvasTemplateRegistry {
  static const CanvasTemplate welcomeCanvas = CanvasTemplate(
    id: 'welcome_canvas',
    name: 'Welcome Canvas',
    description: 'Il template di benvenuto per i nuovi utenti',
    nodes: [
      CanvasTemplateNode(
        title: 'Welcome Canvas',
        type: 'markdown',
        payloadText: '# Welcome Canvas\n\nIn questo spazio puoi esplorare su nuove dimensioni la disposizione di note all\'interno di un sistema di cartelle (Per i NERD: un albero).',
      ),
      CanvasTemplateNode(
        title: 'Cartella Livello 1',
        type: 'folder',
        children: [
          CanvasTemplateNode(
            title: 'A mixed world',
            type: 'markdown',
            payloadText: '# A mixed world\n\nIn questo spazio un canvas è composto sia da cartelle che da testo (e presto molto altro..)',
          ),
          CanvasTemplateNode(
            title: 'Cartella Livello 2',
            type: 'folder',
            children: [
              CanvasTemplateNode(
                title: 'Inner world',
                type: 'markdown',
                payloadText: '# Inner world\n\nE puoi guardare le cartelle in tutte le profondità che vuoi. Prova ad aumentare la profondità l\'incrementatore in alto.',
              ),
              CanvasTemplateNode(
                title: 'Cartella Livello 3',
                type: 'folder',
                children: [
                  CanvasTemplateNode(
                    title: 'Boop!',
                    type: 'markdown',
                    payloadText: '# Boop!\n\nE puoi controllare anche le singole cartelle, direttamente e con il contatore.',
                  ),
                ]
              )
            ]
          ),
          CanvasTemplateNode(
            title: 'Sotto il cofano: Markdown!',
            type: 'markdown',
            payloadText: '# Sotto il cofano: Markdown!\n\nIl testo in questo spazio segue le regole del markdown, quindi potrai usare caratteri speciali (*, _, #, -, etc.) per dare stile e forma alle tue note. Prova a fare swipe della Card per guardare cosa c\'è sotto il cofano del testo e modificarlo!',
          ),
          CanvasTemplateNode(
            title: 'Markdown!',
            type: 'folder',
            children: [
              CanvasTemplateNode(
                title: 'Guida rapida',
                type: 'markdown',
                payloadText: '''# Guida Rapida al Markdown

Ecco una lista di esempi di come utilizzare il Markdown!

## Formattazione Testo
Puoi scrivere in **grassetto**, in *corsivo*, oppure ~~barrato~~.

## Liste
- Elemento non ordinato 1
- Elemento non ordinato 2
  - Sotto-elemento

1. Elemento ordinato 1
2. Elemento ordinato 2

## Citazioni
> Questa è una citazione importante che viene evidenziata nel testo.

## Codice
Puoi inserire codice inline come `var x = 10;` oppure blocchi interi:

```dart
void sayHello() {
  print("Hello Canvas!");
}
```

## Checkbox
- [x] Task completata
- [ ] Task da fare
''',
              )
            ]
          )
        ]
      )
    ]
  );
}
