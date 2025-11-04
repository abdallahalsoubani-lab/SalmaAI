//
//  RealtimeVoiceViewModel.swift
//  SalmaAI
//
//  Created by Soubani on 03/10/2025.
//  FIXED VERSION - Updated for better consistency
//

import Foundation
import AVFoundation
import WebRTC
import SwiftUI
import UIKit

struct ChatMessage: Identifiable, Equatable, Hashable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(id: String = UUID().uuidString,
         text: String,
         isUser: Bool,
         timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct CliQTransferData {
    let page: String
    let amount: String?
    let phone: String?
    let alias: String?
    let checkout: Bool? // للتحقق من checkout في order_batch
    
    init(page: String, amount: String? = nil, phone: String? = nil, alias: String? = nil, checkout: Bool? = nil) {
        self.page = page
        self.amount = amount
        self.phone = phone
        self.alias = alias
        self.checkout = checkout
    }
}

// MARK: - Product Price Catalog (الأسعار الحقيقية)
struct ProductPriceCatalog {
    static let prices: [String: Double] = [
        // قهوة تركية 1 كغم (الأسعار الحقيقية)
        "Turkish_medium_cardamom_1kg": 19.824,      // قهوة تركية وسط مع هيل 1 كغم
        "Turkish_dark_none_1kg": 19.824,            // قهوة تركية غامقة بدون هيل 1 كغم
        "Turkish_decaf_cardamom_1kg": 24.106,       // قهوة تركية منزوعة الكافيين مع هيل 1 كغم
        "Turkish_light_cardamom_1kg": 19.824,
        "Turkish_medium_none_1kg": 19.824,
        "Turkish_dark_cardamom_1kg": 19.824,
        
        // قهوة إسبرسو 1 كغم (الأسعار الحقيقية)
        "Espresso_ground_1kg": 23.822,              // قهوة إسبرسو مطحونة 1 كغم
        "Espresso_beans_1kg": 23.822,               // حبوب إسبرسو 1 كغم
        
        // الكاسات (الأسعار الحقيقية)
        "Cup_Levant_Espresso_50ml": 4.500,          // كوب ليفانت إسبريسو 50 مل
        "Cup_Levant_Espresso_100ml": 6.000,         // كوب ليفانت إسبريسو 100 مل
        "Cup_Jasmina_Latte": 5.000,                  // كوب ياسمينا للاتيه
        "Cup_Jasmina_Cappuccino": 5.000,            // كوب ياسمينا للكابتشينو
        "Cup_Jasmina_double_glass": 4.000,           // كوب ياسمينا زجاج مزدوج
        "Cup_Turkish_plain_100ml": 2.000,            // كوب قهوة تركية سادة 100 مل
        "Cup_Turkish_medium_100ml": 2.000,          // كوب قهوة تركية وسط 100 مل
        "Cup_Turkish_sweet_100ml": 2.000,            // كوب قهوة تركية حلوة 100 مل
        "Cup_Turkish_Sada_100": 2.000,              // Turkish Coffee Sada 100ml (Brewed category)
        "Cup_Sada_small": 2.000,
        "Cup_Sada_medium": 2.500,
        "Cup_Sada_large": 3.000,
    ]
    
    static func getPrice(category: String, productName: String, weight: String?, cardamom: String?, grind: String?, cupType: String?, size: String?) -> Double? {
        // بناء مفتاح البحث
        var key = ""
        
        if category.contains("Turkish") || category.contains("Turkish Coffee") || productName.contains("تركية") || productName.contains("Turkish") {
            // قهوة تركية
            var roast = "medium" // default
            let productNameLower = productName.lowercased()
            let categoryLower = category.lowercased()
            
            if productNameLower.contains("غامقة") || productNameLower.contains("dark") || productNameLower.contains("غامق") {
                roast = "dark"
            } else if productNameLower.contains("فاتحة") || productNameLower.contains("light") || productNameLower.contains("فاتح") {
                roast = "light"
            } else if productNameLower.contains("منزوعة") || productNameLower.contains("decaf") || productNameLower.contains("منزوع") || productNameLower.contains("كافيين") {
                roast = "decaf"
            } else if productNameLower.contains("وسط") || productNameLower.contains("medium") {
                roast = "medium"
            }
            
            let cardamomValue = cardamom?.lowercased() ?? ""
            let cardamomStr: String
            if cardamomValue == "none" || cardamomValue.isEmpty || cardamomValue.contains("بدون") {
                cardamomStr = "none"
            } else {
                cardamomStr = "cardamom"
            }
            
            let weightStr = weight?.lowercased() ?? ""
            if weightStr.contains("1kg") == true || weightStr.contains("1") == true || weightStr.contains("كيلو") == true || weightStr.contains("كغم") == true {
                key = "Turkish_\(roast)_\(cardamomStr)_1kg"
            } else if weightStr.contains("500") == true {
                key = "Turkish_\(roast)_\(cardamomStr)_500g"
            } else if weightStr.contains("250") == true {
                key = "Turkish_\(roast)_\(cardamomStr)_250g"
            }
        } else if category.contains("Espresso") || productName.contains("إسبرسو") || productName.contains("Espresso") {
            // إسبرسو
            let grindStr = (grind?.lowercased().contains("beans") == true || grind?.lowercased().contains("حب") == true || grind?.lowercased().contains("bean") == true) ? "beans" : "ground"
            let weightStr = weight?.lowercased() ?? ""
            if weightStr.contains("1kg") == true || weightStr.contains("1") == true || weightStr.contains("كيلو") == true || weightStr.contains("كغم") == true {
                key = "Espresso_\(grindStr)_1kg"
            }
        } else if category.contains("Brewed") || (category.contains("Brewed") && productName.contains("Turkish Coffee")) {
            // Brewed category (Turkish Coffee Sada/Medium/Sweet)
            let productNameLower = productName.lowercased()
            let sizeStr = (size ?? "").lowercased()
            
            if productNameLower.contains("sada") || productNameLower.contains("سادة") || productNameLower.contains("plain") {
                if sizeStr.contains("100") || sizeStr.contains("100ml") {
                    key = "Cup_Turkish_Sada_100"
                }
            } else if productNameLower.contains("medium") || productNameLower.contains("وسط") {
                if sizeStr.contains("100") || sizeStr.contains("100ml") {
                    key = "Cup_Turkish_medium_100ml"
                }
            } else if productNameLower.contains("sweet") || productNameLower.contains("حلوة") {
                if sizeStr.contains("100") || sizeStr.contains("100ml") {
                    key = "Cup_Turkish_sweet_100ml"
                }
            }
        } else if category.contains("Cups") || category.contains("Cup") || productName.contains("كوب") {
            // الكاسات (Cups category)
            let cupTypeStr = (cupType ?? "").lowercased()
            let sizeStr = (size ?? "").lowercased()
            let productNameLower = productName.lowercased()
            
            if (cupTypeStr.contains("levant") || productNameLower.contains("ليفانت")) && (cupTypeStr.contains("espresso") || productNameLower.contains("إسبريسو")) {
                if sizeStr.contains("50") || sizeStr.contains("50ml") {
                    key = "Cup_Levant_Espresso_50ml"
                } else if sizeStr.contains("100") || sizeStr.contains("100ml") {
                    key = "Cup_Levant_Espresso_100ml"
                }
            } else if cupTypeStr.contains("jasmina") || cupTypeStr.contains("ياسمينا") || productNameLower.contains("ياسمينا") || productNameLower.contains("jasmina") {
                if cupTypeStr.contains("latte") || productNameLower.contains("لاتيه") || productNameLower.contains("latte") {
                    key = "Cup_Jasmina_Latte"
                } else if cupTypeStr.contains("cappuccino") || productNameLower.contains("كابتشينو") || productNameLower.contains("cappuccino") {
                    key = "Cup_Jasmina_Cappuccino"
                } else if cupTypeStr.contains("زجاج") || cupTypeStr.contains("glass") || productNameLower.contains("زجاج") || productNameLower.contains("glass") {
                    key = "Cup_Jasmina_double_glass"
                }
            } else if cupTypeStr.contains("turkish") || cupTypeStr.contains("تركية") || productNameLower.contains("تركية") {
                if sizeStr.contains("100") || sizeStr.contains("100ml") {
                    if productNameLower.contains("سادة") || productNameLower.contains("plain") {
                        key = "Cup_Turkish_plain_100ml"
                    } else if productNameLower.contains("وسط") || productNameLower.contains("medium") {
                        key = "Cup_Turkish_medium_100ml"
                    } else if productNameLower.contains("حلوة") || productNameLower.contains("sweet") {
                        key = "Cup_Turkish_sweet_100ml"
                    }
                }
            } else if cupTypeStr.contains("sada") || cupTypeStr.contains("سادة") || productNameLower.contains("سادة") {
                if sizeStr.contains("small") || sizeStr.contains("صغير") {
                    key = "Cup_Sada_small"
                } else if sizeStr.contains("medium") || sizeStr.contains("وسط") {
                    key = "Cup_Sada_medium"
                } else if sizeStr.contains("large") || sizeStr.contains("كبير") {
                    key = "Cup_Sada_large"
                } else {
                    key = "Cup_Sada_small" // default
                }
            }
        }
        
        // البحث في القائمة
        if let price = prices[key] {
            return price
        }
        
        return nil
    }
}

@MainActor
final class RealtimeVoiceViewModel: NSObject, ObservableObject {

    // MARK: - Published (UI)
    @Published var bands: [CGFloat] = Array(repeating: 0.05, count: 20)
    @Published var isConnected: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var lastReply: String?
    @Published var navigationTarget: String? = nil  // ✅ للتنقل للصفحات
    @Published var pendingNavigation: String? = nil  // ✅ للتنقل المعلق بعد الاتصال
    
    // MARK: - CliQ Transfer Parameters
    @Published var cliqAmount: String? = nil
    @Published var cliqPhoneNumber: String? = nil
    @Published var cliqAlias: String? = nil
    
    // MARK: - Order Parameters
    @Published var orderItems: [OrderItem] = [] {
        didSet {
            print("\n🛒 ========== CART UPDATED ==========")
            print("📊 Total items: \(orderItems.count)")
            for (index, item) in orderItems.enumerated() {
                print("   [\(index + 1)] \(item.name) - \(item.price) × \(item.quantity) = \(item.total)")
            }
            print("=====================================\n")
        }
    }
    @Published var orderId: String? = nil
    @Published var checkoutReady: Bool = false // true فقط عندما يكون checkout: true في JSON
    
    // MARK: - Session Management
    var sessionID: String?  // ✅ للاستخدام في polling
    
    // MARK: - Navigation detection
    private var lastAIText: String = ""
    private var navigationTimer: Timer?
    // ✅ الـ IP الخارجي للسيرفر (تم التحقق: 35.202.32.216)
    private let backendURL = "http://35.202.32.216:8000"
    private var pendingFunctionCallArgs: [String: String] = [:] // لتجميع function arguments
    private var pendingTranscript: String = "" // لتجميع transcript deltas قبل استخراج JSON
    private var pendingContentPart: String = "" // لتجميع content_part deltas قبل استخراج JSON

    // MARK: - WebRTC
    private var pcStored: RTCPeerConnection?
    private let factory = RTCPeerConnectionFactory()

    // MARK: - DataChannel للأحداث
    private var eventsDC: RTCDataChannel?

    // MARK: - Audio Metering (Stats)
    private var statsTimer: Timer?
    private var emaInbound: Double = 0.0  // مستوى صوت AI (inbound)
    private var emaOutbound: Double = 0.0 // صوت المستخدم (outbound)
    private let emaAlpha: Double = 0.35   // تنعيم (0..1)، الأكبر أسرع استجابة
    private let silenceThreshold: Double = 0.015 // فلتر ضجيج منخفض

    // MARK: - Session flags
    private var isScreenCaptured: Bool { UIScreen.main.isCaptured }

    override init() {
        super.init()
        // راقب تغيير حالة تسجيل الشاشة لإعادة تهيئة الصوت
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? self?.reconfigureAudioSessionForCaptureChange()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Mic permission (iOS)
    private func ensureMicPermission() async throws {
        let current = AVAudioSession.sharedInstance().recordPermission
        if current == .granted { return }
        try await withCheckedThrowingContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted { cont.resume() }
                else {
                    cont.resume(throwing: NSError(
                        domain: "RealtimeVoice",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]
                    ))
                }
            }
        }
    }

    // MARK: - Connect
    func connectToRealtime() async {
        do {
            try await ensureMicPermission()
            try configureAudioSession() // تهيئة أولية (تسمح بالمزج والتسجيل)

            // 1) احصل على client_secret من السيرفر (الصوت مقفول cedar بالسيرفر)
            let tokenURL = URL(string: "\(backendURL)/v1/realtime/token")!
            
            var tokenReq = URLRequest(url: tokenURL)
            tokenReq.httpMethod = "POST"
            tokenReq.timeoutInterval = 30.0
            
            let (tokData, tokResp) = try await URLSession.shared.data(for: tokenReq)
            guard let http = tokResp as? HTTPURLResponse, http.statusCode < 300 else {
                let body = String(data: tokData, encoding: .utf8) ?? ""
                throw NSError(domain: "RealtimeVoice", code: -10,
                              userInfo: [NSLocalizedDescriptionKey: "Token HTTP error: \((tokResp as? HTTPURLResponse)?.statusCode ?? -1)\n\(body)"])
            }
            guard
                let json = try JSONSerialization.jsonObject(with: tokData) as? [String: Any],
                let clientSecret = (json["client_secret"] as? [String: Any])?["value"] as? String,
                !clientSecret.isEmpty
            else {
                throw NSError(domain: "RealtimeVoice", code: -11,
                              userInfo: [NSLocalizedDescriptionKey: "client_secret missing/empty"])
            }

            // 2) PeerConnection
            let config = RTCConfiguration()
            config.sdpSemantics = .unifiedPlan
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)

            guard let pc = factory.peerConnection(with: config,
                                                  constraints: constraints,
                                                  delegate: self) else {
                throw NSError(domain: "RealtimeVoice", code: -12,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create RTCPeerConnection"])
            }
            self.pcStored = pc

            // 2.5) DataChannel
            let dcConfig = RTCDataChannelConfiguration()
            dcConfig.isOrdered = true
            let eventsDC = pc.dataChannel(forLabel: "oai-events", configuration: dcConfig)
            eventsDC?.delegate = self
            self.eventsDC = eventsDC

            // 3) Add mic track (إرسال صوت المستخدم)
            let audioSource = factory.audioSource(with: nil)
            let audioTrack = factory.audioTrack(with: audioSource, trackId: "mic")
            pc.add(audioTrack, streamIds: ["local_stream"])

            // Ensure send/recv
            let tx: RTCRtpTransceiver
            if let existing = pc.transceivers.first(where: { $0.mediaType == .audio }) {
                tx = existing
            } else {
                guard let created = pc.addTransceiver(of: .audio) else {
                    throw NSError(domain: "RealtimeVoice", code: -15,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to add audio transceiver"])
                }
                tx = created
            }
            var txErr: NSError?
            _ = tx.setDirection(.sendRecv, error: &txErr)

            // 4) Offer + Local SDP
            let offerConstraints = RTCMediaConstraints(
                mandatoryConstraints: ["OfferToReceiveAudio":"true"],
                optionalConstraints: nil
            )
            let offer = try await pc.offer(for: offerConstraints)
            try await pc.setLocalDescription(offer)

            // 5) ICE
            try await waitForIceGatheringComplete(using: pc, timeout: 8.0)
            guard let localSDP = pc.localDescription?.sdp, !localSDP.isEmpty else {
                throw NSError(domain: "RealtimeVoice", code: -13,
                              userInfo: [NSLocalizedDescriptionKey: "Local SDP empty"])
            }

            // 6) Send SDP to OpenAI Realtime
            var req = URLRequest(url: URL(string: "https://api.openai.com/v1/realtime?model=gpt-realtime")!)
            req.httpMethod = "POST"
            req.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
            req.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
            req.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
            req.setValue("application/sdp", forHTTPHeaderField: "Accept")
            req.httpBody = localSDP.data(using: .utf8)

            let (ansData, ansResp) = try await URLSession.shared.data(for: req)
            if let http = ansResp as? HTTPURLResponse, http.statusCode >= 300 {
                let body = String(data: ansData, encoding: .utf8) ?? ""
                throw NSError(domain: "OpenAIRealtime", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"])
            }

            guard let sdpAnswer = String(data: ansData, encoding: .utf8),
                  sdpAnswer.contains("a=ice-ufrag") else {
                let raw = String(data: ansData, encoding: .utf8) ?? ""
                throw NSError(domain: "OpenAIRealtime", code: -14,
                              userInfo: [NSLocalizedDescriptionKey: "No SDP answer. Got: \(raw)"])
            }

            let answer = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
            try await pc.setRemoteDescription(answer)

            // ✅ Start stats metering
            startStatsMetering(on: pc)
            
            // ✅ Set session ID
            let newSessionID = UUID().uuidString
            self.sessionID = newSessionID

            DispatchQueue.main.async {
                self.isConnected = true
                self.messages.append(ChatMessage(text: "✅ Connected to Realtime Voice", isUser: false))
                self.startNavigationPolling()  // ✅ ابدأ polling
                
                // استعادة أي pending navigation
                if let pendingNav = self.pendingNavigation {
                    self.navigationTarget = pendingNav
                    self.pendingNavigation = nil
                }
            }

        } catch {
            let errorDescription = error.localizedDescription
            let nsError = error as NSError
            print("❌ Realtime connect error:")
            print("   Description: \(errorDescription)")
            print("   Domain: \(nsError.domain)")
            print("   Code: \(nsError.code)")
            if let userInfo = nsError.userInfo as? [String: Any] {
                print("   UserInfo: \(userInfo)")
            }
            
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(text: "❌ \(errorDescription)", isUser: false))
                self.isConnected = false
                self.resetBandsToSilence()
            }
            disconnect()
        }
    }

    func disconnect() {
        stopStatsMetering()
        stopNavigationPolling()  // ✅ أوقف polling
        
        // حفظ أي pending navigation قبل الانفصال
        if let navTarget = navigationTarget {
            pendingNavigation = navTarget
        }
        
        pcStored?.close()
        pcStored = nil
        isConnected = false
        resetBandsToSilence()
        pendingFunctionCallArgs.removeAll() // ✅ نظف function call args
        navigationTarget = nil // ✅ امسح navigationTarget عند الانفصال
        // لا تمسح orderItems - احتفظ بالمنتجات حتى بعد disconnect (لحفظ السلة)
        checkoutReady = false // امسح checkoutReady عند disconnect
    }
    
    // MARK: - Navigation Polling
    
    func startNavigationPolling() {
        guard navigationTimer == nil else { return }
        
        navigationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNavigationCommand()
            }
        }
    }
    
    func stopNavigationPolling() {
        navigationTimer?.invalidate()
        navigationTimer = nil
    }
    
    private func checkForNavigationCommand() async {
        guard let sessionID = sessionID else { return }
        
        let url = URL(string: "\(backendURL)/v1/navigation/check/\(sessionID)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hasNav = json["has_navigation"] as? Bool,
               hasNav == true,
               let page = json["page"] as? String {
                
                DispatchQueue.main.async {
                    self.navigationTarget = page
                }
            }
        } catch {
            // Silent fail - don't spam console
        }
    }

    // MARK: - Audio Session

    /// إعداد صديق لتسجيل الشاشة: يمزج مع الآخرين ويترك ReplayKit يلتقط صوت التطبيق،
    /// ويستمر التطبيق باستخدام المايك للمكالمة.
    private func configureAudioSession() throws {
        let rtc = RTCAudioSession.sharedInstance()
        let av  = AVAudioSession.sharedInstance()

        rtc.lockForConfiguration()
        defer { rtc.unlockForConfiguration() }

        var cfg = RTCAudioSessionConfiguration.webRTC()
        cfg.category = AVAudioSession.Category.playAndRecord.rawValue
        cfg.mode = AVAudioSession.Mode.voiceChat.rawValue

        // مهم: mixWithOthers يسمح لتسجيل الشاشة يأخذ الصوت بدون قطع جلسة التطبيق
        // defaultToSpeaker للخروج من سماعة الجهاز، allowBluetooth/A2DP للسماعات
        let opts: AVAudioSession.CategoryOptions = [
            .mixWithOthers,
            .defaultToSpeaker,
            .allowBluetooth,
            .allowBluetoothA2DP
        ]
        cfg.categoryOptions = opts

        try rtc.setConfiguration(cfg)
        try rtc.setActive(true)

        // أثناء تسجيل الشاشة، لا تجبر الإخراج على السماعة — خلّي iOS يختار المسار المناسب
        if !isScreenCaptured {
            try? av.overrideOutputAudioPort(.speaker)
        } else {
            try? av.overrideOutputAudioPort(.none)
        }

        // عيّن معدل العيّنة ومدة البفر لأداء أفضل مع WebRTC + تسجيل الشاشة
        try? av.setPreferredSampleRate(48000)
        try? av.setPreferredIOBufferDuration(0.01)
    }

    /// إعادة تهيئة سريعة عند بدء/إيقاف تسجيل الشاشة
    private func reconfigureAudioSessionForCaptureChange() throws {
        let av = AVAudioSession.sharedInstance()
        if isScreenCaptured {
            // أثناء التسجيل: لا إجبار على السماعة، أبقِ المزج مفعّل
            try? av.overrideOutputAudioPort(.none)
        } else {
            // رجّع للسماعة بعد الانتهاء (لو تحب السلوك هذا)
            try? av.overrideOutputAudioPort(.speaker)
        }

        // أعد تهيئة RTCAudioSession بنفس الإعدادات لضمان الثبات
        let rtc = RTCAudioSession.sharedInstance()
        rtc.lockForConfiguration()
        defer { rtc.unlockForConfiguration() }
        var cfg = RTCAudioSessionConfiguration.webRTC()
        cfg.category = AVAudioSession.Category.playAndRecord.rawValue
        cfg.mode = AVAudioSession.Mode.voiceChat.rawValue
        cfg.categoryOptions = [.mixWithOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        try? rtc.setConfiguration(cfg)
        try? rtc.setActive(true)
    }

    private func waitForIceGatheringComplete(using pc: RTCPeerConnection, timeout: TimeInterval) async throws {
        let start = Date()
        while pc.iceGatheringState != .complete {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            if Date().timeIntervalSince(start) > timeout {
                throw NSError(domain: "ICE", code: -100,
                              userInfo: [NSLocalizedDescriptionKey: "ICE gathering timeout"])
            }
        }
    }

    // MARK: - Stats Metering
    private func startStatsMetering(on pc: RTCPeerConnection) {
        stopStatsMetering()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self, weak pc] _ in
            guard let self, let pc else { return }

            pc.statistics { report in
                var inboundLevel: Double = 0.0
                var outboundLevel: Double = 0.0

                for (_, stat) in report.statistics {
                    let type = stat.type
                    guard let members = stat.values as? [String: Any] else { continue }

                    if type == "inbound-rtp" {
                        if let lvl = members["audioLevel"] as? Double {
                            inboundLevel = max(inboundLevel, lvl)
                        } else if let lvlNum = members["audioLevel"] as? NSNumber {
                            inboundLevel = max(inboundLevel, lvlNum.doubleValue)
                        }
                    }

                    if type == "outbound-rtp" {
                        if let lvl = members["audioLevel"] as? Double {
                            outboundLevel = max(outboundLevel, lvl)
                        } else if let lvlNum = members["audioLevel"] as? NSNumber {
                            outboundLevel = max(outboundLevel, lvlNum.doubleValue)
                        }
                    }
                }

                self.emaInbound  = self.emaAlpha * inboundLevel  + (1 - self.emaAlpha) * self.emaInbound
                self.emaOutbound = self.emaAlpha * outboundLevel + (1 - self.emaAlpha) * self.emaOutbound

                let activeLevel = max(self.emaInbound, self.emaOutbound)

                DispatchQueue.main.async {
                    if activeLevel > self.silenceThreshold {
                        self.applyLevelToBands(activeLevel)
                    } else {
                        self.fadeBandsToSilence(step: 0.15)
                    }
                }
            }
        }
    }

    private func stopStatsMetering() {
        statsTimer?.invalidate()
        statsTimer = nil
        emaInbound = 0
        emaOutbound = 0
    }

    private func applyLevelToBands(_ level: Double) {
        let clamped = max(0.0, min(1.0, level))
        var newBands: [CGFloat] = []
        newBands.reserveCapacity(20)

        for i in 0..<20 {
            let centerBoost = 1.0 - abs(Double(i) - 9.5) / 9.5
            let jitter = (Double.random(in: -0.08...0.08))
            let v = max(0.0, min(1.0, clamped * (0.65 + 0.45 * centerBoost) + jitter))
            newBands.append(CGFloat(v))
        }
        self.bands = newBands
    }

    private func fadeBandsToSilence(step: CGFloat) {
        let new = bands.map { max(0.05, $0 - step * 0.2) }
        self.bands = new
    }

    private func resetBandsToSilence() {
        self.bands = Array(repeating: 0.05, count: 20)
    }
}

