//
// CartDetailsViewController.swift
//

import UIKit

final class CartDetailsViewController: UIViewController {
    private let table = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart"
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(table)
        table.frame = view.bounds
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.tableFooterView = UIView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearCart))

        CartManager.shared.addObserver(self)
    }

    deinit {
        CartManager.shared.removeObserver(self)
    }

    @objc private func clearCart() {
        let alert = UIAlertController(title: "Clear Cart", message: "Remove all selected items?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            CartManager.shared.clear()
            self.table.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension CartDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        CartManager.shared.items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = CartManager.shared.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        cfg.text = "\(item.subserviceName) x\(item.quantity)"
        cfg.secondaryText = "₹\(Int(item.lineTotal)) • \(item.serviceName)"
        cell.contentConfiguration = cfg
        return cell
    }
}

extension CartDetailsViewController: CartObserver {
    func cartDidChange() {
        table.reloadData()
    }
}

