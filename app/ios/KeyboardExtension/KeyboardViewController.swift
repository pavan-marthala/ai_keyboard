import UIKit

class KeyboardViewController: UIInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("AtFIx: KeyboardViewController viewDidLoad")
        NSLog("AtFIx: TEST VIEW LOADED")

        view.backgroundColor = .systemRed

        let label = UILabel()
        label.text = "AtFIx TEST"
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
        NSLog("AtFIx: viewWillAppear")
        NSLog("AtFIx: bounds = \(view.bounds)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("AtFIx: viewDidAppear")
        NSLog("AtFIx: bounds = \(view.bounds)")
    }
}
