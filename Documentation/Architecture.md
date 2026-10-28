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
       ┌────┴─────┐
       ▼          ▼
SwiftUI-appen   delad cache
                  │
                  ▼
             WidgetKit
```

Appen hämtar endast idag och imorgon. Widgeten försöker göra samma hämtning ungefär var trettionde minut, men iOS bestämmer den faktiska uppdateringstiden. Om hämtningen misslyckas visas senast cachade händelser och en diskret uppdateringssymbol.

Endpointadressen sparas i appgruppen och blir därför tillgänglig för både appen och widgeten. Familjedata skrivs inte till iCloud eller någon separat databas av appen.
