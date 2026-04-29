//
//  ContentView.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/28/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages) { message in
                    HStack {
                        if message.isUser { Spacer() }
                        Text(message.content)
                            .padding()
                            .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .cornerRadius(12)
                        if !message.isUser { Spacer() }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                TextField("질문을 입력하세요...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                Button("전송") { viewModel.send(mode: .normal) }
                    .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
                Button("JSON") { viewModel.send(mode: .structured) }
                    .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
                Button("RAG") { viewModel.send(mode: .rag) }
                    .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
