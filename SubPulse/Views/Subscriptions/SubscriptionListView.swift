import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let items: [SubscriptionItem]
    let baseCurrency: Currency
    let onShowPaywall: () -> Void

    @State private var searchText = ""
    @State private var selectedCategory: SubscriptionCategory?
    @State private var showingAddForm = false
    @State private var editingItem: SubscriptionItem?
    @State private var renewCelebrationTick = 0
    @Namespace private var filterNamespace

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
        ZStack {
            AmbientBackgroundView(
                accent: Color(hex: "#2563EB"),
                secondaryAccent: Color(hex: "#8B5CF6")
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerBar
                    searchBar

                    if !storeManager.isPro {
                        freeTierCard
                            .scrollCardMotion()
                    }

                    if !items.isEmpty {
                        categoryFilterBar
                    }

                    if filteredItems.isEmpty {
                        emptyStateCard
                            .padding(.top, 20)
                    } else if horizontalSizeClass == .regular {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredItems) { item in
                                subscriptionCard(item)
                                    .scrollCardMotion()
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    ))
                            }
                        }
                        .animation(AppMotion.bouncy, value: filteredItems.map(\.id))
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                subscriptionCard(item)
                                    .scrollCardMotion()
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    ))
                            }
                        }
                        .animation(AppMotion.bouncy, value: filteredItems.map(\.id))
                    }

                    Spacer().frame(height: 92)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 960 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 18)
                .padding(.top, 10)
            }
            .scrollBounceBehavior(.always)
        }
        .topSafeAreaScrim()
        .sensoryFeedback(.success, trigger: renewCelebrationTick)
        .sheet(isPresented: $showingAddForm) {
            SubscriptionFormView(
                existingItem: nil,
                defaultCurrency: baseCurrency
            )
        }
        .sheet(item: $editingItem) { item in
            SubscriptionFormView(
                existingItem: item,
                defaultCurrency: baseCurrency
            )
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Text(NSLocalizedString("tab.subscriptions", comment: ""))
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Spacer()
            Button(action: handleAddTapped) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#2563EB"), Color(hex: "#6366F1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: Color(hex: "#4F46E5").opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(BouncyButtonStyle(scale: 0.88))
            .accessibilityLabel(NSLocalizedString("subs.add_first", comment: ""))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(NSLocalizedString("subs.search_prompt", comment: ""), text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    withAnimation(AppMotion.snappy) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.75)
        )
    }

    private var freeTierCard: some View {
        let ratio = min(1.0, Double(items.count) / Double(AppConfig.freeSubscriptionLimit))
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.16))
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(
                        format: NSLocalizedString("subs.free_quota", comment: ""),
                        items.count,
                        AppConfig.freeSubscriptionLimit
                    ))
                    .font(.subheadline.weight(.bold))
                    Text(NSLocalizedString("subs.free_quota_desc", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                Button(action: onShowPaywall) {
                    Text(NSLocalizedString("paywall.upgrade_short", comment: ""))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(BouncyButtonStyle(scale: 0.92))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.orange.opacity(0.14))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF5E3A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * ratio))
                        .animation(AppMotion.bouncy, value: ratio)
                }
            }
            .frame(height: 6)
        }
        .tactileCard(cornerRadius: 22, padding: 16)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: NSLocalizedString("filter.all", comment: ""), isSelected: selectedCategory == nil) {
                    withAnimation(AppMotion.bouncy) {
                        selectedCategory = nil
                    }
                }
                ForEach(SubscriptionCategory.allCases) { category in
                    filterChip(title: category.localizedTitle, isSelected: selectedCategory == category) {
                        withAnimation(AppMotion.bouncy) {
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#2563EB"), Color(hex: "#6366F1")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .matchedGeometryEffect(id: "categoryPill", in: filterNamespace)
                    } else {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
        }
        .buttonStyle(BouncyButtonStyle(scale: 0.94))
    }

    private func subscriptionCard(_ item: SubscriptionItem) -> some View {
        Button {
            editingItem = item
        } label: {
            SubscriptionRowView(item: item, baseCurrency: baseCurrency, showProgressBar: true)
                .tactileCard(cornerRadius: 22, padding: 16)
        }
        .buttonStyle(BouncyButtonStyle(scale: 0.975))
        .contextMenu {
            Button {
                markRenewed(item)
            } label: {
                Label(NSLocalizedString("action.mark_paid", comment: ""), systemImage: "checkmark.circle.fill")
            }

            Button {
                editingItem = item
            } label: {
                Label(NSLocalizedString("form.edit_title", comment: ""), systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label(NSLocalizedString("action.delete", comment: ""), systemImage: "trash")
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 68, height: 68)
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            Text(NSLocalizedString("subs.empty_title", comment: ""))
                .font(.headline.weight(.bold))
            Text(NSLocalizedString("subs.empty_desc", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: handleAddTapped) {
                Text(NSLocalizedString("subs.add_first", comment: ""))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#2563EB"), Color(hex: "#6366F1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
            }
            .buttonStyle(BouncyButtonStyle(scale: 0.94))
        }
        .frame(maxWidth: .infinity)
        .tactileCard(cornerRadius: 24, padding: 28)
    }

    private func handleAddTapped() {
        if canAddMore {
            showingAddForm = true
        } else {
            onShowPaywall()
        }
    }

    private func markRenewed(_ item: SubscriptionItem) {
        withAnimation(AppMotion.bouncy) {
            item.advanceBillingDate()
            renewCelebrationTick += 1
        }
        Task {
            await NotificationManager.shared.scheduleReminder(for: item)
        }
    }

    private func deleteItem(_ item: SubscriptionItem) {
        withAnimation(AppMotion.snappy) {
            NotificationManager.shared.cancelReminder(for: item.id)
            modelContext.delete(item)
        }
    }
}
