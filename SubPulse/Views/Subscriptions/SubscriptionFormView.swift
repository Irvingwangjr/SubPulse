import SwiftData
import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingItem: SubscriptionItem?
    let defaultCurrency: Currency

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var currency: Currency = .usd
    @State private var billingCycle: BillingCycle = .monthly
    @State private var category: SubscriptionCategory = .streaming
    @State private var nextBillingDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var reminderDaysBefore: Int = 1
    @State private var isTrial: Bool = false
    @State private var notes: String = ""
    @State private var iconSymbol: String = SubscriptionCategory.streaming.defaultSymbol
    @State private var colorHex: String = SubscriptionCategory.streaming.defaultHex

    private var isEditing: Bool { existingItem != nil }

    private var parsedAmount: Double? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    Section(NSLocalizedString("form.quick_presets", comment: "")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ServicePreset.popular) { preset in
                                    Button {
                                        applyPreset(preset)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: preset.symbol)
                                                .foregroundStyle(Color(hex: preset.colorHex))
                                            Text(preset.name)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.primary)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(Color(.tertiarySystemFill), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(NSLocalizedString("form.details", comment: "")) {
                    TextField(NSLocalizedString("form.name_placeholder", comment: ""), text: $name)

                    HStack {
                        Picker(NSLocalizedString("form.currency", comment: ""), selection: $currency) {
                            ForEach(Currency.allCases) { item in
                                Text("\(item.flag) \(item.rawValue)").tag(item)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)

                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker(NSLocalizedString("form.cycle", comment: ""), selection: $billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.localizedTitle).tag(cycle)
                        }
                    }

                    Picker(NSLocalizedString("form.category", comment: ""), selection: $category) {
                        ForEach(SubscriptionCategory.allCases) { cat in
                            Label(cat.localizedTitle, systemImage: cat.defaultSymbol).tag(cat)
                        }
                    }
                    .onChange(of: category) { _, newValue in
                        iconSymbol = newValue.defaultSymbol
                        colorHex = newValue.defaultHex
                    }
                }

                Section(NSLocalizedString("form.billing_reminders", comment: "")) {
                    DatePicker(
                        NSLocalizedString("form.next_billing", comment: ""),
                        selection: $nextBillingDate,
                        displayedComponents: .date
                    )

                    Toggle(NSLocalizedString("form.is_trial", comment: ""), isOn: $isTrial)

                    Picker(NSLocalizedString("form.reminder_lead", comment: ""), selection: $reminderDaysBefore) {
                        Text(NSLocalizedString("reminder.1_day", comment: "")).tag(1)
                        Text(NSLocalizedString("reminder.3_days", comment: "")).tag(3)
                        Text(NSLocalizedString("reminder.7_days", comment: "")).tag(7)
                        Text(NSLocalizedString("reminder.14_days", comment: "")).tag(14)
                    }
                }

                Section(NSLocalizedString("form.notes", comment: "")) {
                    TextField(NSLocalizedString("form.notes_placeholder", comment: ""), text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let existingItem {
                    Section {
                        Button(role: .destructive) {
                            NotificationManager.shared.cancelReminder(for: existingItem.id)
                            modelContext.delete(existingItem)
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label(NSLocalizedString("action.delete", comment: ""), systemImage: "trash")
                                    .font(.body.weight(.semibold))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing
                ? NSLocalizedString("form.edit_title", comment: "")
                : NSLocalizedString("form.new_title", comment: "")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("action.cancel", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("action.save", comment: "")) {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear(perform: populateInitialValues)
        }
    }

    private func populateInitialValues() {
        if let item = existingItem {
            name = item.name
            amountText = String(format: item.currency.usesDecimals ? "%.2f" : "%.0f", item.amount)
            currency = item.currency
            billingCycle = item.billingCycle
            category = item.category
            nextBillingDate = item.nextBillingDate
            reminderDaysBefore = item.reminderDaysBefore
            isTrial = item.isTrial
            notes = item.notes
            iconSymbol = item.iconSymbol
            colorHex = item.colorHex
        } else {
            currency = defaultCurrency
        }
    }

    private func applyPreset(_ preset: ServicePreset) {
        name = preset.name
        amountText = String(format: "%.2f", preset.defaultAmount)
        currency = preset.currency
        billingCycle = preset.cycle
        category = preset.category
        iconSymbol = preset.symbol
        colorHex = preset.colorHex
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = parsedAmount ?? 0
        let target: SubscriptionItem

        if let existingItem {
            existingItem.name = trimmedName
            existingItem.amount = amount
            existingItem.currency = currency
            existingItem.billingCycle = billingCycle
            existingItem.category = category
            existingItem.nextBillingDate = nextBillingDate
            existingItem.reminderDaysBefore = reminderDaysBefore
            existingItem.isTrial = isTrial
            existingItem.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            existingItem.iconSymbol = iconSymbol
            existingItem.colorHex = colorHex
            target = existingItem
        } else {
            let newItem = SubscriptionItem(
                name: trimmedName,
                amount: amount,
                currency: currency,
                billingCycle: billingCycle,
                category: category,
                nextBillingDate: nextBillingDate,
                reminderDaysBefore: reminderDaysBefore,
                isTrial: isTrial,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                iconSymbol: iconSymbol,
                colorHex: colorHex
            )
            modelContext.insert(newItem)
            target = newItem
        }

        Task {
            _ = await NotificationManager.shared.requestAuthorization()
            await NotificationManager.shared.scheduleReminder(for: target)
        }
        dismiss()
    }
}
