//
// BudgetDetailViewController.swift
// Vendor Budgets + Own Services toggle — static Figma-like UI
//

import UIKit

final class BudgetDetailViewController: UIViewController {

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let segmented = UISegmentedControl(items: ["Own Service", "Vendor Budgets"])
    private let budgetCard = UIView()
    private let searchField = UITextField()

    // containers for lists (we swap them on toggle)
    private let ownServicesContainer = UIStackView()
    private let vendorBudgetsContainer = UIStackView()

    // bottom Add Payments button
    private let addPaymentsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Payments", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 26
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    // MARK: - Static data
    private let ownServices: [(title: String, subtitle: String)] = [
        ("Catering", "Spent: ₹15,000 | Remaining: ₹5,000"),
        ("Decor", "Spent: ₹10,000 | Remaining: ₹5,000"),
        ("Transportation", "Spent: ₹5,000 | Remaining: ₹5,000")
    ]

    private let vendorBudgets: [(title: String, subtitle: String)] = [
        ("AV Equipment", "Paid: ₹35,000 | Left: ₹5,000"),
        ("Security", "Paid: ₹30,000 | Left: ₹5,000"),
        ("Transportation", "Paid: ₹5,000 | Left: ₹5,000")
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.98, alpha: 1)
        title = "Budget Overview"

        setupScroll()
        setupTopUI()
        setupLists()
        setupBottomButton()

