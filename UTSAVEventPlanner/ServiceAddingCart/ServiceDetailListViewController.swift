//
//  ServiceDetailListViewController.swift
//

import UIKit

final class ServiceDetailListViewController: UIViewController {

    // MARK: - Data
    private let service: Service
    private var filteredSubservices: [Subservice]

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchField = UISearchBar()

    // 🔥 SAME CART UI AS ServicePickerViewController
    private let bottomCartView = UIView()
    private let cartLabel = UILabel()
    private let cartTotalLabel = UILabel()
    private let cartIcon = UIImageView(image: UIImage(systemName: "cart.fill"))

    init(service: Service) {
        self.service = service
        self.filteredSubservices = service.subservices
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .systemBackground
        title = service.name

        setupSearch()
        setupTable()
        setupBottomCart()

        CartManager.shared.addObserver(self)
        updateCartUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    deinit {
        CartManager.shared.removeObserver(self)
    }

    // MARK: - Search
    private func setupSearch() {
        searchField.placeholder = "Search \(service.name)…"
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Table
    private func setupTable() {
        tableView.register(SubserviceCell.self, forCellReuseIdentifier: SubserviceCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 🔥 leave space for cart
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])
    }

    // MARK: - Bottom Cart (SAME CODE)
    private func setupBottomCart() {
        bottomCartView.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.backgroundColor = UIColor(
            red: 136.0/255.0,
            green: 71.0/255.0,
            blue: 246.0/255.0,
            alpha: 1.0
        )
        bottomCartView.layer.cornerRadius = 32
        view.addSubview(bottomCartView)

        let iconBg = UIView()
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.backgroundColor = .white
        iconBg.layer.cornerRadius = 20
        bottomCartView.addSubview(iconBg)

        cartIcon.tintColor = UIColor(
            red: 136.0/255.0,
            green: 71.0/255.0,
            blue: 246.0/255.0,
            alpha: 1.0
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
    }

    private func updateCartUI() {
        let items = CartManager.shared.totalItems()
        bottomCartView.isHidden = items == 0
        cartLabel.text = "\(items) Items Selected"
        cartTotalLabel.text = "Est. Total: ₹\(Int(CartManager.shared.totalAmount()))"
    }

    @objc private func openCart() {
        let vc = EstimateCartViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ServiceDetailListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSubservices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let sub = filteredSubservices[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SubserviceCell.reuseID,
            for: indexPath
        ) as! SubserviceCell

        guard let serviceId = service.id else { return cell }

        let qty = CartManager.shared.items.first {
            $0.serviceName == service.name && $0.subserviceName == sub.name
        }?.quantity ?? 0

        cell.configure(
            parentServiceId: serviceId,
            parentService: service.name,
            sub: sub,
            quantity: qty
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ServiceDetailListViewController: UITableViewDelegate {}

// MARK: - UISearchBarDelegate
extension ServiceDetailListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let term = searchText.trimmed
        filteredSubservices = term.isEmpty
            ? service.subservices
            : service.subservices.filter {
                $0.name.localizedCaseInsensitiveContains(term)
            }
        tableView.reloadData()
    }
}

// MARK: - CartObserver
extension ServiceDetailListViewController: CartObserver {
    func cartDidChange() {
        updateCartUI()
        tableView.reloadData()
    }
}

// MARK: - Helper
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

