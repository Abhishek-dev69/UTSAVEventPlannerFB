//
// EventOverviewViewController.swift
//

import UIKit

final class EventOverviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var event: EventRecord

    // Data (use your Supabase model names)
    private var cartItems: [CartItemRecord] = []
    private var inhouseItems: [CartItemRecord] = []
    private var outsourceItems: [CartItemRecord] = []
    private var totalAmount: Double = 0.0
    private var receivedAmount: Double = 0.0   // payments total

    // MARK: Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("Use init(event:)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupScroll()

        Task {
            await loadCartAndPayments()
        }
    }

    private func setupNav() {
        navigationItem.title = event.eventName

        let backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        backItem.tintColor = .black
        navigationItem.leftBarButtonItem = backItem

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: Load Cart & Payments
    @MainActor
    private func loadCartAndPayments() async {
        do {
            // 1) cart: use EventDataManager
            let items = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            self.cartItems = items

            // 2) payments: use EventDataManager
            let payments = try await EventDataManager.shared.fetchPayments(eventId: event.id)
            self.receivedAmount = payments.reduce(0.0) { $0 + ($1.amount) }

            // 3) compute derived data
            computeFromCart()

            // 4) build UI
            buildAllSections()
        } catch {
            print("Error loading event overview data:", error)
            // show minimal UI so user can still navigate
            computeFromCart()
            buildAllSections()
        }
    }

    // MARK: Helpers to read fields robustly from CartItemRecord
    // These assume CartItemRecord exposes Swift properties if you use JSONDecoder.convertFromSnakeCase.
    // If your model uses other names, adjust accordingly.

    /// Decide the source type string for an item with fallbacks:
    /// 1) item.sourceType (preferred)
    /// 2) metadata["type"] if present
    /// 3) serviceName text check for "outsource"
    /// default: "in_house"
    private func sourceTypeString(for item: CartItemRecord) -> String {
        // 1) direct property (common when using convertFromSnakeCase)
        if let s = item.sourceType, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s.lowercased()
        }

        // 2) metadata (if recorded)
        if let meta = item.metadata,
           let t = meta["type"],
           !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return t.lowercased()
        }

        // 3) fallback: check service name text (serviceName may be optional)
        let svc = (item.serviceName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if svc.contains("outsource") || svc.contains("outsourced") {
            return "outsource"
        }

        // default
        return "in_house"
    }

    /// Compute a single item's line total safely:
    /// prefer stored lineTotal (if present) else compute rate * quantity
    private func lineTotalValue(for item: CartItemRecord) -> Double {
        // prefer stored line total if present
        if let stored = item.lineTotal {
            return stored
        }

        // otherwise compute from rate and quantity
        // handle rate as Double (most likely) and quantity as Int (optional)
        let r = item.rate ?? 0.0
        let q = Double(item.quantity ?? 0)
        return r * q
    }

    // MARK: Data compute (adapts to your CartItemRecord fields)
    private func computeFromCart() {

        // Grouping rule: treat items whose sourceType indicates outsource OR whose serviceName contains "outsource" as outsourced
        inhouseItems = cartItems.filter {
            let s = sourceTypeString(for: $0)
            return s == "in_house" || s == "inhouse"
        }
        outsourceItems = cartItems.filter {
            let s = sourceTypeString(for: $0)
            return s == "outsource" || s == "outsourced"
        }

        // Compute totals:
        // Prefer stored lineTotal if present, otherwise calculate rate * quantity
        totalAmount = cartItems.reduce(0.0) { (acc: Double, item: CartItemRecord) -> Double in
            let line = self.lineTotalValue(for: item)
            return acc + line
        }
    }

    // MARK: Build UI Sections
    private func buildAllSections() {
        // Clear previous
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        addClientRequirements()
        addBudgetCheckIn()
        addPaymentStatus()
        addInventory()
    }

    private func addClientRequirements() {
        let inhouseCount = inhouseItems.count
        let outsourceCount = outsourceItems.count
        let subtitle = "\(inhouseCount) in-house · \(outsourceCount) outsourced"

        let card = EventSectionCard(
            iconName: "checklist",
            title: "Client Requirements",
            subtitle: subtitle,
            progress: computeProgressForRequirements(),
            buttonTitle: "Open"
        ) { [weak self] in
            guard let self = self else { return }

            let vc = ClientRequirementsViewController(
                event: self.event,
                cartItems: self.cartItems
            )
            self.navigationController?.pushViewController(vc, animated: true)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addBudgetCheckIn() {
        // If you have budget in event (budgetInPaise), convert to rupees
        let budgetInPaise = event.budgetInPaise
        let budgetRupees = Double(budgetInPaise) / 100.0
        // For now we use payments as a placeholder for "spent"; you will replace with budget_entries later
        let spentPlaceholder = receivedAmount
        let subtitle = "Spent ₹\(formatMoney(spentPlaceholder)) of ₹\(formatMoney(budgetRupees))"

        let progressFloat: Float = budgetRupees > 0 ? Float(spentPlaceholder / budgetRupees) : 0.0

        let card = EventSectionCard(
            iconName: "indianrupeesign.circle",
            title: "Budget Check-in",
            subtitle: subtitle,
            progress: progressFloat,
            buttonTitle: "Open"
        ) {
            // TODO: open Budget screen (when implemented)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addPaymentStatus() {

        let percentage = totalAmount > 0 ? (receivedAmount / totalAmount) : 0.0
        let subtitle = "Received ₹\(formatMoney(receivedAmount)) of ₹\(formatMoney(totalAmount)) (\(Int(percentage * 100))%)"

        let card = EventSectionCard(
            iconName: "rupeesign.circle",
            title: "Payment Status",
            subtitle: subtitle,
            progress: Float(percentage),
            buttonTitle: "Open"
        ) { [weak self] in
            guard let self = self else { return }

            let vc = PaymentListViewController(event: self.event)
            self.navigationController?.pushViewController(vc, animated: true)
        }

        contentStack.addArrangedSubview(card)
    }
    private func addInventory() {
        let card = EventSectionCard(
            iconName: "shippingbox",
            title: "Inventory Overview",
            subtitle: "Manage items & usage",
            progress: 0.0,
            buttonTitle: "Open"
        ) { [weak self] in
            guard let self = self else { return }
            let vc = InventoryOverviewViewController(event: self.event)
            self.navigationController?.pushViewController(vc, animated: true)
        }

        contentStack.addArrangedSubview(card)
    }
    // Simple requirement progress heuristic (replace with real logic later)
    private func computeProgressForRequirements() -> Float {
        let total = max(1, cartItems.count) // avoid divide by zero
        let done = Double(inhouseItems.count + outsourceItems.count) // placeholder: treat all added as "done"
        return Float(min(1.0, done / Double(total)))
    }

    private func formatMoney(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "0"
    }
}

