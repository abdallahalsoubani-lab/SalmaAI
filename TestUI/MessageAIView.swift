////
////  MessageAIView.swift
////  TestUI
////
////  Chat screen connected to backend LLM API
////
//
//import SwiftUI
//import UIKit
//
//// MARK: - Chat Models
//struct ChatMessage: Identifiable {
//    let id: String
//    let text: String
//    let isUser: Bool
//    let timestamp: Date
//}
//
//// MARK: - Chat Components
//struct ChatBubble: View {
//    let message: ChatMessage
//
//    var body: some View {
//        HStack {
//            if message.isUser {
//                Spacer()
//                VStack(alignment: .trailing, spacing: 4) {
//                    Text(message.text)
//                        .font(.system(size: 15))
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 12)
//                        .background(
//                            LinearGradient(
//                                colors: [Color(hex: "#FDCB4A"), Color(hex: "#1E4B74")],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .clipShape(RoundedRectangle(cornerRadius: 20))
//
//                    Text(formatTime(message.timestamp))
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.6))
//                }
//            } else {
//                VStack(alignment: .leading, spacing: 4) {
//                    HStack(spacing: 8) {
//                        Image("bank_logo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 24, height: 24)
//                            .background(Circle().fill(.white.opacity(0.2)))
//                            .clipShape(Circle())
//
//                        Text(message.text)
//                            .font(.system(size: 15))
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 12)
//                            .background(Color.white.opacity(0.1))
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
//                            )
//                            .clipShape(RoundedRectangle(cornerRadius: 20))
//                    }
//
//                    Text(formatTime(message.timestamp))
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.6))
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                Spacer()
//            }
//        }
//    }
//
//    private func formatTime(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//}
//
//struct TypingIndicator: View {
//    @State private var animationOffset: CGFloat = 0
//
//    var body: some View {
//        HStack(spacing: 8) {
//            Image("bank_logo")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 24, height: 24)
//                .background(Circle().fill(.white.opacity(0.2)))
//                .clipShape(Circle())
//
//            HStack(spacing: 4) {
//                ForEach(0..<3) { index in
//                    Circle()
//                        .fill(Color.white.opacity(0.6))
//                        .frame(width: 8, height: 8)
//                        .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
//                        .animation(
//                            .easeInOut(duration: 0.6)
//                                .repeatForever(autoreverses: true)
//                                .delay(Double(index) * 0.2),
//                            value: animationOffset
//                        )
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(Color.white.opacity(0.1))
//            .overlay(
//                RoundedRectangle(cornerRadius: 20)
//                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 20))
//
//            Spacer()
//        }
//        .onAppear { animationOffset = 2 }
//    }
//}
//
//// MARK: - Arabic TextField
//struct ArabicTextField: UIViewRepresentable {
//    @Binding var text: String
//    let placeholder: String
//
//    func makeUIView(context: Context) -> UITextField {
//        let textField = UITextField()
//        textField.placeholder = placeholder
//        textField.text = text
//        textField.delegate = context.coordinator
//
//        textField.textAlignment = .right
//        textField.semanticContentAttribute = .forceRightToLeft
//
//        textField.font = UIFont.systemFont(ofSize: 15)
//        textField.textColor = UIColor.white
//        textField.backgroundColor = UIColor.white.withAlphaComponent(0.1)
//        textField.layer.cornerRadius = 25
//        textField.layer.borderWidth = 1
//        textField.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
//
//        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
//        textField.leftViewMode = .always
//        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
//        textField.rightViewMode = .always
//
//        textField.autocorrectionType = .no
//        textField.autocapitalizationType = .none
//        textField.keyboardType = .default
//        textField.spellCheckingType = .no
//
//        textField.textContentType = .none
//
//        return textField
//    }
//
//    func updateUIView(_ uiView: UITextField, context: Context) {
//        uiView.text = text
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextFieldDelegate {
//        var parent: ArabicTextField
//
//        init(_ parent: ArabicTextField) {
//            self.parent = parent
//        }
//
//        func textFieldDidChangeSelection(_ textField: UITextField) {
//            parent.text = textField.text ?? ""
//        }
//
//        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//            textField.resignFirstResponder()
//            return true
//        }
//    }
//}
//
//// MARK: - Message AI View
//struct MessageAIView: View {
//    @Environment(\.presentationMode) private var presentationMode
//    @State private var messageText: String = ""
//    @State private var messages: [ChatMessage] = []
//    @State private var isTyping: Bool = false
//
//    var body: some View {
//        ZStack {
//            LinearGradient(colors: [
//                Color(hex: "#FDCB4A"),
//                Color(hex: "#1E4B74")
//            ], startPoint: .top, endPoint: .bottom)
//                .edgesIgnoringSafeArea(.all)
//                .allowsHitTesting(false)
//
//            VStack(spacing: 0) {
//                HStack(spacing: 12) {
//                    Button { presentationMode.wrappedValue.dismiss() } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.system(size: 24))
//                            .foregroundColor(.white.opacity(0.8))
//                    }
//
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("AI Bank Assistant")
//                            .font(.system(size: 18, weight: .semibold))
//                            .foregroundColor(.white)
//                        Text("Chat with AI Bank")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//
//                    Spacer()
//
//                    Image("bank_logo")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 32, height: 32)
//                        .background(Circle().fill(.white.opacity(0.2)))
//                        .clipShape(Circle())
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 16)
//                .background(Color.black.opacity(0.1))
//
//                ScrollView {
//                    VStack(spacing: 16) {
//                        ForEach(messages) { message in
//                            ChatBubble(message: message)
//                        }
//
//                        if isTyping {
//                            TypingIndicator()
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 16)
//                }
//
//                VStack(spacing: 12) {
//                    Divider().background(Color.white.opacity(0.2))
//
//                    HStack(spacing: 12) {
//                        ArabicTextField(text: $messageText, placeholder: "اكتب رسالتك هنا...")
//                            .frame(height: 50)
//
//                        Button { sendMessage() } label: {
//                            Image(systemName: "paperplane.fill")
//                                .font(.system(size: 16, weight: .semibold))
//                                .foregroundColor(.white)
//                                .frame(width: 44, height: 44)
//                                .background(
//                                    Circle().fill(
//                                        LinearGradient(
//                                            colors: [Color(hex: "#FDCB4A"), Color(hex: "#1E4B74")],
//                                            startPoint: .topLeading,
//                                            endPoint: .bottomTrailing
//                                        )
//                                    )
//                                )
//                        }
//                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 16)
//                }
//            }
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                messages.append(ChatMessage(
//                    id: UUID().uuidString,
//                    text: "مرحباً! أنا مساعد البنك الذكي. كيف يمكنني مساعدتك اليوم؟",
//                    isUser: false,
//                    timestamp: Date()
//                ))
//            }
//        }
//    }
//
//    private func sendMessage() {
//        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty else { return }
//
//        let userMessage = ChatMessage(
//            id: UUID().uuidString,
//            text: trimmedText,
//            isUser: true,
//            timestamp: Date()
//        )
//        messages.append(userMessage)
//        messageText = ""
//
//        // 👇 استدعاء API
//        callAIAPI(userMessage: trimmedText)
//    }
//
//    private func callAIAPI(userMessage: String) {
//        isTyping = true
//
//        // ✅ استعمل FastAPI على البورت 8000
//        guard let url = URL(string: "http://34.16.78.158:8000/v1/chat/completions") else { return }
//
//        let payload: [String: Any] = [
//            "model": "demo",
//            "messages": [
//                ["role": "user", "content": userMessage]
//            ]
//        ]
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Bearer my-secret-123", forHTTPHeaderField: "Authorization")
//        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async {
//                self.isTyping = false
//            }
//
//            if let error = error {
//                print("❌ API error:", error)
//                return
//            }
//
//            guard let data = data else { return }
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let choices = json["choices"] as? [[String: Any]],
//                   let msg = choices.first?["message"] as? [String: Any],
//                   let content = msg["content"] as? String {
//
//                    let aiMessage = ChatMessage(
//                        id: UUID().uuidString,
//                        text: content,
//                        isUser: false,
//                        timestamp: Date()
//                    )
//                    DispatchQueue.main.async {
//                        self.messages.append(aiMessage)
//                    }
//                } else {
//                    print("⚠️ Unexpected response:", String(data: data, encoding: .utf8) ?? "")
//                }
//            } catch {
//                print("❌ JSON decode error:", error)
//            }
//        }.resume()
//    }
//}
//
//
//
////
////  AudioWaveViewModel.swift
////  SalmaAI
////
////  Created by Soubani on 01/10/2025.
////
//
//import Foundation
//import AVFoundation
//import SwiftUI
//
//@MainActor
//final class AudioWaveViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
//    
//    // MARK: - Published
//    @Published var bands: [CGFloat] = Array(repeating: 0.1, count: 20)
//    @Published var lastReply: String?
//    @Published var isThinking: Bool = false
//    @Published var messages: [ChatMessage] = []   // ✅ كل الرسائل
//    
//    // MARK: - Audio
//    private var engine: AVAudioEngine?
//    private var audioPlayer: AVAudioPlayer?
//    private var recorder: AVAudioRecorder?
//    private let session = AVAudioSession.sharedInstance()
//    
//    // MARK: - API Keys & URLs
//    private let elevenAPIKey = "sk_1db9098d0fbac26c1e9b995113e37b1b2ebf4fb2e0222f6a"
//    private let elevenVoiceID = "FjJJxwBrv1I5sk34AdgP"
//    private let llamaURL = URL(string: "http://34.16.78.158:8000/v1/chat/completions")!
//    private let openAIKey = "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"
//
//    // MARK: - Mic Visualization (موجات)
//    func startMic() {
//        do {
//            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
//            try session.setActive(true)
//            
//            engine = AVAudioEngine()
//            guard let engine = engine else { return }
//            
//            let input = engine.inputNode
//            let format = input.inputFormat(forBus: 0)
//            
//            input.removeTap(onBus: 0)
//            input.installTap(onBus: 0,
//                             bufferSize: 1024,
//                             format: format) { [weak self] buffer, _ in
//                self?.process(buffer: buffer)
//            }
//            
//            engine.prepare()
//            try engine.start()
//            
//            print("✅ Microphone visualization started")
//        } catch {
//            print("❌ Mic error:", error.localizedDescription)
//        }
//    }
//    
//    func stop() {
//        engine?.stop()
//        engine?.inputNode.removeTap(onBus: 0)
//        engine = nil
//        print("🛑 Visualization stopped")
//    }
//    
//    private func process(buffer: AVAudioPCMBuffer) {
//        let level = CGFloat.random(in: 0...1)
//        DispatchQueue.main.async {
//            self.bands = Array(repeating: level, count: 20)
//        }
//    }
//    
//    // MARK: - Recording Control
//    func startRecording() {
//        let fileURL = getRecordedFileURL()
//        let settings: [String: Any] = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 44100,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//        do {
//            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
//            recorder?.record()
//            print("🎙️ Recording started…")
//        } catch {
//            print("❌ Recorder error:", error.localizedDescription)
//        }
//    }
//    
//    func stopRecording() {
//        recorder?.stop()
//        print("🛑 Recording stopped")
//
//        Task {
//            // 1. استعمل Whisper لتحويل الصوت إلى نص
//            let transcript = await transcribeWithWhisper()
//            guard let transcript = transcript, !transcript.isEmpty else { return }
//            
//            // 2. ضيف رسالة المستخدم
//            await MainActor.run {
//                self.messages.append(ChatMessage(text: transcript, isUser: true))
//            }
//            
//            // 3. ابعت النص للـ LLaMA
//            await sendToLLaMA(userText: transcript)
//        }
//    }
//    
//    private func getRecordedFileURL() -> URL {
//        return FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
//    }
//    
//    // MARK: - Whisper
//    private func transcribeWithWhisper() async -> String? {
//        let fileURL = getRecordedFileURL()
//        let boundary = UUID().uuidString
//        
//        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        var body = Data()
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
//        body.append("whisper-1\r\n".data(using: .utf8)!)
//        
//        if let audioData = try? Data(contentsOf: fileURL) {
//            body.append("--\(boundary)\r\n".data(using: .utf8)!)
//            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
//            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
//            body.append(audioData)
//            body.append("\r\n".data(using: .utf8)!)
//        }
//        
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        request.httpBody = body
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let text = json["text"] as? String {
//                print("📝 Whisper transcript:", text)
//                return text
//            }
//        } catch {
//            print("❌ Whisper error:", error.localizedDescription)
//        }
//        return nil
//    }
//    
//    // MARK: - Play Ding
//    private func playDing() {
//        guard let url = Bundle.main.url(forResource: "ding", withExtension: "mp3") else { return }
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.play()
//        } catch {
//            print("⚠️ Ding sound error:", error.localizedDescription)
//        }
//    }
//    
//    // MARK: - LLaMA
//    func sendToLLaMA(userText: String) async {
//        isThinking = true
//        playDing()
//        
//        defer { isThinking = false }
//        
//        do {
//            var request = URLRequest(url: llamaURL)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            let body: [String: Any] = [
//                "model": "demo",
//                "messages": [
//                    ["role": "user", "content": userText]
//                ]
//            ]
//            request.httpBody = try JSONSerialization.data(withJSONObject: body)
//            
//            let (data, _) = try await URLSession.shared.data(for: request)
//            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let choices = json["choices"] as? [[String: Any]],
//               let message = choices.first?["message"] as? [String: Any],
//               let reply = message["content"] as? String {
//                
//                await MainActor.run {
//                    self.lastReply = reply
//                    self.messages.append(ChatMessage(text: reply, isUser: false))
//                }
//                
//                print("🤖 LLaMA Reply:", reply)
//                await speakWithElevenLabs(reply)
//            }
//        } catch {
//            print("❌ Error sending to LLaMA:", error.localizedDescription)
//        }
//    }
//    
//    // MARK: - ElevenLabs TTS
//    private func speakWithElevenLabs(_ text: String) async {
//        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenVoiceID)") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(elevenAPIKey, forHTTPHeaderField: "xi-api-key")
//        
//        let body: [String: Any] = ["text": text,
//                                   "voice_settings": ["stability": 0.5, "similarity_boost": 0.7]]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("reply.mp3")
//            try data.write(to: tmpURL)
//            
//            DispatchQueue.main.async {
//                do {
//                    self.audioPlayer = try AVAudioPlayer(contentsOf: tmpURL)
//                    try? self.session.setCategory(.playback, options: [.defaultToSpeaker])
//                    self.audioPlayer?.delegate = self
//                    self.audioPlayer?.play()
//                    print("🔊 Playing reply…")
//                } catch {
//                    print("❌ TTS error:", error.localizedDescription)
//                }
//            }
//        } catch {
//            print("❌ ElevenLabs error:", error.localizedDescription)
//        }
//    }
//}

//
////
////  AICallLandingView.swift
////  SalmaAI
////
////  Created by Soubani on 01/10/2025.
////
//
//import SwiftUI
//
//// MARK: - Chat Message Model
//struct ChatMessage: Identifiable {
//    let id = UUID()
//    let text: String
//    let isUser: Bool
//    let timestamp = Date()   // ✅ وقت الرسالة
//}
//
//struct AICallLandingView: View {
//    @StateObject private var vm = AudioWaveViewModel()
//    
//    var body: some View {
//        ZStack {
//            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
//                           startPoint: .top,
//                           endPoint: .bottom)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 12) {
//                // العنوان
//                Text("🎧 محادثة مع المساعد الذكي")
//                    .font(.system(size: 22, weight: .semibold))
//                    .foregroundColor(.white)
//                    .padding(.top, 12)
//                
//                // موجات الصوت
//                WaveBars(values: vm.bands)
//                    .frame(height: 80)
//                    .padding(.horizontal, 24)
//                
//                // ✅ الرسائل (زي واتساب)
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 8) {
//                            ForEach(vm.messages) { msg in
//                                MessageBubble(msg: msg)
//                                    .id(msg.id)
//                            }
//                        }
//                        .padding(.horizontal, 12)
//                        .onChange(of: vm.messages.count) { _ in
//                            // سكرول تلقائي لآخر رسالة
//                            if let lastID = vm.messages.last?.id {
//                                withAnimation {
//                                    proxy.scrollTo(lastID, anchor: .bottom)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // ✅ حالة التفكير
//                if vm.isThinking {
//                    ProgressView("💭 المساعد يفكر...")
//                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                        .foregroundColor(.white)
//                        .padding()
//                }
//                
//                // ✅ زر المايك (اضغط مطول للتسجيل)
//                PressAndHoldMicButton(
//                    onStart: { vm.startRecording() },
//                    onStop: { vm.stopRecording() }
//                )
//                .padding(.bottom, 20)
//            }
//        }
//        .onAppear {
//            vm.startMic()
//        }
//        .onDisappear {
//            vm.stop()
//        }
//    }
//}
//
//// MARK: - رسالة شات
//struct MessageBubble: View {
//    let msg: ChatMessage
//    
//    var body: some View {
//        HStack {
//            if msg.isUser { Spacer() }
//            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
//                Text(msg.text)
//                    .foregroundColor(msg.isUser ? .white : .black)
//                    .padding(12)
//                    .background(msg.isUser ? Color.blue : Color.yellow)
//                    .cornerRadius(12)
//                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
//                           alignment: msg.isUser ? .trailing : .leading)
//                
//                Text(msg.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//            }
//            if !msg.isUser { Spacer() }
//        }
//        .padding(msg.isUser ? .leading : .trailing, 40)
//        .transition(.move(edge: msg.isUser ? .trailing : .leading))
//        .animation(.spring(), value: msg.id)
//    }
//}
//
//// MARK: - كبسة المايك
//struct PressAndHoldMicButton: View {
//    var onStart: () -> Void
//    var onStop: () -> Void
//    
//    @GestureState private var isPressing = false
//    
//    var body: some View {
//        Circle()
//            .fill(isPressing ? Color.red : Brand.accent)
//            .frame(width: 80, height: 80)
//            .overlay(
//                Image(systemName: "mic.fill")
//                    .foregroundColor(.white)
//                    .font(.system(size: 28))
//            )
//            .shadow(radius: 6)
//            .gesture(
//                DragGesture(minimumDistance: 0) // يظل شغال طول الضغط
//                    .updating($isPressing) { value, state, _ in
//                        if !state { onStart() }
//                        state = true
//                    }
//                    .onEnded { _ in
//                        onStop()
//                    }
//            )
//    }
//}
//
//// MARK: - موجات الصوت
//struct WaveBars: View {
//    let values: [CGFloat]
//    
//    var body: some View {
//        GeometryReader { geo in
//            let count = max(1, values.count)
//            let barWidth = max(2.0, geo.size.width / CGFloat(count) * 0.55)
//            let spacing  = max(2.0, (geo.size.width / CGFloat(count)) - barWidth)
//            
//            HStack(spacing: spacing) {
//                ForEach(values.indices, id: \.self) { i in
//                    Capsule()
//                        .fill(.white)
//                        .frame(width: barWidth,
//                               height: max(6, values[i] * geo.size.height))
//                        .shadow(color: Brand.accent.opacity(0.6), radius: 4)
//                        .animation(.linear(duration: 0.08), value: values[i])
//                }
//            }
//        }
//    }
//}
//
//
////
////  HomePageView.swift
////  MobileBankingJKB
////
////  Created by Alaa Mohammed on 30/07/2025.
////
//
//import SwiftUI
//
//struct HomePageView: View {
//  @State private var showAudioWaveView: Bool = false
//
//  var body: some View {
//    ZStack {
//      // خلفية سوداء
//      Color.black.ignoresSafeArea()
//
//      // المحتوى في منتصف الشاشة
//      VStack(spacing: 16) {
//        Image("salma_ai_logo")
//          .resizable()
//          .scaledToFit()
//          .frame(width: 300, height: 300) // الحجم المطلوب
//          .accessibilityLabel("Salma AI Logo")
//
//        Text("Salma AI")
//          .font(.system(size: 28, weight: .semibold))
//          .foregroundColor(.white)
//      }
//      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//      .padding()
//
//      // زر AI العائم (قابل للسحب + يحفظ موقعه)
//      FloatingDraggableButton {
//        showAudioWaveView = true
//      }
//      .padding(.bottom, 24)   // ملاحظة: الـ FloatingDraggableButton يستخدم position خاصته
//      .padding(.trailing, 16) // padding هنا تجميلي، بس التحكم الفعلي بالموقع من داخل الكومبوننت
//    }
//    .sheet(isPresented: $showAudioWaveView) {
//      AICallLandingView()
//    }
//  }
//}
//
//// MARK: - Floating Draggable Button
//struct FloatingDraggableButton: View {
//  let action: () -> Void
//
//  // تخزين موقع الزر (يحفظ آخر مكان)
//  @State private var positionX: Double = UserDefaults.standard.double(forKey: "floatingButtonPositionX")
//  @State private var positionY: Double = UserDefaults.standard.double(forKey: "floatingButtonPositionY")
//
//  // حالات السحب
//  @State private var dragOffset: CGSize = .zero
//  @State private var isDragging: Bool = false
//
//  private func initializePosition() {
//    // ضبط موقع ابتدائي (أسفل يمين الشاشة)
//    if positionX == 0 {
//      positionX = UIScreen.main.bounds.width - 80
//      UserDefaults.standard.set(positionX, forKey: "floatingButtonPositionX")
//    }
//    if positionY == 0 {
//      positionY = UIScreen.main.bounds.height - 180
//      UserDefaults.standard.set(positionY, forKey: "floatingButtonPositionY")
//    }
//  }
//
//  private func savePosition() {
//    UserDefaults.standard.set(positionX, forKey: "floatingButtonPositionX")
//    UserDefaults.standard.set(positionY, forKey: "floatingButtonPositionY")
//  }
//
//  var body: some View {
//    Button(action: action) {
//      Image("bank_logo") // غيّرها لشعارك إن لزم
//        .resizable()
//        .scaledToFit()
//        .frame(width: 65, height: 65)
//        .background(
//          Circle()
//            .fill(
//              LinearGradient(
//                colors: [Color(hex: "#FDCB4A"), Color(hex: "#1E4B74")],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//              )
//            )
//        )
//        .overlay(
//          Circle()
//            .stroke(Color(hex: "#FDCB4A"), lineWidth: 3)
//        )
//        .shadow(color: Color.black.opacity(0.3),
//                radius: isDragging ? 8 : 4,
//                x: 0, y: isDragging ? 4 : 2)
//        .scaleEffect(isDragging ? 1.1 : 1.0)
//        .animation(.easeInOut(duration: 0.2), value: isDragging)
//        .contentShape(Circle())
//    }
//    .position(x: positionX + dragOffset.width, y: positionY + dragOffset.height)
//    .highPriorityGesture(
//      DragGesture()
//        .onChanged { value in
//          isDragging = true
//          dragOffset = value.translation
//        }
//        .onEnded { value in
//          isDragging = false
//
//          let finalX = positionX + value.translation.width
//          let finalY = positionY + value.translation.height
//
//          let screenBounds = UIScreen.main.bounds
//          let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
//
//          // حدود آمنة
//          let minX: CGFloat = 28 + safeAreaInsets.left
//          let maxX: CGFloat = screenBounds.width - 28 - safeAreaInsets.right
//          let minY: CGFloat = 100 + safeAreaInsets.top
//          let maxY: CGFloat = screenBounds.height - 100 - safeAreaInsets.bottom
//
//          let snappedX = max(minX, min(maxX, finalX))
//          let snappedY = max(minY, min(maxY, finalY))
//
//          positionX = snappedX
//          positionY = snappedY
//          savePosition()
//          dragOffset = .zero
//        }
//    )
//    .onAppear {
//      initializePosition()
//
//      let screenBounds = UIScreen.main.bounds
//      let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
//
//      let minX: CGFloat = 28 + safeAreaInsets.left
//      let maxX: CGFloat = screenBounds.width - 28 - safeAreaInsets.right
//      let minY: CGFloat = 100 + safeAreaInsets.top
//      let maxY: CGFloat = screenBounds.height - 100 - safeAreaInsets.bottom
//
//      positionX = max(minX, min(maxX, positionX))
//      positionY = max(minY, min(maxY, positionY))
//      savePosition()
//    }
//  }
//}
//
//// MARK: - Color Hex Extension
//public extension Color {
//  init(hex: String) {
//    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//    var int = UInt64()
//    Scanner(string: hex).scanHexInt64(&int)
//    let a, r, g, b: UInt64
//    switch hex.count {
//    case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
//    case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
//    default: (a, r, g, b) = (255, 0, 0, 0)
//    }
//    self.init(.sRGB,
//              red: Double(r) / 255,
//              green: Double(g) / 255,
//              blue: Double(b) / 255,
//              opacity: Double(a) / 255)
//  }
//}














////
////  AICallLandingView.swift
////  SalmaAI
////
////  Created by Soubani on 01/10/2025.
////
//
//import SwiftUI
//
//// MARK: - Chat Message Model
//struct ChatMessage: Identifiable {
//    let id = UUID()
//    let text: String
//    let isUser: Bool
//    let timestamp = Date()   // ✅ وقت الرسالة
//}
//
//struct AICallLandingView: View {
//    @StateObject private var vm = AudioWaveViewModel()
//    
//    var body: some View {
//        ZStack {
//            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
//                           startPoint: .top,
//                           endPoint: .bottom)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 12) {
//                // العنوان
//                Text("🎧 محادثة مع المساعد الذكي")
//                    .font(.system(size: 22, weight: .semibold))
//                    .foregroundColor(.white)
//                    .padding(.top, 12)
//                
//                // موجات الصوت (تتحرك فقط مع صوت AI)
//                WaveBars(values: vm.bands)
//                    .frame(height: 80)
//                    .padding(.horizontal, 24)
//                
//                // ✅ الرسائل (زي واتساب)
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 8) {
//                            ForEach(vm.messages) { msg in
//                                MessageBubble(msg: msg)
//                                    .id(msg.id)
//                            }
//                        }
//                        .padding(.horizontal, 12)
//                        .onChange(of: vm.messages.count) { _ in
//                            // سكرول تلقائي لآخر رسالة
//                            if let lastID = vm.messages.last?.id {
//                                withAnimation {
//                                    proxy.scrollTo(lastID, anchor: .bottom)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // ✅ حالة التفكير
//                if vm.isThinking {
//                    ProgressView("💭 المساعد يفكر...")
//                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                        .foregroundColor(.white)
//                        .padding()
//                }
//                
//                // زر إعادة المحادثة
//                Button(action: {
//                    vm.resetSession()
//                }) {
//                    Text("🔄 محادثة جديدة")
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 8)
//                        .background(Color.red)
//                        .cornerRadius(8)
//                }
//                .padding(.bottom, 20)
//            }
//        }
//        .onAppear {
//            vm.startContinuousVoice() // ✅ يبدأ المايك تلقائي
//        }
//    }
//}
//
//// MARK: - رسالة شات
//struct MessageBubble: View {
//    let msg: ChatMessage
//    
//    var body: some View {
//        HStack {
//            if msg.isUser { Spacer() }
//            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
//                Text(msg.text)
//                    .foregroundColor(msg.isUser ? .white : .black)
//                    .padding(12)
//                    .background(msg.isUser ? Color.blue : Color.yellow)
//                    .cornerRadius(12)
//                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
//                           alignment: msg.isUser ? .trailing : .leading)
//                
//                Text(msg.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//            }
//            if !msg.isUser { Spacer() }
//        }
//        .padding(msg.isUser ? .leading : .trailing, 40)
//        .transition(.move(edge: msg.isUser ? .trailing : .leading))
//        .animation(.spring(), value: msg.id)
//    }
//}
//
//// MARK: - موجات الصوت
//struct WaveBars: View {
//    let values: [CGFloat]
//    
//    var body: some View {
//        GeometryReader { geo in
//            let count = max(1, values.count)
//            let barWidth = max(2.0, geo.size.width / CGFloat(count) * 0.55)
//            let spacing  = max(2.0, (geo.size.width / CGFloat(count)) - barWidth)
//            
//            HStack(spacing: spacing) {
//                ForEach(values.indices, id: \.self) { i in
//                    Capsule()
//                        .fill(.white)
//                        .frame(width: barWidth,
//                               height: max(6, values[i] * geo.size.height))
//                        .shadow(color: Brand.accent.opacity(0.6), radius: 4)
//                        .animation(.linear(duration: 0.08), value: values[i])
//                }
//            }
//        }
//    }
//}




//
////
////  AudioWaveViewModel.swift
////  SalmaAI
////
////  Created by Soubani on 01/10/2025.
////
//
//import Foundation
//import AVFoundation
//import SwiftUI
//
//@MainActor
//final class AudioWaveViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
//    
//    // MARK: - Published
//    @Published var bands: [CGFloat] = Array(repeating: 0.1, count: 20)
//    @Published var lastReply: String?
//    @Published var isThinking: Bool = false
//    @Published var messages: [ChatMessage] = []
//    @Published var sessionID: String? = nil
//    
//    // MARK: - Audio
//    private var audioPlayer: AVAudioPlayer?
//    private var recorder: AVAudioRecorder?
//    private let session = AVAudioSession.sharedInstance()
//    
//    // MARK: - API Keys & URLs
//    private let elevenAPIKey = "sk_1db9098d0fbac26c1e9b995113e37b1b2ebf4fb2e0222f6a"
//    private let elevenVoiceID = "FjJJxwBrv1I5sk34AdgP"
//    private let llamaURL = URL(string: "http://34.16.78.158:8000/v1/chat/completions")!
//    private let openAIKey = "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"
//
//    // MARK: - Start continuous voice mode
//    func startContinuousVoice() {
//        startRecording()
//    }
//    
//    // MARK: - Recording
//    private var recordTimer: Timer?
//
//    private func startRecording() {
//        let fileURL = getRecordedFileURL()
//        let settings: [String: Any] = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 44100,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//        do {
//            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
//            try session.setActive(true)
//            
//            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
//            recorder?.record()
//            
//            // ⏱️ بعد 5 ثواني أوقف التسجيل وأبعث للصوت
//            recordTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
//                self.stopRecording()
//            }
//            
//            print("🎙️ Recording started…")
//        } catch {
//            print("❌ Recorder error:", error.localizedDescription)
//        }
//    }
//
//    private func stopRecording() {
//        recorder?.stop()
//        recordTimer?.invalidate()
//        recordTimer = nil
//        print("🛑 Recording stopped")
//        
//        Task {
//            let transcript = await transcribeWithWhisper()
//            guard let transcript = transcript, !transcript.isEmpty else {
//                startRecording() // لو ما في نص → رجع سجل تاني
//                return
//            }
//            
//            await MainActor.run {
//                self.messages.append(ChatMessage(text: transcript, isUser: true))
//            }
//            
//            await sendToLLaMA(userText: transcript)
//        }
//    }
//
//    private func getRecordedFileURL() -> URL {
//        return FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
//    }
//    
//    // MARK: - Whisper
//    private func transcribeWithWhisper() async -> String? {
//        let fileURL = getRecordedFileURL()
//        let boundary = UUID().uuidString
//        
//        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        var body = Data()
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
//        body.append("whisper-1\r\n".data(using: .utf8)!)
//        
//        if let audioData = try? Data(contentsOf: fileURL) {
//            body.append("--\(boundary)\r\n".data(using: .utf8)!)
//            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
//            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
//            body.append(audioData)
//            body.append("\r\n".data(using: .utf8)!)
//        }
//        
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        request.httpBody = body
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let text = json["text"] as? String {
//                print("📝 Whisper transcript:", text)
//                return text
//            }
//        } catch {
//            print("❌ Whisper error:", error.localizedDescription)
//        }
//        return nil
//    }
//    
//    // MARK: - LLaMA
//    private func sendToLLaMA(userText: String) async {
//        isThinking = true
//        defer { isThinking = false }
//        
//        do {
//            var request = URLRequest(url: llamaURL)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            let body: [String: Any] = [
//                "model": "demo",
//                "session_id": sessionID ?? "demo-session",
//                "messages": [
//                    ["role": "user", "content": userText]
//                ]
//            ]
//            
//            request.httpBody = try JSONSerialization.data(withJSONObject: body)
//            
//            let (data, _) = try await URLSession.shared.data(for: request)
//            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                
//                if let sid = json["session_id"] as? String {
//                    self.sessionID = sid
//                    print("💾 Session ID set:", sid)
//                }
//                
//                if let choices = json["choices"] as? [[String: Any]],
//                   let message = choices.first?["message"] as? [String: Any],
//                   let reply = message["content"] as? String {
//                    
//                    await MainActor.run {
//                        self.lastReply = reply
//                        self.messages.append(ChatMessage(text: reply, isUser: false))
//                    }
//                    
//                    print("🤖 LLaMA Reply:", reply)
//                    await speakWithElevenLabs(reply)
//                }
//            }
//        } catch {
//            print("❌ Error sending to LLaMA:", error.localizedDescription)
//        }
//    }
//    
//    // MARK: - ElevenLabs TTS
//    private func speakWithElevenLabs(_ text: String) async {
//        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenVoiceID)") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(elevenAPIKey, forHTTPHeaderField: "xi-api-key")
//        
//        let body: [String: Any] = [
//            "text": text,
//            "voice_settings": ["stability": 0.5, "similarity_boost": 0.7]
//        ]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("reply.mp3")
//            try data.write(to: tmpURL)
//            
//            DispatchQueue.main.async {
//                do {
//                    self.audioPlayer = try AVAudioPlayer(contentsOf: tmpURL)
//                    try? self.session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
//                    self.audioPlayer?.delegate = self
//                    self.audioPlayer?.play()
//                    
//                    self.startWaveAnimation()
//                    
//                    print("🔊 Playing reply…")
//                } catch {
//                    print("❌ TTS error:", error.localizedDescription)
//                }
//            }
//        } catch {
//            print("❌ ElevenLabs error:", error.localizedDescription)
//        }
//    }
//    
//    // MARK: - Wave Animation لصوت AI
//    private var waveTimer: Timer?
//    
//    private func startWaveAnimation() {
//        stopWaveAnimation()
//        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
//            let randomLevels = (0..<20).map { _ in CGFloat.random(in: 0...1) }
//            DispatchQueue.main.async {
//                self.bands = randomLevels
//            }
//        }
//    }
//    
//    private func stopWaveAnimation() {
//        waveTimer?.invalidate()
//        waveTimer = nil
//        DispatchQueue.main.async {
//            self.bands = Array(repeating: 0.1, count: 20)
//        }
//    }
//    
//    // MARK: - AVAudioPlayerDelegate
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        stopWaveAnimation()
//        // ✅ بعد ما يخلص صوت AI نرجع نسجل
//        startRecording()
//    }
//    
//    // MARK: - Reset Session
//    func resetSession() {
//        sessionID = nil
//        messages.removeAll()
//        lastReply = nil
//        print("🔄 New session will start on next request")
//        startRecording() // نرجع نسمع فوراً
//    }
//}
