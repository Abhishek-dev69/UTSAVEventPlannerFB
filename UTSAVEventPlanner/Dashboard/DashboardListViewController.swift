import UIKit

final class DashboardListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: UI Elements
    private let glassHeaderCard = UIView()          // the floating glass container
    private let blurView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintOverlay     = UIView()          // subtle purple tint over the blur
    private let headerSeparator = UIView()          // thin line that appears on scroll

    private let avatar     = UIImageView()
    private let titleLabel = UILabel()
    private let addButton  = UIButton(type: .system)

    // ✅ UPDATED SEGMENTS (added Draft)
    private let segments = UISegmentedControl(items: ["All", "Draft", "Upcoming", "Completed"])

    private let searchBar = UISearchBar()

    // Empty State
    private let emptyStateView = UIView()
    private let emptyIcon      = UIImageView()
    private let emptyLabel     = UILabel()
    private let emptySubLabel  = UILabel()

    private var allEvents: [EventRecord] = []
    private var events: [EventRecord] = []

    // bg layer
    private let bgGradientLayer = CAGradientLayer()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Background Gradient (Aesthetic Brand Purple)
        let brandPurple = UIColor(red: 136.0/255.0, green: 71.0/255.0, blue: 246.0/255.0, alpha: 1.0)
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
        setupSegments()
        setupSearchBar()
        setupTable()
        setupEmptyState()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEvents),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )

        // ✅ 1. Show cached events instantly
        if DashboardEventStore.shared.hasCache {
            self.allEvents = DashboardEventStore.shared.cachedEvents
            self.events = self.allEvents
            self.tableView.reloadData()
            self.updateEmptyState()
        }

        // ✅ 2. Sync from server in background
        Task { await refreshFromServer() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgGradientLayer.frame = view.bounds
        
        // Keep the gradient layer sized to the tintOverlay bounds
        if let grad = tintOverlay.layer.sublayers?.first as? CAGradientLayer {
            grad.frame = tintOverlay.bounds
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search events"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundColor = .clear

        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segments.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Header (Glassmorphic)
    private func setupHeader() {

        // ── Glass card container ─────────────────────────────────────
        glassHeaderCard.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.clipsToBounds = false
        view.addSubview(glassHeaderCard)

        // Blur layer (the frosted glass effect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        // Rounded bottom corners only
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.alpha = 0 // Initially transparent
        glassHeaderCard.addSubview(blurView)

        // Purple-tinted gradient overlay on top of the blur
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.layer.cornerRadius = 20
        tintOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tintOverlay.clipsToBounds = true
        tintOverlay.alpha = 0 // Initially transparent

        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 0.18).cgColor,
            UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 0.04).cgColor
        ]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        tintOverlay.layer.insertSublayer(grad, at: 0)
        glassHeaderCard.addSubview(tintOverlay)

        // Thin bottom separator (appears on scroll)
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        headerSeparator.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 0.25)
        headerSeparator.alpha = 0
        glassHeaderCard.addSubview(headerSeparator)

        // ── Content: avatar, title, add button ───────────────────────
        avatar.image = UIImage(systemName: "person.circle")
        avatar.tintColor = .gray
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        )
        glassHeaderCard.addSubview(avatar)

        titleLabel.text = "Dashboard"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderCard.addSubview(titleLabel)

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        addButton.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addEventTapped), for: .touchUpInside)
        glassHeaderCard.addSubview(addButton)

        // Shadow on the glass card (visible on scroll)
        glassHeaderCard.layer.shadowColor   = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1).cgColor
        glassHeaderCard.layer.shadowOpacity = 0.0 // Initially flat
        glassHeaderCard.layer.shadowRadius  = 12
        glassHeaderCard.layer.shadowOffset  = CGSize(width: 0, height: 4)

        // ── Constraints ──────────────────────────────────────────────
        let safeTop = view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            // Glass card spans full width, from top of view to below add-button
            glassHeaderCard.topAnchor.constraint(equalTo: view.topAnchor),
            glassHeaderCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHeaderCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassHeaderCard.bottomAnchor.constraint(equalTo: safeTop, constant: 60),   // safe area + content

            // Blur fills the card
            blurView.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            // Tint overlay fills the card
            tintOverlay.topAnchor.constraint(equalTo: glassHeaderCard.topAnchor),
            tintOverlay.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),

            // Separator at the very bottom edge
            headerSeparator.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor),
            headerSeparator.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            // Avatar, title, add button sit in the safe-area part of the card
            avatar.leadingAnchor.constraint(equalTo: glassHeaderCard.leadingAnchor, constant: 20),
            avatar.bottomAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: -10),
            avatar.widthAnchor.constraint(equalToConstant: 44),
            avatar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: glassHeaderCard.centerXAnchor),

            addButton.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: glassHeaderCard.trailingAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Segments
    private func setupSegments() {
        segments.selectedSegmentIndex = 0
        segments.selectedSegmentTintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        segments.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: UIColor(white: 0.2, alpha: 1)], for: .normal)
        segments.translatesAutoresizingMaskIntoConstraints = false
        segments.addTarget(self, action: #selector(segmentedChanged), for: .valueChanged)

        view.addSubview(segments)

        NSLayoutConstraint.activate([
            // anchor to the bottom of the glass header card
            segments.topAnchor.constraint(equalTo: glassHeaderCard.bottomAnchor, constant: 12),
            segments.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segments.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segments.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(EventCardCell.self, forCellReuseIdentifier: "EventCardCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        tableView.addGestureRecognizer(longPress)
        tableView.keyboardDismissMode = .onDrag

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private func setupEmptyState() {
        emptyIcon.image = UIImage(systemName: "calendar.badge.plus")
        emptyIcon.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        emptyLabel.text = "No Events Yet"
        emptyLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        emptyLabel.textColor = .darkGray

        emptySubLabel.text = "Tap + to create your first event"
        emptySubLabel.font = .systemFont(ofSize: 14)
        emptySubLabel.textColor = .gray

        let stack = UIStackView(arrangedSubviews: [emptyIcon, emptyLabel, emptySubLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        emptyStateView.addSubview(stack)
        emptyStateView.alpha = 0
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    private func updateEmptyState() {
        let noEvents = events.isEmpty
        emptyStateView.alpha = noEvents ? 1 : 0
        tableView.alpha = noEvents ? 0 : 1
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {

        guard gesture.state == .began else { return }

        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        let event = events[indexPath.row]

        let alert = UIAlertController(
            title: event.eventName,
            message: "Are you sure you want to delete this event?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.deleteEvent(event, at: indexPath)
                }
            }
        )

        present(alert, animated: true)
    }
    
    private func deleteEvent(_ event: EventRecord, at indexPath: IndexPath) async {
        do {
            try await EventSupabaseManager.shared.deleteEvent(eventId: event.id)

            await MainActor.run {

                // Remove locally
                self.allEvents.removeAll { $0.id == event.id }
                self.events.removeAll { $0.id == event.id }

                // Update cache
                DashboardEventStore.shared.set(self.allEvents)

                // Animate row deletion
                self.tableView.deleteRows(at: [indexPath], with: .automatic)

                // Update empty state
                self.updateEmptyState()

                // Reload dashboard everywhere
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReloadEventsDashboard"),
                    object: nil
                )
            }

        } catch {
            print("❌ Delete failed:", error)

            await MainActor.run {
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to delete event. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - Data
    @objc private func reloadEvents() {
        Task { await refreshFromServer() }
    }

    private func refreshFromServer() async {
        do {
            let uid = try await EventSupabaseManager.shared.ensureUserId()
            let fetched = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)

            await MainActor.run {
                DashboardEventStore.shared.set(fetched)
                self.allEvents = fetched
                self.events = fetched
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        } catch {
            print("❌ Dashboard refresh failed:", error)
        }
    }
    private func openDraftCart(eventId: String) async {
        do {
            print("🟡 Opening draft cart for event:", eventId)

            EventSession.shared.currentEventId = eventId

            let sessionId = try await EventSupabaseManager.shared.fetchCartSessionId(eventId: eventId)

            await MainActor.run {
                CartSession.shared.currentSessionId = sessionId
            }

            // ✅ Clear only local cart
            CartManager.shared.resetLocalCart()

            // ✅ WAIT for cart to load
            await withCheckedContinuation { continuation in
                CartManager.shared.loadFromServer(eventId: eventId)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    continuation.resume()
                }
            }

            await MainActor.run {
                let cartVC = EstimateCartViewController()
                cartVC.hidesBottomBarWhenPushed = true

                // ✅ FORCE NAVIGATION BAR TO SHOW
                self.navigationController?.setNavigationBarHidden(false, animated: false)

                self.navigationController?.pushViewController(cartVC, animated: true)
            }

        } catch {
            print("❌ Failed to open draft cart:", error)
        }
    }


    // MARK: - Actions
    @objc private func segmentedChanged() {
        switch segments.selectedSegmentIndex {

        case 0: // All
            events = allEvents

        case 1: // ✅ Draft
            events = allEvents.filter { ($0.status ?? "confirmed") == "draft" }

        case 2: // Upcoming (confirmed + future date)
            events = allEvents.filter {
                ($0.status ?? "confirmed") == "confirmed" &&
                eventStatus(for: $0) == .upcoming
            }

        case 3: // Completed
            events = allEvents.filter {
                eventStatus(for: $0) == .completed
            }

        default:
            events = allEvents
        }

        tableView.reloadData()
        updateEmptyState()
    }

    @objc private func addEventTapped() {
        let vc = EventDetailsViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func profileTapped() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }
}

// MARK: - Helpers (DB → UI Model)

private let dashboardDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .init(abbreviation: "UTC")
    return f
}()

private let dashboardCurrencyFormatter: NumberFormatter = {
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    nf.currencyCode = "INR"
    nf.locale = Locale(identifier: "en_IN")
    nf.maximumFractionDigits = 0
    return nf
}()

private func parseDate(_ string: String) -> Date {
    dashboardDateFormatter.date(from: string) ?? Date()
}

enum EventStatus {
    case upcoming
    case ongoing
    case completed
}

private func eventStatus(for record: EventRecord) -> EventStatus {
    let eventDate = parseDate(record.startDate)
    let today = Calendar.current.startOfDay(for: Date())
    let eventDay = Calendar.current.startOfDay(for: eventDate)

    if eventDay < today {
        return .completed
    } else if eventDay == today {
        return .ongoing
    } else {
        return .upcoming
    }
}

// MARK: - Table Delegates
extension DashboardListViewController: UITableViewDataSource, UITableViewDelegate {

    // Separator and glass blur fades in as the list scrolls under the glass header
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        // Start fading in at 10pt scroll, fully visible by 40pt
        let progress = min(max((offset - 10) / 30, 0), 1)
        UIView.animate(withDuration: 0.1) {
            self.blurView.alpha = progress
            self.tintOverlay.alpha = progress
            self.headerSeparator.alpha = progress
            self.glassHeaderCard.layer.shadowOpacity = Float(progress * 0.08)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EventCardCell",
            for: indexPath
        ) as! EventCardCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let record = events[indexPath.row]

        // ✅ Set session
        EventSession.shared.currentEventId = record.id
        EventSession.shared.currentEventName = record.eventName
        EventSession.shared.currentClientName = record.clientName
        EventSession.shared.currentLocation = record.location
        EventSession.shared.currentStartDate = parseDate(record.startDate)
        EventSession.shared.currentEndDate = parseDate(record.endDate)

        let status = (record.status ?? "")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let servicesAdded = record.metadata?["servicesAdded"] == "true"

        print("📌 Status:", status)
        print("📌 servicesAdded:", servicesAdded)

        // -------------------------------------
        // ✅ 1. CONFIRMED → Open Overview
        // -------------------------------------
        if status == "confirmed" {
            let vc = EventOverviewViewController(event: record)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        // -------------------------------------
        // ✅ 2. Draft with services → Open Cart
        // -------------------------------------
        if servicesAdded {
            Task {
                await openDraftCart(eventId: record.id)
            }
            return
        }

        // -------------------------------------
        // ✅ 3. No services → Open Confirmation
        // -------------------------------------
        let details = EventDetails(
            eventName: record.eventName,
            clientName: record.clientName,
            location: record.location,
            guestCount: record.guestCount,
            budgetInPaise: Int(record.budgetInPaise),
            startDate: parseDate(record.startDate),
            endDate: parseDate(record.endDate)
        )

        let vc = ConfirmationViewController(
            details: details,
            currencyFormatter: dashboardCurrencyFormatter,
            dateFormatter: dashboardDateFormatter,
            title: record.eventName
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension DashboardListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if q.isEmpty {
            segmentedChanged()
            return
        }

        events = allEvents.filter {
            $0.eventName.lowercased().contains(q) ||
            $0.clientName.lowercased().contains(q) ||
            $0.location.lowercased().contains(q)
        }

        tableView.reloadData()
        updateEmptyState()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
