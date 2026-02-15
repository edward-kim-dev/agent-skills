---
name: writing-plans
description: 멀티스텝 작업에 대한 스펙/요구사항이 있을 때, 코드를 수정하기 전에 사용합니다.
---

# Writing Plans

## Overview

코드베이스 맥락이 거의 없고 취향도 들쭉날쭉한 엔지니어를 가정하고, 구현 계획을 완전하게 작성합니다. 각 태스크마다 어떤 파일을 건드릴지, 어떤 코드를 작성할지, 어떤 테스트를 실행할지, 어떤 문서를 확인해야 할지까지 모두 명시합니다. 전체 계획은 잘게 쪼갠 작업 단위로 제공합니다. DRY. YAGNI. TDD. 잦은 커밋.

상대는 숙련 개발자라고 가정하되, 우리 도구 체인/도메인 지식은 거의 없다고 가정하십시오. 또한 테스트 설계 역량이 높지 않을 수 있다고 가정하십시오.

**시작 시 반드시 선언:** "I'm using the writing-plans skill to create the implementation plan."

**맥락:** 이 작업은 brainstorming 스킬에서 생성한 전용 worktree에서 수행해야 합니다.

**저장 위치:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**각 단계는 단일 행동(2-5분):**
- "실패 테스트 작성" - 1단계
- "실패 확인 실행" - 1단계
- "통과 최소 구현 작성" - 1단계
- "테스트 통과 확인" - 1단계
- "커밋" - 1단계

## Plan Document Header

**모든 계획 문서는 반드시 아래 헤더로 시작:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

## Remember
- 항상 정확한 파일 경로 사용
- 계획에는 완성 코드 포함 ("검증 추가" 같은 추상 문장 금지)
- 명령은 정확히 쓰고 기대 출력까지 명시
- 관련 스킬은 @ 구문으로 참조
- DRY, YAGNI, TDD, 잦은 커밋 유지

## Execution Handoff

계획 저장 후 실행 방식을 제안합니다.

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - 태스크마다 새로운 서브에이전트 실행, 태스크 사이 리뷰, 빠른 반복

**2. Parallel Session (separate)** - 새 세션에서 executing-plans 사용, 체크포인트 기반 배치 실행

**Which approach?"**

**Subagent-Driven 선택 시:**
- **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development 사용
- 현재 세션 유지
- 태스크마다 fresh subagent + code review

**Parallel Session 선택 시:**
- worktree에서 새 세션 열도록 안내
- **REQUIRED SUB-SKILL:** 새 세션은 superpowers:executing-plans 사용
