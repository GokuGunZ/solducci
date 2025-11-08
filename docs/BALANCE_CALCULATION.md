# Calcolo Saldo Carl/Pit - Documentazione

## Overview

Il sistema di calcolo del saldo tra Carl e Pit è automatico e basato sul campo `moneyFlow` di ogni spesa. Il calcolo tiene traccia di chi deve cosa a chi e calcola un saldo netto finale.

## Logica di Calcolo

### Variabili Tracciate

- **carlOwes**: Quanto Carl deve a Pit (in €)
- **pitOwes**: Quanto Pit deve a Carl (in €)
- **netBalance**: Saldo netto = `carlOwes - pitOwes`
  - Se **positivo**: Carl deve a Pit
  - Se **negativo**: Pit deve a Carl
  - Se **zero**: Saldo in pareggio

### Regole per MoneyFlow

| MoneyFlow | Descrizione | Effetto sul Saldo |
|-----------|-------------|-------------------|
| `carlToPit` | Carl ha pagato per Pit | `pitOwes += amount` (Pit deve a Carl) |
| `pitToCarl` | Pit ha pagato per Carl | `carlOwes += amount` (Carl deve a Pit) |
| `carlDiv2` | Carl ha pagato, spesa split 50/50 | `pitOwes += amount / 2` (Pit deve metà a Carl) |
| `pitDiv2` | Pit ha pagato, spesa split 50/50 | `carlOwes += amount / 2` (Carl deve metà a Pit) |
| `carlucci` | Spesa personale di Carl | Nessun effetto sul saldo |
| `pit` | Spesa personale di Pit | Nessun effetto sul saldo |

## Esempi Pratici

### Esempio 1: Carl paga per Pit
```
Spesa: Cena ristorante - 50€
MoneyFlow: carlToPit

Risultato:
- pitOwes = 50€
- Pit deve 50€ a Carl
```

### Esempio 2: Spesa condivisa 50/50 (Carl paga)
```
Spesa: Spesa al supermercato - 100€
MoneyFlow: carlDiv2

Risultato:
- pitOwes = 50€
- Pit deve 50€ a Carl (la sua metà)
```

### Esempio 3: Scenario complesso
```
Spese:
1. Carl paga cena per Pit: 60€ (carlToPit)
2. Pit paga spesa condivisa: 80€ (pitDiv2)
3. Carl paga benzina condivisa: 40€ (carlDiv2)

Calcolo:
- Spesa 1: pitOwes = 60€
- Spesa 2: carlOwes = 40€ (80/2)
- Spesa 3: pitOwes = 60€ + 20€ = 80€

Totali:
- carlOwes = 40€
- pitOwes = 80€
- netBalance = 40 - 80 = -40€

Risultato finale:
Pit deve 40€ a Carl
```

## Implementazione

### Codice (dashboard_data.dart)

```dart
factory DebtBalance.calculate(List<Expense> expenses) {
  double carlOwes = 0.0;
  double pitOwes = 0.0;

  for (var expense in expenses) {
    switch (expense.moneyFlow) {
      case MoneyFlow.carlToPit:
        pitOwes += expense.amount;
        break;
      case MoneyFlow.pitToCarl:
        carlOwes += expense.amount;
        break;
      case MoneyFlow.carlDiv2:
        pitOwes += expense.amount / 2;
        break;
      case MoneyFlow.pitDiv2:
        carlOwes += expense.amount / 2;
        break;
      case MoneyFlow.carlucci:
      case MoneyFlow.pit:
        // Spese personali, nessun debito
        break;
    }
  }

  final netBalance = carlOwes - pitOwes;
  String balanceLabel;

  if (netBalance > 0) {
    balanceLabel = "Carl deve ${netBalance.toStringAsFixed(2)} € a Pit";
  } else if (netBalance < 0) {
    balanceLabel = "Pit deve ${(-netBalance).toStringAsFixed(2)} € a Carl";
  } else {
    balanceLabel = "Saldo in pareggio";
  }

  return DebtBalance(
    carlOwes: carlOwes,
    pitOwes: pitOwes,
    netBalance: netBalance,
    balanceLabel: balanceLabel,
  );
}
```

## UI della Vista Saldo

La vista mostra:

1. **Card principale centrale**:
   - Icona e colore in base a chi deve
   - Importo del saldo netto
   - Label user-friendly ("Carl deve X€ a Pit")

2. **Breakdown individuali**:
   - Card per Carl con totale che deve
   - Card per Pit con totale che deve

3. **Card spiegazione**:
   - Legenda con tutte le regole di calcolo
   - Aiuta l'utente a capire come funziona il sistema

## Note Tecniche

- Il calcolo viene eseguito **in tempo reale** ogni volta che lo stream di spese emette nuovi dati
- Tutte le spese vengono considerate nel calcolo (non ci sono filtri temporali)
- Per vedere solo il saldo di un periodo specifico, sarebbe necessario implementare filtri (feature futura)
- Il calcolo è **stateless** e **deterministico**: lo stesso set di spese produrrà sempre lo stesso risultato

## Test Manuale

Per testare il calcolo:

1. Aggiungi diverse spese con MoneyFlow diversi
2. Vai alla Dashboard → Saldo
3. Verifica che il calcolo corrisponda alle tue aspettative
4. Confronta i breakdown individuali con il saldo netto

## Prossimi Sviluppi

- Filtri temporali (saldo mensile, trimestrale, annuale)
- Storico dei saldi nel tempo
- Notifiche quando il saldo supera una soglia
- Esportazione report saldo in PDF
