//
//  PreferencesView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-21.


//  PreferencesView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-21.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct PreferencesView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Theme storage (local)
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    // MARK: - Preference State
    @State private var defaultCurrency: String = "USD"       // will be overridden by locale / DB
    @State private var languageCode: String = "en"          // will be overridden by locale / DB
    @State private var timeZoneId: String = TimeZone.current.identifier
    
    @State private var notificationsEnabled: Bool = true
    @State private var expenseRemindersEnabled: Bool = true
    @State private var groupActivityEnabled: Bool = true
    @State private var weeklySummaryEnabled: Bool = true
    
    // MARK: - UI State
    // No blocking spinner anymore – only used for Save button
    @State private var isSaving: Bool = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    headerSection
                    
                    // Appearance
                    ESCard {
                        themeSection
                    }
                    .padding(.horizontal)
                    
                    // Defaults: currency, language, timezone
                    ESCard {
                        currencyLanguageTimezoneSection
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Notifications
                    ESCard {
                        notificationsSection
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Save button + messages
                    saveSection
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 1) Start with safe local / locale defaults
            applyLocaleDefaults()
            // 2) Then silently try to sync from Firebase
            await loadPreferences()
        }
    }
}

// MARK: - Header

private extension PreferencesView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("App Preferences")
                .font(.title.bold())
            
            Text("Customize how Expense Splitter behaves for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Theme Section

private extension PreferencesView {
    var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
            
            HStack {
                Label("App Theme", systemImage: "paintbrush.fill")
                    .foregroundColor(.esPrimary)
                Spacer()
                
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.menu)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Currency, Language & Time Zone Section

private extension PreferencesView {
    
    var currencyLanguageTimezoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Defaults")
                .font(.headline)
            
            // Default Currency
            VStack(alignment: .leading, spacing: 6) {
                Text("Default Currency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Currency", selection: $defaultCurrency) {
                        ForEach(currencyOptions, id: \.code) { option in
                            Text("\(option.code) – \(option.name)")
                                .tag(option.code)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                }
            }
            
            // Default Language
            VStack(alignment: .leading, spacing: 6) {
                Text("Default Language")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Language", selection: $languageCode) {
                        ForEach(languageOptions, id: \.code) { option in
                            Text(option.name).tag(option.code)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                }
            }
            
            // Time Zone
            VStack(alignment: .leading, spacing: 6) {
                Text("Time Zone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Time Zone", selection: $timeZoneId) {
                        ForEach(timeZoneOptions, id: \.self) { id in
                            Text(timeZoneDisplayName(id: id))
                                .tag(id)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                }
            }
        }
    }
    
    struct CurrencyOption { let code: String; let name: String }
    struct LanguageOption { let code: String; let name: String }
    
    var currencyOptions: [CurrencyOption] {
        [
            .init(code: "CAD", name: "Canadian Dollar"),
            .init(code: "USD", name: "US Dollar"),
            .init(code: "EUR", name: "Euro"),
            .init(code: "GBP", name: "British Pound"),
            .init(code: "AUD", name: "Australian Dollar"),
            .init(code: "NZD", name: "New Zealand Dollar"),
            .init(code: "JPY", name: "Japanese Yen"),
            .init(code: "CNY", name: "Chinese Yuan"),
            .init(code: "INR", name: "Indian Rupee"),
            .init(code: "CHF", name: "Swiss Franc"),
            .init(code: "SEK", name: "Swedish Krona"),
            .init(code: "NOK", name: "Norwegian Krone"),
            .init(code: "DKK", name: "Danish Krone"),
            .init(code: "BRL", name: "Brazilian Real"),
            .init(code: "MXN", name: "Mexican Peso"),
            .init(code: "ZAR", name: "South African Rand"),
            .init(code: "RUB", name: "Russian Ruble"),
            .init(code: "HKD", name: "Hong Kong Dollar"),
            .init(code: "SGD", name: "Singapore Dollar"),
            .init(code: "KRW", name: "South Korean Won"),
            .init(code: "TRY", name: "Turkish Lira"),
            .init(code: "AED", name: "UAE Dirham"),
            .init(code: "SAR", name: "Saudi Riyal"),
            .init(code: "PLN", name: "Polish Złoty"),
            .init(code: "IDR", name: "Indonesian Rupiah")
        ]
    }
    
    var languageOptions: [LanguageOption] {
        [
            .init(code: "en", name: "English"),
            .init(code: "fr", name: "French"),
            .init(code: "es", name: "Spanish"),
            .init(code: "de", name: "German"),
            .init(code: "it", name: "Italian"),
            .init(code: "pt", name: "Portuguese"),
            .init(code: "ru", name: "Russian"),
            .init(code: "zh", name: "Chinese (Mandarin)"),
            .init(code: "ja", name: "Japanese"),
            .init(code: "ko", name: "Korean"),
            .init(code: "hi", name: "Hindi"),
            .init(code: "gu", name: "Gujarati"),
            .init(code: "ar", name: "Arabic"),
            .init(code: "tr", name: "Turkish"),
            .init(code: "nl", name: "Dutch"),
            .init(code: "sv", name: "Swedish"),
            .init(code: "no", name: "Norwegian"),
            .init(code: "da", name: "Danish"),
            .init(code: "pl", name: "Polish"),
            .init(code: "th", name: "Thai"),
            .init(code: "id", name: "Indonesian"),
            .init(code: "vi", name: "Vietnamese"),
            .init(code: "fa", name: "Persian"),
            .init(code: "he", name: "Hebrew"),
            .init(code: "ur", name: "Urdu")
        ]
    }
    
    /// Curated timezone options with current device time zone at top.
    var timeZoneOptions: [String] {
        var ids = [
            "America/Toronto",
            "America/Vancouver",
            "America/New_York",
            "Europe/London",
            "Europe/Paris",
            "Asia/Kolkata",
            "Asia/Dubai",
            "Asia/Tokyo",
            "Australia/Sydney"
        ]
        
        let currentId = TimeZone.current.identifier
        if !ids.contains(currentId) {
            ids.insert(currentId, at: 0)
        }
        return ids
    }
    
    func timeZoneDisplayName(id: String) -> String {
        guard let tz = TimeZone(identifier: id) else { return id }
        let city = id.split(separator: "/").last.map(String.init) ?? id
        let cleanCity = city.replacingOccurrences(of: "_", with: " ")
        let abbrev = tz.abbreviation() ?? ""
        return "\(cleanCity) (\(abbrev))"
    }
}

// MARK: - Notifications Section

private extension PreferencesView {
    var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
            
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .tint(.esPrimary)
            
            Group {
                Toggle("Expense reminders", isOn: $expenseRemindersEnabled)
                Toggle("Group activity updates", isOn: $groupActivityEnabled)
                Toggle("Weekly summary", isOn: $weeklySummaryEnabled)
            }
            .tint(.esPrimary)
            .disabled(!notificationsEnabled)
            .opacity(notificationsEnabled ? 1 : 0.5)
        }
    }
}

