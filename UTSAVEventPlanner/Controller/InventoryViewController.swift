import UIKit

final class InventoryViewController: UIViewController {
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var imageCard: UIView!
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyBodyLabel: UILabel!

    override func loadView() {
        let nib = UINib(nibName: "InventoryViewController", bundle: .main)
        guard let root = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("InventoryViewController.xib must have a top-level UIView")
        }
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