// MARK: - RTCPeerConnectionDelegate
extension RealtimeVoiceViewModel: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        if newState == .disconnected || newState == .failed || newState == .closed {
            DispatchQueue.main.async { self.isConnected = false }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd rtpReceiver: RTCRtpReceiver,
                        streams: [RTCMediaStream]) {
    }
}

// MARK: - RTCDataChannelDelegate
extension RealtimeVoiceViewModel: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        guard dataChannel.readyState == .open, dataChannel.label == "oai-events" else { return }
        
        // ===========================================
        // OPTIONAL: لو بدك auto-greeting (بدون conflict)
        // ===========================================
        // Uncomment the code below if you want automatic greeting:
        /*
        let payload: [String: Any] = [
            "type": "response.create",
            "response": [
                "modalities": ["audio", "text"]
                // ⚠️ بدون "instructions" و بدون "conversation": "none"
                // هذا بيحفّز الـ AI يرد، بس بياخذ التعليمات من السيناريو الأساسي
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let buf = RTCDataBuffer(data: data, isBinary: false)
                dataChannel.sendData(buf)
                print("🚀 Triggered AI greeting (using server scenario)")
            }
        }
        */
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if !buffer.isBinary, let txt = String(data: buffer.data, encoding: .utf8) {
            // ✅ طباعة جميع الرسائل الواردة للتحقق
            if let data = txt.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                print("\n📨 ========== MESSAGE RECEIVED ==========")
                print("📋 Type: \(type)")
                
                // ✅ Handle audio transcript done - extract JSON from transcript
                if type == "response.audio_transcript.done",
                   let transcript = json["transcript"] as? String {
                    
                    print("📝 AUDIO TRANSCRIPT:")
                    print("📏 Length: \(transcript.count) characters")
                    print("📄 Content: \(transcript)")
                    print("🔍 Contains 'page': \(transcript.contains("\"page\""))")
                    print("🔍 Contains 'add_product': \(transcript.contains("add_product"))")
                    print("🔍 Contains 'order_batch': \(transcript.contains("order_batch"))")
                    
                    // ✅ طباعة رد أمجد في console التطبيق (نفس شكل السيرفر)
                    print("")
                    print("🤖 Reply: \(transcript)")
                    print("")
                    
                    // ✅ إرسال رد أمجد للسيرفر للتسجيل
                    self.logMessageToServer(message: transcript, role: "assistant")
                    
                    // ابحث عن JSON في الـ transcript
                    if transcript.contains("\"page\"") {
                        print("✅ Found 'page' in transcript - extracting JSON...")
                        DispatchQueue.main.async {
                            self.extractAndStoreProductFromJSON(transcript)
                        }
                    } else {
                        print("⚠️ Transcript does not contain 'page' - skipping JSON extraction")
                    }
                    print("==========================================\n")
                    return
                }
                
                // ✅ Handle content_part added - جمع deltas للـ JSON
                if type == "response.content_part.added",
                   let delta = json["delta"] as? String {
                    print("📝 CONTENT PART DELTA:")
                    print("📄 Delta: \(delta)")
                    pendingContentPart += delta
                    print("📦 Total content so far: \(String(pendingContentPart.prefix(200)))")
                    print("==========================================\n")
                    return
                }
                
                // ✅ Handle content_part done - استخراج JSON من content الكامل
                if type == "response.content_part.done",
                   let content = json["content"] as? String {
                    print("📝 CONTENT PART DONE:")
                    print("📏 Length: \(content.count) characters")
                    print("📄 Content: \(content)")
                    print("🔍 Contains 'page': \(content.contains("\"page\""))")
                    
                    // استخدم content الكامل (أو pendingContentPart إذا كان content فارغ)
                    let fullContent = content.isEmpty ? pendingContentPart : content
                    
                    // ابحث عن JSON في الـ content
                    if fullContent.contains("\"page\"") {
                        print("✅ Found 'page' in content_part - extracting JSON...")
                        DispatchQueue.main.async {
                            self.extractAndStoreProductFromJSON(fullContent)
                        }
                    } else {
                        print("⚠️ Content part does not contain 'page' - skipping JSON extraction")
                    }
                    
                    // امسح pendingContentPart بعد الاستخدام
                    pendingContentPart = ""
                    print("==========================================\n")
                    return
                }
                
                // ✅ Handle function call arguments (delta - جمع القطع)
                if type == "response.function_call_arguments.delta",
                   let callId = json["call_id"] as? String,
                   let delta = json["delta"] as? String {
                    print("📦 FUNCTION CALL ARGUMENTS DELTA:")
                    print("🔑 Call ID: \(callId)")
                    print("📄 Delta: \(delta)")
                    if pendingFunctionCallArgs[callId] == nil {
                        pendingFunctionCallArgs[callId] = ""
                    }
                    pendingFunctionCallArgs[callId] = (pendingFunctionCallArgs[callId] ?? "") + delta
                    print("📦 Total args so far: \(pendingFunctionCallArgs[callId] ?? "")")
                    print("==========================================\n")
                    return
                }
                
                // ✅ Handle completed function call
                if type == "response.function_call_arguments.done",
                   let callId = json["call_id"] as? String,
                   let functionName = json["name"] as? String {
                    print("✅ FUNCTION CALL COMPLETED:")
                    print("🔑 Call ID: \(callId)")
                    print("📛 Function Name: \(functionName)")
                    
                    if let arguments = pendingFunctionCallArgs[callId] {
                        print("📦 Full Arguments: \(arguments)")
                        
                        if let argsData = arguments.data(using: .utf8),
                           let argsJson = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                            
                            // ✅ طباعة JSON بشكل منسق
                            if let jsonPretty = try? JSONSerialization.data(withJSONObject: argsJson, options: .prettyPrinted),
                               let jsonString = String(data: jsonPretty, encoding: .utf8) {
                                print("\n📦 ========== FUNCTION CALL JSON ==========")
                                print(jsonString)
                                print("==========================================\n")
                            }
                            
                            if let page = argsJson["page"] as? String {
                                print("🎯 Page found: \(page)")
                                DispatchQueue.main.async {
                                    self.navigationTarget = page
                                    self.pendingNavigation = page
                                    // إذا كان add_product أو order_batch، استخرج JSON
                                    if page == "add_product" || page == "order_batch" {
                                        self.extractAndStoreProductFromJSON(arguments)
                                    }
                                }
                            } else {
                                print("⚠️ No 'page' key in function call arguments")
                            }
                        } else {
                            print("❌ Failed to parse function call arguments as JSON")
                        }
                    } else {
                        print("⚠️ No pending arguments for call ID: \(callId)")
                    }
                    pendingFunctionCallArgs.removeValue(forKey: callId)
                    print("==========================================\n")
                    return
                }
                
                // ✅ Handle other message types
                print("📋 Other message type: \(type)")
                print("==========================================\n")
                
                // ⚠️ مهم: ما نستخرج JSON من delta events - فقط من transcript الكامل
                // الـ delta events بتحتوي على قطع صغيرة من النص (مثلاً "page" فقط)
                // والـ JSON الكامل موجود في response.audio_transcript.done
                return
            }
            
            // ✅ Handle navigation event مباشر (مش delta event)
            if let data = txt.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String,
               type == "navigation",
               let page = json["page"] as? String {
                DispatchQueue.main.async {
                    self.navigationTarget = page
                }
                return
            }
            
            // ✅ استخراج JSON فقط من نص كامل (مش delta events)
            // التحقق إن الرسالة مش delta event قبل الاستخراج
            if txt.contains("\"page\"") && !txt.contains("\"type\":\"response.audio_transcript.delta\"") {
                print("\n🔍 ========== FOUND 'page' IN RAW TEXT (NOT DELTA) ==========")
                print("📄 Raw text: \(String(txt.prefix(500)))")
                print("==========================================\n")
                
                if let result = extractNavigationFromText(txt) {
                    DispatchQueue.main.async {
                        self.navigationTarget = result.page
                        self.cliqAmount = result.amount
                        self.cliqPhoneNumber = result.phone
                        self.cliqAlias = result.alias
                        if result.page == "add_product" || result.page == "order_batch" {
                            self.extractAndStoreProductFromJSON(txt)
                        }
                    }
                }
            }
        }
    }
    
    private func extractNavigationFromText(_ text: String) -> CliQTransferData? {
        // Handle multiline JSON and normalize all whitespace
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
        
        // Try to extract full JSON object
        if let jsonRange = cleaned.range(of: "{\"") {
            let after = String(cleaned[jsonRange.lowerBound...])
            if let jsonEnd = after.range(of: "}") {
                let jsonString = String(after[..<jsonEnd.upperBound])
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    let page = json["page"] as? String ?? ""
                    let amount = json["amount"] as? String
                    let phone = json["phone"] as? String
                    let alias = json["alias"] as? String
                    let checkout = json["checkout"] as? Bool
                    
                    return CliQTransferData(page: page, amount: amount, phone: phone, alias: alias, checkout: checkout)
                }
            }
        }
        
        // Fallback: Try simple pattern matching
        if let pageRange = cleaned.range(of: "\"page\"") {
            let afterPage = String(cleaned[pageRange.upperBound...])
            if let colonRange = afterPage.range(of: ":"),
               let firstQuote = afterPage.range(of: "\"", range: colonRange.upperBound..<afterPage.endIndex) {
                let afterQuote = afterPage[firstQuote.upperBound...]
                if let secondQuote = afterQuote.range(of: "\"") {
                    let pageName = String(afterQuote[..<secondQuote.lowerBound]).trimmingCharacters(in: .whitespaces)
                    return CliQTransferData(page: pageName, amount: nil, phone: nil, alias: nil, checkout: nil)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Log Messages to Server
    private func logMessageToServer(message: String, role: String) {
        guard !message.isEmpty else { return }
        
        let url = URL(string: "\(backendURL)/v1/conversation/log")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        
        let body: [String: Any] = [
            "message": message,
            "role": role,
            "session_id": sessionID
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("📤 Sending message to server: \(role) - \(message.prefix(50))...")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Failed to log message to server: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Message logged successfully to server")
                    } else {
                        print("⚠️ Server returned status code: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        } catch {
            print("❌ Failed to serialize message for server: \(error)")
        }
    }
    
    // MARK: - Extract Product from JSON
    private func extractAndStoreProductFromJSON(_ text: String) {
        // ✅ دعم عدة JSON objects في نفس النص (للمنتجات المتعددة)
        var jsonStrings: [String] = []
        
        // محاولة 1: استخرج جميع JSON من code blocks (```json ... ```)
        var searchRange = text.startIndex..<text.endIndex
        while let codeBlockStart = text.range(of: "```json", range: searchRange),
              let codeBlockEnd = text.range(of: "```", range: codeBlockStart.upperBound..<text.endIndex) {
            let codeBlockContent = String(text[codeBlockStart.upperBound..<codeBlockEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // ✅ إذا كان الـ code block يحتوي على عدة JSON objects (مفصولة بأسطر)
            // استخرج كل JSON object منفصل
            let lines = codeBlockContent.components(separatedBy: .newlines)
            var currentJson = ""
            var braceCount = 0
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.isEmpty { continue }
                
                currentJson += (currentJson.isEmpty ? "" : "\n") + trimmedLine
                braceCount += trimmedLine.filter { $0 == "{" }.count
                braceCount -= trimmedLine.filter { $0 == "}" }.count
                
                // إذا وصلنا لـ JSON كامل (عدد الأقواس متساوي)
                if braceCount == 0 && !currentJson.isEmpty && currentJson.contains("{") && currentJson.contains("\"page\"") {
                    if !jsonStrings.contains(currentJson) {
                        jsonStrings.append(currentJson)
                    }
                    currentJson = ""
                    braceCount = 0
                }
            }
            
            // إذا بقي JSON غير مكتمل، جرب إضافته
            if !currentJson.isEmpty && currentJson.contains("{") && currentJson.contains("\"page\"") {
                if !jsonStrings.contains(currentJson) {
                    jsonStrings.append(currentJson)
                }
            }
            
            searchRange = codeBlockEnd.upperBound..<text.endIndex
        }
        
        // محاولة 2: استخرج جميع JSON من generic code blocks (``` ... ```)
        searchRange = text.startIndex..<text.endIndex
        while let codeBlockStart = text.range(of: "```", range: searchRange),
              let codeBlockEnd = text.range(of: "```", range: codeBlockStart.upperBound..<text.endIndex) {
            let codeBlockContent = String(text[codeBlockStart.upperBound..<codeBlockEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // ✅ إذا كان الـ code block يحتوي على عدة JSON objects (مفصولة بأسطر)
            // استخرج كل JSON object منفصل
            let lines = codeBlockContent.components(separatedBy: .newlines)
            var currentJson = ""
            var braceCount = 0
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.isEmpty { continue }
                
                currentJson += (currentJson.isEmpty ? "" : "\n") + trimmedLine
                braceCount += trimmedLine.filter { $0 == "{" }.count
                braceCount -= trimmedLine.filter { $0 == "}" }.count
                
                // إذا وصلنا لـ JSON كامل (عدد الأقواس متساوي)
                if braceCount == 0 && !currentJson.isEmpty && currentJson.contains("{") && currentJson.contains("\"page\"") {
                    if !jsonStrings.contains(currentJson) {
                        jsonStrings.append(currentJson)
                    }
                    currentJson = ""
                    braceCount = 0
                }
            }
            
            // إذا بقي JSON غير مكتمل، جرب إضافته
            if !currentJson.isEmpty && currentJson.contains("{") && currentJson.contains("\"page\"") {
                if !jsonStrings.contains(currentJson) {
                    jsonStrings.append(currentJson)
                }
            }
            
            searchRange = codeBlockEnd.upperBound..<text.endIndex
        }
        
        // محاولة 3: استخرج جميع JSON objects مباشرة من النص (بدون code blocks)
        if jsonStrings.isEmpty {
            searchRange = text.startIndex..<text.endIndex
            while let jsonStart = text.range(of: "{\"", range: searchRange),
                  let jsonEnd = findMatchingBrace(in: text, startIndex: jsonStart.lowerBound) {
                let jsonStr = String(text[jsonStart.lowerBound..<jsonEnd])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // تحقق من أنه يحتوي على "page" (JSON navigation)
                if jsonStr.contains("\"page\"") {
                    jsonStrings.append(jsonStr)
                }
                // jsonEnd هو String.Index يشير إلى الموضع بعد نهاية JSON
                searchRange = jsonEnd..<text.endIndex
            }
        }
        
        // محاولة 4: fallback - استخرج من أول { لحد آخر }
        if jsonStrings.isEmpty {
            if let firstBrace = text.firstIndex(of: "{"),
               let lastBrace = text.lastIndex(of: "}"),
               firstBrace < lastBrace {
                let jsonStr = String(text[firstBrace...lastBrace])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if jsonStr.contains("\"page\"") {
                    jsonStrings.append(jsonStr)
                }
            }
        }
        
        if jsonStrings.isEmpty {
            return
        }
        
        // معالجة كل JSON object
        for (index, jsonStr) in jsonStrings.enumerated() {
            guard let jsonData = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }
            
            // ✅ طباعة JSON بشكل منسق
            if let jsonPretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let jsonString = String(data: jsonPretty, encoding: .utf8) {
                print("\n📦 ========== JSON #\(index + 1) ==========")
                print(jsonString)
                print("========================================\n")
            }
            
            let page = json["page"] as? String ?? ""
            
            // ✅ Handle order_batch - استخرج كل المنتجات من array
            if page == "order_batch" {
                let checkout = json["checkout"] as? Bool ?? false
                print("🛒 order_batch detected - checkout: \(checkout)")
                
                if !checkout {
                    print("⚠️ SKIPPING: order_batch without checkout: true")
                    DispatchQueue.main.async {
                        self.checkoutReady = false
                    }
                    continue
                }
                
                print("✅ Processing order_batch with checkout: true")
                
                if let orders = json["orders"] as? [[String: Any]] {
                    var batchItems: [OrderItem] = []
                    for order in orders {
                        if let item = extractSingleProductFromJSON(order) {
                            batchItems.append(item)
                        }
                    }
                    
                    if !batchItems.isEmpty {
                        DispatchQueue.main.async {
                            self.orderItems = batchItems
                            self.checkoutReady = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.checkoutReady = false
                        }
                    }
                }
                continue
            }
            
            // ✅ Handle add_product
            guard page == "add_product" else {
                continue
            }
            
            // ✅ تحقق من ready: true قبل إضافة المنتج
            let ready = json["ready"] as? Bool ?? false
            print("🔍 add_product detected - ready: \(ready)")
            
            if !ready {
                print("⚠️ SKIPPING: add_product without 'ready: true'")
                continue
            }
            
            print("✅ Processing add_product with ready: true")
            
            // استخرج بيانات المنتج من add_product
            if let item = extractSingleProductFromJSON(json) {
                DispatchQueue.main.async {
                    self.orderItems.append(item)
                }
            }
        } // end of for loop
    }
    
    // MARK: - Extract Single Product from JSON Object
    private func extractSingleProductFromJSON(_ json: [String: Any]) -> OrderItem? {
        // استخرج بيانات المنتج
        let productName = json["product_name"] as? String ?? json["category"] as? String ?? "منتج"
        let category = json["category"] as? String ?? ""
        let weight = json["weight"] as? String ?? ""
        let cardamom = json["cardamom"] as? String
        let grind = json["grind"] as? String
        let quantity = (json["quantity"] as? Int) ?? (json["quantity"] as? String).flatMap { Int($0) } ?? 1
        
        // بناء اسم المنتج مع التفاصيل
        var fullProductName = productName
        let cupType = json["cup_type"] as? String
        let size = json["size"] as? String
        
        // للـ Brewed category: استخدم product_name و size
        if category.contains("Brewed") {
            if let sizeStr = size, !sizeStr.isEmpty {
                fullProductName += " (\(sizeStr))"
            }
        } else {
            // للـ Turkish Coffee: استخدم weight, cardamom, grind
            if !weight.isEmpty {
                fullProductName += " (\(weight))"
            }
            if let cardamom = cardamom, cardamom != "none" {
                fullProductName += " - \(cardamom)"
            }
            if let grind = grind, !grind.isEmpty {
                fullProductName += " - \(grind)"
            }
            // للـ Cups category: استخدم cup_type و size
            if let cupTypeStr = cupType, !cupTypeStr.isEmpty {
                fullProductName += " - \(cupTypeStr)"
            }
            if let sizeStr = size, !sizeStr.isEmpty {
                fullProductName += " (\(sizeStr))"
            }
        }
        
        // حساب السعر: أولوية لـ unit_price من JSON، ثم الكتالوج، ثم fallback
        let price: Double
        
        // ✅ أولوية 1: استخدم unit_price من JSON إذا كان موجود
        if let unitPriceFromJSON = json["unit_price"] as? Double {
            price = unitPriceFromJSON
        } else if let unitPriceString = json["unit_price"] as? String,
                  let unitPriceDouble = Double(unitPriceString) {
            price = unitPriceDouble
        } else if let catalogPrice = ProductPriceCatalog.getPrice(
            category: category,
            productName: productName,
            weight: weight,
            cardamom: cardamom,
            grind: grind,
            cupType: cupType,
            size: size
        ) {
            // ✅ أولوية 2: استخدم السعر من الكتالوج
            price = catalogPrice
        } else {
            // ✅ أولوية 3: fallback prices
            if weight.contains("250") || weight.contains("250g") {
                price = category.contains("Turkish") ? 3.5 : (category.contains("Espresso") ? 4.0 : 3.0)
            } else if weight.contains("500") || weight.contains("500g") {
                price = category.contains("Turkish") ? 6.5 : (category.contains("Espresso") ? 7.5 : 5.5)
            } else if weight.contains("1kg") || weight.contains("1") {
                price = category.contains("Turkish") ? 19.824 : (category.contains("Espresso") ? 23.822 : 10.0)
            } else if category.contains("Brewed") {
                price = 2.0
            } else if category.contains("Cups") {
                price = cupType?.contains("Espresso") == true ? 2.0 : (cupType?.contains("Latte") == true || cupType?.contains("Cappuccino") == true ? 3.5 : 2.5)
            } else {
                price = 5.0
            }
        }
        
        // تحديد اسم الصورة بناءً على نوع المنتج
        let imageName: String?
        if category.contains("Turkish Coffee") && !weight.isEmpty {
            // قهوة تركية بالوزن (كيلو/جرام) → صورة الباكيت
            imageName = "turkish_coffee_packet"
        } else if category.contains("Brewed") || (category.contains("Cups") && (productName.contains("Turkish") || productName.contains("تركية"))) {
            // كاسة قهوة تركية → صورة الكاسة التركية
            imageName = "turkish_coffee_cup"
        } else if category.contains("Cups") && (cupType?.contains("Espresso") == true || productName.contains("Espresso") || productName.contains("إسبريسو")) {
            // كاسة إسبريسو → صورة كاسة الإسبريسو
            imageName = "espresso_cup"
        } else if category.contains("Cups") {
            // كاسات أخرى (Latte, Cappuccino, etc.)
            imageName = "coffee_cup"
        } else {
            // منتجات أخرى (إسبريسو بالوزن، أمريكان، etc.)
            imageName = "coffee_packet"
        }
        
        // إنشاء OrderItem
        return OrderItem(
            name: fullProductName,
            price: price,
            quantity: quantity,
            imageName: imageName
        )
    }
    
    // MARK: - Helper: Find Matching Brace
    private func findMatchingBrace(in text: String, startIndex: String.Index) -> String.Index? {
        var depth = 0
        var index = startIndex
        
        while index < text.endIndex {
            let char = text[index]
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    return text.index(after: index)
                }
            }
            index = text.index(after: index)
        }
        
        return nil
    }
}

/*
 ===========================================
 📝 ملاحظات مهمة:
 ===========================================
 
 1. التعديل الرئيسي: إلغاء الـ greeting التلقائي في dataChannelDidChangeState
    - هذا يحل مشكلة conflict بين تعليمات التطبيق والسيرفر
    - النتيجة: نبرة ونطق أكثر ثباتاً
 
 2. الـ greeting الآن محدد في السيناريو على السيرفر:
    - "مرحبًا أُستاذ غيث. معك أمجد من البنك الافتراضي..."
    - يشتغل تلقائياً أول ما المستخدم يحكي
 
 3. لو بدك auto-greeting:
    - Uncomment الكود في dataChannelDidChangeState
    - بس تأكد إنه بدون "instructions" و "conversation": "none"
 
 4. النتيجة المتوقعة:
    - ✅ نبرة أكثر ثباتاً
    - ✅ نطق أوضح (14 كلمة محفوظة في السيرفر)
    - ✅ ردود متسقة
    - ✅ أقل تشتت
 
 ===========================================
 */
