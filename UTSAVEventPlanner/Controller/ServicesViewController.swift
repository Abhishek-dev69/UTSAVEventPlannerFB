import UIKit

final class ServicesViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var vendorTypeLabel: UILabel!

    @IBOutlet weak var vendorMarketplaceCard: UIView!
    @IBOutlet weak var vendorMarketplaceCardImage: UIImageView!
    @IBOutlet weak var vendorMarketplaceLabel: UILabel!

    @IBOutlet weak var myVendorsCard: UIView!
    @IBOutlet weak var myVendorsImage: UIImageView!
    @IBOutlet weak var myVendorsLabel: UILabel!

    @IBOutlet weak var myServicesCard: UIView!
    @IBOutlet weak var myServicesCardImage: UIImageView!
    @IBOutlet weak var myServicesCardLabel: UILabel!

    override func loadView() {
        let nib = UINib(nibName: "ServicesViewController", bundle: .main)
        guard let root = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("ServicesViewController.xib must have a top-level UIView")
        }
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTapHandlers()
    }

    // MARK: - Tap Gesture Setup
    private func setupTapHandlers() {

        // ⭐ My Services Portfolio → Should open ServicesListViewController
        let myServicesTap = UITapGestureRecognizer(target: self, action: #selector(openMyServices))
        myServicesCard.isUserInteractionEnabled = true
        myServicesCard.addGestureRecognizer(myServicesTap)

        // ⭐ Vendor Marketplace → VendorMarketplaceViewController
        let vendorMarketplaceTap = UITapGestureRecognizer(target: self, action: #selector(openVendorMarketplace))
        vendorMarketplaceCard.isUserInteractionEnabled = true
        vendorMarketplaceCard.addGestureRecognizer(vendorMarketplaceTap)

        // ⭐ My Vendors → MyVendorsViewController
        let myVendorsTap = UITapGestureRecognizer(target: self, action: #selector(openMyVendors))
        myVendorsCard.isUserInteractionEnabled = true
        myVendorsCard.addGestureRecognizer(myVendorsTap)
    }

    // MARK: - Open My Services -> ServicesListViewController
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

    // MARK: - Open Vendor Marketplace -> VendorMarketplaceViewController
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

    // MARK: - Open My Vendors -> MyVendorsViewController
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
