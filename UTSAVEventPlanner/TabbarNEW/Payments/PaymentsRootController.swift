import UIKit

// MARK: - Protocols
protocol EventSearchable: AnyObject {
    func updateSearch(text: String)
}

protocol VendorSearchable: AnyObject {
    func updateVendorSearch(text: String)
}

final class PaymentsRootController: UIViewController {

    // MARK: - UI
    private let glassHeaderCard = UIView()
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()
    private let headerSeparator = UIView()

    private let titleLabel = UILabel()
    private let segmented  = UISegmentedControl(items: ["Client Payments", "Vendor Payments"])
    private let searchBar  = UISearchBar()

    // MARK: - Child VCs
    private let emptyVC = PaymentsEmptyViewController()
    private var clientListVC: PaymentsEventsListViewController?
    private let vendorListVC = VendorPaymentsListViewController()

    // MARK: - State
    private var hasEvents = false
    private var currentChild: UIViewController?

    // bg layer
    private let bgGradientLayer = CAGradientLayer()

    // MARK: - Theme
    private let utsavPurple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background Gradient (Aesthetic Brand Purple)
        let brandPurple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        bgGradientLayer.colors = [
            brandPurple.withAlphaComponent(0.30).cgColor, // Top (Darker Purple)
            brandPurple.withAlphaComponent(0.08).cgColor  // Bottom (Light Purple)
        ]
        bgGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        bgGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        bgGradientLayer.locations = [0, 1.0]
        view.layer.insertSublayer(bgGradientLayer, at: 0)
        view.backgroundColor = .systemBackground

        setupHeader()
        setupSegmented()
        setupSearchBar()
        setupKeyboardDismissTap()
        
        vendorListVC.onScroll = { [weak self] offset in
            self?.updateHeaderForScroll(offset: offset)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: Notification.Name("ReloadEventsDashboard"),
            object: nil
        )

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgGradientLayer.frame = view.bounds
        if let grad = tintOverlay.layer.sublayers?.first as? CAGradientLayer {
            grad.frame = tintOverlay.bounds
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Header
    private func setupHeader() {
        let purple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        glassHeaderCard.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.clipsToBounds = false
        glassHeaderCard.layer.shadowColor   = purple.cgColor
        glassHeaderCard.layer.shadowOpacity = 0.0 // Initially flat
        glassHeaderCard.layer.shadowRadius  = 12
        glassHeaderCard.layer.shadowOffset  = CGSize(width: 0, height: 4)
        view.addSubview(glassHeaderCard)

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0 // Initially transparent
        glassHeaderCard.addSubview(blurView)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.layer.cornerRadius = 20
        tintOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tintOverlay.clipsToBounds = true
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.alpha = 0 // Initially transparent
        let grad = CAGradientLayer()
        grad.colors = [purple.withAlphaComponent(0.18).cgColor,
                       purple.withAlphaComponent(0.04).cgColor]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        tintOverlay.layer.insertSublayer(grad, at: 0)
        glassHeaderCard.addSubview(tintOverlay)

        headerSeparator.backgroundColor = purple.withAlphaComponent(0.25)
        headerSeparator.alpha = 0
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(headerSeparator)

        titleLabel.text = "Payments"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(titleLabel)

        let safeTop = view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            glassHeaderCard.topAnchor.constraint(equalTo: view.topAnchor),
            glassHeaderCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHeaderCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassHeaderCard.bottomAnchor.constraint(equalTo: safeTop, constant: 52),

            blurView.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            tintOverlay.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            tintOverlay.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            headerSeparator.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            headerSeparator.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            titleLabel.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: -12),
            titleLabel.centerXAnchor.constraint(equalTo: glassHeaderCard.centerXAnchor)
        ])
    }

    // MARK: - Segmented Control
    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = utsavPurple
        segmented.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor(white: 0.2, alpha: 1)], for: .normal)
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Search Bar
    private func setupSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Keyboard Dismiss
    private func setupKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    // MARK: - Reload
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load Events
    private func loadEvents() async {

        // 1️⃣ Load cached events first
        if PaymentsEventStore.shared.hasCache {

            let cached = PaymentsEventStore.shared.cachedEvents

            await MainActor.run {
                hasEvents = !cached.isEmpty

                if hasEvents, clientListVC == nil {
                    clientListVC = PaymentsEventsListViewController()
                    clientListVC?.onScroll = { [weak self] offset in
                        self?.updateHeaderForScroll(offset: offset)
                    }
                }

                showCurrentSegment()
            }

            // 🔴 IMPORTANT: refresh list using cached data
            if hasEvents {
                await clientListVC?.refreshEvents()
            }

            return
        }

        // 2️⃣ If no cache → call API
        do {

            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            PaymentsEventStore.shared.set(events)

            await MainActor.run {

                hasEvents = !events.isEmpty

                if hasEvents, clientListVC == nil {
                    clientListVC = PaymentsEventsListViewController()
                    clientListVC?.onScroll = { [weak self] offset in
                        self?.updateHeaderForScroll(offset: offset)
                    }
                }

                showCurrentSegment()
            }

            if hasEvents {
                await clientListVC?.refreshEvents()
            }

        } catch {

            await MainActor.run {
                hasEvents = false
                showCurrentSegment()
            }
        }
    }
    // MARK: - Dynamic Header Effect
    private func updateHeaderForScroll(offset: CGFloat) {
        let progress = min(max((offset - 10) / 30, 0), 1)
        UIView.animate(withDuration: 0.1) {
            self.blurView.alpha = progress
            self.tintOverlay.alpha = progress
            self.headerSeparator.alpha = progress
            self.glassHeaderCard.layer.shadowOpacity = Float(progress * 0.08)
        }
    }

    // MARK: - Segment Switch
    @objc private func segmentChanged() {
        showCurrentSegment()
    }

    private func showCurrentSegment() {

        if segmented.selectedSegmentIndex == 0 {
            // Client Payments
            searchBar.placeholder = "Search events"

            if hasEvents, let clientVC = clientListVC {
                show(clientVC)
            } else {
                show(emptyVC)
            }

        } else {
            // Vendor Payments
            searchBar.placeholder = "Search vendors"
            show(vendorListVC)
        }
    }

    // MARK: - Child Handling
    private func show(_ vc: UIViewController) {
        if currentChild === vc { return }

        currentChild?.willMove(toParent: nil)
        currentChild?.view.removeFromSuperview()
        currentChild?.removeFromParent()

        currentChild = vc
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }
}

// MARK: - Search Routing
extension PaymentsRootController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if segmented.selectedSegmentIndex == 0 {
            (currentChild as? EventSearchable)?.updateSearch(text: searchText)
        } else {
            (currentChild as? VendorSearchable)?.updateVendorSearch(text: searchText)
        }
    }
}

