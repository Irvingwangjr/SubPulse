import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    let items: [SubscriptionItem]
    let baseCurrency: Currency
    let onShowPaywall: () -> Void

    @State private var searchText = ""
    @State private var selectedCategory: SubscriptionCategory?
    @State private var showingAddForm = false
    @State private var editingItem: SubscriptionItem?

    private var canAddMore: Bool {
        storeManager.isPro || items.count < AppConfig.freeSubscriptionLimit
    }

    private var filteredItems: [SubscriptionItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !storeManager.isPro {
                    Section {
                        freeTierBanner
                    }
                }

                if !items.isEmpty {
                    Section {
                        categoryFilterBar
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label(NSLocalizedString("subs.empty_title", comment: ""), systemImage: "rectangle.stack.badge.plus")
                    } description: {
                        Text(NSLocalizedString("subs.empty_desc", comment: ""))
                    } actions: {
                        Button(NSLocalizedString("subs.add_first", comment: "")) {
                            handleAddTapped()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(filteredItems) { item in
                            Button {
                                editingItem = item
                            } label: {
                                SubscriptionRowView(item: item, baseCurrency: baseCurrency)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    markRenewed(item)
                                } label: {
                                    Label(NSLocalizedString("action.mark_paid", comment: ""), systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label(NSLocalizedString("action.delete", comment: ""), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: NSLocalizedString("subs.search_prompt", comment: ""))
            .navigationTitle(NSLocalizedString("tab.subscriptions", comment: ""))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: handleAddTapped) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                SubscriptionFormView(
                    existingItem: nil,
                    defaultCurrency: baseCurrency,
                    onShowPaywall: onShowPaywall
                )
            }
            .sheet(item: $editingItem) { item in
                SubscriptionFormView(
                    existingItem: item,
                    defaultCurrency: baseCurrency,
                    onShowPaywall: onShowPaywall
                )
            }
        }
    }

    private var freeTierBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(
                    format: NSLocalizedString("subs.free_quota", comment: ""),
                    items.count,
                    AppConfig.freeSubscriptionLimit
                ))
                .font(.subheadline.weight(.semibold))
                Text(NSLocalizedString("subs.free_quota_desc", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(NSLocalizedString("paywall.upgrade_short", comment: ""), action: onShowPaywall)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: NSLocalizedString("filter.all", comment: ""), isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(SubscriptionCategory.allCases) { category in
                    filterChip(title: category.localizedTitle, isSelected: selectedCategory == category) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func handleAddTapped() {
        if canAddMore {
            showingAddForm = true
        } else {
            onShowPaywall()
        }
    }

    private func markRenewed(_ item: SubscriptionItem) {
        item.advanceBillingDate()
        Task {
            await NotificationManager.shared.scheduleReminder(for: item)
        }
    }

    private func deleteItem(_ item: SubscriptionItem) {
        NotificationManager.shared.cancelReminder(for: item.id)
        modelContext.delete(item)
    }
}
