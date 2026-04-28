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
}