        segmented.selectedSegmentIndex = 0
        updateListForSegment() // initial
    }

    // MARK: - Layout Setup

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
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
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -120), // give space for bottom button
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
    }

    private func setupTopUI() {
        // Segmented Control styling
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = 0
        segmented.backgroundColor = UIColor(white: 0.95, alpha: 1)
        segmented.layer.cornerRadius = 18
        segmented.addTarget(self, action: #selector(segmentedChanged(_:)), for: .valueChanged)
        content.addArrangedSubview(segmented)
        segmented.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Budget Card
        budgetCard.translatesAutoresizingMaskIntoConstraints = false
        budgetCard.backgroundColor = .white
        budgetCard.layer.cornerRadius = 12
        budgetCard.layer.shadowColor = UIColor.black.cgColor
        budgetCard.layer.shadowOpacity = 0.06
        budgetCard.layer.shadowRadius = 6
        budgetCard.layer.shadowOffset = CGSize(width: 0, height: 3)

        // Build budget card contents
        let title = UILabel()
        title.text = "Budget Overview"
        title.font = .systemFont(ofSize: 18, weight: .semibold)

        let util = UILabel()
        util.text = "Budget Utilization"
        util.font = .systemFont(ofSize: 14)
        util.textColor = .secondaryLabel

        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = UIColor(white: 0.94, alpha: 1)
        progress.progressTintColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        progress.progress = 0.71

        let amounts = UILabel()
        amounts.text = "₹85,000 / ₹120,000"
        amounts.font = .systemFont(ofSize: 13)
        amounts.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, util, progress, amounts])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        budgetCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: budgetCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: budgetCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: budgetCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: budgetCard.bottomAnchor, constant: -16),
            budgetCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 110)
        ])

        content.addArrangedSubview(budgetCard)

        // Search field
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholder = "Search Services..."
        searchField.borderStyle = .roundedRect
        searchField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        content.addArrangedSubview(searchField)
    }

    private func setupLists() {
        ownServicesContainer.axis = .vertical
        ownServicesContainer.spacing = 12
        ownServicesContainer.translatesAutoresizingMaskIntoConstraints = false

        vendorBudgetsContainer.axis = .vertical
        vendorBudgetsContainer.spacing = 12
        vendorBudgetsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Populate static cards
        for s in ownServices {
            let v = makeServiceCard(title: s.title, subtitle: s.subtitle)
            ownServicesContainer.addArrangedSubview(v)
        }

        for v in vendorBudgets {
            let vcard = makeServiceCard(title: v.title, subtitle: v.subtitle)
            // make vendor card tappable and tag/accessibility for identification
            vcard.isUserInteractionEnabled = true
            vcard.accessibilityLabel = v.title
            let tap = UITapGestureRecognizer(target: self, action: #selector(vendorCardTapped(_:)))
            vcard.addGestureRecognizer(tap)
            vendorBudgetsContainer.addArrangedSubview(vcard)
        }

        // Section header labels
        let ownHeader = UILabel()
        ownHeader.text = "Own Services Budgets"
        ownHeader.font = .systemFont(ofSize: 18, weight: .semibold)

        let vendorHeader = UILabel()
        vendorHeader.text = "Vendor Budgets"
        vendorHeader.font = .systemFont(ofSize: 18, weight: .semibold)

        // Wrap containers with header stacks
        let ownStack = UIStackView(arrangedSubviews: [ownHeader, ownServicesContainer])
        ownStack.axis = .vertical
        ownStack.spacing = 10

        let vendorStack = UIStackView(arrangedSubviews: [vendorHeader, vendorBudgetsContainer])
        vendorStack.axis = .vertical
        vendorStack.spacing = 10

        // We'll add both to content but hide the one not active (keeps constraints simple)
        content.addArrangedSubview(ownStack)
        content.addArrangedSubview(vendorStack)

        // Keep references so we can toggle visibility
        ownStack.tag = 1001
        vendorStack.tag = 1002

        // Initially show own, hide vendor
        ownStack.isHidden = segmented.selectedSegmentIndex != 0
        vendorStack.isHidden = segmented.selectedSegmentIndex != 1
    }

    private func setupBottomButton() {
        view.addSubview(addPaymentsButton)

        NSLayoutConstraint.activate([
            addPaymentsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addPaymentsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            addPaymentsButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 60),
            addPaymentsButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -60)
        ])

        // Attach action
        addPaymentsButton.addTarget(self, action: #selector(addPaymentsTapped), for: .touchUpInside)
    }

    // MARK: - Helpers

    private func makeServiceCard(title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 3)

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 15, weight: .semibold)

        let subtitleLbl = UILabel()
        subtitleLbl.text = subtitle
        subtitleLbl.font = .systemFont(ofSize: 13)
        subtitleLbl.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])

        return card
    }

    // MARK: - Actions

    @objc private func segmentedChanged(_ s: UISegmentedControl) {
        updateListForSegment(animated: true)
    }

    private func updateListForSegment(animated: Bool = false) {
        // Find the header stacks we inserted
        guard let ownStack = content.arrangedSubviews.first(where: { $0.tag == 1001 }),
              let vendorStack = content.arrangedSubviews.first(where: { $0.tag == 1002 }) else {
            // fallback: update by scanning for our containers
            ownServicesContainer.superview?.isHidden = segmented.selectedSegmentIndex != 0
            vendorBudgetsContainer.superview?.isHidden = segmented.selectedSegmentIndex != 1
            return
        }

        let showOwn = segmented.selectedSegmentIndex == 0
        let showVendor = !showOwn

        if animated {
            // Cross-fade
            UIView.animate(withDuration: 0.22) {
                ownStack.alpha = showOwn ? 1 : 0
                vendorStack.alpha = showVendor ? 1 : 0
            } completion: { _ in
                ownStack.isHidden = !showOwn
                vendorStack.isHidden = !showVendor
                ownStack.alpha = 1
                vendorStack.alpha = 1
            }
        } else {
            ownStack.isHidden = !showOwn
            vendorStack.isHidden = !showVendor
        }
    }

    @objc private func addPaymentsTapped() {
        // Present the AddBudgetViewController — use proper init signature (vendorName optional)
        let addVC = AddBudgetViewController(vendorName: nil)
        let nav = UINavigationController(rootViewController: addVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func vendorCardTapped(_ g: UITapGestureRecognizer) {
        guard let v = g.view, let vendorTitle = v.accessibilityLabel else { return }
        // Push AddBudgetViewController with vendor prefilled
        let addVC = AddBudgetViewController(vendorName: vendorTitle)
        navigationController?.pushViewController(addVC, animated: true)
    }
}

