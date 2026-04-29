//
//  ContentView.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/28/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Namespace private var bottomID
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 채팅 영역
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        // 로딩 인디케이터
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // 스크롤 앵커
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            
            Divider()
            
            // MARK: - 입력 영역
            VStack(spacing: 8) {
                // 모드 선택
                Picker("모드", selection: $viewModel.selectedMode) {
                    Text("일반").tag(SendMode.normal)
                    Text("JSON").tag(SendMode.structured)
                    Text("RAG").tag(SendMode.rag)
                }
                .pickerStyle(.segmented)
                
                // 입력창 + 전송 버튼
                HStack {
                    TextField("질문을 입력하세요...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { viewModel.send() }
                    
                    Button {
                        viewModel.send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.isLoading || viewModel.inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle("보안 AI 어시스턴트")
    }
}

// MARK: - 메시지 버블 컴포넌트
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .textSelection(.enabled)
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
