//
//  AudioWaveViewModel.swift
//  SalmaAI
//
//  Created by Soubani on 01/10/2025.
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class AudioWaveViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    // MARK: - Published
    @Published var bands: [CGFloat] = Array(repeating: 0.1, count: 20)
    @Published var lastReply: String?
    @Published var isThinking: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var sessionID: String? = nil
    
    // MARK: - Audio
    private var audioPlayer: AVAudioPlayer?
    private var recorder: AVAudioRecorder?
    private let session = AVAudioSession.sharedInstance()
    
    // MARK: - API
    private let backendAudioURL = URL(string: "http://34.16.78.158:8000/v1/chat/audio")!
    private let openAIKey = "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"


    // ✅ OpenAI TTS voice
    private let openAIVoice = "ballad" // جرّب: verse, sage, ballad, coral, ash
    private let openAIModel = "gpt-4o-mini-tts"
    
    // MARK: - Start continuous voice mode
    func startContinuousVoice() {
        startRecording()
    }
    
    // MARK: - Recording
    private var recordTimer: Timer?
    
    private func startRecording() {
        let fileURL = getRecordedFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.record()
            
            recordTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
                self.stopRecording()
            }
            
            print("🎙️ Recording started…")
        } catch {
            print("❌ Recorder error:", error.localizedDescription)
        }
    }
    
    private func stopRecording() {
        recorder?.stop()
        recordTimer?.invalidate()
        recordTimer = nil
        print("🛑 Recording stopped")
        
        Task {
            if let reply = await sendAudioToBackend() {
                await MainActor.run {
                    self.messages.append(ChatMessage(text: reply, isUser: false))
                    self.lastReply = reply
                }
                print("🤖 Assistant Reply:", reply)
                
                // 🔊 بدّل Google → OpenAI TTS
                await speakWithOpenAITTS(reply)
            } else {
                startRecording()
            }
        }
    }
    
    private func getRecordedFileURL() -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
    }
    
    // MARK: - Send Audio to Backend
    private func sendAudioToBackend() async -> String? {
        let fileURL = getRecordedFileURL()
        var request = URLRequest(url: backendAudioURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let audioData = try? Data(contentsOf: fileURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        let sid = sessionID ?? UUID().uuidString
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sid)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let sid = json["session_id"] as? String {
                    self.sessionID = sid
                    print("💾 Session ID set:", sid)
                }
                if let reply = json["reply"] as? String {
                    return reply
                }
            } else {
                if let raw = String(data: data, encoding: .utf8) {
                    print("📥 Backend raw JSON:\n", raw)
                }
            }
        } catch {
            print("❌ Backend error:", error.localizedDescription)
        }
        
        return nil
    }
    
    // MARK: - OpenAI TTS
    private func speakWithOpenAITTS(_ text: String) async {
        let endpoint = "https://api.openai.com/v1/audio/speech"
        
        let payload: [String: Any] = [
            "model": openAIModel,
            "voice": openAIVoice,
            "input": text,
            "temperature": 0
        ]
        
        do {
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("openai_reply.mp3")
            try data.write(to: tmpURL)
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: tmpURL)
                    try? self.session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.play()
                    
                    self.startWaveAnimation()
                    print("🔊 Playing OpenAI TTS reply (\(self.openAIVoice))…")
                } catch {
                    print("❌ OpenAI TTS play error:", error.localizedDescription)
                }
            }
        } catch {
            print("❌ OpenAI TTS error:", error.localizedDescription)
        }
    }
    
    // MARK: - Wave Animation
    private var waveTimer: Timer?
    
    private func startWaveAnimation() {
        stopWaveAnimation()
        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            let randomLevels = (0..<20).map { _ in CGFloat.random(in: 0...1) }
            DispatchQueue.main.async {
                self.bands = randomLevels
            }
        }
    }
    
    private func stopWaveAnimation() {
        waveTimer?.invalidate()
        waveTimer = nil
        DispatchQueue.main.async {
            self.bands = Array(repeating: 0.1, count: 20)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopWaveAnimation()
        startRecording()
    }
    
    // MARK: - Reset Session
    func resetSession() {
        sessionID = nil
        messages.removeAll()
        lastReply = nil
        print("🔄 New session will start on next request")
        startRecording()
    }
}
