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
    struct ChatResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
            struct Message: Codable {
                let content: String
            }
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
    
    // MARK: - 공통 요청 빌더
    private func buildRequest(body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func makeMessages(system: String, history: [Message], user: String) -> [[String: String]] {
        var messages: [[String: String]] = [["role": "system", "content": system]]
        messages += history.map { ["role": $0.role, "content": $0.content] }
        messages.append(["role": "user", "content": user])
        return messages
    }
    
    // MARK: - API 함수들
    func sendMessageStream(_ userMessage: String, history: [Message] = [], systemPrompt: String = "당신은 보안/인증 전문가입니다.") async throws -> AsyncThrowingStream<String, Error> {
        let request = try buildRequest(body: [
            "model": "gpt-4o-mini",
            "messages": makeMessages(system: systemPrompt, history: history, user: userMessage),
            "stream": true
        ])
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        if jsonString == "[DONE]" { continuation.finish(); break }
                        
                        guard let data = jsonString.data(using: .utf8),
                              let streamResponse = try? JSONDecoder().decode(StreamResponse.self, from: data),
                              let content = streamResponse.choices.first?.delta.content else { continue }
                        continuation.yield(content)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func askStructured(_ userMessage: String) async throws -> String {
        let systemPrompt = """
        당신은 보안/인증 전문가입니다.
        반드시 아래 JSON 형식으로만 답하세요:
        {"term": "용어명", "definition": "한 줄 정의", "example": "실제 사용 예시", "related_terms": ["관련용어1", "관련용어2"]}
        """
        let request = try buildRequest(body: [
            "model": "gpt-4o-mini",
            "messages": makeMessages(system: systemPrompt, history: [], user: userMessage),
            "response_format": ["type": "json_object"]
        ])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }
    
    func sendMessageWithRAG(_ userMessage: String, context: String, history: [Message] = []) async throws -> AsyncThrowingStream<String, Error> {
        let systemPrompt = """
        당신은 보안/인증 전문가입니다.
        아래 문서를 참고해서 답변하세요. 문서에 없는 내용은 "제공된 문서에 없는 내용입니다"라고 답하세요.
        
        [참고 문서]
        \(context)
        """
        return try await sendMessageStream(userMessage, history: history, systemPrompt: systemPrompt)
    }
}
