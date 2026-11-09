# Arkitektur

```text
Google Sheet, fliken 2022-25
            │
            ▼
Google Apps Script
filtrerar datum + formar JSON
            │ HTTPS
            ▼
SheetAPIClient
            │
      EventPrioritizer
       ┌────┴──────────┐
       ▼               ▼
SwiftUI-appen      delad cache
       │               │
       ▼               ▼
lokala notiser      WidgetKit
```

Appen hämtar 60 dagar framåt för att kunna schemalägga lokala notiser, men visar bara idag och sex dagar framåt. Widgeten hämtar en vecka och försöker uppdatera ungefär var trettionde minut, men iOS bestämmer den faktiska uppdateringstiden. Om hämtningen misslyckas visas senast cachade händelser och en diskret uppdateringssymbol.

Endpointadressen sparas i appgruppen och blir därför tillgänglig för både appen och widgeten. Familjedata skrivs inte till iCloud eller någon separat databas av appen.

Notisregler, vald notistid och aktiveringsstatus sparas också lokalt i appgruppen. `NotificationScheduler` tar bort appens tidigare väntande påminnelser och bygger om schemat efter varje lyckad hämtning eller inställningsändring. Högst 60 kommande påminnelser skapas för att lämna marginal till iOS gräns för väntande lokala notiser.
