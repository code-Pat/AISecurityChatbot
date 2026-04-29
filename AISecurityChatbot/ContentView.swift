//
//  ContentView.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var messages: [(role: String, content: String)] = []
    @State private var inputText = ""
    @State private var isLoading = false
    private let service = OpenAIService()
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages.indices, id: \.self) { i in
                    HStack {
                        if messages[i].role == "user" { Spacer() }
                        Text(messages[i].content)
                            .padding()
                            .background(messages[i].role == "user" ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(messages[i].role == "user" ? .white : .primary)
                            .cornerRadius(12)
                        if messages[i].role == "assistant" { Spacer() }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                TextField("질문을 입력하세요...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                Button("전송") {
                    Task { await sendMessage() }
                }
                .disabled(isLoading || inputText.isEmpty)
                
                Button("JSON 모드") {
                    Task { await sendStructured() }
                }
                .disabled(isLoading || inputText.isEmpty)
                
                Button("RAG 모드") {
                    Task { await sendWithRAG() }
                }
                .disabled(isLoading || inputText.isEmpty)
            }
            .padding()
        }
    }
    
    func sendMessage() async {
        let userInput = inputText
        inputText = ""
        messages.append((role: "user", content: userInput))
        isLoading = true
        
        // 빈 assistant 메시지 먼저 추가
        messages.append((role: "assistant", content: ""))
        let assistantIndex = messages.count - 1
        
        do {
            let stream = try await service.sendMessageStream(userInput)
            for try await chunk in stream {
                messages[assistantIndex].content += chunk
            }
        } catch {
            messages[assistantIndex].content = "에러 발생: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func sendStructured() async {
        let userInput = inputText
        inputText = ""
        messages.append((role: "user", content: userInput))
        isLoading = true
        messages.append((role: "assistant", content: ""))
        let assistantIndex = messages.count - 1
        
        do {
            let reply = try await service.askStructured(userInput)
            messages[assistantIndex].content = reply
        } catch {
            messages[assistantIndex].content = "에러 발생: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func sendWithRAG() async {
        let userInput = inputText
        inputText = ""
        messages.append((role: "user", content: userInput))
        isLoading = true
        messages.append((role: "assistant", content: ""))
        let assistantIndex = messages.count - 1
        
        let ragService = RAGService()
        let context = ragService.retrieveRelevantChunks(for: userInput)
        
        do {
            let stream = try await service.sendMessageWithRAG(userInput, context: context)
            for try await chunk in stream {
                messages[assistantIndex].content += chunk
            }
        } catch {
            messages[assistantIndex].content = "에러 발생: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
}
