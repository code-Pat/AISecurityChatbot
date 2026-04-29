//
//  ChatViewModel.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/29/26.
//

import Foundation
import Combine

enum SendMode {
    case normal
    case structured
    case rag
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var selectedMode: SendMode = .normal
    
    private let openAIService = OpenAIService()
    private let ragService = RAGService()
    
    func send() {
        send(mode: selectedMode)
    }
    
    func send(mode: SendMode = .normal) {
        guard !inputText.isEmpty else { return }
        Task { await handleSend(mode: mode) }
    }
    
    private func handleSend(mode: SendMode) async {
        let userInput = inputText
        inputText = ""
        messages.append(Message(role: "user", content: userInput))
        isLoading = true
        
        messages.append(Message(role: "assistant", content: ""))
        let assistantIndex = messages.count - 1
        
        // 히스토리: 마지막 빈 assistant 메시지 제외
        let history = Array(messages.dropLast())
        
        do {
            switch mode {
            case .normal:
                let stream = try await openAIService.sendMessageStream(userInput, history: history)
                for try await chunk in stream {
                    messages[assistantIndex].content += chunk
                }
                
            case .structured:
                let reply = try await openAIService.askStructured(userInput)
                messages[assistantIndex].content = reply
                
            case .rag:
                let context = ragService.retrieveRelevantChunks(for: userInput)
                let stream = try await openAIService.sendMessageWithRAG(userInput, context: context, history: history)
                for try await chunk in stream {
                    messages[assistantIndex].content += chunk
                }
            }
        } catch {
            messages[assistantIndex].content = "에러 발생: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
