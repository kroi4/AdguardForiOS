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

protocol ThemableProtocol {
    func updateTheme()
}

extension AppDelegate {

    func subscribeToThemeChangeNotification() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { [weak self] _ in
            let themeService: ThemeServiceProtocol = ServiceLocator.shared.getService()!
            self?.window?.backgroundColor = themeService.backgroundColor
            self?.updateTheme()
        }
    }

    func updateTheme() {
        guard let root =  window?.rootViewController else { return }
        recursiveThemeUpdate(vc: root)
    }

    private func recursiveThemeUpdate(vc: UIViewController?) {
        if vc == nil { return }
        recursiveThemeUpdate(vc: vc?.presentedViewController)
        recursiveChildrenThemeUpdate(children: vc?.children)
        (vc as? ThemableProtocol)?.updateTheme()
    }

    private func recursiveChildrenThemeUpdate(children: [UIViewController]?) {
        guard let children = children, !children.isEmpty else { return }
        children.forEach {
            recursiveChildrenThemeUpdate(children: $0.children)
            if $0.isViewLoaded {
                ($0 as? ThemableProtocol)?.updateTheme()
            }
        }
    }
}