// MARK: - Save Section

private extension PreferencesView {
    var saveSection: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            if let statusMessage {
                Text(statusMessage)
                    .foregroundColor(.green)
                    .font(.footnote)
            }
            
            Button {
                Task { await savePreferences() }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isSaving ? "Saving…" : "Save Preferences")
                        .font(.headline)
                }
            }
            .buttonStyle(ESPrimaryButtonStyle())
            .disabled(isSaving)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Loading & Saving

private extension PreferencesView {
    
    /// 1) Local / device-based defaults (runs immediately on launch)
    func applyLocaleDefaults() {
        let locale = Locale.current
        
        // Currency default
        if let code = locale.currencyCode,
           currencyOptions.map(\.code).contains(code) {
            defaultCurrency = code
        } else {
            defaultCurrency = "USD"
        }
        
        // Language default
        let langFromLocale =
            locale.language.languageCode?.identifier ??
            locale.languageCode ??
            "en"
        
        if languageOptions.map(\.code).contains(langFromLocale) {
            languageCode = langFromLocale
        } else if langFromLocale.hasPrefix("fr") {
            languageCode = "fr"
        } else if langFromLocale.hasPrefix("es") {
            languageCode = "es"
        } else {
            languageCode = "en"
        }
        
        // Timezone default
        timeZoneId = TimeZone.current.identifier
    }
    
    /// 2) Non-blocking Firebase load – silently overrides local defaults if data exists.
    func loadPreferences() async {
        guard let uid = authService.currentUserId else {
            // Not logged in → keep local defaults
            return
        }
        
        let ref = FirebaseManager.shared.database
            .child("users")
            .child(uid)
            .child("settings")
        
        do {
            let snap = try await ref.getValueAsync()
            
            guard let data = snap.value as? [String: Any] else {
                // No settings saved → keep local defaults
                return
            }
            
            await MainActor.run {
                defaultCurrency = data["defaultCurrency"] as? String ?? defaultCurrency
                languageCode    = data["languageCode"]    as? String ?? languageCode
                timeZoneId      = data["timeZoneId"]      as? String ?? timeZoneId
                appTheme        = data["appTheme"]        as? String ?? appTheme
                
                notificationsEnabled      = data["notificationsEnabled"]      as? Bool ?? notificationsEnabled
                expenseRemindersEnabled   = data["expenseRemindersEnabled"]   as? Bool ?? expenseRemindersEnabled
                groupActivityEnabled      = data["groupActivityEnabled"]      as? Bool ?? groupActivityEnabled
                weeklySummaryEnabled      = data["weeklySummaryEnabled"]      as? Bool ?? weeklySummaryEnabled
            }
            
        } catch {
            // Per Option 1: silent failure (no UI indicator), keep local defaults
            // You could log this in console if needed.
            print("Preferences load error: \(error.localizedDescription)")
        }
    }
    
    /// 3) Save to Firebase (and implicitly keep @AppStorage updated via bindings)
    func savePreferences() async {
        guard let uid = authService.currentUserId else { return }
        
        await MainActor.run {
            isSaving = true
            statusMessage = nil
            errorMessage = nil
        }
        
        let ref = FirebaseManager.shared.database
            .child("users")
            .child(uid)
            .child("settings")
        
        let payload: [String: Any] = [
            "defaultCurrency": defaultCurrency,
            "languageCode": languageCode,
            "timeZoneId": timeZoneId,
            "appTheme": appTheme,
            "notificationsEnabled": notificationsEnabled,
            "expenseRemindersEnabled": expenseRemindersEnabled,
            "groupActivityEnabled": groupActivityEnabled,
            "weeklySummaryEnabled": weeklySummaryEnabled
        ]
        
        do {
            try await ref.setValueAsync(payload)
            
            await MainActor.run {
                isSaving = false
                statusMessage = "Preferences saved."
            }
            
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
