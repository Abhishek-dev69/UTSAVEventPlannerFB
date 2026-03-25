//
//  ClientRequirementsViewController.swift
//

import UIKit
import Supabase

final class ClientRequirementsViewController: UIViewController {

    private let tableView = UITableView()
    private let event: EventRecord
    private var cartItems: [CartItemRecord] = []

    // ✅ Selection storage
    private var selectedItemIds: Set<String> = []

    // ✅ Bottom button
    private let assignVendorButton = UIButton(type: .system)

    private var cartRealtimeChannel: RealtimeChannelV2?
    private var cartPersistObserver: NSObjectProtocol?

    // Init
    init(event: EventRecord, cartItems: [CartItemRecord] = []) {
        self.event = event
        self.cartItems = cartItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(event:cartItems:)")
    }

    deinit {
        if let obs = cartPersistObserver {
            NotificationCenter.default.removeObserver(obs)
        }

        if let channel = cartRealtimeChannel {
            Task { await channel.unsubscribe() }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .clear
        setupUTSAVNavbar(title: "Client Requirements")

        setupTable()
        setupAddButton()
        setupAssignVendorButton()
        subscribeToCartRealtime()

        cartPersistObserver = NotificationCenter.default.addObserver(
            forName: .CartItemPersisted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.fetchCart() }
        }

        Task { await fetchCart() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    // MARK: - Realtime Subscription
    private func subscribeToCartRealtime() {

        guard cartRealtimeChannel == nil else { return }

        let client = SupabaseManager.shared.client
        let channel = client.channel("cart-items-\(event.id)")
        cartRealtimeChannel = channel

        channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "cart_items",
            filter: "event_id=eq.\(event.id)"
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.fetchCart() }
        }

        Task {
            do {
                try await channel.subscribeWithError()
                print("✅ Subscribed to cart realtime")
            } catch {
                print("❌ Realtime subscription failed:", error)
            }
        }
    }

    // MARK: - Bottom Assign Button
    private func setupAssignVendorButton() {

        assignVendorButton.setTitle("Assign Vendor (0)", for: .normal)
        assignVendorButton.setTitleColor(.white, for: .normal)
        assignVendorButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        assignVendorButton.layer.cornerRadius = 26
        assignVendorButton.isHidden = true
        assignVendorButton.translatesAutoresizingMaskIntoConstraints = false
        assignVendorButton.addTarget(self, action: #selector(assignVendorTapped), for: .touchUpInside)

        view.addSubview(assignVendorButton)

        NSLayoutConstraint.activate([
            assignVendorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            assignVendorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            assignVendorButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            assignVendorButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        tableView.contentInset.bottom = 100
    }

    @objc private func assignVendorTapped() {

        let selectedItems = cartItems.filter {
            selectedItemIds.contains($0.id)
        }

        guard !selectedItems.isEmpty else { return }

        let vc = VendorSelectionViewController(requirements: selectedItems)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func updateAssignButton() {
        let count = selectedItemIds.count
        assignVendorButton.setTitle("Assign Vendor (\(count))", for: .normal)
        assignVendorButton.isHidden = count == 0
    }

    // MARK: - Add Services
    private func setupAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addMoreServicesTapped)
        )
    }

    @objc private func addMoreServicesTapped() {
        CartSession.shared.startNewSession()
        EventSession.shared.currentEventId = event.id

        let picker = ServicePickerViewController()
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Table Setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true

        tableView.register(
            InhouseRequirementCell.self,
            forCellReuseIdentifier: "RequirementCell"
        )

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.contentInset.top = 15
        tableView.verticalScrollIndicatorInsets.top = 15
    }

    // MARK: - Data
    private func fetchCart() async {
        do {
            let items = try await EventDataManager.shared.fetchCartItems(eventId: event.id)

                await MainActor.run {
                self.cartItems = items
                self.selectedItemIds.removeAll()
                self.tableView.reloadData()
                self.updateAssignButton()
            }

        } catch {
            print("❌ Failed to fetch cart:", error)
        }
    }
}

// MARK: - UITableView
extension ClientRequirementsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return cartItems.count
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "RequirementCell",
            for: indexPath
        ) as! InhouseRequirementCell

        let item = cartItems[indexPath.row]

        let selectable = item.assignmentStatus == nil ||
                         item.assignmentStatus == "rejected"

        let isSelected = selectedItemIds.contains(item.id)

        cell.configure(item: item, isSelected: isSelected,isSelectable: selectable)

        cell.onCheckboxToggle = { [weak self] in
            guard let self = self else { return }
            guard selectable else { return }

            if isSelected {
                self.selectedItemIds.remove(item.id)
            } else {
                self.selectedItemIds.insert(item.id)
            }

            self.updateAssignButton()
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let item = cartItems[indexPath.row]

        guard item.assignmentStatus == nil ||
              item.assignmentStatus == "rejected"
        else { return }

        selectedItemIds.insert(item.id)
        updateAssignButton()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func tableView(_ tableView: UITableView,
                   didDeselectRowAt indexPath: IndexPath) {

        let item = cartItems[indexPath.row]

        selectedItemIds.remove(item.id)
        updateAssignButton()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

