//
//  VoiceGatewayMode.swift
//  TestUI
//
//  Voice Gateway Mode Selection
//  اختيار نوع النظام الصوتي
//

import Foundation

// MARK: - Voice Gateway Mode
enum VoiceGatewayMode: String, CaseIterable, Identifiable {
    case openaiRealtime = "OpenAI Realtime"
    case hybrid = "Hybrid (Llama)"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .openaiRealtime:
            return "النظام الأصلي (OpenAI Realtime API)\n• WebRTC\n• لا يدعم التعلم"
        case .hybrid:
            return "النظام الهجين (Llama + OpenAI)\n• WebSocket\n• يدعم Fine-tuning\n• 95% أرخص"
        }
    }
    
    var endpoint: String {
        switch self {
        case .openaiRealtime:
            return "/v1/realtime/token"
        case .hybrid:
            return "/voice/stream"
        }
    }
    
    var connectionType: ConnectionType {
        switch self {
        case .openaiRealtime:
            return .webrtc
        case .hybrid:
            return .websocket
        }
    }
}

enum ConnectionType {
    case webrtc
    case websocket
}

// MARK: - WebSocket Message Types
struct VoiceGatewayMessage: Codable {
    let type: String
    let sessionId: String?
    let text: String?
    let token: String?
    let error: String?
    let config: VoiceGatewayConfig?
    
    enum CodingKeys: String, CodingKey {
        case type
        case sessionId = "session_id"
        case text
        case token
        case error
        case config
    }
}

struct VoiceGatewayConfig: Codable {
    let llmProvider: String
    let llmModel: String
    let asrModel: String
    let ttsModel: String
    let ttsVoice: String
    
    enum CodingKeys: String, CodingKey {
        case llmProvider = "llm_provider"
        case llmModel = "llm_model"
        case asrModel = "asr_model"
        case ttsModel = "tts_model"
        case ttsVoice = "tts_voice"
    }
}

