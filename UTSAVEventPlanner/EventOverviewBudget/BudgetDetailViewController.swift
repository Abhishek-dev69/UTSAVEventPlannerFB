import UIKit

final class BudgetDetailViewController: UIViewController {

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let budgetCard = UIView()
    private let searchField = UITextField()
    private let expensesContainer = UIStackView()

    // ✅ Professional Floating Button
    private let addExpenseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("＋ Add Expense", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = UIColor.utsavPurple
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 28
        b.translatesAutoresizingMaskIntoConstraints = false

        // Shadow (Premium Look)
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.25
        b.layer.shadowRadius = 10
        b.layer.shadowOffset = CGSize(width: 0, height: 6)

        return b
    }()

    // MARK: - DATA
    private var budgetEntries: [BudgetEntryRecord] = []
    private var totalSpent: Double = 0
    private var eventBudget: Double = 0

    // MARK: - Budget Card UI refs
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let remainingLabel = UILabel()
    private let spentLabel = UILabel()
    private let totalLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.98, alpha: 1)
        title = "Budget Overview"

        setupScroll()
        setupBudgetCard()
        setupSearch()
        setupExpenseList()
        setupFloatingButton()

        Task { await loadBudget() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadBudget() }
    }

    // MARK: - DATA LOADING
    private func loadBudget() async {
        guard let eventId = EventDataManager.shared.currentEventId else { return }

        do {
            let entries = try await EventDataManager.shared.fetchBudgetEntries(eventId: eventId)
            let cartItems = try await EventDataManager.shared.fetchCartItems(eventId: eventId)

            let totalCartAmount = cartItems.reduce(0) { sum, item in
                let lineTotal = item.lineTotal ?? ((item.rate ?? 0) * Double(item.quantity ?? 0))
                return sum + lineTotal
            }

            await MainActor.run {
                self.budgetEntries = entries
                self.totalSpent = entries.reduce(0) { $0 + $1.amount }
                self.eventBudget = totalCartAmount
                self.reloadBudgetCard()
                self.reloadExpenses()
            }
        } catch {
            print("❌ Budget load failed:", error)
        }
    }

    // MARK: - UI SETUP

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -120),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Premium Budget Card
    private func setupBudgetCard() {
        budgetCard.backgroundColor = UIColor.utsavPurple
        budgetCard.layer.cornerRadius = 18
        budgetCard.layer.shadowColor = UIColor.black.cgColor
        budgetCard.layer.shadowOpacity = 0.15
        budgetCard.layer.shadowRadius = 12
        budgetCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        let titleLabel = UILabel()
        titleLabel.text = "REMAINING BALANCE"
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        remainingLabel.font = .systemFont(ofSize: 30, weight: .bold)
        remainingLabel.textColor = .white

        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.25)
        progressView.progressTintColor = .white

        spentLabel.font = .systemFont(ofSize: 13)
        spentLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        totalLabel.font = .systemFont(ofSize: 13)
        totalLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        totalLabel.textAlignment = .right

        let bottomStack = UIStackView(arrangedSubviews: [spentLabel, UIView(), totalLabel])
        bottomStack.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [titleLabel, remainingLabel, progressView, bottomStack])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        budgetCard.addSubview(stack)
        content.addArrangedSubview(budgetCard)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: budgetCard.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: budgetCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: budgetCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: budgetCard.bottomAnchor, constant: -20)
        ])
    }

    private func setupSearch() {
        searchField.placeholder = "Search expenses..."
        searchField.borderStyle = .roundedRect
        content.addArrangedSubview(searchField)
    }

    private func setupExpenseList() {
        let header = UILabel()
        header.text = "Expenses"
        header.font = .systemFont(ofSize: 18, weight: .semibold)

        expensesContainer.axis = .vertical
        expensesContainer.spacing = 12

        content.addArrangedSubview(header)
        content.addArrangedSubview(expensesContainer)
    }

    // ✅ Floating Button Layout
    private func setupFloatingButton() {
        view.addSubview(addExpenseButton)
        addExpenseButton.addTarget(self, action: #selector(addExpenseTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            addExpenseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addExpenseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addExpenseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            addExpenseButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - UI Updates
    private func reloadBudgetCard() {
        let remaining = max(eventBudget - totalSpent, 0)
        let progress = eventBudget == 0 ? 0 : Float(totalSpent / eventBudget)

        progressView.progress = progress
        remainingLabel.text = "₹\(Int(remaining))"
        spentLabel.text = "Spent: ₹\(Int(totalSpent))"
        totalLabel.text = "Total: ₹\(Int(eventBudget))"
    }

    private func reloadExpenses() {
        expensesContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for entry in budgetEntries {
            let subtitle = "Spent: ₹\(Int(entry.amount))"
            expensesContainer.addArrangedSubview(makeExpenseCard(title: entry.title, subtitle: subtitle))
        }
    }

    private func makeExpenseCard(title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 15, weight: .semibold)

        let s = UILabel()
        s.text = subtitle
        s.font = .systemFont(ofSize: 13)
        s.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [t, s])
        stack.axis = .vertical
        stack.spacing = 6

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    // MARK: - Bottom Sheet Add Expense
    @objc private func addExpenseTapped() {
        let vc = AddBudgetViewController(vendorName: nil)

        // ✅ CALLBACK WHEN EXPENSE IS ADDED
        vc.onExpenseAdded = { [weak self] in
            Task { await self?.loadBudget() }   // reload instantly
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22
        }

        present(nav, animated: true)
    }
}
