import UIKit

class KeyboardViewController: UIInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("AtFix: KeyboardViewController viewDidLoad")
        NSLog("AtFix: TEST VIEW LOADED")

        view.backgroundColor = .systemRed

        let label = UILabel()
        label.text = "AtFix TEST"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let height = view.heightAnchor.constraint(equalToConstant: 256)
        height.priority = .defaultHigh
        height.isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("AtFix: viewWillAppear")
        NSLog("AtFix: bounds = \(view.bounds)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("AtFix: viewDidAppear")
        NSLog("AtFix: bounds = \(view.bounds)")
    }
}
