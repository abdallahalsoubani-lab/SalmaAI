//
//  HybridVoiceClient.swift
//  TestUI
//
//  WebSocket Client for Hybrid Voice Gateway
//  عميل WebSocket للنظام الهجين
//

import Foundation
import AVFoundation

// MARK: - Hybrid Voice Client
class HybridVoiceClient: NSObject {
    
    // MARK: - Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private let backendURL: String
    private let sessionId: String
    
    // Callbacks
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onTextReceived: ((String) -> Void)?
    var onAudioReceived: ((Data) -> Void)?
    var onError: ((String) -> Void)?
    
    // Audio Recording
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecording = false
    
    // MARK: - Init
    init(backendURL: String, sessionId: String = UUID().uuidString) {
        self.backendURL = backendURL
        self.sessionId = sessionId
        super.init()
        
        // Configure session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Connect
    func connect() {
        guard let url = URL(string: "\(backendURL)?session_id=\(sessionId)") else {
            onError?("Invalid URL")
            return
        }
        
        // Create WebSocket connection
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        print("🔌 Connecting to Hybrid Voice Gateway...")
        print("   URL: \(url.absoluteString)")
    }
    
    // MARK: - Disconnect
    func disconnect() {
        stopRecording()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("🔌 Disconnected from Voice Gateway")
    }
    
    // MARK: - Receive Messages
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                    
                case .data(let data):
                    // Audio data من TTS
                    self.onAudioReceived?(data)
                    
                @unknown default:
                    break
                }
                
                // Continue receiving
                self.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self.onError?(error.localizedDescription)
                self.onDisconnected?(error)
            }
        }
    }
    
    // MARK: - Handle Text Message
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let message = try? JSONDecoder().decode(VoiceGatewayMessage.self, from: data) else {
            print("⚠️ Failed to decode message: \(text)")
            return
        }
        
        print("📨 Received: \(message.type)")
        
        switch message.type {
        case "session.created":
            print("✅ Session created: \(message.sessionId ?? "?")")
            onConnected?()
            
        case "asr.started":
            print("🎤 ASR started (transcribing...)")
            
        case "asr.completed":
            if let text = message.text {
                print("🎤 Transcript: \(text)")
                onTextReceived?(text)
            }
            
        case "llm.started":
            print("🧠 LLM processing...")
            
        case "llm.token":
            if let token = message.token {
                print("🧠 Token: \(token)", terminator: "")
            }
            
        case "llm.completed":
            if let text = message.text {
                print("\n🧠 Response: \(text)")
                onTextReceived?(text)
            }
            
        case "tts.started":
            if let text = message.text {
                print("🔊 TTS: \(text)")
            }
            
        case "tts.completed":
            print("✅ TTS completed")
            
        case "barge_in.detected":
            print("⚡ Barge-in detected (user interrupted)")
            
        case "error":
            let errorMsg = message.error ?? "Unknown error"
            print("❌ Error: \(errorMsg)")
            onError?(errorMsg)
            
        default:
            print("ℹ️ Unknown message type: \(message.type)")
        }
    }
    
    // MARK: - Start Recording
    func startRecording() {
        guard !isRecording else { return }
        
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            // Setup audio engine
            audioEngine = AVAudioEngine()
            inputNode = audioEngine?.inputNode
            
            guard let inputNode = inputNode else {
                throw NSError(domain: "HybridVoiceClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No input node"])
            }
            
            // Configure format (16kHz, mono, 16-bit)
            let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: 16000,
                                               channels: 1,
                                               interleaved: false)!
            
            // Install tap
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
                // Convert to Data
                guard let channelData = buffer.int16ChannelData else { return }
                let data = Data(bytes: channelData[0], count: Int(buffer.frameLength) * MemoryLayout<Int16>.size)
                
                // Send to WebSocket
                self?.sendAudio(data)
            }
            
            // Start engine
            audioEngine?.prepare()
            try audioEngine?.start()
            
            isRecording = true
            print("🎙️ Recording started")
            
        } catch {
            print("❌ Failed to start recording: \(error)")
            onError?("Recording failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stop Recording
    func stopRecording() {
        guard isRecording else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isRecording = false
        
        print("🎙️ Recording stopped")
    }
    
    // MARK: - Send Audio
    private func sendAudio(_ data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("❌ Failed to send audio: \(error)")
            }
        }
    }
    
    // MARK: - Send Control Message
    func sendControlMessage(type: String, payload: [String: Any] = [:]) {
        var message = payload
        message["type"] = type
        
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode control message")
            return
        }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("❌ Failed to send control message: \(error)")
            }
        }
    }
    
    // MARK: - Manual Barge-in
    func triggerBargeIn() {
        sendControlMessage(type: "barge_in.cancel")
    }
}

// MARK: - URLSessionWebSocketDelegate
extension HybridVoiceClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        DispatchQueue.main.async {
            self.onConnected?()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket closed: \(closeCode.rawValue)")
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) }
        print("   Reason: \(reasonString ?? "none")")
        
        DispatchQueue.main.async {
            self.onDisconnected?(nil)
        }
    }
}

// MARK: - URLSessionDelegate
extension HybridVoiceClient: URLSessionDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ Session task error: \(error)")
            DispatchQueue.main.async {
                self.onError?(error.localizedDescription)
            }
        }
    }
}

