//
//  ServicePickerViewController.swift
//

import UIKit

final class ServicePickerViewController: UIViewController, CartObserver {

    // MARK: - UI
    private let segmented = UISegmentedControl(items: ["In-House Services", "Outsource Services"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let bottomCartView = UIView()
    private let cartLabel = UILabel()
    private let cartTotalLabel = UILabel()
    private let cartIcon = UIImageView(image: UIImage(systemName: "cart.fill"))

    // MARK: - Data
    private var services: [Service] = []
    private var expanded: [Bool] = []    // accordion states

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNav()
        setupTable()
        setupBottomCart()

        CartManager.shared.addObserver(self)

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        Task {
            _ = try? await SupabaseManager.shared.ensureUserId()
            CartManager.shared.loadFromServer()
            await fetchServices()
        }
    }

    deinit { CartManager.shared.removeObserver(self) }

    // MARK: - Cart Observer
    func cartDidChange() {
        updateCartUI()
        tableView.reloadData()
    }

    // MARK: - Navigation Bar
    private func setupNav() {
        navigationItem.title = "Add Requirements"
        navigationItem.titleView = segmented

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .black
        back.addTarget(self, action: #selector(close), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)
    }

    @objc private func close() { dismiss(animated: true) }

    // MARK: - Table Setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .white

        // Register only CELL
        tableView.register(SubserviceInnerCell.self,
                           forCellReuseIdentifier: SubserviceInnerCell.reuseID)

        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -95)
        ])
    }
    // MARK: - Bottom Cart UI
    private func setupBottomCart() {
        bottomCartView.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        bottomCartView.layer.cornerRadius = 26
        view.addSubview(bottomCartView)

        cartIcon.tintColor = .white
        cartIcon.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(cartIcon)

        cartLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        cartLabel.textColor = .white
        cartLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(cartLabel)

        cartTotalLabel.textColor = .white
        cartTotalLabel.font = .systemFont(ofSize: 14)
        cartTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(cartTotalLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openCart))
        bottomCartView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            bottomCartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomCartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomCartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bottomCartView.heightAnchor.constraint(equalToConstant: 64),

            cartIcon.leadingAnchor.constraint(equalTo: bottomCartView.leadingAnchor, constant: 16),
            cartIcon.centerYAnchor.constraint(equalTo: bottomCartView.centerYAnchor),

            cartLabel.leadingAnchor.constraint(equalTo: cartIcon.trailingAnchor, constant: 12),
            cartLabel.topAnchor.constraint(equalTo: bottomCartView.topAnchor, constant: 10),

            cartTotalLabel.leadingAnchor.constraint(equalTo: cartLabel.leadingAnchor),
            cartTotalLabel.topAnchor.constraint(equalTo: cartLabel.bottomAnchor, constant: 2)
        ])

        updateCartUI()
    }

    @objc private func openCart() {
        let vc = CartDetailsViewController()
        present(vc, animated: true)
    }

    private func updateCartUI() {
        let count = CartManager.shared.totalItems()
        let total = Int(CartManager.shared.totalAmount())
        cartLabel.text = "\(count) Items Selected"
        cartTotalLabel.text = "Est. Total: ₹\(total)"
    }

    @objc private func segmentChanged() {
        tableView.reloadData()
    }

    // MARK: - Fetch Services
    private func fetchServices() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()
            services = records.map { $0.toServiceModel() }
            expanded = Array(repeating: false, count: services.count)

            DispatchQueue.main.async { self.tableView.reloadData() }
        } catch {
            print("fetch error:", error.localizedDescription)
        }
    }
}

// MARK: - TableView
extension ServicePickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        expanded[section] ? min(2, services[section].subservices.count) + 1 : 0
        // +1 for "View All →"
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let svc = services[section]
        let cell = ServiceCardHeaderCell()
        cell.configure(with: svc.name, expanded: expanded[section])
        cell.onToggle = { [weak self] in
            self?.expanded[section].toggle()
            tableView.reloadSections([section], with: .automatic)
        }
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let svc = services[indexPath.section]

        // Last row = View All link
        if indexPath.row == min(2, svc.subservices.count) {
            let cell = UITableViewCell()
            cell.selectionStyle = .none

            let label = UILabel()
            label.text = "View All →"
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            label.textColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 32),
                label.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
                label.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -10)
            ])

            return cell
        }

        let sub = svc.subservices[indexPath.row]
        let qty = CartManager.shared.items.first(where: {
            $0.serviceName == svc.name && $0.subserviceName == sub.name
        })?.quantity ?? 0

        let cell = tableView.dequeueReusableCell(withIdentifier: SubserviceInnerCell.reuseID, for: indexPath) as! SubserviceInnerCell
        cell.configure(parentService: svc.name, sub: sub, quantity: qty)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let svc = services[indexPath.section]

        // View All tapped
        if indexPath.row == min(2, svc.subservices.count) {
            let vc = ServiceDetailListViewController(service: svc)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

