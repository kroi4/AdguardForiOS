/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DnsAdGuardSDK

enum UserFilterStatus {
    case allowlisted, blocklisted, none
}

/**
 view model for dns request log
 */
class DnsLogRecord {
    // processed dns requestinfo
    let event: DnsRequestProcessedEvent
    // dns tracker info for event.domain
    let tracker: DnsTracker?
    // status determines whether the matched rules are contained in custom filters
    var userFilterStatus: UserFilterStatus

    private let dnsProtection: DnsProtectionProtocol
    private let domainsConverter: DomainsConverterProtocol

    init(event: DnsRequestProcessedEvent, dnsProtection: DnsProtectionProtocol, dnsTrackers: DnsTrackersProviderProtocol, domainsConverter: DomainsConverterProtocol, domainParser: DomainParser?) {
        self.event = event
        self.dnsProtection = dnsProtection
        self.domainsConverter = domainsConverter

        let firstLevelDomain = domainParser?.parse(host: event.domain)?.domain
        tracker = firstLevelDomain == nil ? nil : dnsTrackers.getTracker(by: firstLevelDomain!)
        userFilterStatus = DnsLogRecord.userFilterStatusForDomain(event.domain, dnsProtection: dnsProtection, domainsConverter: domainsConverter)
    }

    // returns subtitle text for table view cell
    func getDetailsString(_ fontSize: CGFloat, _ advancedMode: Bool) -> NSMutableAttributedString {

        let recordType = event.type

        if advancedMode {
            var newDomain = event.domain.hasSuffix(".") ? String(event.domain.dropLast()) : event.domain
            newDomain = " " + newDomain

            let typeAttr = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .semibold) ]
            let domainAttr = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .regular) ]

            let typeAttrString = NSAttributedString(string: recordType, attributes: typeAttr)
            let domainAttrString = NSAttributedString(string: newDomain, attributes: domainAttr)

            let combination = NSMutableAttributedString()
            combination.append(typeAttrString)
            combination.append(domainAttrString)

            return combination
        } else {
            let typeAttr = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .semibold) ]
            let statusAttr = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
                               NSAttributedString.Key.foregroundColor: event.processedStatus.textColor]

            let typeAttrString = NSAttributedString(string: " (" + recordType + ")", attributes: typeAttr)
            let statusAttrString = NSAttributedString(string: event.processedStatus.title, attributes: statusAttr)

            let combination = NSMutableAttributedString()
            combination.append(statusAttrString)
            combination.append(typeAttrString)

            return combination
        }
    }

    // returns first level domain for this request
    func firstLevelDomain(parser: DomainParser?) -> String {
        let firstLevelDomain = parser?.parse(host: event.domain)?.domain
        return firstLevelDomain ?? event.domain
    }

    func updateUserStatus() {
        userFilterStatus = DnsLogRecord.userFilterStatusForDomain(event.domain, dnsProtection: dnsProtection, domainsConverter: domainsConverter)
    }

    private static func userFilterStatusForDomain(_ domain: String, dnsProtection: DnsProtectionProtocol, domainsConverter: DomainsConverterProtocol)->UserFilterStatus {

        // we should check user rules for all domains
        let subdomains: [String] = String.generateSubDomains(from: domain)

        // check allowlist
        for subdomain in subdomains {
            if dnsProtection.checkRuleExists(subdomain, for: .allowlist) {
                return .allowlisted
            }
        }

        // check blocklist
        for subdomain in subdomains {
            let rule = domainsConverter.userFilterBlockRuleFromDomain(subdomain)
            if dnsProtection.checkRuleExists(rule, for: .blocklist) {
                return .blocklisted
            }
        }

        return .none
    }
}

extension DnsLogRecord {
    private func getTypeString() -> String {
        let IPv4 = "A"
        let IPv6 = "AAAA"

        let IPv4String = "IPv4"
        let IPv6String = "IPv6"

        if event.type == IPv4 {
            return IPv4String
        } else if event.type == IPv6 {
            return IPv6String
        } else {
            return event.type
        }
    }

    func getTypeAndIp() -> String {
        let IPv4 = "A"
        let IPv6 = "AAAA"

        let IPv4String = "IPv4"
        let IPv6String = "IPv6"

        if event.type == IPv4 {
            return "\(event.type)(\(IPv4String))"
        } else if event.type == IPv6 {
            return "\(event.type)(\(IPv6String))"
        } else {
            return event.type
        }
    }
}
