//
//  Untitled.swift
//  SalmaAI
//
//  Created by Soubani on 02/10/2025.
//
//
////
////  AudioWaveViewModel.swift
////  MobileBankingJKB
////
////  Created by Soubani on 11/08/2025.
////
//
//import SwiftUI
//import AVFoundation
//import Combine
//import UIKit
//
//// MARK: - Brand
//struct Brand {
//    static let accent   = Color(hex6: "#FFD046")
//    static let accent2  = Color(hex6: "#F3C22A")
//    static let bgTop    = Color(red: 0.04, green: 0.08, blue: 0.14)
//    static let bgBottom = Color.black
//}
//
//// MARK: - Start Mode
//enum WaveStart: Identifiable {
//    case mic
//    case file(name: String, ext: String)
//    var id: String {
//        switch self {
//        case .mic: return "mic"
//        case .file(let n, let e): return "file:\(n).\(e)"
//        }
//    }
//}
//
//// MARK: - ViewModel (Mic / File / Dual Files)
//@MainActor
//final class AudioWaveViewModel: ObservableObject {
//    @Published var bands: [CGFloat] = Array(repeating: 0, count: 36)
//    @Published var overlayLabel: String? = nil // اسم الصوت الثاني
//
//    private var engine: AVAudioEngine?
//
//    // تشغيل أحادي قديم
//    private var player: AVAudioPlayerNode?
//    private var playerAttached = false
//
//    // تشغيل مزدوج جديد
//    private var playerPrimary: AVAudioPlayerNode?
//    private var playerSecondary: AVAudioPlayerNode?
//    private var visualMixer: AVAudioMixerNode?
//
//    private let smoothing: CGFloat = 0.78
//    private let sensitivity: Float = 0.35
//
//    // MARK: - Mic
//    func startMic() {
//        stop()
//
//        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
//            DispatchQueue.main.async {
//                if granted {
//                    self?.setupAndStartMic()
//                } else {
//                    print("❌ Microphone permission denied")
//                }
//            }
//        }
//    }
//
//    private func setupAndStartMic() {
//        do {
//            engine = AVAudioEngine()
//            player = AVAudioPlayerNode()
//            playerAttached = false
//
//            guard let engine = engine else { return }
//
//            try configureAudioSession(for: .playAndRecord)
//
//            let input = engine.inputNode
//            let format = input.inputFormat(forBus: 0)
//            let compatibleFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) ?? format
//
//            input.removeTap(onBus: 0)
//            engine.mainMixerNode.removeTap(onBus: 0)
//
//            input.installTap(onBus: 0, bufferSize: 1024, format: compatibleFormat) { [weak self] buffer, _ in
//                self?.process(buffer: buffer)
//            }
//
//            try engine.start()
//            print("✅ Microphone started successfully")
//
//        } catch {
//            handleAudioError(error, context: "setupAndStartMic")
//        }
//    }
//
//    // MARK: - File (single)
//    func startFileFromBundle(name: String = "TestCall", ext: String = "m4a") {
//        stop()
//
//        do {
//            engine = AVAudioEngine()
//            player = AVAudioPlayerNode()
//            playerAttached = false
//
//            guard let engine = engine, let player = player else { return }
//            try configureAudioSession(for: .playback)
//
//            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
//                print("⚠️ File not found: \(name).\(ext)")
//                return
//            }
//
//            let file = try AVAudioFile(forReading: url)
//            print("✅ File loaded: \(name).\(ext)")
//            print("File format: \(file.processingFormat)")
//
//            engine.attach(player)
//            playerAttached = true
//
//            let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
//            engine.connect(player, to: engine.mainMixerNode, format: outputFormat)
//
//            engine.mainMixerNode.removeTap(onBus: 0)
//            let mixFormat = engine.mainMixerNode.outputFormat(forBus: 0)
//            let visualizationFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) ?? mixFormat
//
//            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: visualizationFormat) { [weak self] buffer, _ in
//                self?.process(buffer: buffer)
//            }
//
//            try engine.start()
//            print("✅ Engine started successfully")
//
//            player.stop()
//            player.scheduleFile(file, at: nil) { [weak self] in
//                DispatchQueue.main.async { self?.stop() }
//            }
//            player.play()
//            print("✅ Player started successfully")
//
//        } catch {
//            handleAudioError(error, context: "startFileFromBundle")
//        }
//    }
//
//    // MARK: - Dual files (wave من الأول فقط)
//    func startDualFilesFromBundle(
//        primaryName: String = "TestCall", primaryExt: String = "m4a",
//        secondaryName: String = "TestCall_V2", secondaryExt: String = "m4a"
//    ) {
//        stop()
//        do {
//            let engine = AVAudioEngine()
//            self.engine = engine
//
//            let p1 = AVAudioPlayerNode()       // مصدر الـ wave
//            let p2 = AVAudioPlayerNode()       // تشغيل فقط
//            let vMix = AVAudioMixerNode()      // عليه الـ tap
//
//            self.playerPrimary = p1
//            self.playerSecondary = p2
//            self.visualMixer = vMix
//
//            try configureAudioSession(for: .playback)
//
//            guard
//                let url1 = Bundle.main.url(forResource: primaryName, withExtension: primaryExt),
//                let url2 = Bundle.main.url(forResource: secondaryName, withExtension: secondaryExt)
//            else {
//                print("⚠️ One of the files is missing")
//                return
//            }
//
//            let file1 = try AVAudioFile(forReading: url1)
//            let file2 = try AVAudioFile(forReading: url2)
//
//            engine.attach(p1)
//            engine.attach(p2)
//            engine.attach(vMix)
//
//            // p1 -> vMix -> main
//            engine.connect(p1, to: vMix, format: file1.processingFormat)
//            engine.connect(vMix, to: engine.mainMixerNode, format: file1.processingFormat)
//
//            // p2 -> main (لا يمر على الـ tap)
//            engine.connect(p2, to: engine.mainMixerNode, format: file2.processingFormat)
//
//            // tap على vMix فقط
//            vMix.removeTap(onBus: 0)
//            let tapFormat = vMix.outputFormat(forBus: 0)
//            vMix.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
//                self?.process(buffer: buffer)
//            }
//
//            try engine.start()
//            print("✅ Engine started (dual)")
//
//            p1.stop(); p2.stop()
//            p1.scheduleFile(file1, at: nil, completionHandler: nil)
//            p2.scheduleFile(file2, at: nil, completionHandler: nil)
//            p1.play(); p2.play()
//            print("✅ Both players started")
//
//            DispatchQueue.main.async { [weak self] in
////                self?.overlayLabel = "\(secondaryName).\(secondaryExt)"
//            }
//
//        } catch {
//            handleAudioError(error, context: "startDualFilesFromBundle")
//        }
//    }
//
//    // MARK: - Stop / Cleanup
//    func stop() {
//        // إزالة أي taps
//        engine?.inputNode.removeTap(onBus: 0)
//        engine?.mainMixerNode.removeTap(onBus: 0)
//        visualMixer?.removeTap(onBus: 0)
//
//        // إيقاف المحرك
//        if let engine = engine, engine.isRunning {
//            engine.stop()
//            print("✅ Engine stopped")
//        }
//
//        // إيقاف وفصل اللاعبين (الأحادي)
//        if let player = player, playerAttached {
//            player.stop()
//            engine?.disconnectNodeOutput(player)
//            engine?.detach(player)
//            playerAttached = false
//            print("✅ Player stopped")
//        }
//
//        // إيقاف وفصل اللاعبين (المزدوج)
//        if let p1 = playerPrimary {
//            p1.stop()
//            engine?.disconnectNodeOutput(p1)
//            engine?.detach(p1)
//        }
//        if let p2 = playerSecondary {
//            p2.stop()
//            engine?.disconnectNodeOutput(p2)
//            engine?.detach(p2)
//        }
//        if let vm = visualMixer {
//            engine?.disconnectNodeOutput(vm)
//            engine?.detach(vm)
//        }
//
//        player = nil
//        playerPrimary = nil
//        playerSecondary = nil
//        visualMixer = nil
//
//        // Reset
//        bands = Array(repeating: 0, count: bands.count)
//        overlayLabel = nil
//
//        do {
//            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//            print("✅ Audio session deactivated")
//        } catch {
//            print("❌ Error deactivating audio session:", error)
//        }
//    }
//
//    // MARK: - تحليل للموجة
//    private func process(buffer: AVAudioPCMBuffer) {
//        guard let channelData = buffer.floatChannelData else { return }
//        let n = Int(buffer.frameLength)
//        if n == 0 { return }
//
//        let channelCount = Int(buffer.format.channelCount)
//        let samples: [Float]
//
//        if channelCount == 1 {
//            samples = Array(UnsafeBufferPointer(start: channelData[0], count: n))
//        } else if channelCount == 2 {
//            let left = Array(UnsafeBufferPointer(start: channelData[0], count: n))
//            let right = Array(UnsafeBufferPointer(start: channelData[1], count: n))
//            samples = zip(left, right).map { ($0 + $1) / 2.0 }
//        } else {
//            samples = Array(UnsafeBufferPointer(start: channelData[0], count: n))
//        }
//
//        let count = bands.count
//        let chunk = max(1, samples.count / count)
//
//        var nb = [CGFloat](repeating: 0, count: count)
//        for i in 0..<count {
//            let s = i * chunk
//            let e = min(s + chunk, samples.count)
//            if s >= e { continue }
//            var sum: Float = 0
//            for v in samples[s..<e] { sum += abs(v) }
//            let mean = sum / Float(e - s)
//            nb[i] = CGFloat(min(1, mean / sensitivity))
//        }
//
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            for i in 0..<count {
//                self.bands[i] = self.smoothing * self.bands[i] + (1 - self.smoothing) * nb[i]
//            }
//        }
//    }
//
//    // MARK: - Error Handling
//    private func handleAudioError(_ error: Error, context: String) {
//        print("❌ Audio Error in \(context): \(error)")
//        print("Error Domain: \((error as NSError).domain)")
//        print("Error Code: \((error as NSError).code)")
//        print("Error Description: \(error.localizedDescription)")
//
//        DispatchQueue.main.async { [weak self] in
//            self?.stop()
//        }
//    }
//
//    // MARK: - Audio Session
//    private func configureAudioSession(for category: AVAudioSession.Category) throws {
//        let session = AVAudioSession.sharedInstance()
//        var options: AVAudioSession.CategoryOptions = [.mixWithOthers]
//
//        if category == .playAndRecord {
//            options.insert(.defaultToSpeaker)
//            options.insert(.allowBluetooth)
//            options.insert(.allowBluetoothA2DP)
//        }
//
//        try session.setCategory(category, options: options)
//        try session.setActive(true, options: .notifyOthersOnDeactivation)
//
//        print("✅ Audio session configured for: \(category) with options: \(options)")
//    }
//}
//
//// MARK: - UI Parts
//struct GlowCapsuleLabel: View {
//    let title: String
//    var body: some View {
//        Text(title)
//            .font(.system(size: 17, weight: .medium))
//            .foregroundColor(.black)
//            .padding(.horizontal, 24).padding(.vertical, 14)
//            .background(LinearGradient(colors: [Brand.accent, Brand.accent2], startPoint: .top, endPoint: .bottom))
//            .clipShape(Capsule())
//            .shadow(color: Brand.accent.opacity(0.35), radius: 30, x: 0, y: 12)
//    }
//}
//
//struct OutlineCapsuleLabel: View {
//    let title: String
//    var body: some View {
//        Text(title)
//            .font(.system(size: 17, weight: .medium))
//            .foregroundColor(.white)
//            .padding(.horizontal, 22).padding(.vertical, 12)
//            .background(Color.white.opacity(0.06))
//            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
//            .clipShape(Capsule())
//    }
//}
//
//struct WaveBars: View {
//    let values: [CGFloat]
//    var body: some View {
//        GeometryReader { geo in
//            let count = max(1, values.count)
//            let barWidth = max(2.0, geo.size.width / CGFloat(count) * 0.55)
//            let spacing  = max(2.0, (geo.size.width / CGFloat(count)) - barWidth)
//            HStack(spacing: spacing) {
//                ForEach(values.indices, id: \.self) { i in
//                    Capsule()
//                        .fill(.white)
//                        .frame(width: barWidth, height: max(8, values[i] * geo.size.height))
//                        .shadow(color: Brand.accent.opacity(0.6), radius: 10)
//                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
//                        .animation(.linear(duration: 0.08), value: values[i])
//                }
//            }
//        }
//        .compositingGroup()
//        .shadow(color: Brand.accent.opacity(0.35), radius: 24)
//        .allowsHitTesting(false)
//    }
//}
//
//// هولوغرام أوضح (إطار + توهج)
//struct AvatarHologram: View {
//    var body: some View {
//        ZStack {
//            RadialGradient(colors: [Brand.accent.opacity(0.45), .clear],
//                           center: .center, startRadius: 10, endRadius: 320)
//                .blur(radius: 6)
//                .allowsHitTesting(false)
//
//            RoundedRectangle(cornerRadius: 28)
//                .fill(Color.white.opacity(0.08))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 28)
//                        .stroke(Brand.accent.opacity(0.35), lineWidth: 1.2)
//                )
//                .shadow(color: .black.opacity(0.35), radius: 28, y: 14)
//
//            VStack(spacing: 18) {
//                ZStack {
//                    Circle()
//                        .fill(Color.white.opacity(0.08))
//                        .frame(width: 110, height: 110)
//                        .overlay(Circle().stroke(Brand.accent, lineWidth: 3))
//                        .shadow(color: Brand.accent.opacity(0.55), radius: 18)
//                }
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color.white.opacity(0.08))
//                    .frame(width: 220, height: 110)
//                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Brand.accent, lineWidth: 3))
//            }
//
//            VStack { Spacer()
//                ZStack {
//                    Capsule().fill(Brand.accent.opacity(0.22)).frame(width: 240, height: 20)
//                    Capsule().stroke(Brand.accent.opacity(0.7), lineWidth: 1.2).frame(width: 240, height: 20)
//                }
//                .shadow(color: Brand.accent.opacity(0.5), radius: 14)
//            }
//            .padding(.bottom, 22)
//        }
//        .frame(height: 340)
//        .padding(.horizontal, 24)
//        .allowsHitTesting(false)
//    }
//}
//
//// MARK: - Landing (Start + Message Ai + هولوغرام واضح)
//struct AICallLandingView: View {
//    @State private var start: WaveStart?
//    @State private var showMessageAIView: Bool = false
//
//    var body: some View {
//        ZStack {
//            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom], startPoint: .top, endPoint: .bottom)
//                .edgesIgnoringSafeArea(.all)
//                .allowsHitTesting(false)
//
//            VStack(spacing: 24) {
//                HStack(spacing: 12) {
//                    Image("bank_logo")
//                        .resizable().scaledToFit()
//                        .frame(width: 40, height: 40)
//                        .shadow(color: Brand.accent.opacity(0.45), radius: 24)
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Welcome to").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
//                        Text("AI Bank").font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
//                    }
//                    Spacer()
//                    Image(systemName: "lock.shield").foregroundColor(.white.opacity(0.75))
//                }
//                .padding(.horizontal, 20)
//
//                Text("AI Call")
//                    .font(.system(size: 28, weight: .semibold))
//                    .foregroundColor(.white)
//
//                VStack(spacing: 12) {
//                    Button { start = .file(name: "TestCall", ext: "m4a") } label: {
//                        GlowCapsuleLabel(title: "Start AI Call")
//                    }
//                    .buttonStyle(.plain)
//
//                    Button(action: { showMessageAIView = true }) {
//                        OutlineCapsuleLabel(title: "Message Ai")
//                    }
//                    .buttonStyle(.plain)
//                }
//
//                AvatarHologram()
//                Spacer(minLength: 0)
//            }
//            .padding(.top, 24)
//        }
//        .sheet(item: $start) { mode in
//            AICallWaveformView(start: mode)
//        }
//        .sheet(isPresented: $showMessageAIView) {
//            MessageAIView()
//        }
//    }
//}
//
//// MARK: - Waveform (auto-start حسب النمط)
//struct AICallWaveformView: View {
//    @Environment(\.presentationMode) private var presentationMode
//    @ObservedObject private var vm = AudioWaveViewModel()
//    let start: WaveStart
//
//    var body: some View {
//        ZStack {
//            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom], startPoint: .top, endPoint: .bottom)
//                .edgesIgnoringSafeArea(.all)
//                .allowsHitTesting(false)
//
//            VStack(spacing: 18) {
//                HStack(spacing: 12) {
//                    Text("AI Call")
//                        .font(.system(size: 22, weight: .semibold))
//                        .foregroundColor(.white)
//                    Spacer()
//                    Button {
//                        vm.stop()
//                        presentationMode.wrappedValue.dismiss()
//                    } label: {
//                        Text("End")
//                            .font(.system(size: 14, weight: .semibold))
//                            .padding(.horizontal, 16).padding(.vertical, 8)
//                            .background(Color.red.opacity(0.85))
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                    }
//                }
//                .padding(.horizontal, 20)
//
//                ZStack {
//                    RadialGradient(colors: [Brand.accent.opacity(0.25), .clear],
//                                   center: .center, startRadius: 10, endRadius: 260)
//                        .allowsHitTesting(false)
//
//                    VStack(spacing: 18) {
//                        Image("jkbCircularLogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 65, height: 65)
//                            .shadow(color: Brand.accent.opacity(0.55), radius: 22)
//                            .overlay(Circle().stroke(Brand.accent.opacity(0.8), lineWidth: 1))
//                            .background(Circle().fill(Brand.accent.opacity(0.18)).blur(radius: 20))
//                            .allowsHitTesting(false)
//
//                        ZStack {
//                            WaveBars(values: vm.bands)
//                                .frame(height: 140)
//                                .padding(.horizontal, 24)
//                                .allowsHitTesting(false)
//
//                            if let label = vm.overlayLabel {
//                                if #available(iOS 14.0, *) {
//                                    Text(label)
//                                        .font(.system(size: 12, weight: .semibold))
//                                        .foregroundColor(.black)
//                                        .padding(.horizontal, 12).padding(.vertical, 6)
//                                        .background(
//                                            Capsule().fill(
//                                                LinearGradient(colors: [Brand.accent, Brand.accent2],
//                                                               startPoint: .top, endPoint: .bottom)
//                                            )
//                                        )
//                                        .shadow(color: Brand.accent.opacity(0.35), radius: 14, y: 6)
//                                        .accessibilityIdentifier("secondary-audio-label")
//                                } else {
//                                    // Fallback on earlier versions
//                                }
//                            }
//                        }
//                    }
//
//                    Spacer(minLength: 0)
//                }
//
//                Spacer()
//            }
//            .padding(.top, 24)
//        }
//        .onAppear {
//            switch start {
//            case .file(let name, let ext):
//                // تشغيل ملفين: wave من الأول + تشغيل الثاني فقط
//                vm.startDualFilesFromBundle(
//                    primaryName: name, primaryExt: ext,
//                    secondaryName: "TestCall_V2", secondaryExt: "m4a"
//                )
//            case .mic:
//                vm.startMic()
//            }
//        }
//        .onDisappear { vm.stop() }
//    }
//}
//
//
//// MARK: - Hex helpers
//extension Color {
//    init(hex6: String) {
//        var hex = hex6.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
//        case 6: (a,r,g,b) = (255,int>>16, int>>8 & 0xFF, int & 0xFF)
//        case 8: (a,r,g,b) = (int>>24, int>>16 & 0xFF, int>>8 & 0xFF, int & 0xFF)
//        default:(a,r,g,b) = (255,0,0,0)
//        }
//        self.init(.sRGB,
//                  red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255,
//                  opacity: Double(a)/255)
//    }
//}
