# Solducci Design Guidelines

Questo documento sintetizza le scelte stilistiche, i pattern e le best practice introdotte nel branch `new_design`. Lo scopo è mantenere un'identità visiva omogenea, moderna e premium per tutti i futuri sviluppi dell'app.

## 1. Tema Core e Palette Colori

Il nuovo design abbraccia un'estetica **Dark/OLED** di base, arricchita da accenti neon e sfumature eleganti.

*   **Background (OLED Dark):** `Color(0xFF09090B)` o `Color(0xFF121212)`. Usato per gli sfondi principali (Scaffold) per garantire contrasto e risparmio energetico su schermi OLED.
*   **Surface (Card/Tile):** `Color(0xFF18181B)` o `Color(0xFF1E1E2C)`. Usato per raggruppare i contenuti e farli risaltare sul fondo scuro.
*   **Colori d'Accento (Vibrant/Neon):**
    *   **Primary (Indigo):** `Color(0xFF6366F1)` - Elementi interattivi principali.
    *   **Success (Emerald):** `Color(0xFF10B981)`
    *   **Warning (Amber):** `Color(0xFFF59E0B)`
    *   **Error (Red):** `Color(0xFFEF4444)`
    *   **Extra (Pink/Purple):** `Color(0xFFE068F1)` - Usato per effetti speciali e animazioni (es. Liquid Card).

## 2. Tipografia

*   **Font Family:** **Inter**.
*   **Gerarchia:**
    *   Titoli grandi e in grassetto (`FontWeight.bold`, fontSize 20-24) usando il colore primario del testo (`Colors.white` o `Color(0xFFE0E0E0)`).
    *   Testo secondario pulito e leggibile con opacità ridotta (`Colors.white54` o `Colors.white70`).

## 3. Forme e Bordi (Squircles)

L'interfaccia abbandona gli spigoli vivi a favore di forme morbide ed eleganti.
*   **Border Radius:** Utilizzare raggi ampi per le card, i dialog e le bottom sheet, tipicamente `BorderRadius.circular(16)` fino a `BorderRadius.circular(24)`.
*   **Bordi Sottili:** Al posto dell'elevation classica (ombra nera piatta), le card scure si staccano dal fondo tramite bordi sottilissimi semitrasparenti: `BorderSide(color: Colors.white10, width: 1)`.

## 4. Effetti Visivi (Glow & Glassmorphism)

Per ottenere l'effetto "WOW", l'app utilizza tecniche avanzate di rendering:

*   **Neon Glow (Ombre Colorate):** Invece delle classiche ombre nere, usa ombre colorate per creare effetti di luminescenza (neon glow). Questo si ottiene in Flutter con:
    *   `MaskFilter.blur(BlurStyle.solid, 4)` (o 8/20) nei `CustomPaint`.
    *   Lista di `BoxShadow` o `Shadow` nei testi con il colore d'accento e alta opacità (es. `Shadow(color: Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 20)`).
*   **Glassmorphism (Vetro Smerigliato):** Quando si sovrappongono livelli, specialmente su sfondi complessi (gradienti), si usa l'effetto vetro tramite `BackdropFilter` con `ImageFilter.blur(sigmaX: 5, sigmaY: 5)` e container semi-trasparenti (`Colors.white.withValues(alpha: 0.1)` o `0.9` in light mode contestuali).
*   **Gradienti Sofisticati:** Come visto in `BackgroundShowcase`, l'app supporta background complessi multistrato (Gradienti Lineari, Radiali) fusi assieme per creare scenari "Ethereal" o "Aurora". I gradienti lineari sfumano spesso verso la trasparenza per i grafici (`NeonWaveGraph`).

## 5. Animazioni, Interattività e Fisica (Motion)

Il design non è statico; deve sembrare "vivo" e reagire fisicamente al tocco dell'utente:

*   **Animazioni Fluide e Continue:** I grafici (come il `NeonWaveGraph`) "respirano" usando funzioni sinusoidali nel tempo (`sin(time * 2 * pi)`).
*   **Fisica Elastica (Liquid UI):** Le interazioni complesse (es. la *Elastic Liquid Card*) reagiscono non solo alla posizione ma anche alla *velocità* del gesto, deformando i bordi elasticamente.
*   **Rotazioni 3D:** Uso del 3D flip card per transizioni di stato e rivelazione di contenuti nascosti, dando profondità z-index all'interfaccia.
*   **Micro-interazioni:** Elementi come il `TimeDialWidget` scalano leggermente (es. `scale(1.1)`) quando diventano attivi/selezionati. Utilizza la libreria `flutter_animate` per micro-animazioni rapide (200-300ms).

## 6. Pattern di Layout e Componenti

*   **SolducciAppBar:** L'AppBar standard è trasparente, senza elevation (`elevation: 0`), e integra nativamente il `ContextSwitcher` assieme al pulsante "Indietro", mantenendo l'header pulito e unificato.
*   **ListTiles Custom:** Le liste utilizzano ListTile con padding abbondante, shape circolare (16px), sfondo colorato (`tileColor`) e l'aggiunta di bordi semitrasparenti (`Colors.white10`).
*   **Menu Radiali & Floating:** Uso di menu non convenzionali (es. Constellation Menu, Omni Radial Menu) per azioni rapide (Quick Add), che sbocciano dal centro/basso, offrendo un'esperienza tattile superiore ai menu a tendina tradizionali.

## Checklist per Sviluppi Futuri

Quando crei una nuova pagina o un nuovo widget, chiediti sempre:
1. [ ] Sto usando `AppTheme.background` o `AppTheme.surface`?
2. [ ] Ho arrotondato gli angoli (`16px` o `24px`)?
3. [ ] Ho sostituito l'elevation base con un bordo sottile (`white10`) o un bagliore neon?
4. [ ] Il componente reagisce al tocco dell'utente in maniera fluida o elastica?
5. [ ] Sto usando font "Inter" con gerarchie di peso e colore corrette?
6. [ ] C'è un'opportunità per applicare un effetto glassmorphism?
