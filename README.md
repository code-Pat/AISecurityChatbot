# AISecurityChatbot

보안/인증 도메인 지식을 기반으로 한 iOS AI 챗봇 앱.  
OpenAI API를 Swift + SwiftUI로 직접 연동하며 LLM API 통합의 핵심 개념을 학습한 프로젝트입니다.

<br>

## 주요 기능

- **일반 모드** — OpenAI API 스트리밍 응답으로 실시간 타이핑 효과 구현
- **JSON 모드** — 보안 용어를 구조화된 JSON 형식으로 응답 (term / definition / example / related_terms)
- **RAG 모드** — 보안/인증 문서(JWT, OAuth, OTP, FIDO)를 컨텍스트로 주입해 도메인 특화 답변 생성
- **멀티턴 대화** — 이전 대화 히스토리를 유지해 문맥 기반 답변 지원

<br>

## 기술 스택

| 항목 | 내용 |
|------|------|
| Language | Swift 5 |
| UI | SwiftUI |
| 아키텍처 | MVVM |
| AI API | OpenAI Chat Completions API (gpt-4o-mini) |
| 네트워크 | URLSession (외부 라이브러리 미사용) |
| 스트리밍 | SSE(Server-Sent Events) + AsyncThrowingStream |
| RAG | Naive RAG (벡터 DB 없이 텍스트 청크 주입) |

<br>

## 프로젝트 구조

```
AISecurityChatbot/
├── Models/
│   └── Message.swift          # 메시지 데이터 모델
├── ViewModels/
│   └── ChatViewModel.swift    # 비즈니스 로직, 상태 관리 (MVVM)
├── Services/
│   ├── OpenAIService.swift    # OpenAI API 호출, 스트리밍, JSON mode
│   └── RAGService.swift       # 문서 로드 및 청크 검색
├── ContentView.swift          # 채팅 UI
└── security_docs.txt          # RAG용 보안/인증 도메인 문서
```

<br>

## 작업 내용

**LLM API 통합** 프로젝트

- `URLSession`으로 REST API 직접 호출 (외부 라이브러리 미사용)
- SSE 파싱으로 스트리밍 응답 구현 (`AsyncThrowingStream`)
- System prompt, Few-shot, JSON mode를 활용한 프롬프트 엔지니어링
- 벡터 DB 없이 텍스트 문서를 컨텍스트로 주입하는 Naive RAG 구현
- MVVM 패턴으로 비즈니스 로직과 UI 분리
- `xcconfig`를 활용한 API 키 보안 관리

<br>

## 실행 방법

1. 저장소 클론
```bash
git clone https://github.com/code-Pat/AISecurityChatbot.git
```

2. `Secrets.xcconfig` 파일 생성 (프로젝트 루트)
```
OPENAI_API_KEY = your_api_key_here
```

3. Xcode에서 프로젝트 열고 실행

> API 키는 [OpenAI Platform](https://platform.openai.com/api-keys)에서 발급받을 수 있습니다.

<br>

