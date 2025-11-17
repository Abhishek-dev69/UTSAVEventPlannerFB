//
//  ServicePickerViewController.swift
//

import UIKit

final class ServicePickerViewController: UIViewController, CartObserver {

    // MARK: - UI Components
    private let segmented = UISegmentedControl(items: ["In-House Services", "Outsource Services"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    // Outsource form container
    private let outsourceContainer = UIView()
    private var outsourceForm: OutsourceFormView?

    // Bottom cart UI
    private let bottomCartView = UIView()
    private let cartLabel = UILabel()
    private let cartTotalLabel = UILabel()
    private let cartIcon = UIImageView(image: UIImage(systemName: "cart.fill"))

    // MARK: - Data
    private var services: [Service] = []
    private var expanded: [Bool] = []   // accordion expand states

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNav()
        setupTable()
        setupOutsourceForm()
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

    deinit {
        CartManager.shared.removeObserver(self)
    }

    // MARK: - Navigation
    private func setupNav() {
        navigationItem.title = "Add Requirements"
        navigationItem.titleView = segmented

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .black
        back.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)
    }

    @objc private func closeScreen() {
        dismiss(animated: true)
    }

    // MARK: - Table Setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        tableView.register(SubserviceInnerCell.self, forCellReuseIdentifier: SubserviceInnerCell.reuseID)

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

    // MARK: - Outsource Form Setup
    // MARK: - Outsource Form Setup
    private func setupOutsourceForm() {

        outsourceContainer.translatesAutoresizingMaskIntoConstraints = false
        outsourceContainer.isHidden = true
        outsourceContainer.alpha = 0
        view.addSubview(outsourceContainer)

        NSLayoutConstraint.activate([
            outsourceContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outsourceContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            outsourceContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            outsourceContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -95)
        ])

        let form = OutsourceFormView()

        form.onSubmit = { [weak self] item in
            CartManager.shared.addItem(
                serviceId: nil,
                serviceName: "Outsource",
                subserviceId: UUID().uuidString,
                subserviceName: item.name,
                rate: item.estimatedBudget ?? 0,
                unit: "*unit*",
                quantity: 1,
                sourceType: "outsource"
            )

            // Stay on same screen — do NOT navigate back
            self?.cartDidChange()
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
    // MARK: - Bottom Cart
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
        let vc = EstimateCartViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    
    // MARK: - Segmented Control
    @objc private func segmentChanged() {
        let isOutsource = segmented.selectedSegmentIndex == 1

        if isOutsource {
            // show outsource form
            outsourceContainer.isHidden = false
            tableView.isHidden = false

            UIView.animate(withDuration: 0.25) {
                self.tableView.alpha = 0
                self.outsourceContainer.alpha = 1
            } completion: { _ in
                self.tableView.isHidden = true
            }

        } else {
            // show in-house table
            outsourceContainer.isHidden = false
            tableView.isHidden = false

            UIView.animate(withDuration: 0.25) {
                self.tableView.alpha = 1
                self.outsourceContainer.alpha = 0
            } completion: { _ in
                self.outsourceContainer.isHidden = true
            }
        }
    }

    // MARK: - Cart Observer
    func cartDidChange() {
        updateCartUI()
        tableView.reloadData()
    }

    private func updateCartUI() {
        let count = CartManager.shared.totalItems()
        let total = Int(CartManager.shared.totalAmount())
        cartLabel.text = "\(count) Items Selected"
        cartTotalLabel.text = "Est. Total: ₹\(total)"
    }

    // MARK: - Fetch Services
    private func fetchServices() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()
            services = records.map { $0.toServiceModel() }
            expanded = Array(repeating: false, count: services.count)

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("fetch services error:", error.localizedDescription)
        }
    }
}

// MARK: - TableView Data
extension ServicePickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // subservices (max 2) + "View All →"
        expanded[section] ? min(2, services[section].subservices.count) + 1 : 0
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let svc = services[section]
        let header = ServiceCardHeaderCell()
        header.configure(with: svc.name, expanded: expanded[section])
        header.onToggle = { [weak self] in
            guard let self else { return }
            expanded[section].toggle()
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

        let svc = services[indexPath.section]

        // last row = "View All →"
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

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SubserviceInnerCell.reuseID,
            for: indexPath
        ) as! SubserviceInnerCell

        guard let serviceId = svc.id else { return cell }   // safer
        cell.configure(
            parentServiceId: serviceId,
            parentService: svc.name,
            sub: sub,
            quantity: qty
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let svc = services[indexPath.section]

        if indexPath.row == min(2, svc.subservices.count) {
            let vc = ServiceDetailListViewController(service: svc)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

