# Testing Anti-Patterns

**다음 상황에서 이 레퍼런스를 로드:** 테스트 작성/수정, mock 추가, 프로덕션 코드에 테스트 전용 메서드를 넣고 싶어질 때.

## Overview

테스트는 mock의 동작이 아니라 실제 동작을 검증해야 합니다. mock은 격리를 위한 수단이지, 검증 대상이 아닙니다.

**핵심 원칙:** 코드가 실제로 하는 일을 테스트하십시오. mock이 하는 일을 테스트하지 마십시오.

**엄격한 TDD를 따르면 이 안티패턴을 예방할 수 있습니다.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**위반 사례:**
```typescript
// ❌ BAD: mock 존재 여부를 테스트
 test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**왜 잘못인가:**
- 컴포넌트 동작이 아니라 mock 동작을 검증함
- mock이 있으면 통과, 없으면 실패
- 실제 동작에 대한 정보가 전혀 없음

**your human partner's correction:** "Are we testing the behavior of a mock?"

**수정:**
```typescript
// ✅ GOOD: 실제 컴포넌트를 테스트하거나 mock하지 않기
test('renders sidebar', () => {
  render(<Page />);  // sidebar를 mock하지 않음
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

// 또는 sidebar를 격리를 위해 반드시 mock해야 한다면:
// mock 자체를 assert하지 말고, sidebar가 있는 상태에서 Page의 동작을 테스트
```

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"

  IF testing mock existence:
    STOP - Delete the assertion or unmock the component

  Test real behavior instead
```

## Anti-Pattern 2: Test-Only Methods in Production

**위반 사례:**
```typescript
// ❌ BAD: destroy()가 테스트에서만 사용됨
class Session {
  async destroy() {  // 프로덕션 API처럼 보임
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... cleanup
  }
}

// In tests
afterEach(() => session.destroy());
```

**왜 잘못인가:**
- 프로덕션 클래스가 테스트 전용 코드로 오염됨
- 실수로 프로덕션에서 호출될 위험
- YAGNI, 관심사 분리 원칙 위반
- 객체 수명주기와 엔터티 수명주기 혼동

**수정:**
```typescript
// ✅ GOOD: 테스트 정리는 테스트 유틸에서 처리
// Session에는 destroy() 없음 - 프로덕션에서는 무상태

// In test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// In tests
afterEach(() => cleanupSession(session));
```

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"

  IF yes:
    STOP - Don't add it
    Put it in test utilities instead

  Ask: "Does this class own this resource's lifecycle?"

  IF no:
    STOP - Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

**위반 사례:**
```typescript
// ❌ BAD: mock이 테스트 로직을 깨뜨림
test('detects duplicate server', () => {
  // 테스트가 의존하는 config write를 mock이 막아버림
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // Should throw - but won't!
});
```

**왜 잘못인가:**
- mock한 메서드에 테스트가 의존하는 부작용(설정 쓰기)이 있었음
- "안전"을 위한 과도한 mock이 실제 동작을 깨뜨림
- 테스트가 잘못된 이유로 통과하거나, 원인 모르게 실패

**수정:**
```typescript
// ✅ GOOD: 올바른 레벨에서 mock
test('detects duplicate server', () => {
  // 느린 부분만 mock하고 테스트가 필요한 동작은 보존
  vi.mock('MCPServerManager'); // 느린 서버 시작만 mock

  await addServer(config);  // Config written
  await addServer(config);  // Duplicate detected ✓
});
```

### Gate Function

```
BEFORE mocking any method:
  STOP - Don't mock yet

  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on any of those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at lower level (the actual slow/external operation)
    OR use test doubles that preserve necessary behavior
    NOT the high-level method the test depends on

  IF unsure what test depends on:
    Run test with real implementation FIRST
    Observe what actually needs to happen
    THEN add minimal mocking at the right level

  Red flags:
    - "I'll mock this to be safe"
    - "This might be slow, better mock it"
    - Mocking without understanding the dependency chain
```

## Anti-Pattern 4: Incomplete Mocks

**위반 사례:**
```typescript
// ❌ BAD: 필요한 것만 있다고 생각하고 일부 필드만 mock
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // Missing: metadata that downstream code uses
};

// Later: breaks when code accesses response.metadata.requestId
```

**왜 잘못인가:**
- **부분 mock은 구조 가정을 숨깁니다** - 아는 필드만 채움
- **다운스트림 코드가 누락 필드에 의존할 수 있음** - 조용히 실패
- **테스트는 통과하지만 통합에서 실패** - mock 불완전, 실제 API는 완전
- **허위 신뢰 제공** - 실제 동작 증명 실패

**The Iron Rule:** 실제에 존재하는 **완전한 데이터 구조**를 mock해야 하며, 현재 테스트가 쓰는 필드만 뽑아선 안 됩니다.

**수정:**
```typescript
// ✅ GOOD: 실제 API의 완전성을 반영
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // All fields real API returns
};
```

### Gate Function

```
BEFORE creating mock responses:
  Check: "What fields does the real API response contain?"

  Actions:
    1. Examine actual API response from docs/examples
    2. Include ALL fields system might consume downstream
    3. Verify mock matches real response schema completely

  Critical:
    If you're creating a mock, you must understand the ENTIRE structure
    Partial mocks fail silently when code depends on omitted fields

  If uncertain: Include all documented fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**위반 사례:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing"
```

**왜 잘못인가:**
- 테스트는 구현의 일부이지 선택적 후속 단계가 아님
- TDD라면 이런 누락이 발생하지 않음
- 테스트 없이 완료 주장 불가

**수정:**
```
TDD cycle:
1. Write failing test
2. Implement to pass
3. Refactor
4. THEN claim complete
```

## When Mocks Become Too Complex

**경고 신호:**
- mock 설정이 테스트 로직보다 길다
- 테스트 통과를 위해 모든 것을 mock한다
- mock에 실제 컴포넌트가 가진 메서드가 없다
- mock 변경 시 테스트가 같이 깨진다

**your human partner's question:** "Do we need to be using a mock here?"

**고려:** 복잡한 mock보다 실제 컴포넌트를 쓰는 통합 테스트가 더 단순한 경우가 많습니다.

## TDD Prevents These Anti-Patterns

**TDD가 도움이 되는 이유:**
1. **테스트를 먼저 작성** -> 무엇을 검증해야 하는지 먼저 사고하게 함
2. **실패를 직접 확인** -> mock이 아니라 실제 동작을 검증하는지 확인
3. **최소 구현** -> 테스트 전용 메서드 유입 방지
4. **실제 의존성 확인** -> mock 추가 전 필요한 의존성을 정확히 파악

**mock 동작을 테스트하고 있다면 TDD를 위반한 것입니다** - 실제 코드 실패 확인 없이 mock을 먼저 추가했기 때문입니다.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | 실제 컴포넌트를 테스트하거나 unmock |
| Test-only methods in production | 테스트 유틸로 이동 |
| Mock without understanding | 의존성 먼저 이해, 최소 mock |
| Incomplete mocks | 실제 API 구조를 완전 반영 |
| Tests as afterthought | TDD - 테스트 우선 |
| Over-complex mocks | 통합 테스트 고려 |

## Red Flags

- `*-mock` test ID를 직접 assert
- 테스트 파일에서만 호출되는 메서드
- mock 설정이 테스트의 50% 이상
- mock 제거 시 테스트 붕괴
- 왜 mock이 필요한지 설명 불가
- "안전하게 하려고"라는 이유만으로 mock

## The Bottom Line

**mock은 격리 도구이지, 검증 대상이 아닙니다.**

TDD 과정에서 mock 동작 검증에 빠졌다면 잘못된 방향입니다.

수정 원칙: 실제 동작을 테스트하거나, 왜 mock이 필요한지부터 다시 검토하십시오.
