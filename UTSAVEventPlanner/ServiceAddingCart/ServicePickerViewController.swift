//
//  ServicePickerViewController.swift
//

import UIKit

final class ServicePickerViewController: UIViewController, CartObserver {

    // MARK: - UI Components
    private let segmented = UISegmentedControl(items: ["In-House Services", "Outsource Services"])
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let segmentContainer = UIView()

    // Outsource form container
    private let outsourceContainer = UIView()
    private var outsourceForm: OutsourceFormView?

    // Bottom cart UI
    private let bottomCartView = UIView()
    private let cartLabel = UILabel()
    private let cartTotalLabel = UILabel()
    private let cartIcon = UIImageView(image: UIImage(systemName: "cart.fill"))

    // MARK: - Data
    private var services: [Service] = []           // original
    private var filteredServices: [Service] = []   // used by table
    private var expanded: [Bool] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNav()
        setupSegmentContainer()
        setupSearchBar()          // ✅ NEW
        setupTable()
        setupOutsourceForm()
        setupBottomCart()
        setupKeyboardDismissGesture()

        CartManager.shared.addObserver(self)

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        Task {
            _ = try? await SupabaseManager.shared.ensureUserId()
            CartManager.shared.loadFromServer(eventId: EventSession.shared.currentEventId)
            await fetchServices()
        }
    }

    deinit {
        CartManager.shared.removeObserver(self)
    }
    
    // MARK: - Bottom Cart UI
    private func setupBottomCart() {
        bottomCartView.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.backgroundColor = UIColor(
            red: 136/255,
            green: 71/255,
            blue: 246/255,
            alpha: 1
        )
        bottomCartView.layer.cornerRadius = 32
        view.addSubview(bottomCartView)

        let iconBg = UIView()
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.backgroundColor = .white
        iconBg.layer.cornerRadius = 20
        bottomCartView.addSubview(iconBg)

        cartIcon.tintColor = UIColor(
            red: 136/255,
            green: 71/255,
            blue: 246/255,
            alpha: 1
        )
        cartIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(cartIcon)

        cartLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        cartLabel.textColor = .white
        cartLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(cartLabel)

        cartTotalLabel.font = .systemFont(ofSize: 14)
        cartTotalLabel.textColor = .white
        cartTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(cartTotalLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openCart))
        bottomCartView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            bottomCartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomCartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomCartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomCartView.heightAnchor.constraint(equalToConstant: 70),

            iconBg.leadingAnchor.constraint(equalTo: bottomCartView.leadingAnchor, constant: 16),
            iconBg.centerYAnchor.constraint(equalTo: bottomCartView.centerYAnchor),
            iconBg.heightAnchor.constraint(equalToConstant: 40),
            iconBg.widthAnchor.constraint(equalToConstant: 40),

            cartIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            cartIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),

            cartLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            cartLabel.topAnchor.constraint(equalTo: bottomCartView.topAnchor, constant: 14),

            cartTotalLabel.leadingAnchor.constraint(equalTo: cartLabel.leadingAnchor),
            cartTotalLabel.topAnchor.constraint(equalTo: cartLabel.bottomAnchor, constant: 2)
        ])

        updateCartUI()
    }
    @objc private func openCart() { let vc = EstimateCartViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true) }


    // MARK: - Navigation
    private func setupNav() {
        navigationItem.title = "Add Requirements"

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .black
        back.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "plus"),
                    style: .plain,
                    target: self,
                    action: #selector(addCustomServiceTapped)
                )
    }
    
    @objc private func addCustomServiceTapped() {
            let alert = UIAlertController(
                title: "Add Custom Service",
                message: "Enter service / material details",
                preferredStyle: .alert
            )

            alert.addTextField { $0.placeholder = "Service / Material Name" }

            alert.addTextField {
                $0.placeholder = "Quantity"
                $0.keyboardType = .numberPad
            }

            alert.addTextField {
                $0.placeholder = "Rate (₹)"
                $0.keyboardType = .decimalPad
            }

            alert.addTextField {
                $0.placeholder = "Notes (optional)"
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
                let name = alert.textFields?[0].text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let qty = Int(alert.textFields?[1].text ?? "1") ?? 1
                let rate = Double(alert.textFields?[2].text ?? "") ?? 0
                let notes = alert.textFields?[3].text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                guard !name.isEmpty else { return }

                CartManager.shared.addItem(
                    serviceId: nil,
                    serviceName: name,
                    subserviceId: UUID().uuidString,
                    subserviceName: notes.isEmpty ? name : notes,
                    rate: rate,
                    unit: "unit",
                    quantity: qty,
                    sourceType: "in_house"
                )
            })

            present(alert, animated: true)
        }

    @objc private func closeScreen() {
        dismiss(animated: true)
    }
    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false   // 🔥 VERY IMPORTANT
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }


    // MARK: - Segmented Control
    private func setupSegmentContainer() {
        segmentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentContainer)

        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.backgroundColor = UIColor(white: 0.95, alpha: 1)
        segmented.layer.cornerRadius = 16
        segmented.clipsToBounds = true
        segmentContainer.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmentContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentContainer.heightAnchor.constraint(equalToConstant: 50),

            segmented.leadingAnchor.constraint(equalTo: segmentContainer.leadingAnchor, constant: 20),
            segmented.trailingAnchor.constraint(equalTo: segmentContainer.trailingAnchor, constant: -20),
            segmented.centerYAnchor.constraint(equalTo: segmentContainer.centerYAnchor),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - 🔍 Search Bar (NEW)
    private func setupSearchBar() {
        searchBar.placeholder = "Search services or sub-services"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor, constant: 6),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        tableView.keyboardDismissMode = .onDrag

        tableView.register(SubserviceInnerCell.self,
                           forCellReuseIdentifier: SubserviceInnerCell.reuseID)

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])
    }

    // MARK: - Outsource Form
    private func setupOutsourceForm() {
        outsourceContainer.translatesAutoresizingMaskIntoConstraints = false
        outsourceContainer.isHidden = true
        outsourceContainer.alpha = 0
        view.addSubview(outsourceContainer)

        NSLayoutConstraint.activate([
            outsourceContainer.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor, constant: 10),
            outsourceContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outsourceContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            outsourceContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])

        let form = OutsourceFormView()
        form.onSubmit = { item in
            CartManager.shared.addOutsource(item: item, quantity: 1)
        }

        form.translatesAutoresizingMaskIntoConstraints = false
        outsourceContainer.addSubview(form)

        NSLayoutConstraint.activate([
            form.leadingAnchor.constraint(equalTo: outsourceContainer.leadingAnchor),
            form.trailingAnchor.constraint(equalTo: outsourceContainer.trailingAnchor),
            form.topAnchor.constraint(equalTo: outsourceContainer.topAnchor)
        ])

        outsourceForm = form
    }

    // MARK: - Segment Switch
    @objc private func segmentChanged() {
        let isOutsource = segmented.selectedSegmentIndex == 1

        UIView.animate(withDuration: 0.25) {
            self.tableView.alpha = isOutsource ? 0 : 1
            self.outsourceContainer.alpha = isOutsource ? 1 : 0
        } completion: { _ in
            self.tableView.isHidden = isOutsource
            self.outsourceContainer.isHidden = !isOutsource
        }
    }

    // MARK: - Cart Observer
    func cartDidChange() {
        updateCartUI()
        tableView.reloadData()
    }

    private func updateCartUI() {
        cartLabel.text = "\(CartManager.shared.totalItems()) Items Selected"
        cartTotalLabel.text = "Est. Total: ₹\(Int(CartManager.shared.totalAmount()))"
    }

    // MARK: - Fetch
    private func fetchServices() async {
        let records = try? await SupabaseManager.shared.fetchServices()
        services = records?.map { $0.toServiceModel() } ?? []
        filteredServices = services
        expanded = Array(repeating: false, count: filteredServices.count)

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: - Table Data
extension ServicePickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        filteredServices.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        expanded[section]
            ? min(2, filteredServices[section].subservices.count) + 1
            : 0
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let svc = filteredServices[section]
        let header = ServiceCardHeaderCell()
        header.configure(with: svc.name, expanded: expanded[section])

        header.onToggle = { [weak self] in
            guard let self else { return }
            self.expanded[section].toggle()
            tableView.reloadSections([section], with: .automatic)
        }
        return header
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        64
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let svc = filteredServices[indexPath.section]

        if indexPath.row == min(2, svc.subservices.count) {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.textLabel?.text = "View All →"
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            cell.textLabel?.textColor = .systemPurple
            return cell
        }

        let sub = svc.subservices[indexPath.row]
        let qty = CartManager.shared.items.first {
            $0.serviceName == svc.name && $0.subserviceName == sub.name
        }?.quantity ?? 0

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SubserviceInnerCell.reuseID,
            for: indexPath
        ) as! SubserviceInnerCell

        if let id = svc.id {
            cell.configure(
                parentServiceId: id,
                parentService: svc.name,
                sub: sub,
                quantity: qty
            )
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let svc = filteredServices[indexPath.section]

        if indexPath.row == min(2, svc.subservices.count) {
            let vc = ServiceDetailListViewController(service: svc)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - 🔍 Search Logic
extension ServicePickerViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !term.isEmpty else {
            filteredServices = services
            expanded = Array(repeating: false, count: filteredServices.count)
            tableView.reloadData()
            return
        }

        filteredServices = services.compactMap { service in
            if service.name.localizedCaseInsensitiveContains(term) {
                return service
            }

            let matchedSubs = service.subservices.filter {
                $0.name.localizedCaseInsensitiveContains(term)
            }

            if !matchedSubs.isEmpty {
                var copy = service
                copy.subservices = matchedSubs
                return copy
            }
            return nil
        }

        expanded = Array(repeating: true, count: filteredServices.count)
        tableView.reloadData()
    }
}

