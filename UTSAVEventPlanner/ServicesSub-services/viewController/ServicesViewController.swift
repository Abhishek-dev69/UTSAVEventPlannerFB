import UIKit

final class ServicesViewController: UIViewController {

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let vendorTypeLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Vendor Type"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return l
    }()

    // Cards (no image)
    private lazy var vendorMarketplaceCard = makeCard(title: "Vendor Marketplace")
    private lazy var myVendorsCard = makeCard(title: "My Vendors")
    private lazy var myServicesCard = makeCard(title: "My Service Portfolio")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Page background (same soft gray as other tabs)
        applyBrandGradient()
        view.backgroundColor = .systemBackground

        // Use navigation bar title (matches Dashboard / Inventory)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Services"

        // Optionally adjust nav bar appearance to match others (uncomment if desired)
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear // subtle match
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 22, weight: .bold)
            ]
            appearance.shadowColor = .clear
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

        setupLayout()
        setupTapHandlers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }
 
    // MARK: - Layout

    private func setupLayout() {
        // Add scrollView and content
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Inside contentView add labels and cards
        contentView.addSubview(vendorTypeLabel)
        contentView.addSubview(vendorMarketplaceCard)
        contentView.addSubview(myVendorsCard)

        // My Services header + card
        let myServicesHeader = UILabel()
        myServicesHeader.translatesAutoresizingMaskIntoConstraints = false
        myServicesHeader.text = "My Services"
        myServicesHeader.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        contentView.addSubview(myServicesHeader)
        contentView.addSubview(myServicesCard)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Scroll view pinned to safe area (below nav bar)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // content view pinned to scroll view content layout
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // match widths so it scrolls vertically
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Vendor Type label (start content close to top of the scroll area)
            vendorTypeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            vendorTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            vendorTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Vendor Marketplace card
            vendorMarketplaceCard.topAnchor.constraint(equalTo: vendorTypeLabel.bottomAnchor, constant: 16),
            vendorMarketplaceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            vendorMarketplaceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            vendorMarketplaceCard.heightAnchor.constraint(equalToConstant: 76),

            // My Vendors card
            myVendorsCard.topAnchor.constraint(equalTo: vendorMarketplaceCard.bottomAnchor, constant: 16),
            myVendorsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            myVendorsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            myVendorsCard.heightAnchor.constraint(equalToConstant: 76),

            // My Services header
            myServicesHeader.topAnchor.constraint(equalTo: myVendorsCard.bottomAnchor, constant: 28),
            myServicesHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            myServicesHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // My Services card
            myServicesCard.topAnchor.constraint(equalTo: myServicesHeader.bottomAnchor, constant: 16),
            myServicesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            myServicesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            myServicesCard.heightAnchor.constraint(equalToConstant: 76),

            // bottom anchor to provide scrollable content
            myServicesCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Card Factory (text-only + chevron; card color = systemBackground)

    private func makeCard(title: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 14
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = title
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        lbl.numberOfLines = 1

        let chevron = UIImageView()
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            chevron.image = UIImage(systemName: "chevron.right")
            chevron.tintColor = .tertiaryLabel
        }

        card.addSubview(lbl)
        card.addSubview(chevron)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            lbl.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 20)
        ])

        return card
    }

    // MARK: - Tap Handlers

    private func setupTapHandlers() {
        vendorMarketplaceCard.isUserInteractionEnabled = true
        let vendorMarketplaceTap = UITapGestureRecognizer(target: self, action: #selector(openVendorMarketplace))
        vendorMarketplaceCard.addGestureRecognizer(vendorMarketplaceTap)

        myVendorsCard.isUserInteractionEnabled = true
        let myVendorsTap = UITapGestureRecognizer(target: self, action: #selector(openMyVendors))
        myVendorsCard.addGestureRecognizer(myVendorsTap)

        myServicesCard.isUserInteractionEnabled = true
        let myServicesTap = UITapGestureRecognizer(target: self, action: #selector(openMyServices))
        myServicesCard.addGestureRecognizer(myServicesTap)
    }

    // MARK: - Navigation actions

    @objc private func openMyServices() {
        let vc = ServicesListViewController()
        vc.hidesBottomBarWhenPushed = true
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    @objc private func openVendorMarketplace() {
        let vc = VendorMarketplaceViewController()
        vc.hidesBottomBarWhenPushed = true
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    @objc private func openMyVendors() {
        let vc = MyVendorsViewController()
        vc.hidesBottomBarWhenPushed = true
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

