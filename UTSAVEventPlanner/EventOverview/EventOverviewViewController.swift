import UIKit
import SwiftUI

final class EventOverviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var event: EventRecord

    // Data
    private var cartItems: [CartItemRecord] = []
    private var totalAmount: Double = 0.0
    private var receivedAmount: Double = 0.0
    private var totalExpenses: Double = 0.0

    // Header UI
    private let headerCard = UIView()
    private let headerClientLabel = UILabel()

    private let headerDateIcon = UIImageView()
    private let headerDateLabel = UILabel()

    private let headerLocationIcon = UIImageView()
    private let headerLocationLabel = UILabel()

    private let headerGuestIcon = UIImageView()
    private let headerGuestLabel = UILabel()

    // MARK: Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupScroll()
        setupHeaderCard()

        if let cached = EventOverviewStore.shared.load(eventId: event.id) {
            self.cartItems = cached.cartItems
            self.receivedAmount = cached.receivedAmount
            self.totalExpenses = cached.totalExpenses

            computeFromCart()
            updateHeaderContent()
            buildAllSections()
        }

        Task { await refreshFromServer() }
    }

    // MARK: - NAV
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

        // ✅ SHARE PDF BUTTON
        let shareItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(didTapShare)
        )
        shareItem.tintColor = .black
        let downloadItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.down.circle"),
            style: .plain,
            target: self,
            action: #selector(didTapDownload)
        )

        navigationItem.rightBarButtonItems = [shareItem, downloadItem]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .semibold)]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - PDF SHARE
    @objc private func didTapShare() {
        shareEventPDF()
    }
    @objc private func didTapDownload() {

        let alert = UIAlertController(
            title: "Download Requirements",
            message: "Choose format",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Download PDF", style: .default) { _ in
            self.downloadPDF()
        })

        alert.addAction(UIAlertAction(title: "Save as Image", style: .default) { _ in
            self.saveImage()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    private func downloadPDF() {

        guard !cartItems.isEmpty else { return }

        let mappedItems = mapToCartItems(cartItems)

        let pdfData = QuotationPDFData(
            eventName: event.eventName,
            clientName: event.clientName,
            location: event.location,
            eventDate: composedDateString(
                startISO: event.startDate,
                endISO: event.endDate
            ),
            items: mappedItems,
            subtotal: totalAmount,
            tax: 0,
            discount: 0,
            grandTotal: totalAmount
        )

        let pdfView = QuotationPDFView(data: pdfData)

        do {

            let pdfURL = try PDFGenerator.generate(
                view: pdfView,
                fileName: "Requirements-\(event.eventName).pdf"
            )

            saveFileToEventFolder(fileURL: pdfURL)
            showSavedAlert()

        } catch {
            print("PDF save failed:", error)
        }
    }
    private func saveImage() {

        guard !cartItems.isEmpty else { return }

        let mappedItems = mapToCartItems(cartItems)

        let pdfData = QuotationPDFData(
            eventName: event.eventName,
            clientName: event.clientName,
            location: event.location,
            eventDate: composedDateString(
                startISO: event.startDate,
                endISO: event.endDate
            ),
            items: mappedItems,
            subtotal: totalAmount,
            tax: 0,
            discount: 0,
            grandTotal: totalAmount
        )

        let pdfView = QuotationPDFView(data: pdfData)

        let hosting = UIHostingController(rootView: pdfView)
        let view = hosting.view!

        view.bounds = CGRect(x: 0, y: 0, width: 800, height: 1200)
        view.backgroundColor = .white

        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)

        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        showSavedAlert()
    }
    private func saveFileToEventFolder(fileURL: URL) {

        let fileManager = FileManager.default

        let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let eventsFolder = documents.appendingPathComponent("Events")

        let eventFolder = eventsFolder.appendingPathComponent(event.id)

        try? fileManager.createDirectory(
            at: eventFolder,
            withIntermediateDirectories: true
        )

        let destination = eventFolder.appendingPathComponent(fileURL.lastPathComponent)

        try? fileManager.copyItem(at: fileURL, to: destination)
    }
    private func showSavedAlert() {

        let alert = UIAlertController(
            title: "Saved",
            message: "File saved successfully",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
    private func mapToCartItems(_ records: [CartItemRecord]) -> [CartItem] {
        records.map {
            CartItem(
                serviceId: $0.serviceId ?? "",
                serviceName: $0.serviceName ?? "",
                subserviceId: $0.subserviceId ?? "",
                subserviceName: $0.subserviceName ?? "",
                rate: $0.rate ?? 0,
                unit: $0.unit ?? "",
                quantity: $0.quantity ?? 0
            )
        }
    }

    private func shareEventPDF() {

        guard !cartItems.isEmpty else {
            print("❌ No items to generate PDF")
            return
        }

        let mappedItems = mapToCartItems(cartItems)

        let pdfData = QuotationPDFData(
            eventName: event.eventName,
            clientName: event.clientName,
            location: event.location,
            eventDate: composedDateString(
                startISO: event.startDate,
                endISO: event.endDate
            ),
            items: mappedItems,
            subtotal: totalAmount,
            tax: 0,
            discount: 0,
            grandTotal: totalAmount
        )

        let pdfView = QuotationPDFView(data: pdfData)

        do {
            let pdfURL = try PDFGenerator.generate(
                view: pdfView,
                fileName: "Requirements of \(event.eventName).pdf"
            )

            let vc = UIActivityViewController(
                activityItems: [pdfURL],
                applicationActivities: nil
            )

            vc.popoverPresentationController?.barButtonItem =
                navigationItem.rightBarButtonItem

            present(vc, animated: true)

        } catch {
            print("❌ PDF generation failed:", error)
        }
    }

    // MARK: - SCROLLVIEW
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

    // MARK: - HEADER CARD
    private func setupHeaderCard() {
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 14
        headerCard.layer.shadowColor = UIColor.black.cgColor
        headerCard.layer.shadowOpacity = 0.06
        headerCard.layer.shadowRadius = 8
        headerCard.layer.shadowOffset = CGSize(width: 0, height: 6)

        headerClientLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerClientLabel.numberOfLines = 2

        func setupIcon(_ icon: UIImageView, name: String) {
            icon.image = UIImage(systemName: name)
            icon.tintColor = .secondaryLabel
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 16),
                icon.heightAnchor.constraint(equalToConstant: 16)
            ])
        }

        setupIcon(headerDateIcon, name: "calendar")
        setupIcon(headerLocationIcon, name: "location.fill")
        setupIcon(headerGuestIcon, name: "person.2")

        [headerDateLabel, headerLocationLabel, headerGuestLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
        }

        let dateRow = UIStackView(arrangedSubviews: [headerDateIcon, headerDateLabel])
        dateRow.axis = .horizontal
        dateRow.spacing = 6

        let locationRow = UIStackView(arrangedSubviews: [headerLocationIcon, headerLocationLabel])
        locationRow.axis = .horizontal
        locationRow.spacing = 6

        let guestRow = UIStackView(arrangedSubviews: [headerGuestIcon, headerGuestLabel])
        guestRow.axis = .horizontal
        guestRow.spacing = 6

        let infoStack = UIStackView(arrangedSubviews: [
            headerClientLabel,
            dateRow,
            locationRow,
            guestRow
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(infoStack)

        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(headerCard)
    }

    private func lineTotal(for item: CartItemRecord) -> Double {
        item.lineTotal ?? ((item.rate ?? 0) * Double(item.quantity ?? 0))
    }
    private func computeFromCart() {
        totalAmount = cartItems.reduce(0) { $0 + lineTotal(for: $1) }
    }
    // MARK: - HEADER CONTENT
    private func updateHeaderContent() {
        let client = event.clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        headerClientLabel.text = !client.isEmpty ? client : event.eventName
        headerDateLabel.text = composedDateString(startISO: event.startDate, endISO: event.endDate)

        let loc = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        headerLocationLabel.text = !loc.isEmpty ? loc : "—"
        headerGuestLabel.text = event.guestCount > 0 ? "\(event.guestCount)" : "—"
    }

    // MARK: - DATE FORMAT
    private func composedDateString(startISO: String, endISO: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let out = DateFormatter()
        out.dateFormat = "dd/MM/yyyy"

        guard let s = f.date(from: startISO) else { return "Date not set" }
        if let e = f.date(from: endISO), !Calendar.current.isDate(s, inSameDayAs: e) {
            return "\(out.string(from: s)) - \(out.string(from: e))"
        }
        return out.string(from: s)
    }

    // MARK: - SERVER DATA
    @MainActor
    private func refreshFromServer() async {
        do {
            let cart = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            let payments = try await EventDataManager.shared.fetchPayments(eventId: event.id)
            let expenses = try await EventDataManager.shared.fetchBudgetEntries(eventId: event.id)

            let received = payments.reduce(0) { $0 + $1.amount }
            let spent = expenses.reduce(0) { $0 + $1.amount }

            let overview = EventOverviewCache(
                eventId: event.id,
                cartItems: cart,
                receivedAmount: received,
                totalExpenses: spent
            )

            EventOverviewStore.shared.save(overview)

            self.cartItems = cart
            self.receivedAmount = received
            self.totalExpenses = spent

            computeFromCart()
            updateHeaderContent()
            buildAllSections()

        } catch {
            print("⚠️ Overview sync failed:", error)
        }
    }

    // MARK: - UI SECTIONS
    private func buildAllSections() {
        contentStack.arrangedSubviews.dropFirst().forEach { $0.removeFromSuperview() }
        addClientRequirements()
        addBudgetCheckIn()
        addPaymentStatus()
        addInventory()
    }

    private func addClientRequirements() {
        let subtitle = "\(cartItems.count) services added"
        let card = EventSectionCard(
            iconName: "checklist",
            title: "Client Requirements",
            subtitle: subtitle,
            progress: nil
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                ClientRequirementsViewController(event: self.event, cartItems: self.cartItems),
                animated: true
            )
        }
        contentStack.addArrangedSubview(card)
    }

    private func addBudgetCheckIn() {
        let subtitle = "Spent ₹\(formatMoney(totalExpenses)) of ₹\(formatMoney(totalAmount))"
        let progress: Float = totalAmount > 0 ? Float(totalExpenses / totalAmount) : 0

        let card = EventSectionCard(
            iconName: "indianrupeesign.circle",
            title: "Budget Check-in",
            subtitle: subtitle,
            progress: progress
        ) { [weak self] in
            guard let self else { return }
            EventDataManager.shared.currentEventId = self.event.id
            self.navigationController?.pushViewController(BudgetDetailViewController(), animated: true)
        }
        contentStack.addArrangedSubview(card)
    }

    private func addPaymentStatus() {
        let percent = totalAmount > 0 ? (receivedAmount / totalAmount) : 0
        let subtitle = "Received ₹\(formatMoney(receivedAmount)) of ₹\(formatMoney(totalAmount)) (\(Int(percent * 100))%)"

        let card = EventSectionCard(
            iconName: "rupeesign.circle",
            title: "Payment Status",
            subtitle: subtitle,
            progress: Float(percent)
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                PaymentListViewController(event: self.event),
                animated: true
            )
        }
        contentStack.addArrangedSubview(card)
    }

    private func addInventory() {
        let card = EventSectionCard(
            iconName: "shippingbox",
            title: "Inventory Overview",
            subtitle: "Track items & usage",
            progress: nil
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                InventoryOverviewViewController(event: self.event),
                animated: true
            )
        }
        contentStack.addArrangedSubview(card)
    }
    private func formatMoney(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "0"
    }
}

