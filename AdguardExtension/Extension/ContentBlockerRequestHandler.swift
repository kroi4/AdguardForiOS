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

import SafariAdGuardSDK
import SharedAdGuardSDK

private let LOG = LoggerFactory.getLoggerWrapper(ContentBlockerRequestHandler.self)

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {

        let resources = AESharedResources()

        // Init Logger
        let logManager = LoggerManagerImpl(url: resources.sharedLogsURL())
        let logLevel: LogLevel = resources.isDebugLogs ? .debug : .info
        logManager.configure(logLevel)
        LOG.info("InitLogger \(logLevel)")


        // migrate settings if needed
        let migration = ContentBlockerMigrationService(resources: resources)
        migration.migrateIfNeeded()

        LOG.info("ActionRequestHandler start request")

        guard let cbBundleId = Bundle.main.bundleIdentifier else {
            LOG.error("ActionRequestHandler received nil bundle id")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let url: URL?

        do {
            let jsonProvider = try ContentBlockerJsonProvider(
                cbBundleId: cbBundleId,
                mainAppBundleId: Bundle.main.hostAppBundleId,
                jsonStorageUrl: SharedStorageUrls().cbJsonsFolderUrl,
                userDefaults: resources.sharedDefaults()
            )
            url = jsonProvider.jsonUrl
        } catch {
            LOG.error("ActionRequestHandler error getting JSON URL; Error: \(error)")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        guard let url = url, let attachment = NSItemProvider(contentsOf: url) else {
            LOG.error("ActionRequestHandler Can't init attachment")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]

        LOG.info("ActionRequestHandler complete request")
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
