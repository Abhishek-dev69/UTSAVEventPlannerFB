//
//  EstimateCartViewController.swift
//  FINAL — corrected & updated
//

import UIKit

// -------------------------------------------------------------
// MARK: - PaddedLabel
// -------------------------------------------------------------
final class PaddedLabel: UILabel {
    var contentInset: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        let inset = rect.inset(by: contentInset)
        super.drawText(in: inset)
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + contentInset.left + contentInset.right,
            height: base.height + contentInset.top + contentInset.bottom
        )
    }
}

// -------------------------------------------------------------
// MARK: UILabel convenience init
// -------------------------------------------------------------
extension UILabel {
    convenience init(text: String) {
        self.init(frame: .zero)
        self.text = text
        self.font = .systemFont(ofSize: 14)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

// -------------------------------------------------------------
// MARK: - EstimateCartViewController
// -------------------------------------------------------------
final class EstimateCartViewController: UIViewController {

    // MARK: UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let servicesHeader = AccordionHeaderView(icon: UIImage(systemName: "tray.fill"), title: "Services")
    private let servicesCard = UIStackView()

    private let outsourcedHeader = AccordionHeaderView(icon: UIImage(systemName: "shippingbox.fill"), title: "Outsourced")
    private let outsourcedCard = UIStackView()

    private let summaryCard = CardView()
    private let subtotalLabel = UILabel()
    private let taxField = UITextField()
    private let taxAmountLabel = UILabel()
    private let discountField = UITextField()
    private let grandTotalLabel = UILabel()

    private let paymentCard = CardView()
    private let partialPercentField = UITextField()
    private let customAmountField = UITextField()

    private let balanceLabel: PaddedLabel = {
        let l = PaddedLabel()
        l.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Bottom Buttons Area
    private let bottomContainer = UIView()
    private let saveDraftBtn = UIButton(type: .system)
    private let sendQuotationBtn = UIButton(type: .system)
    private let confirmOrderBtn = UIButton(type: .system)

    // MARK: Data
    private var servicesItems: [CartItem] { CartManager.shared.items.filter { $0.sourceType == "in_house" } }
    private var outsourcedItems: [CartItem] { CartManager.shared.items.filter { $0.sourceType == "outsource" } }

    private var taxPercent: Double { Double(taxField.text ?? "") ?? 0 }

    private lazy var currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₹"
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = "Estimate for Approval"

        setupScroll()
        setupSections()
        setupSummary()
        setupPayment()
        setupBottomButtons()
        setupKeyboardNotifications()
        setupKeyboardDismissRecognizer()   // 👈 NEW — dismiss keyboard on any tap

        CartManager.shared.addObserver(self)

        rebuildCards()
        updateSummary()
    }

    deinit {
        CartManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func closeTapped() {
        if let nav = navigationController, nav.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // -------------------------------------------------------------
    // MARK: - Keyboard handling
    // -------------------------------------------------------------
    private func setupKeyboardDismissRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingForced))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingForced() { view.endEditing(true) }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scroll.contentInset.bottom = frame.height + 40
        scroll.scrollIndicatorInsets = scroll.contentInset
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        scroll.contentInset.bottom = 0
        scroll.scrollIndicatorInsets = scroll.contentInset
    }

    // -------------------------------------------------------------
    // MARK: Scroll Setup
    // -------------------------------------------------------------
    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        ])

        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    // -------------------------------------------------------------
    // MARK: Sections (Accordion)
    // -------------------------------------------------------------
    private func setupSections() {
        content.addArrangedSubview(servicesHeader)
        let sContainer = addCard(for: servicesCard)
        content.addArrangedSubview(sContainer)

        servicesHeader.onToggle = { open in sContainer.isHidden = !open }

        content.addArrangedSubview(outsourcedHeader)
        let oContainer = addCard(for: outsourcedCard)
        content.addArrangedSubview(oContainer)

        outsourcedHeader.onToggle = { open in oContainer.isHidden = !open }
    }

    private func addCard(for stack: UIStackView) -> CardView {
        let container = CardView()
        container.isHidden = true

        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        container.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor)
        ])

        return container
    }

    // -------------------------------------------------------------
    // MARK: Summary card
    // -------------------------------------------------------------
    private func setupSummary() {
        let title = UILabel(text: "Summary")
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        subtotalLabel.font = .systemFont(ofSize: 14)
        taxAmountLabel.font = .systemFont(ofSize: 14)

        taxField.borderStyle = .roundedRect
        taxField.keyboardType = .decimalPad
        taxField.placeholder = "0"   // 👈 changed from "8.25"
        taxField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        taxField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        discountField.borderStyle = .roundedRect
        discountField.keyboardType = .decimalPad
        discountField.placeholder = "0"
        discountField.widthAnchor.constraint(equalToConstant: 90).isActive = true
        discountField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        grandTotalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        grandTotalLabel.textColor = UIColor(red: 140/255, green: 77/255, blue: 246/255, alpha: 1)

        let subtotalRow = lineRow(label: "Subtotal", right: subtotalLabel)

        let taxRow = UIStackView(arrangedSubviews: [
            UILabel(text: "Tax (%)"),
            taxField,
            UIView(),
            taxAmountLabel
        ])
        taxRow.axis = .horizontal
        taxRow.spacing = 8
        taxRow.alignment = .center

        let discountRow = UIStackView(arrangedSubviews: [
            UILabel(text: "Discount (₹)"),
            discountField
        ])
        discountRow.axis = .horizontal
        discountRow.spacing = 8

        let grandRow = lineRow(label: "Grand Total", right: grandTotalLabel)

        let stack = UIStackView(arrangedSubviews: [
            title,
            subtotalRow,
            taxRow,
            discountRow,
            grandRow
        ])
        stack.axis = .vertical
        stack.spacing = 14

        summaryCard.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: summaryCard.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: summaryCard.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: summaryCard.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: summaryCard.contentView.bottomAnchor, constant: -12)
        ])

        content.addArrangedSubview(summaryCard)
    }

    // -------------------------------------------------------------
    // MARK: Payment card
    // -------------------------------------------------------------
    private func setupPayment() {
        let title = UILabel(text: "Payment Details")
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        partialPercentField.borderStyle = .roundedRect
        partialPercentField.keyboardType = .decimalPad
        partialPercentField.placeholder = "30"
        partialPercentField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        partialPercentField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        customAmountField.borderStyle = .roundedRect
        customAmountField.keyboardType = .decimalPad
        customAmountField.placeholder = "Custom"
        customAmountField.widthAnchor.constraint(equalToConstant: 90).isActive = true
        customAmountField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        let row = UIStackView(arrangedSubviews: [
            partialPercentField,
            UILabel(text: "% or ₹"),
            customAmountField
        ])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center

        balanceLabel.backgroundColor = UIColor(red: 241/255, green: 237/255, blue: 255/255, alpha: 1)
        balanceLabel.layer.cornerRadius = 8
        balanceLabel.layer.masksToBounds = true

        let stack = UIStackView(arrangedSubviews: [
            title,
            UILabel(text: "Capture Partial Payment"),
            row,
            balanceLabel
        ])
        stack.axis = .vertical
        stack.spacing = 14

        paymentCard.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: paymentCard.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: paymentCard.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: paymentCard.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: paymentCard.contentView.bottomAnchor, constant: -12)
        ])

        content.addArrangedSubview(paymentCard)
    }

    // -------------------------------------------------------------
    // MARK: Bottom Buttons
    // -------------------------------------------------------------
    private func setupBottomButtons() {
        NSLayoutConstraint.activate([
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: 140)
        ])

        let topRow = UIStackView(arrangedSubviews: [
            saveDraftBtn, sendQuotationBtn
        ])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        saveDraftBtn.setTitle("Save Draft", for: .normal)
        saveDraftBtn.layer.cornerRadius = 20
        saveDraftBtn.backgroundColor = UIColor(white: 0.9, alpha: 1)

        sendQuotationBtn.setTitle("Send Quotation", for: .normal)
        sendQuotationBtn.layer.cornerRadius = 20
        sendQuotationBtn.setTitleColor(.white, for: .normal)
        sendQuotationBtn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)

        confirmOrderBtn.setTitle("Confirm Order", for: .normal)
        confirmOrderBtn.layer.cornerRadius = 24
        confirmOrderBtn.setTitleColor(.white, for: .normal)
        confirmOrderBtn.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        confirmOrderBtn.addTarget(self, action: #selector(confirmOrderTapped), for: .touchUpInside)

        bottomContainer.addSubview(topRow)
        bottomContainer.addSubview(confirmOrderBtn)

        topRow.translatesAutoresizingMaskIntoConstraints = false
        confirmOrderBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topRow.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            topRow.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            topRow.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 12),
            topRow.heightAnchor.constraint(equalToConstant: 44),

            confirmOrderBtn.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            confirmOrderBtn.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            confirmOrderBtn.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 12),
            confirmOrderBtn.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // -------------------------------------------------------------
    // MARK: Build Cards
    // -------------------------------------------------------------
    private func rebuildCards() {
        servicesCard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        outsourcedCard.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in servicesItems {
            servicesCard.addArrangedSubview(makeCardItem(item))
        }
        if servicesItems.isEmpty {
            servicesCard.addArrangedSubview(UILabel(text: "No items"))
        }

        for item in outsourcedItems {
            outsourcedCard.addArrangedSubview(makeCardItem(item))
        }
        if outsourcedItems.isEmpty {
            outsourcedCard.addArrangedSubview(UILabel(text: "No items"))
        }
    }

    private func makeCardItem(_ item: CartItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        card.layer.borderWidth = 0.6
        card.translatesAutoresizingMaskIntoConstraints = false

        // Show serviceName for outsourced items, subserviceName for in-house ones
        let titleText: String = (item.sourceType == "outsource") ? item.serviceName : item.subserviceName
        let title = UILabel(text: titleText)
        title.font = .systemFont(ofSize: 15, weight: .semibold)

        // Info button (SF Symbol) to show detailed requirements (subserviceName)
        let infoBtn = UIButton(type: .system)
        infoBtn.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoBtn.tintColor = UIColor(white: 0.3, alpha: 1)
        infoBtn.translatesAutoresizingMaskIntoConstraints = false
        infoBtn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        infoBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        infoBtn.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.showDetailsPopup(title: item.serviceName, details: item.subserviceName)
        }), for: .touchUpInside)

        // Delete uses canonical subserviceId for safety
        let del = UIButton(type: .system)
        del.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        del.tintColor = .systemRed
        del.addAction(UIAction { _ in
            CartManager.shared.removeItem(subserviceId: item.subserviceId)
        }, for: .touchUpInside)

        let rate = textField(text: "\(Int(item.rate))", width: 80)
        let qty = textField(text: "\(item.quantity)", width: 60)
        qty.keyboardType = .numberPad

        let subtotalVal = currencyFormatter.string(from: NSNumber(value: item.lineTotal)) ?? "₹0"
        let subtotal = UILabel(text: subtotalVal)
        subtotal.font = .systemFont(ofSize: 14, weight: .semibold)

        let rateStack = vertical(label: "Rate", control: rate)
        let qtyStack = vertical(label: "Qty", control: qty)
        let subtotalStack = vertical(label: "Subtotal", control: subtotal)

        rate.tag = tagFor(item)
        qty.tag = tagFor(item)

        rate.addTarget(self, action: #selector(rateChanged(_:)), for: .editingDidEnd)
        qty.addTarget(self, action: #selector(qtyChanged(_:)), for: .editingDidEnd)

        // Title row: title + info button + spacer + delete
        let leftTitleStack = UIStackView(arrangedSubviews: [title, infoBtn])
        leftTitleStack.axis = .horizontal
        leftTitleStack.spacing = 8
        leftTitleStack.alignment = .center

        let topRow = UIStackView(arrangedSubviews: [leftTitleStack, UIView(), del])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let values = UIStackView(arrangedSubviews: [rateStack, qtyStack, subtotalStack])
        values.axis = .horizontal
        values.spacing = 12
        values.alignment = .center

        let stack = UIStackView(arrangedSubviews: [topRow, values])
        stack.axis = .vertical
        stack.spacing = 12

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

    private func showDetailsPopup(title: String, details: String) {
        let alert = UIAlertController(title: title.isEmpty ? "Details" : title, message: details.isEmpty ? "No details provided." : details, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func textField(text: String, width: CGFloat) -> UITextField {
        let t = UITextField()
        t.text = text
        t.borderStyle = .roundedRect
        t.translatesAutoresizingMaskIntoConstraints = false
        t.widthAnchor.constraint(equalToConstant: width).isActive = true
        return t
    }

    private func vertical(label: String, control: UIView) -> UIStackView {
        let lbl = UILabel(text: label)
        lbl.font = .systemFont(ofSize: 12)

        let v = UIStackView(arrangedSubviews: [lbl, control])
        v.axis = .vertical
        v.spacing = 6
        return v
    }

    // -------------------------------------------------------------
    // MARK: Summary Calculation
    // -------------------------------------------------------------
    @objc private func updateSummaryAction() { updateSummary() }

    private func updateSummary() {
        let subtotal = CartManager.shared.totalAmount()
        subtotalLabel.text = currencyFormatter.string(from: NSNumber(value: subtotal))

        let taxValue = subtotal * (taxPercent / 100)
        taxAmountLabel.text = currencyFormatter.string(from: NSNumber(value: taxValue))

        let discount = Double(discountField.text ?? "") ?? 0
        let grand = subtotal + taxValue - discount

        grandTotalLabel.text = currencyFormatter.string(from: NSNumber(value: grand))

        updateBalance(for: grand)
    }

    private func updateBalance(for total: Double) {
        let custom = Double(customAmountField.text ?? "") ?? 0
        if custom > 0 {
            let remain = total - custom
            balanceLabel.text =
                "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: remain)) ?? "₹0")"
            return
        }

        let p = Double(partialPercentField.text ?? "") ?? 0
        if p > 0 {
            let paid = total * p / 100
            let remain = total - paid
            balanceLabel.text =
                "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: remain)) ?? "₹0")"
            return
        }

        balanceLabel.text =
            "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: total)) ?? "₹0")"
    }

    // -------------------------------------------------------------
    // MARK: Rate/Qty change
    // -------------------------------------------------------------
    private func tagFor(_ item: CartItem) -> Int {
        (item.serviceName.hashValue ^ item.subserviceName.hashValue) & 0x7FFFFFFF
    }

    private func itemForTag(_ tag: Int) -> CartItem? {
        CartManager.shared.items.first { tagFor($0) == tag }
    }

    @objc private func rateChanged(_ tf: UITextField) {
        guard let item = itemForTag(tf.tag) else { return }
        let newRate = Double(tf.text ?? "") ?? 0

        // Use canonical subserviceId when replacing item
        CartManager.shared.removeItem(subserviceId: item.subserviceId)

        CartManager.shared.addItem(
            serviceId: item.serviceId,
            serviceName: item.serviceName,
            subserviceId: item.subserviceId,
            subserviceName: item.subserviceName,
            rate: newRate,
            unit: item.unit,
            quantity: item.quantity,
            sourceType: item.sourceType
        )

        rebuildCards()
        updateSummary()
    }

    @objc private func qtyChanged(_ tf: UITextField) {
        guard let item = itemForTag(tf.tag) else { return }
        let qty = Int(tf.text ?? "") ?? 0

        // Use canonical setter by subserviceId
        CartManager.shared.setQuantity(subserviceId: item.subserviceId, quantity: qty)

        rebuildCards()
        updateSummary()
    }

    // -------------------------------------------------------------
    // MARK: Confirm Order
    // -------------------------------------------------------------
    @objc private func confirmOrderTapped() {
        UserDefaults.standard.set(true, forKey: "event_registered")

        Task {
            do {
                guard let eventId = EventSession.shared.currentEventId else {
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "Missing Event",
                            message: "Please fill event details before confirming.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }

                try await EventSupabaseManager.shared.linkCartItemsToEvent(eventId: eventId)

                await MainActor.run {
                    let scenes = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }

                    guard let window = scenes.first?.windows.first(where: { $0.isKeyWindow }),
                          let root = window.rootViewController else {
                        self.view.window?.rootViewController?.dismiss(animated: false)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadEventsDashboard"), object: nil)
                        return
                    }

                    if let tab = root as? UITabBarController {
                        tab.dismiss(animated: false)
                        tab.selectedIndex = 0
                        if let nav = tab.selectedViewController as? UINavigationController {
                            nav.popToRootViewController(animated: false)
                        }
                    } else if let nav = root as? UINavigationController {
                        nav.popToRootViewController(animated: false)
                        nav.dismiss(animated: false)
                    } else {
                        root.dismiss(animated: false)
                    }

                    self.presentingViewController?.dismiss(animated: false)
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadEventsDashboard"), object: nil)
                }

            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // -------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------
    private func lineRow(label: String, right: UIView) -> UIStackView {
        let lbl = UILabel(text: label)
        let row = UIStackView(arrangedSubviews: [lbl, UIView(), right])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }
}

// -------------------------------------------------------------
// MARK: Observer
// -------------------------------------------------------------
extension EstimateCartViewController: CartObserver {
    func cartDidChange() {
        rebuildCards()
        updateSummary()
    }
}

// -------------------------------------------------------------
// MARK: CardView
// -------------------------------------------------------------
final class CardView: UIView {
    let contentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowOpacity = 0.06
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// -------------------------------------------------------------
// MARK: AccordionHeaderView
// -------------------------------------------------------------
final class AccordionHeaderView: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    var onToggle: ((Bool) -> Void)?
    private(set) var isOpen = false

    init(icon: UIImage?, title: String) {
        super.init(frame: .zero)
        iconView.image = icon
        titleLabel.text = title
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let card = CardView()
        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        iconView.tintColor = UIColor(red: 26/255, green: 115/255, blue: 232/255, alpha: 1)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), chevron])
        h.axis = .horizontal
        h.spacing = 12
        h.alignment = .center
        h.translatesAutoresizingMaskIntoConstraints = false

        card.contentView.addSubview(h)

        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        card.contentView.addGestureRecognizer(tap)
    }

    @objc private func toggle() {
        isOpen.toggle()

        UIView.animate(withDuration: 0.25) {
            self.chevron.transform = self.isOpen
                ? CGAffineTransform(rotationAngle: .pi / 2)
                : .identity
        }

        onToggle?(isOpen)
    }
}

