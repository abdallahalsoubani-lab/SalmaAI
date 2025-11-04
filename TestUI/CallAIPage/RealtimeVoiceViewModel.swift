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
    
    init(page: String, amount: String? = nil, phone: String? = nil, alias: String? = nil) {
        self.page = page
        self.amount = amount
        self.phone = phone
        self.alias = alias
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
    
    // MARK: - Session Management
    var sessionID: String?  // ✅ للاستخدام في polling
    
    // MARK: - Navigation detection
    private var lastAIText: String = ""
    private var navigationTimer: Timer?
    private let backendURL = "http://34.132.130.63:8000"
    private var pendingFunctionCallArgs: [String: String] = [:] // لتجميع function arguments

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
            let tokenURL = URL(string: "http://34.132.130.63:8000/v1/realtime/token")!
            var tokenReq = URLRequest(url: tokenURL)
            tokenReq.httpMethod = "POST"

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
            print("🟢 clientSecret length:", clientSecret.count)

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
            if let e = txErr { print("⚠️ setDirection error:", e.localizedDescription) }

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
            print("📱 Session ID: \(newSessionID)")

            DispatchQueue.main.async {
                self.isConnected = true
                self.messages.append(ChatMessage(text: "✅ Connected to Realtime Voice", isUser: false))
                self.startNavigationPolling()  // ✅ ابدأ polling
                
                // استعادة أي pending navigation
                if let pendingNav = self.pendingNavigation {
                    print("🔔 Restoring pending navigation: \(pendingNav)")
                    self.navigationTarget = pendingNav
                    self.pendingNavigation = nil
                }
            }
            print("✅ Connected to Realtime Voice")

        } catch {
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(text: "❌ \(error.localizedDescription)", isUser: false))
                self.isConnected = false
                self.resetBandsToSilence()
            }
            print("❌ Realtime connect error:", error.localizedDescription)
            disconnect()
        }
    }

    func disconnect() {
        stopStatsMetering()
        stopNavigationPolling()  // ✅ أوقف polling
        
        // حفظ أي pending navigation قبل الانفصال
        if let navTarget = navigationTarget {
            pendingNavigation = navTarget
            print("📦 Saved pending navigation: \(navTarget)")
        }
        
        pcStored?.close()
        pcStored = nil
        isConnected = false
        resetBandsToSilence()
        pendingFunctionCallArgs.removeAll() // ✅ نظف function call args
        navigationTarget = nil // ✅ امسح navigationTarget عند الانفصال
        print("🛑 Disconnected from Realtime")
    }
    
    // MARK: - Navigation Polling
    
    func startNavigationPolling() {
        guard navigationTimer == nil else { return }
        
        navigationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNavigationCommand()
            }
        }
        print("✅ Started navigation polling")
    }
    
    func stopNavigationPolling() {
        navigationTimer?.invalidate()
        navigationTimer = nil
        print("🛑 Stopped navigation polling")
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
                
                print("🎯 Navigation command received: \(page)")
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
        print("🔁 AudioSession reconfigured (isCaptured=\(isScreenCaptured))")
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
        print("📡 Signaling:", stateChanged.rawValue)
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("🤝 Should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        print("🔗 ICE Conn State:", newState.rawValue)
        if newState == .disconnected || newState == .failed || newState == .closed {
            DispatchQueue.main.async { self.isConnected = false }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        print("🧊 ICE Gathering:", newState.rawValue)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        print("➕ ICE candidate generated")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        print("➖ ICE candidates removed:", candidates.count)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        print("📨 DataChannel opened:", dataChannel.label)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("📥 Legacy: didAdd stream:", stream.streamId)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        print("🧹 Legacy: didRemove stream:", stream.streamId)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd rtpReceiver: RTCRtpReceiver,
                        streams: [RTCMediaStream]) {
        if rtpReceiver.track is RTCAudioTrack {
            print("🔊 Remote audio track (Unified Plan):", rtpReceiver.track?.trackId ?? "-")
        }
    }
}

// MARK: - RTCDataChannelDelegate
extension RealtimeVoiceViewModel: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("🧵 DataChannel '\(dataChannel.label)' state: \(dataChannel.readyState.rawValue)")
        
        guard dataChannel.readyState == .open, dataChannel.label == "oai-events" else { return }
        
        // ✅ FIXED: إلغاء الـ greeting التلقائي - الآن الـ AI رح يرد طبيعي أول ما المستخدم يحكي
        // الـ greeting محدد في السيناريو على السيرفر وبيشتغل تلقائياً
        // هذا يحسّن الثبات لأنه ما فيش conflict بين تعليمات التطبيق والسيرفر
        
        print("✅ DataChannel ready - waiting for user to speak")
        
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
            // Print response in requested format
            print("\n===========> RESPONSE")
            print(txt)
            print("===========> END RESPONSE\n")
            
            // Log only if contains interesting data
            if txt.contains("function") || txt.contains("page") || txt.contains("navigation") {
                print("🔍 FOUND FUNCTION/PAGE/Navigation in message!")
            }
            
            // ✅ تحقق إذا كان navigation event مباشر
            if let data = txt.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // استخرج text من response.text.done
                if let responseText = json["text"] as? String {
                    print("📝 AI text response: \(responseText)")
                    print("🔍 Calling extractNavigationFromText...")
                    // ابحث عن navigation command في النص
                    if let result = extractNavigationFromText(responseText) {
                        print("✅ Found navigation in text: \(result)")
                        print("🎯 Setting navigationTarget to: \(result.page)")
                        DispatchQueue.main.async {
                            print("📱 INSIDE MAIN THREAD - Setting navigationTarget")
                            self.navigationTarget = result.page
                            self.cliqAmount = result.amount
                            self.cliqPhoneNumber = result.phone
                            print("📱 navigationTarget value after set: \(self.navigationTarget ?? "nil")")
                        }
                        return
                    } else {
                        print("❌ extractNavigationFromText returned nil")
                    }
                }
                
                // ✅ Handle function call arguments (delta - جمع القطع)
                if let type = json["type"] as? String,
                   type == "response.function_call_arguments.delta",
                   let callId = json["call_id"] as? String,
                   let delta = json["delta"] as? String {
                    print("📝 Collecting function call args for \(callId): \(delta)")
                    if pendingFunctionCallArgs[callId] == nil {
                        pendingFunctionCallArgs[callId] = ""
                    }
                    pendingFunctionCallArgs[callId] = (pendingFunctionCallArgs[callId] ?? "") + delta
                    print("📦 Total args for \(callId): \(pendingFunctionCallArgs[callId] ?? "")")
                    return
                }
                
                // ✅ Handle audio transcript done - extract JSON from transcript
                if let type = json["type"] as? String,
                   type == "response.audio_transcript.done",
                   let transcript = json["transcript"] as? String {
                    print("📝 Audio transcript done: \(transcript)")
                    // ابحث عن JSON navigation command في الـ transcript
                    if let result = extractNavigationFromText(transcript) {
                        print("✅ Found navigation in transcript: page=\(result.page), amount=\(result.amount ?? "nil"), phone=\(result.phone ?? "nil"), alias=\(result.alias ?? "nil")")
                        DispatchQueue.main.async {
                            self.navigationTarget = result.page
                            self.pendingNavigation = result.page
                            self.cliqAmount = result.amount
                            self.cliqPhoneNumber = result.phone
                            self.cliqAlias = result.alias
                            print("✅ Set navigation data")
                        }
                    }
                    return
                }
                
                // ✅ Handle completed function call
                if let type = json["type"] as? String,
                   type == "response.function_call_arguments.done",
                   let callId = json["call_id"] as? String,
                   let functionName = json["name"] as? String {
                    print("🎯 Function call completed: \(functionName), callId: \(callId)")
                    if let arguments = pendingFunctionCallArgs[callId] {
                        print("📦 Full arguments: \(arguments)")
                        if let argsData = arguments.data(using: .utf8),
                           let argsJson = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                            print("✅ Parsed args JSON: \(argsJson)")
                            if let page = argsJson["page"] as? String {
                                print("🎯 Found function call \(functionName): \(page)")
                                // Force main thread update
                                DispatchQueue.main.async {
                                    // Set navigationTarget و pendingNavigation معاً للضمان
                                    self.navigationTarget = page
                                    self.pendingNavigation = page
                                    print("✅ Set navigationTarget and pendingNavigation: \(page)")
                                }
                            } else {
                                print("❌ No 'page' key in args")
                            }
                        } else {
                            print("❌ Failed to parse args JSON")
                        }
                    } else {
                        print("❌ No pending args for \(callId)")
                    }
                    pendingFunctionCallArgs.removeValue(forKey: callId)
                    return
                }
                
                // ✅ Handle function call from output_item (legacy fallback)
                if let type = json["type"] as? String,
                   type == "response.output_item.added" || type == "response.output_item.done",
                   let item = json["item"] as? [String: Any],
                   let itemType = item["type"] as? String,
                   itemType == "function_call",
                   let functionName = item["name"] as? String,
                   functionName == "redirect_to_page",
                   let arguments = item["arguments"] as? String,
                   let argsData = arguments.data(using: .utf8),
                   let argsJson = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any],
                   let page = argsJson["page"] as? String {
                    print("🎯 Found function call redirect_to_page (legacy): \(page)")
                    DispatchQueue.main.async {
                        self.navigationTarget = page
                    }
                    return
                }
                
                // تحقق إذا كان navigation event مباشر
                if let type = json["type"] as? String, type == "navigation",
                   let page = json["page"] as? String {
                    print("🎯 Navigation received: \(page)")
                    DispatchQueue.main.async {
                        self.navigationTarget = page
                    }
                    return
                }
            }
            
            // ✅ بحث فشل، حاول extract من الـ raw text
            if txt.contains("\"page\"") {
                print("🔍 Searching for navigation JSON in raw text...")
                if let result = extractNavigationFromText(txt) {
                    print("✅ Found navigation command: \(result)")
                    DispatchQueue.main.async {
                        self.navigationTarget = result.page
                        self.cliqAmount = result.amount
                        self.cliqPhoneNumber = result.phone
                        self.cliqAlias = result.alias
                    }
                }
            }
        }
    }
    
    private func extractNavigationFromText(_ text: String) -> CliQTransferData? {
        print("🔧 extractNavigationFromText called with: '\(text)'")
        // Handle multiline JSON and normalize all whitespace
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            // Replace multiple spaces with single space
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
        print("🔧 After cleaning: '\(cleaned)'")
        
        // Try to extract full JSON object
        if let jsonRange = cleaned.range(of: "{\"") {
            let after = String(cleaned[jsonRange.lowerBound...])
            if let jsonEnd = after.range(of: "}") {
                let jsonString = String(after[..<jsonEnd.upperBound])
                print("🔍 Found JSON: '\(jsonString)'")
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    let page = json["page"] as? String ?? ""
                    let amount = json["amount"] as? String
                    let phone = json["phone"] as? String
                    let alias = json["alias"] as? String
                    
                    print("✅ Extracted: page=\(page), amount=\(amount ?? "nil"), phone=\(phone ?? "nil"), alias=\(alias ?? "nil")")
                    return CliQTransferData(page: page, amount: amount, phone: phone, alias: alias)
                }
            }
        }
        
        // Fallback: Try simple pattern matching - flexible spacing after colon
        if let pageRange = cleaned.range(of: "\"page\"") {
            let afterPage = String(cleaned[pageRange.upperBound...])
            if let colonRange = afterPage.range(of: ":"),
               let firstQuote = afterPage.range(of: "\"", range: colonRange.upperBound..<afterPage.endIndex) {
                let afterQuote = afterPage[firstQuote.upperBound...]
                if let secondQuote = afterQuote.range(of: "\"") {
                    let pageName = String(afterQuote[..<secondQuote.lowerBound]).trimmingCharacters(in: .whitespaces)
                    print("📱 Extracted page name (flexible): '\(pageName)'")
                    return CliQTransferData(page: pageName, amount: nil, phone: nil)
                }
            }
        }
        
        print("❌ Could not extract JSON from text")
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
