import SwiftUI

struct SetupCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(FamilyTheme.accent)

            Text("Anslut familjens Google Sheet")
                .font(.title3.bold())
                .foregroundStyle(FamilyTheme.ink)

            Text("Klistra in webbadressen från Google Apps Script. Därefter hämtas den kommande veckan automatiskt.")
                .font(.subheadline)
                .foregroundStyle(FamilyTheme.secondaryInk)

            Button("Öppna inställningar", action: action)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct LoadingCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ProgressView()
            Text("Hämtar dagens viktigaste…")
                .font(.headline)
                .foregroundStyle(FamilyTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct ErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kunde inte uppdatera", systemImage: "wifi.exclamationmark")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FamilyTheme.secondaryInk)
            Button("Försök igen", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct EmptyCalendarCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(FamilyTheme.accent)
            Text("Lugnt den kommande veckan")
                .font(.title3.bold())
                .foregroundStyle(FamilyTheme.ink)
            Text("Inga kalenderhändelser hittades för de närmaste sju dagarna.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(FamilyTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
