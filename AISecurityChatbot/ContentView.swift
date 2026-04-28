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
            }
            .padding()
        }
    }
    
    func sendMessage() async {
        let userInput = inputText
        inputText = ""
        messages.append((role: "user", content: userInput))
        isLoading = true
        
        do {
            let reply = try await service.sendMessage(userInput)
            messages.append((role: "assistant", content: reply))
        } catch {
            messages.append((role: "assistant", content: "에러 발생: \(error.localizedDescription)"))
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
}
