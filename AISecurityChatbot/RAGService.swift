//
//  RAGService.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/29/26.
//

import Foundation

class RAGService {
    // 문서 전체 로드
    private func loadDocument() -> String {
        guard let url = Bundle.main.url(forResource: "security_docs", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return content
    }
    
    // 질문과 관련된 섹션만 추출 (Naive RAG)
    func retrieveRelevantChunks(for query: String) -> String {
        let document = loadDocument()
        let chunks = document.components(separatedBy: "\n\n")
        
        let queryLower = query.lowercased()
        let relevant = chunks.filter { chunk in
            chunk.lowercased().contains(queryLower) ||
            queryLower.contains(chunk.prefix(10).lowercased().trimmingCharacters(in: .init(charactersIn: "[]")))
        }
        
        // 관련 섹션 없으면 전체 문서 반환
        return relevant.isEmpty ? document : relevant.joined(separator: "\n\n")
    }
}
