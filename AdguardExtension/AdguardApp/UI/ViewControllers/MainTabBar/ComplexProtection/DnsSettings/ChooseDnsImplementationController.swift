//
// This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
// Copyright © Adguard Software Limited. All rights reserved.
//
// Adguard for iOS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Adguard for iOS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Adguard for iOS. If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import DnsAdGuardSDK

protocol ChooseDnsImplementationControllerDelegate: AnyObject {
    func currentImplementationChanged()
}

final class ChooseDnsImplementationController: BottomAlertController {

    @IBOutlet weak var adGuardButton: UIButton!
    @IBOutlet weak var nativeButton: UIButton!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet var themableLabels: [ThemableLabel]!
    @IBOutlet var popupButtons: [RoundRectButton]!

    weak var delegate: ChooseDnsImplementationControllerDelegate?

    // MARK: - services
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let resources: AESharedResourcesProtocol = ServiceLocator.shared.getService()!
    private let nativeDnsManager: NativeDnsSettingsManagerProtocol = ServiceLocator.shared.getService()!
    private let dnsProvidersManager: DnsProvidersManagerProtocol = ServiceLocator.shared.getService()!

    override func viewDidLoad() {
        super.viewDidLoad()
        processCurrentImplementation()
        updateTheme()
    }

    // MARK: - Private methods

    @IBAction func adGuardSelected(_ sender: UIButton) {
        dnsProvidersManager.update(dnsImplementation: .adGuard)
        resources.dnsImplementation = .adGuard
        delegate?.currentImplementationChanged()
        processCurrentImplementation()
        if #available(iOS 14.0, *) {
            nativeDnsManager.removeDnsConfig { _ in }
        }
        dismiss(animated: true)
    }

    @IBAction func nativeSelected(_ sender: UIButton) {
        dnsProvidersManager.update(dnsImplementation: .native)
        resources.dnsImplementation = .native
        delegate?.currentImplementationChanged()
        processCurrentImplementation()
        dismiss(animated: true)
    }

    // MARK: - Private methods

    private func processCurrentImplementation() {
        let implementation = resources.dnsImplementation

        adGuardButton.isSelected = implementation == .adGuard
        nativeButton.isSelected = implementation == .native
    }
}

extension ChooseDnsImplementationController: ThemableProtocol {
    func updateTheme() {
        titleLabel.textColor = theme.popupTitleTextColor
        contentView.backgroundColor = theme.popupBackgroundColor
        theme.setupLabels(themableLabels)
        theme.setupSeparator(separator)
        theme.setupPopupButtons(popupButtons)
    }
}
