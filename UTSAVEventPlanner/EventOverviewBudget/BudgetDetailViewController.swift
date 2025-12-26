import UIKit

final class BudgetDetailViewController: UIViewController {

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let budgetCard = UIView()
    private let searchField = UITextField()
    private let expensesContainer = UIStackView()

    private let addPaymentsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Expense", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 26
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    // MARK: - DATA
    private var budgetEntries: [BudgetEntryRecord] = []
    private var totalSpent: Double = 0
    private var eventBudget: Double = 0

    // MARK: - Budget Card refs
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let amountLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.98, alpha: 1)
        title = "Budget Overview"

        setupScroll()
        setupBudgetCard()
        setupSearch()
        setupExpenseList()
        setupBottomButton()

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
            let event = try await EventSupabaseManager.shared.fetchEvent(id: eventId)

            await MainActor.run {
                self.budgetEntries = entries
                self.totalSpent = entries.reduce(0) { $0 + $1.amount }
                self.eventBudget = Double(event.budgetInPaise) / 100
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

    private func setupBudgetCard() {
        let title = UILabel()
        title.text = "Budget Overview"
        title.font = .systemFont(ofSize: 18, weight: .semibold)

        let util = UILabel()
        util.text = "Budget Utilization"
        util.font = .systemFont(ofSize: 14)
        util.textColor = .secondaryLabel

        progressView.trackTintColor = UIColor(white: 0.94, alpha: 1)
        progressView.progressTintColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)

        amountLabel.font = .systemFont(ofSize: 13)
        amountLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, util, progressView, amountLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        budgetCard.backgroundColor = .white
        budgetCard.layer.cornerRadius = 12
        budgetCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: budgetCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: budgetCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: budgetCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: budgetCard.bottomAnchor, constant: -16)
        ])

        content.addArrangedSubview(budgetCard)
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

    private func setupBottomButton() {
        view.addSubview(addPaymentsButton)
        addPaymentsButton.addTarget(self, action: #selector(addExpenseTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            addPaymentsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addPaymentsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
    }

    // MARK: - UI Updates

    private func reloadBudgetCard() {
        let progress = eventBudget == 0 ? 0 : Float(totalSpent / eventBudget)
        progressView.progress = progress
        amountLabel.text = "₹\(Int(totalSpent)) / ₹\(Int(eventBudget))"
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
        card.layer.cornerRadius = 10

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

    // MARK: - Actions
    @objc private func addExpenseTapped() {
        let vc = AddBudgetViewController(vendorName: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}

