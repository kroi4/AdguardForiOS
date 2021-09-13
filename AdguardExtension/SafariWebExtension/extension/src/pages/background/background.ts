/* eslint-disable consistent-return */
import browser from 'webextension-polyfill';

import {
    MessagesToBackgroundPage,
    MessagesToContentScript,
} from '../common/constants';
import { permissions } from './permissions';
import { log } from '../common/log';
import { app } from './app';
import { Engine } from './engine';
import { getDomain } from '../common/utils/url';
import { buildStyleSheet } from './css-service';
import { SelectorsAndScripts } from '../common/interfaces';
import { adguard } from './adguard';

interface Message {
    type: string,
    data?: any,
}

const getEngine = (() => {
    const engine = new Engine();
    let startPromise: Promise<Engine>;

    const start = async () => {
        const rulesText = await adguard.nativeHost.getAdvancedRulesText();
        await engine.start(rulesText);
        return engine;
    };

    return () => {
        if (!startPromise) {
            startPromise = start();
        }
        return startPromise;
    };
})();

const getScriptsAndSelectors = async (url: string): Promise<SelectorsAndScripts> => {
    const engine = await getEngine();

    const hostname = getDomain(url);
    const cosmeticResult = engine.getCosmeticResult(hostname);

    const injectCssRules = [
        ...cosmeticResult.CSS.generic,
        ...cosmeticResult.CSS.specific,
    ];

    const elementHidingExtCssRules = [
        ...cosmeticResult.elementHiding.genericExtCss,
        ...cosmeticResult.elementHiding.specificExtCss,
    ];

    const injectExtCssRules = [
        ...cosmeticResult.CSS.genericExtCss,
        ...cosmeticResult.CSS.specificExtCss,
    ];

    const cssInject = buildStyleSheet([], injectCssRules, true);
    const cssExtended = buildStyleSheet(
        elementHidingExtCssRules,
        injectExtCssRules,
        false,
    );

    const scriptRules = cosmeticResult.getScriptRules();

    const debug = false;
    const scripts = scriptRules
        .map((scriptRule) => scriptRule.getScript(debug))
        .filter((script): script is string => script !== null);

    // remove repeating scripts
    const uniqueScripts = [...new Set(scripts)];

    return {
        scripts: uniqueScripts,
        cssInject,
        cssExtended,
    };
};

const handleMessages = () => {
    browser.runtime.onMessage.addListener(async (message: Message) => {
        const { type, data } = message;

        switch (type) {
            case MessagesToBackgroundPage.GetScriptsAndSelectors: {
                const { url } = data;
                const scriptsAndSelectors = await getScriptsAndSelectors(url);
                return scriptsAndSelectors as SelectorsAndScripts;
            }
            case MessagesToBackgroundPage.AddRule: {
                await adguard.nativeHost.addToUserRules(data.ruleText);
                break;
            }
            case MessagesToBackgroundPage.OpenAssistant: {
                let { tabId } = data;

                if (!tabId) {
                    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
                    if (!tab.id) {
                        log.error('Was unable to get active tab');
                        return;
                    }
                    tabId = tab.id;
                }

                await browser.tabs.executeScript(tabId, { file: 'assistant.js' });

                // init assistant
                await browser.tabs.sendMessage(tabId, {
                    type: MessagesToContentScript.InitAssistant,
                    data: { addRuleCallbackName: MessagesToBackgroundPage.AddRule },
                });
                break;
            }
            case MessagesToBackgroundPage.SetPermissionsModalViewed: {
                return app.setPermissionsModalViewed();
            }
            case MessagesToBackgroundPage.GetPopupData: {
                const { url } = data;

                const allSitesAllowed = await permissions.areAllSitesAllowed();
                const permissionsModalViewed = await app.isPermissionsModalViewed();

                const {
                    protectionEnabled,
                    hasUserRules,
                    premiumApp,
                    appearanceTheme,
                    contentBlockersEnabled,
                } = await adguard.nativeHost.getInitData(url);

                return {
                    allSitesAllowed,
                    permissionsModalViewed,
                    protectionEnabled,
                    hasUserRules,
                    premiumApp,
                    appearanceTheme,
                    contentBlockersEnabled,
                };
            }
            case MessagesToBackgroundPage.SetProtectionStatus: {
                const { enabled, url } = data;
                if (enabled) {
                    return adguard.nativeHost.enableProtection(url);
                }
                return adguard.nativeHost.disableProtection(url);
            }
            case MessagesToBackgroundPage.ReportProblem: {
                const { url } = data;
                return adguard.nativeHost.reportProblem(url);
            }
            case MessagesToBackgroundPage.UpgradeClicked: {
                await adguard.nativeHost.upgradeMe();
                break;
            }
            default:
                break;
        }
    });
};

export const background = () => {
    // Message listener should be on the upper level to wake up background page
    // when it is necessary
    handleMessages();
};
