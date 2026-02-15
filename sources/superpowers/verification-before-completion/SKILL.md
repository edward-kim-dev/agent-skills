---
name: verification-before-completion
description: 작업이 완료/수정/통과되었다고 주장하기 직전에 사용합니다. 커밋/PR 생성 전 반드시 검증 명령을 실행하고 출력으로 확인한 뒤에만 성공 주장을 허용합니다. 항상 주장보다 증거가 우선입니다.
---

# Verification Before Completion

## Overview

검증 없이 완료를 주장하는 것은 효율이 아니라 부정직입니다.

**핵심 원칙:** 항상 주장보다 증거가 먼저입니다.

**이 규칙의 문구만 피해서 우회하는 것도 규칙 위반입니다.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

현재 메시지에서 검증 명령을 실제 실행하지 않았다면, 통과했다고 주장할 수 없습니다.

## The Gate Function

```
어떤 상태 주장이나 만족 표현을 하기 전에:

1. IDENTIFY: 이 주장을 입증하는 명령이 무엇인지 식별
2. RUN: 전체 명령을 새로/완전하게 실행
3. READ: 전체 출력 확인, exit code 확인, 실패 개수 확인
4. VERIFY: 출력이 주장 내용을 입증하는지 확인
   - NO: 증거와 함께 실제 상태 보고
   - YES: 증거와 함께 주장 보고
5. ONLY THEN: 주장 표현

한 단계라도 건너뛰면 = 검증이 아니라 허위 주장
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- "should", "probably", "seems to" 같은 추정 표현 사용
- 검증 전 만족 표현("Great!", "Perfect!", "Done!" 등)
- 검증 없이 커밋/푸시/PR 진행
- 에이전트 성공 보고를 그대로 신뢰
- 부분 검증에 의존
- "이번 한 번만" 사고
- 피로를 이유로 종료하려는 상태
- **검증 없이 성공을 암시하는 모든 표현**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

24개의 실패 메모리에서 반복된 결과:
- 파트너가 "믿기 어렵다"고 반응 -> 신뢰 훼손
- 정의되지 않은 함수 배포 -> 런타임 장애
- 요구사항 누락 배포 -> 불완전 기능 전달
- 가짜 완료로 시간 낭비 -> 재지시 -> 재작업
- "정직은 핵심 가치" 원칙 위반

## When To Apply

**항상 적용(다음 이전):**
- 모든 성공/완료 주장
- 모든 만족 표현
- 작업 상태에 대한 긍정 표현
- 커밋, PR 생성, 태스크 완료
- 다음 태스크 이동
- 에이전트 위임

**규칙 적용 범위:**
- 정확히 같은 문구
- 바꿔 말한 문구/동의어
- 성공을 암시하는 표현
- 완료/정확성을 암시하는 모든 커뮤니케이션

## The Bottom Line

**검증에는 지름길이 없습니다.**

명령을 실행하고, 출력을 읽고, 그 다음 결과를 주장하십시오.

협상 불가 규칙입니다.
