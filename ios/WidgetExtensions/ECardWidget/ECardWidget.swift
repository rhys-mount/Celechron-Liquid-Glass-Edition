//
//  ECardWidget.swift
//  WidgetExtensions
//
//  Created by 施子捷 on 2024/7/8.
//

import SwiftUI
import WidgetKit

struct ECardEntry: TimelineEntry {
    let date: Date
    let balance: Int
}

struct ECardWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ECardEntry {
        ECardEntry(date: Date(), balance: -1)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ECardEntry) -> Void) {
        completion(ECardEntry(date: Date(), balance: -1))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    #if DEBUG
        let accessGroup = "group.top.celechron.celechron.debug"
    #else
        let accessGroup = "group.top.celechron.celechron"
    #endif
        let keychainQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount: "synjonesAuth",
            kSecAttrAccessGroup: accessGroup,
            kSecAttrService: "Celechron",
            kSecAttrSynchronizable: false,
            kSecReturnData: true,
        ]
        var ref: AnyObject?
        let status = SecItemCopyMatching(
            keychainQuery as CFDictionary,
            &ref
        )
        if (status == errSecItemNotFound) {
            cacheBalance(-1)
            completion(Timeline(entries: [ECardEntry(date: Date(), balance: -1)], policy: .after(Date(timeIntervalSinceNow: 1800))))
            return
        }
        
        var value: String? = nil
        if (status == noErr) {
            value = String(data: ref as! Data, encoding: .utf8)
        }
        
        if (value == nil) {
            cacheBalance(-1)
            completion(Timeline(entries: [ECardEntry(date: Date(), balance: -1)], policy: .after(Date(timeIntervalSinceNow: 1800))))
            return
        } else if (value == "3200000000") {
            // 测试账号没有真实余额，不能把样例金额写入运行时缓存。
            cacheBalance(-1)
            completion(Timeline(entries: [ECardEntry(date: Date(), balance: -1)], policy: .after(Date(timeIntervalSinceNow: 1800))))
            return
        }
        
        let cachedBalance = readCachedBalance()
        let service = ECardService()
        service.fetchCards(auth: value!) { result in
            let balance: Int
            let refreshInterval: TimeInterval
            switch result {
            case let .success(cards):
                balance = cards.first?.balance ?? -1
                refreshInterval = 1800
                cacheBalance(balance)
            case .failure(.authenticationExpired), .failure(.noCards):
                // Match Watch's definition of an unusable credential/card, but
                // never delete the shared iPhone Keychain item from an extension.
                balance = -1
                refreshInterval = 300
                cacheBalance(-1)
            case .failure(.transientFailure):
                // A network outage is not credential expiry; retain the last
                // known balance and ask WidgetKit to retry sooner.
                balance = cachedBalance
                refreshInterval = 300
            case .failure(.invalidResponse), .failure(.noBarcode):
                balance = cachedBalance
                refreshInterval = 900
            }
            completion(Timeline(
                entries: [ECardEntry(date: Date(), balance: balance)],
                policy: .after(Date(timeIntervalSinceNow: refreshInterval))
            ))
        }
    }

    private func readCachedBalance() -> Int {
        #if DEBUG
        let suiteName = "group.top.celechron.celechron.debug"
        #else
        let suiteName = "group.top.celechron.celechron"
        #endif
        let defaults = UserDefaults(suiteName: suiteName)
        guard defaults?.object(forKey: "ecardBalance") != nil else { return -1 }
        return defaults?.integer(forKey: "ecardBalance") ?? -1
    }

    /// 缓存余额到 App Group，供 Apple Watch 经 iPhone 同步读取
    private func cacheBalance(_ balance: Int) {
        #if DEBUG
        let suiteName = "group.top.celechron.celechron.debug"
        #else
        let suiteName = "group.top.celechron.celechron"
        #endif
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(balance, forKey: "ecardBalance")
        defaults?.set(Date(), forKey: "ecardUpdateTime")
    }
}

struct ECardWidget: Widget {
    let kind: String = "ECardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ECardWidgetProvider()) { entry in
            ECardWidgetView(entry: entry)
        }.supportedFamilies([.systemSmall])
    }
}

struct ECardWidgetView: View {
    let entry: ECardWidgetProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        #if DEBUG
        let suite = "group.top.celechron.celechron.debug"
        #else
        let suite = "group.top.celechron.celechron"
        #endif
        switch UserDefaults(suiteName: suite)?.string(forKey: "ecardWidgetBrightness") ?? "system" {
        case "light": return false
        case "dark": return true
        default: return colorScheme == .dark
        }
    }
    
    var body: some View {
        let dark = isDark
        let accent = dark
            ? Color(red: 10 / 255.0, green: 132 / 255.0, blue: 1)
            : Color(red: 0, green: 63 / 255.0, blue: 136 / 255.0)
        let darkSurface = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)
        let balanceString = entry.balance > 0 ? 
                                entry.balance < 10000 ?
        String(format: "%d.%d%d元", arguments: [entry.balance / 100, entry.balance % 100 / 10, entry.balance % 10])
                                  : String(format: "%d.%d元", arguments: [entry.balance / 100, entry.balance % 100 / 10])
                            : "待刷新"
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "creditcard").foregroundColor(accent)
                Spacer().frame(width: 4)
                Text("校园卡余额")
                    .font(.footnote).bold()
                    .foregroundColor(dark ? .white : darkSurface)
            }
            
            Spacer().frame(height: 8)
            
            HStack(spacing: 6) {
                Group {
                    if #available(iOSApplicationExtension 16.1, *) {
                        Text(balanceString).font(.title).bold().fontDesign(.rounded)
                    } else {
                        Text(balanceString).font(.title.bold())
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: "qrcode").font(.title2)
            }
            .foregroundColor(accent)
        }
        .widgetBackground(dark ? darkSurface : Color.white)
        .widgetURL(URL(string: "celechron://ecardpaypage"))
    }
}

@available(iOS 18.0, *)
#Preview(as: .systemSmall) {
    ECardWidget()
} timeline: {
    ECardEntry(date: Date(), balance: 1888)
}
