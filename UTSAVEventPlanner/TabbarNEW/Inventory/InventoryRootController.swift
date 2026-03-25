import UIKit

final class InventoryRootController: UIViewController {

    private let glassHeaderCard = UIView()
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()
    private let headerSeparator = UIView()

    private let titleLabel = UILabel()
    private let searchBar  = UISearchBar()

    private let emptyVC = InventoryEmptyViewController()
    private var listVC: InventoryEventsListViewController?

    // bg layer
    private let bgGradientLayer = CAGradientLayer()

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
        setupSearchBar()
        setupKeyboardDismissTap()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: NSNotification.Name("ReloadEventsDashboard"),
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

        titleLabel.text = "Inventory"
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

    // MARK: - Search
    private func setupSearchBar() {
        searchBar.placeholder = "Search events"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Keyboard
    private func setupKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
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

    // MARK: - Reload
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load
    private func loadEvents() async {
        do {
            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {

                if events.isEmpty {
                    show(emptyVC)
                } else {
                    if listVC == nil {
                        listVC = InventoryEventsListViewController()
                        listVC?.onScroll = { [weak self] offset in
                            self?.updateHeaderForScroll(offset: offset)
                        }
                    }
                    show(listVC!)
                    Task { await listVC?.refreshEvents() }
                }
            }
        } catch {
            await MainActor.run { show(emptyVC) }
        }
    }

    private func show(_ vc: UIViewController) {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

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

// MARK: - Search forwarding
extension InventoryRootController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        (children.first as? EventSearchable)?.updateSearch(text: searchText)
    }
}

