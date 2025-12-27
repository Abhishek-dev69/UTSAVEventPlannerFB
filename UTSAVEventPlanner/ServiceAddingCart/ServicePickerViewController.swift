//
//  ServicePickerViewController.swift
//

import UIKit

final class ServicePickerViewController: UIViewController, CartObserver {

    // MARK: - UI Components
    private let segmented = UISegmentedControl(items: ["In-House Services", "Outsource Services"])
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let segmentContainer = UIView()

    private let outsourceContainer = UIView()
    private var outsourceForm: OutsourceFormView?

    // Bottom cart UI
    private let bottomCartView = UIView()
    private let cartLabel = UILabel()
    private let cartTotalLabel = UILabel()
    private let cartIcon = UIImageView(image: UIImage(systemName: "cart.fill"))

    // MARK: - Data
    private var services: [Service] = []
    private var expanded: [Bool] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNav()
        setupSegmentContainer()
        setupTable()
        setupOutsourceForm()
        setupBottomCart()

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

    // MARK: - Navigation Bar
    private func setupNav() {
        navigationItem.title = "Add Requirements"

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .black
        back.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)

        // ✅ PLUS BUTTON
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addCustomServiceTapped)
        )
    }

    @objc private func closeScreen() {
        dismiss(animated: true)
    }

    // MARK: - ➕ Custom Service Form
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
            $0.text = "1"
        }
        alert.addTextField {
            $0.placeholder = "Rate (₹)"
            $0.keyboardType = .decimalPad
        }
        alert.addTextField { $0.placeholder = "Notes (optional)" }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            self.handleCustomServiceSubmit(alert)
        })

        present(alert, animated: true)
    }

    private func handleCustomServiceSubmit(_ alert: UIAlertController) {
        let name = alert.textFields?[0].text?.trimmed ?? ""
        let qty = Int(alert.textFields?[1].text ?? "1") ?? 1
        let rate = Double(alert.textFields?[2].text ?? "") ?? 0
        let notes = alert.textFields?[3].text?.trimmed ?? ""

        guard !name.isEmpty, qty > 0 else { return }

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
    }

    // MARK: - Segmented Control
    private func setupSegmentContainer() {
        segmentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentContainer)

        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.backgroundColor = UIColor(white: 0.95, alpha: 1)
        segmented.layer.cornerRadius = 16

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

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(SubserviceInnerCell.self, forCellReuseIdentifier: SubserviceInnerCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])
    }

    // MARK: - Outsource
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

    // MARK: - Bottom Cart
    private func setupBottomCart() {
        bottomCartView.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        bottomCartView.layer.cornerRadius = 32
        view.addSubview(bottomCartView)

        let iconBg = UIView()
        iconBg.backgroundColor = .white
        iconBg.layer.cornerRadius = 20
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        bottomCartView.addSubview(iconBg)

        cartIcon.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        cartIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(cartIcon)

        cartLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        cartLabel.textColor = .white
        cartLabel.translatesAutoresizingMaskIntoConstraints = false

        cartTotalLabel.font = .systemFont(ofSize: 14)
        cartTotalLabel.textColor = .white
        cartTotalLabel.translatesAutoresizingMaskIntoConstraints = false

        bottomCartView.addSubview(cartLabel)
        bottomCartView.addSubview(cartTotalLabel)

        bottomCartView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openCart))
        )

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

    @objc private func openCart() {
        let nav = UINavigationController(rootViewController: EstimateCartViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Segment switch
    @objc private func segmentChanged() {
        let isOutsource = segmented.selectedSegmentIndex == 1

        outsourceContainer.isHidden = !isOutsource
        tableView.isHidden = isOutsource

        UIView.animate(withDuration: 0.25) {
            self.outsourceContainer.alpha = isOutsource ? 1 : 0
            self.tableView.alpha = isOutsource ? 0 : 1
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

    // MARK: - Fetch Services
    private func fetchServices() async {
        let records = try? await SupabaseManager.shared.fetchServices()
        services = records?.map { $0.toServiceModel() } ?? []
        expanded = Array(repeating: false, count: services.count)
        tableView.reloadData()
    }
}

// MARK: - Table Data
extension ServicePickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { services.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        expanded[section] ? min(2, services[section].subservices.count) + 1 : 0
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let header = ServiceCardHeaderCell()
        header.configure(with: services[section].name, expanded: expanded[section])
        header.onToggle = {
            self.expanded[section].toggle()
            tableView.reloadSections([section], with: .automatic)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 64 }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let svc = services[indexPath.section]

        if indexPath.row == min(2, svc.subservices.count) {
            let cell = UITableViewCell()
            cell.textLabel?.text = "View All →"
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
            cell.configure(parentServiceId: id, parentService: svc.name, sub: sub, quantity: qty)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let svc = services[indexPath.section]
        if indexPath.row == min(2, svc.subservices.count) {
            navigationController?.pushViewController(
                ServiceDetailListViewController(service: svc),
                animated: true
            )
        }
    }
}
