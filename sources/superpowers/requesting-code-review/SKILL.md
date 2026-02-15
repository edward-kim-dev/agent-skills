---
name: requesting-code-review
description: 태스크 완료 시점, 주요 기능 구현 후, 메인 병합 전에 결과가 요구사항을 충족하는지 검증할 때 사용합니다.
---

# Requesting Code Review

문제가 누적되기 전에 잡기 위해 superpowers:code-reviewer 서브에이전트를 디스패치합니다.

**핵심 원칙:** 일찍 리뷰하고, 자주 리뷰합니다.

## When to Request Review

**필수:**
- subagent-driven 개발의 각 태스크 후
- 주요 기능 완료 후
- main 병합 전

**선택이지만 가치 있음:**
- 막혔을 때(새 관점 확보)
- 리팩터링 전(기준선 점검)
- 복잡한 버그 수정 직후

## How to Request

**1. git SHA 확보:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. code-reviewer 서브에이전트 디스패치:**

Task 도구에서 superpowers:code-reviewer 타입을 사용하고 `code-reviewer.md` 템플릿을 채웁니다.

**플레이스홀더:**
- `{WHAT_WAS_IMPLEMENTED}` - 방금 구현한 내용
- `{PLAN_OR_REQUIREMENTS}` - 의도한 요구사항
- `{BASE_SHA}` - 시작 커밋
- `{HEAD_SHA}` - 끝 커밋
- `{DESCRIPTION}` - 요약 설명

**3. 피드백 반영:**
- Critical은 즉시 수정
- Important는 다음 단계 전 수정
- Minor는 후속 처리로 기록
- 리뷰어가 틀렸다면 근거를 제시해 반박

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch superpowers:code-reviewer subagent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- 모든 태스크 후 리뷰
- 누적되기 전에 문제 포착
- 다음 태스크로 넘어가기 전 수정

**Executing Plans:**
- 배치(예: 3개 태스크) 후 리뷰
- 피드백 적용 후 계속 진행

**Ad-Hoc Development:**
- 병합 전 리뷰
- 막힐 때 리뷰

## Red Flags

**절대 금지:**
- "간단하니까" 리뷰 생략
- Critical 이슈 무시
- Important 미해결 상태로 진행
- 타당한 기술 피드백과의 감정적 논쟁

**리뷰어가 틀린 경우:**
- 기술적 근거로 반박
- 동작 증명 코드/테스트 제시
- 필요 시 재질문

템플릿: `requesting-code-review/code-reviewer.md`
