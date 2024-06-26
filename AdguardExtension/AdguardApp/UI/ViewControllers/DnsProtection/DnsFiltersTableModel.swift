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

import SharedAdGuardSDK
import DnsAdGuardSDK

/// Delegate for model
protocol DnsFiltersTableModelDelegate: AnyObject {
    func filterAdded()
    func modelsChanged()
}

// TODO: - We should change the order of the filters
// For more info about filters order implementation look up `UserRulesModelsProvider`

/// Model for `DnsFiltersTableController`
/// It encapsulates logic for working with `DnsAdGuardSDK`
final class DnsFiltersTableModel {

    // MARK: - Public variables

    weak var delegate: DnsFiltersTableModelDelegate?

    var searchString: String? {
        didSet {
            modelsProvider.searchString = searchString
            delegate?.modelsChanged()
        }
    }

    var isSearching: Bool { searchString != nil && !searchString!.isEmpty }

    var cellModels: [DnsFilterCellModel] { modelsProvider.filtersModels }

    var enabledRulesCount: Int {
        dnsProtection.filters.reduce(0, { $1.isEnabled ? $0 + $1.rulesCount : $0 })
    }

    // MARK: - Private variables

    private let dnsProtection: DnsProtectionProtocol
    private let dnsConfigAssistant: DnsConfigManagerAssistantProtocol
    private var modelsProvider: DnsFiltersModelsProviderProtocol

    // MARK: - Initialization

    init(dnsProtection: DnsProtectionProtocol, dnsConfigAssistant: DnsConfigManagerAssistantProtocol) {
        self.dnsProtection = dnsProtection
        self.dnsConfigAssistant = dnsConfigAssistant
        self.modelsProvider = DnsFiltersModelsProvider(sdkModels: dnsProtection.filters)
    }

    // MARK: - Private methods

    // TODO: - Don't reinitalize models for every action
    /// There is a problem with interface of `DnsProtection` object from SDK
    /// All the methods that influence custom filters change filters storage directly
    /// For example let's look at `dnsProtection.addFilter`
    /// We provide it with `name` and `url` and it appdends the filter to the storage
    /// But we can't handle or influence the data we save to the storage
    /// We also don't know when and what the filter was added recently when we obtain them from storage
    private func updateModels() {
        modelsProvider = DnsFiltersModelsProvider(sdkModels: dnsProtection.filters)
        modelsProvider.searchString = searchString
    }
}

// MARK: - DnsFiltersTableModel + NewCustomFilterDetailsControllerDelegate

extension DnsFiltersTableModel: NewCustomFilterDetailsControllerDelegate {
    func addCustomFilter(_ meta: ExtendedCustomFilterMetaProtocol, _ onFilterAdded: @escaping (Error?) -> Void) {
        guard let name = meta.name, let urlString = meta.filterDownloadPage, let url = URL(string: urlString) else {
            onFilterAdded(CommonError.missingData)
            return
        }
        dnsProtection.addFilter(withName: name, url: url, isEnabled: true, onFilterAdded: { [weak self] error in
            DispatchQueue.asyncSafeMain { [weak self] in
                self?.updateModels()
                self?.delegate?.filterAdded()
            }

            // Restart tunnel to apply new filter
            if error == nil {
                self?.dnsConfigAssistant.applyDnsPreferences(for: .modifiedDnsFilters, completion: nil)
            }

            onFilterAdded(error)
        })
    }

    func renameFilter(withId filterId: Int, to newName: String) throws -> FilterDetailsProtocol {
        try dnsProtection.renameFilter(withId: filterId, to: newName)
        updateModels()
        delegate?.modelsChanged()
        if let filter = dnsProtection.filters.first(where: { $0.filterId == filterId }) {
            return filter
        }
        throw CommonError.missingData
    }
}

// MARK: - DnsFiltersTableModel + FilterDetailsViewControllerDelegate

extension DnsFiltersTableModel: FilterDetailsViewControllerDelegate {
    func deleteFilter(filterId: Int) throws {
        try dnsProtection.removeFilter(withId: filterId)
        updateModels()
        delegate?.modelsChanged()
        dnsConfigAssistant.applyDnsPreferences(for: .modifiedDnsFilters, completion: nil)
    }

    func setFilter(with groupId: Int?, filterId: Int, enabled: Bool) throws -> FilterDetailsProtocol {
        try dnsProtection.setFilter(withId: filterId, to: enabled)
        updateModels()
        delegate?.modelsChanged()
        dnsConfigAssistant.applyDnsPreferences(for: .modifiedDnsFilters, completion: nil)

        if let filter = dnsProtection.filters.first(where: { $0.filterId == filterId }) {
            return filter
        }
        throw CommonError.missingData
    }
}

// MARK: - DnsFiltersTableModel + DnsFilterCellDelegate

extension DnsFiltersTableModel: DnsFilterCellDelegate {
    func dnsFilterStateChanged(_ filterId: Int, newState: Bool) {
        _ = try? setFilter(with: nil, filterId: filterId, enabled: newState)
    }
}
