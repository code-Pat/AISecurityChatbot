//
//  OpenAIService.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/28/26.
//

import Foundation

class OpenAIService {
    private let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String ?? ""
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    // MARK: - Codable 모델
    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatRequest.Message
        }
    }
    
    struct StreamResponse: Codable {
        let choices: [StreamChoice]
        
        struct StreamChoice: Codable {
            let delta: Delta
            
            struct Delta: Codable {
                let content: String?
            }
        }
    }
    
    // MARK: - API 호출
    func sendMessage(_ userMessage: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "system", content: "당신은 보안/인증 전문가입니다."),
                .init(role: "user", content: userMessage)
            ]
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            print("Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Error body: \(errorBody)")
            throw URLError(.badServerResponse)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }
    
    func sendMessageStream(_ userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "당신은 보안/인증 전문가입니다."],
                ["role": "user", "content": userMessage]
            ],
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        // "data: " 접두사 제거
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        
                        // 스트림 종료 신호
                        if jsonString == "[DONE]" {
                            continuation.finish()
                            break
                        }
                        
                        // JSON 파싱
                        guard let data = jsonString.data(using: .utf8),
                              let streamResponse = try? JSONDecoder().decode(StreamResponse.self, from: data),
                              let content = streamResponse.choices.first?.delta.content else {
                            continue
                        }
                        
                        continuation.yield(content)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
