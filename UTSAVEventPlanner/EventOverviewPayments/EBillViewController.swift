import UIKit

final class EBillViewController: UIViewController {

    private let event: EventRecord
    private var profile: UserProfile?
    private var items: [CartItemRecord] = []
    private var payments: [PaymentRecord] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let billStack = UIStackView()

    // MARK: - Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
        self.profile = ProfileStore.shared.cachedProfile
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .systemBackground
        setupNav()
        setupUI()
        Task { await loadData() }
    }

    private func setupNav() {
        setupUTSAVNavbar(title: "E-Bill")
        
        let shareBtn = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareOptionsTapped))
        navigationItem.rightBarButtonItem = shareBtn
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        billStack.axis = .vertical
        billStack.spacing = 20
        billStack.alignment = .fill
        billStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(billStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            billStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            billStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            billStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            billStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func loadData() async {
        do {
            async let fetchedItems = EventDataManager.shared.fetchCartItems(eventId: event.id)
            async let fetchedPayments = PaymentSupabaseManager.shared.fetchPayments(eventId: event.id, payerType: "client")
            
            self.items = try await fetchedItems
            self.payments = try await fetchedPayments
            
            await MainActor.run {
                renderBill()
            }
        } catch {
            print("EBill load error:", error)
        }
    }

    private func renderBill() {
        billStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // --- 1. Business Header ---
        let header = makeBusinessHeader()
        billStack.addArrangedSubview(header)

        // --- 2. Event Info ---
        let info = makeEventInfoCard()
        billStack.addArrangedSubview(info)

        // --- 3. Items Table ---
        let table = makeItemsTable()
        billStack.addArrangedSubview(table)

        // --- 4. Summary ---
        let summary = makeSummaryCard()
        billStack.addArrangedSubview(summary)

        // --- 5. Footer ---
        let footer = UILabel()
        footer.text = "Thank you for choosing \(profile?.businessName ?? "UTSAV")!"
        footer.font = .systemFont(ofSize: 14, weight: .medium)
        footer.textColor = .secondaryLabel
        footer.textAlignment = .center
        billStack.addArrangedSubview(footer)
    }

    private func makeBusinessHeader() -> UIView {
        let card = glassCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let logo = UIImageView(image: UIImage(named: "utsav_logo"))
        logo.contentMode = .scaleAspectFit
        logo.heightAnchor.constraint(equalToConstant: 50).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let bizName = UILabel()
        bizName.text = profile?.businessName ?? "UTSAV Events"
        bizName.font = .systemFont(ofSize: 22, weight: .bold)
        bizName.textColor = .black

        let bizAddr = UILabel()
        bizAddr.text = profile?.businessAddress ?? "Event Planning Professional"
        bizAddr.font = .systemFont(ofSize: 13)
        bizAddr.textColor = .secondaryLabel
        bizAddr.numberOfLines = 0
        bizAddr.textAlignment = .center

        stack.addArrangedSubview(logo)
        stack.addArrangedSubview(bizName)
        stack.addArrangedSubview(bizAddr)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeEventInfoCard() -> UIView {
        let card = glassCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let title = UILabel()
        title.text = "INVOICE FOR"
        title.font = .systemFont(ofSize: 11, weight: .bold)
        title.textColor = .secondaryLabel

        let eventName = UILabel()
        eventName.text = event.eventName
        eventName.font = .systemFont(ofSize: 18, weight: .bold)

        let clientLabel = row(title: "Client", value: event.clientName)
        let dateLabel = row(title: "Date", value: event.startDate)

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(eventName)
        stack.addArrangedSubview(clientLabel)
        stack.addArrangedSubview(dateLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeItemsTable() -> UIView {
        let card = glassCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let header = itemRow(name: "Requirement", qty: "Qty", total: "Total", isHeader: true)
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(divider())

        for item in items {
            let name = item.subserviceName ?? item.serviceName ?? "Item"
            let qty = "\(item.quantity ?? 1)"
            let total = formatCurrency(item.lineTotal ?? ((item.rate ?? 0) * Double(item.quantity ?? 1)))
            stack.addArrangedSubview(itemRow(name: name, qty: qty, total: total))
        }

        if items.isEmpty {
            let empty = UILabel()
            empty.text = "No items listed"
            empty.font = .italicSystemFont(ofSize: 13)
            empty.textColor = .lightGray
            stack.addArrangedSubview(empty)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeSummaryCard() -> UIView {
        let card = glassCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let subtotal = items.reduce(0.0) { $0 + ($1.lineTotal ?? (($1.rate ?? 0) * Double($1.quantity ?? 1))) }
        let paid = payments.reduce(0.0) { $0 + $1.amount }
        let balance = max(0, subtotal - paid)

        stack.addArrangedSubview(summaryRow(title: "Subtotal", value: formatCurrency(subtotal)))
        stack.addArrangedSubview(summaryRow(title: "Received Amount", value: formatCurrency(paid)))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(summaryRow(title: "Balance Due", value: formatCurrency(balance), isBold: true))

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    // MARK: - Component Helpers
    private func glassCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowRadius = 10
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }

    private func row(title: String, value: String) -> UIView {
        let h = UIStackView()
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 14)
        t.textColor = .secondaryLabel
        let v = UILabel()
        v.text = value
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textAlignment = .right
        h.addArrangedSubview(t)
        h.addArrangedSubview(v)
        return h
    }

    private func itemRow(name: String, qty: String, total: String, isHeader: Bool = false) -> UIView {
        let h = UIStackView()
        h.spacing = 8
        let nl = UILabel(); nl.text = name; nl.font = .systemFont(ofSize: isHeader ? 12 : 14, weight: isHeader ? .bold : .regular); nl.textColor = isHeader ? .secondaryLabel : .black
        let ql = UILabel(); ql.text = qty; ql.font = .systemFont(ofSize: isHeader ? 12 : 14); ql.textColor = isHeader ? .secondaryLabel : .black; ql.textAlignment = .center
        let tl = UILabel(); tl.text = total; tl.font = .systemFont(ofSize: isHeader ? 12 : 14, weight: .bold); tl.textColor = isHeader ? .secondaryLabel : .black; tl.textAlignment = .right
        
        h.addArrangedSubview(nl)
        h.addArrangedSubview(ql)
        h.addArrangedSubview(tl)
        
        ql.widthAnchor.constraint(equalToConstant: 40).isActive = true
        tl.widthAnchor.constraint(equalToConstant: 80).isActive = true
        return h
    }

    private func summaryRow(title: String, value: String, isBold: Bool = false) -> UIView {
        let h = UIStackView()
        let t = UILabel(); t.text = title; t.font = .systemFont(ofSize: isBold ? 16 : 14, weight: isBold ? .bold : .regular)
        let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: isBold ? 16 : 14, weight: isBold ? .bold : .regular); v.textAlignment = .right
        h.addArrangedSubview(t)
        h.addArrangedSubview(v)
        return h
    }

    private func divider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.locale = Locale(identifier: "en_IN")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "₹\(value)"
    }

    // MARK: - Actions
    @objc private func shareOptionsTapped() {
        let alert = UIAlertController(title: "E-Bill Options", message: "Choose how you'd like to share the bill", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Save as Image", style: .default) { _ in
            self.downloadAsImage()
        })
        
        alert.addAction(UIAlertAction(title: "Share as PDF", style: .default) { _ in
            self.shareAsPDF()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func downloadAsImage() {
        // Snapshot the scroll view content
        let originalOffset = scrollView.contentOffset
        let originalFrame = scrollView.frame
        
        // Temporarily expand to show everything
        let contentSize = scrollView.contentSize
        UIGraphicsBeginImageContextWithOptions(contentSize, true, 0.0)
        
        scrollView.contentOffset = .zero
        scrollView.frame = CGRect(origin: .zero, size: contentSize)
        
        scrollView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        scrollView.contentOffset = originalOffset
        scrollView.frame = originalFrame
        
        if let img = image {
            UIImageWriteToSavedPhotosAlbum(img, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Save error:", error)
        } else {
            let alert = UIAlertController(title: "Saved!", message: "E-Bill has been saved to your photos.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func shareAsPDF() {
        let fileName = "E-Bill_\(event.eventName.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let contentSize = scrollView.contentSize
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: contentSize))
        
        do {
            try pdfRenderer.writePDF(to: url) { context in
                context.beginPage()
                scrollView.layer.render(in: context.cgContext)
            }
            
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(vc, animated: true)
        } catch {
            print("PDF generation error:", error)
        }
    }
}
