# Familjekoll

Familjekoll är en intern iOS-app som visar familjens viktigaste händelser idag och imorgon. Data läses från fliken `2022-25` i ett Google Sheet via en liten Google Apps Script-webbapp. Projektet innehåller även en Home Screen-widget och Lock Screen-widget.

## Det som ingår

- SwiftUI-app för iOS 17 eller senare.
- Automatisk uppdatering när appen öppnas, blir aktiv eller dras ned för uppdatering.
- Fem kategorier: Johan, Emma, Ia, Allie och Annat.
- Enkel prioritering med datum, klockslag och viktiga nyckelord.
- WidgetKit-extension för Small, Medium, Inline, Circular och Rectangular.
- Delad lokal cache så widgeten kan visa senaste kända data om nätet tillfälligt saknas.
- Google Apps Script som bara läser kolumner C och E–I från fliken `2022-25`.

## Anslut Google Sheet

1. Öppna Google Sheet-dokumentet.
2. Välj **Tillägg → Apps Script**.
3. Ersätt innehållet i `Code.gs` med filen `GoogleAppsScript/Code.gs` från projektet.
4. Kontrollera under **Projektinställningar** att tidszonen är `Europe/Stockholm`.
5. Rekommenderat: lägg till en skriptegenskap med namnet `API_KEY` och ett långt slumpmässigt värde.
6. Välj **Distribuera → Ny distribution → Webbapp**.
7. Kör som dig själv. Ge åtkomst till alla med länken. `API_KEY` gör att länken ensam inte räcker.
8. Kopiera webbappens adress som slutar på `/exec`.
9. Om du satte en nyckel, lägg till den sist: `?key=DIN_NYCKEL`.
10. Starta Familjekoll, öppna kugghjulet och klistra in adressen.

Efter kodändringar i Apps Script behöver webbappen distribueras som en ny version. Adressen kan vanligtvis behållas.

## Kolumnmappning

Apps Script använder fasta positioner eftersom rubrikerna för barnkolumnerna innehåller en ålder som ändras:

| Sheet-kolumn | Appkategori |
| --- | --- |
| C | Datum |
| E | Johan |
| F | Emma |
| G | Ia / B2s lilla liv |
| H | Allie / B3s lilla liv |
| I | Annat |

Tomma celler, punkt/komma som platshållare och vanliga kalkylbladsfel ignoreras. Flera rader i samma cell blir separata händelser.

## Xcode och signering

Öppna `Familjekoll.xcodeproj`. Projektet använder Apple-teamet från det ursprungliga startprojektet. Byt vid behov bundle-id:n och appgruppen `group.mojo.Familjekoll.shared` i båda targetarnas Signing & Capabilities. Appen och widgeten måste använda exakt samma appgrupp.

## Nästa steg för AI-urval

Den första versionen använder `EventPrioritizer.swift` och `scoreEvent_` i Apps Script. En senare AI-lösning bör ligga på serversidan:

1. Apps Script hämtar kandidater för idag och imorgon.
2. En skyddad serverfunktion skickar endast kandidattexterna till vald AI-modell.
3. Modellen returnerar event-id:n i prioriteringsordning och en kort motivering.
4. Apps Script faller tillbaka på dagens regelbaserade poäng om AI-anropet misslyckas.

Lägg aldrig en AI-nyckel direkt i iOS-appen eller i källkod som delas.

## Verifiera endpointen

Öppna följande adress i en webbläsare och byt datum:

```text
https://script.google.com/macros/s/DEPLOYMENT_ID/exec?key=DIN_NYCKEL&from=2026-10-28&to=2026-10-29
```

Svaret ska innehålla `events` med `date`, `title`, `category`, `sourceColumn` och `priority`.
