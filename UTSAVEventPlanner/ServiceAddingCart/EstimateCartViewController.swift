//  EstimateCartViewController.swift
//  FINAL FIXED VERSION - corrected for sourceType and observer handling

import UIKit

// -------------------------------------------------------------
// MARK: - Padded Label (Used for balance row)
// -------------------------------------------------------------

final class PaddedLabel: UILabel {

    var contentInset: UIEdgeInsets = .zero

    convenience init(text: String,
                     padding: UIEdgeInsets = .zero,
                     font: UIFont = .systemFont(ofSize: 14)) {

        self.init(frame: .zero)
        self.text = text
        self.contentInset = padding
        self.font = font
        self.numberOfLines = 0
    }

    override func drawText(in rect: CGRect) {
        let inset = rect.inset(by: contentInset)
        super.drawText(in: inset)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }
}

// -------------------------------------------------------------
// MARK: Simple UILabel(text:) initializer
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
// MARK: EstimateCartViewController
// -------------------------------------------------------------

final class EstimateCartViewController: UIViewController {

    // MARK: UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let servicesHeader = AccordionHeaderView(
        icon: UIImage(systemName: "tray.fill"),
        title: "Services"
    )

    private let servicesCard = UIStackView()

    private let outsourcedHeader = AccordionHeaderView(
        icon: UIImage(systemName: "shippingbox.fill"),
        title: "Outsourced"
    )

    private let outsourcedCard = UIStackView()

    private let summaryCard = CardView()
    private let subtotalLabel = UILabel()
    private let taxLabel = UILabel()
    private let discountField = UITextField()
    private let grandTotalLabel = UILabel()

    private let paymentCard = CardView()
    private let partialPercentField = UITextField()
    private let customAmountField = UITextField()

    private let balanceLabel = PaddedLabel(
        text: "Balance Remaining",
        padding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 12),
        font: .systemFont(ofSize: 14, weight: .semibold)
    )

    // bottom buttons
    private let bottomContainer = UIView()
    private let saveDraftBtn = UIButton(type: .system)
    private let sendQuotationBtn = UIButton(type: .system)
    private let confirmOrderBtn = UIButton(type: .system)

    // MARK: Data
    // Use sourceType to split items — this is robust even when serviceName varies.
    private var servicesItems: [CartItem] {
        CartManager.shared.items.filter { $0.sourceType == "in_house" }
    }
    private var outsourcedItems: [CartItem] {
        CartManager.shared.items.filter { $0.sourceType == "outsource" }
    }

    private let taxPercent: Double = 8.25

    private lazy var currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₹"
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = "Estimate for Approval"

        setupScroll()
        setupSections()
        setupSummary()
        setupPayment()
        setupBottomButtons()

        // Register as observer so UI updates when cart changes.
        CartManager.shared.addObserver(self)

        // Build UI
        rebuildCards()
        updateSummary()
    }

    deinit { CartManager.shared.removeObserver(self) }

    // -------------------------------------------------------------
    // MARK: Setup ScrollView + Stack
    // -------------------------------------------------------------

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -140)
        ])

        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isLayoutMarginsRelativeArrangement = true

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
    // MARK: Setup Accordion Sections
    // -------------------------------------------------------------

    private func setupSections() {

        // ⭐ SERVICES HEADER
        content.addArrangedSubview(servicesHeader)

        servicesCard.axis = .vertical
        servicesCard.spacing = 12
        servicesCard.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        servicesCard.isLayoutMarginsRelativeArrangement = true

        let sContainer = CardView()
        sContainer.isHidden = true
        sContainer.isUserInteractionEnabled = false

        sContainer.contentView.addSubview(servicesCard)
        servicesCard.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            servicesCard.topAnchor.constraint(equalTo: sContainer.contentView.topAnchor),
            servicesCard.leadingAnchor.constraint(equalTo: sContainer.contentView.leadingAnchor),
            servicesCard.trailingAnchor.constraint(equalTo: sContainer.contentView.trailingAnchor),
            servicesCard.bottomAnchor.constraint(equalTo: sContainer.contentView.bottomAnchor)
        ])

        content.addArrangedSubview(sContainer)

        // Toggle behavior
        servicesHeader.onToggle = { [weak self] open in
            guard let self else { return }
            sContainer.isHidden = !open
            sContainer.isUserInteractionEnabled = open
            content.setCustomSpacing(open ? 16 : 0, after: servicesHeader)
        }

        // ⭐ OUTSOURCED HEADER
        content.addArrangedSubview(outsourcedHeader)

        outsourcedCard.axis = .vertical
        outsourcedCard.spacing = 12
        outsourcedCard.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        outsourcedCard.isLayoutMarginsRelativeArrangement = true

        let oContainer = CardView()
        oContainer.isHidden = true
        oContainer.isUserInteractionEnabled = false

        oContainer.contentView.addSubview(outsourcedCard)
        outsourcedCard.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            outsourcedCard.topAnchor.constraint(equalTo: oContainer.contentView.topAnchor),
            outsourcedCard.leadingAnchor.constraint(equalTo: oContainer.contentView.leadingAnchor),
            outsourcedCard.trailingAnchor.constraint(equalTo: oContainer.contentView.trailingAnchor),
            outsourcedCard.bottomAnchor.constraint(equalTo: oContainer.contentView.bottomAnchor)
        ])

        content.addArrangedSubview(oContainer)

        outsourcedHeader.onToggle = { [weak self] open in
            guard let self else { return }
            oContainer.isHidden = !open
            oContainer.isUserInteractionEnabled = open
            content.setCustomSpacing(open ? 16 : 0, after: outsourcedHeader)
        }
    }

    // -------------------------------------------------------------
    // MARK: Summary Card
    // -------------------------------------------------------------

    private func setupSummary() {
        let title = UILabel(text: "Summary")
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        discountField.placeholder = "₹0"
        discountField.borderStyle = .roundedRect
        discountField.keyboardType = .decimalPad
        discountField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        let subtotalRow = lineRow(label: "Subtotal", right: subtotalLabel)
        let taxRow = lineRow(label: "Tax (\(taxPercent)%)", right: taxLabel)

        let dLeft = UILabel(text: "Discount")
        let dContainer = UIView()
        dContainer.addSubview(dLeft)
        dContainer.addSubview(discountField)

        dLeft.translatesAutoresizingMaskIntoConstraints = false
        discountField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dLeft.leadingAnchor.constraint(equalTo: dContainer.leadingAnchor),
            dLeft.centerYAnchor.constraint(equalTo: dContainer.centerYAnchor),

            discountField.trailingAnchor.constraint(equalTo: dContainer.trailingAnchor),
            discountField.centerYAnchor.constraint(equalTo: dContainer.centerYAnchor),
            discountField.widthAnchor.constraint(equalToConstant: 120)
        ])

        grandTotalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        grandTotalLabel.textColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        let grandRow = lineRow(label: "Grand Total", right: grandTotalLabel)

        let stack = UIStackView(arrangedSubviews: [
            title, subtotalRow, taxRow, dContainer, UIView(), grandRow
        ])
        stack.axis = .vertical
        stack.spacing = 12

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
    // MARK: Payment Details
    // -------------------------------------------------------------

    private func setupPayment() {

        let title = UILabel(text: "Payment Details")
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        let capture = UILabel(text: "Capture Partial Payment")
        capture.font = .systemFont(ofSize: 13)
        capture.textColor = .secondaryLabel

        partialPercentField.placeholder = "30"
        partialPercentField.borderStyle = .roundedRect
        partialPercentField.keyboardType = .numberPad
        partialPercentField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        partialPercentField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        customAmountField.placeholder = "Custom"
        customAmountField.borderStyle = .roundedRect
        customAmountField.keyboardType = .decimalPad
        customAmountField.widthAnchor.constraint(equalToConstant: 120).isActive = true
        customAmountField.addTarget(self, action: #selector(updateSummaryAction), for: .editingChanged)

        let row = UIStackView(arrangedSubviews: [
            partialPercentField, UILabel(text: "% or ₹"), customAmountField
        ])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center

        balanceLabel.backgroundColor = UIColor(red: 241/255, green: 237/255, blue: 255/255, alpha: 1)
        balanceLabel.layer.cornerRadius = 8
        balanceLabel.layer.masksToBounds = true
        balanceLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [
            title, capture, row, balanceLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12

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
    // -------------------------------------------------------------
    // MARK: Confirm Order action (link cart items to created event)
    // -------------------------------------------------------------
    @objc private func confirmOrderTapped() {
        Task {
            do {
                // 1) ensure event exists
                guard let eventId = EventSession.shared.currentEventId else {
                    await MainActor.run {
                        let a = UIAlertController(
                            title: "Missing Event",
                            message: "Please fill event details before confirming.",
                            preferredStyle: .alert
                        )
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(a, animated: true)
                    }
                    return
                }

                // 2) link cart items to event (server)
                try await EventSupabaseManager.shared.linkCartItemsToEvent(eventId: eventId)

                // 3) NAVIGATION: Return to the app's Home (root tab) robustly
                await MainActor.run {
                    let scenes = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }

                    guard let window = scenes.first?.windows.first(where: { $0.isKeyWindow }),
                          let root = window.rootViewController else {
                        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadEventsDashboard"), object: nil)
                        return
                    }

                    if let tab = root as? UITabBarController {
                        tab.dismiss(animated: false, completion: nil)
                        tab.selectedIndex = 0
                        if let nav = tab.selectedViewController as? UINavigationController {
                            nav.popToRootViewController(animated: false)
                        }
                    } else {
                        if let nav = root as? UINavigationController {
                            nav.popToRootViewController(animated: false)
                            nav.dismiss(animated: false, completion: nil)
                        } else {
                            root.dismiss(animated: false, completion: nil)
                        }
                    }

                    self.presentingViewController?.dismiss(animated: false, completion: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadEventsDashboard"), object: nil)
                }

            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    private func setupBottomButtons() {

        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: 140)
        ])

        let topRow = UIStackView(arrangedSubviews: [saveDraftBtn, sendQuotationBtn])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        saveDraftBtn.setTitle("Save Draft", for: .normal)
        saveDraftBtn.backgroundColor = UIColor(white: 0.9, alpha: 1)
        saveDraftBtn.layer.cornerRadius = 20

        sendQuotationBtn.setTitle("Send Quotation", for: .normal)
        sendQuotationBtn.setTitleColor(.white, for: .normal)
        sendQuotationBtn.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        sendQuotationBtn.layer.cornerRadius = 20

        confirmOrderBtn.setTitle("Confirm Order", for: .normal)
        confirmOrderBtn.addTarget(self, action: #selector(confirmOrderTapped), for: .touchUpInside)
        confirmOrderBtn.setTitleColor(.white, for: .normal)
        confirmOrderBtn.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        confirmOrderBtn.layer.cornerRadius = 24

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

        for item in servicesItems { servicesCard.addArrangedSubview(makeCardItem(item)) }
        if servicesItems.isEmpty { servicesCard.addArrangedSubview(UILabel(text: "No items")) }

        for item in outsourcedItems { outsourcedCard.addArrangedSubview(makeCardItem(item)) }
        if outsourcedItems.isEmpty { outsourcedCard.addArrangedSubview(UILabel(text: "No items")) }
    }

    private func makeCardItem(_ item: CartItem) -> UIView {

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        card.layer.borderWidth = 0.6

        let title = UILabel(text: item.subserviceName)
        title.font = .systemFont(ofSize: 15, weight: .semibold)

        let del = UIButton(type: .system)
        del.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        del.tintColor = .systemRed

        del.addAction(UIAction { _ in
            CartManager.shared.removeItem(serviceName: item.serviceName, subserviceName: item.subserviceName)
        }, for: .touchUpInside)

        let rate = textField(text: String(Int(item.rate)), width: 80)
        let qty = textField(text: String(item.quantity), width: 60)
        qty.keyboardType = .numberPad

        let subtotal = UILabel(
            text: currencyFormatter.string(from: NSNumber(value: item.lineTotal)) ?? "₹0"
        )
        subtotal.font = .systemFont(ofSize: 14, weight: .semibold)

        let rateStack = vertical(label: "Rate", control: rate)
        let qtyStack = vertical(label: "Qty", control: qty)
        let subtotalStack = vertical(label: "Subtotal", control: subtotal)

        rate.tag = tagFor(item)
        qty.tag = tagFor(item)

        rate.addTarget(self, action: #selector(rateChanged(_:)), for: .editingDidEnd)
        qty.addTarget(self, action: #selector(qtyChanged(_:)), for: .editingDidEnd)

        let topRow = UIStackView(arrangedSubviews: [title, UIView(), del])
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

    private func textField(text: String, width: CGFloat) -> UITextField {
        let t = UITextField()
        t.text = text
        t.borderStyle = .roundedRect
        t.translatesAutoresizingMaskIntoConstraints = false
        t.widthAnchor.constraint(equalToConstant: width).isActive = true
        return t
    }

    private func vertical(label: String, control: UIView) -> UIStackView {
        let l = UILabel(text: label)
        l.font = .systemFont(ofSize: 12)
        let v = UIStackView(arrangedSubviews: [l, control])
        v.axis = .vertical
        v.spacing = 6
        return v
    }

    // -------------------------------------------------------------
    // MARK: Summary Calc
    // -------------------------------------------------------------

    @objc private func updateSummaryAction() { updateSummary() }

    private func updateSummary() {

        let subtotal = CartManager.shared.totalAmount()
        subtotalLabel.text = currencyFormatter.string(from: NSNumber(value: subtotal))

        let tax = subtotal * taxPercent / 100
        taxLabel.text = currencyFormatter.string(from: NSNumber(value: tax))

        let discount = Double(discountField.text ?? "") ?? 0
        let total = subtotal + tax - discount

        grandTotalLabel.text = currencyFormatter.string(from: NSNumber(value: total))

        updateBalance(for: total)
    }

    private func updateBalance(for total: Double) {

        let custom = Double(customAmountField.text ?? "") ?? 0
        if custom > 0 {
            let remain = total - custom
            balanceLabel.text = "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: remain)) ?? "₹0")"
            return
        }

        let p = Double(partialPercentField.text ?? "") ?? 0
        if p > 0 {
            let paid = total * p / 100
            let remain = total - paid
            balanceLabel.text = "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: remain)) ?? "₹0")"
            return
        }

        balanceLabel.text = "Balance Remaining: \(currencyFormatter.string(from: NSNumber(value: total)) ?? "₹0")"
    }

    // -------------------------------------------------------------
    // MARK: Rate / Qty Change
    // -------------------------------------------------------------

    @objc private func rateChanged(_ tf: UITextField) {
        guard let item = itemForTag(tf.tag) else { return }
        let newRate = Double(tf.text ?? "") ?? 0

        // Remove local/server row, then re-insert with new rate.
        CartManager.shared.removeItem(serviceName: item.serviceName, subserviceName: item.subserviceName)

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

        CartManager.shared.setQuantity(
            serviceName: item.serviceName,
            subserviceName: item.subserviceName,
            quantity: qty
        )

        rebuildCards()
        updateSummary()
    }

    // Tag mapping
    private func tagFor(_ item: CartItem) -> Int {
        (item.serviceName.hashValue ^ item.subserviceName.hashValue) & 0x7FFFFFFF
    }

    private func itemForTag(_ tag: Int) -> CartItem? {
        CartManager.shared.items.first { tagFor($0) == tag }
    }

    // Row helper
    private func lineRow(label: String, right: UIView) -> UIView {
        let l = UILabel(text: label)
        let row = UIStackView(arrangedSubviews: [l, UIView(), right])
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
// MARK: CardView container
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
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
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
// MARK: Accordion Header
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

        card.contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

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
            self.chevron.transform = self.isOpen ?
                CGAffineTransform(rotationAngle: .pi / 2) :
                .identity
        }

        onToggle?(isOpen)
    }
}

