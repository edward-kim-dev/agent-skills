# AgentSkills

AI 코딩 도구(Cursor, Claude Code, Codex)의 스킬을 중앙에서 관리하고 프로젝트에 배포하는 저장소.

## 구조

```
AgentSkills/
├── sources/            # 스킬팩 원본 (직접 수정 가능)
│   └── superpowers/    # obra/superpowers 기반 커스텀 스킬
│
├── cursor/             # Cursor용 (symlink)
├── claude-code/        # Claude Code용 (symlink)
├── codex/              # Codex용 (symlink)
│
├── custom/             # 직접 만든 커스텀 스킬
├── Makefile            # 배포/관리 명령어
└── README.md
```

**원리:** `sources/`에 스킬팩 원본을 두고, 각 도구 디렉토리에서 심볼릭 링크로 연결.
프로젝트 배포 시 `sources/`의 실제 경로로 링크를 생성.

## 스킬팩 카탈로그

| 스킬팩 | 설명 | 스킬 목록 |
|--------|------|----------|
| superpowers | obra/superpowers 기반 개발 워크플로우 | brainstorming, requesting-code-review, test-driven-development, using-superpowers, verification-before-completion, writing-plans |

## 빠른 시작

```bash
# 사용 가능한 스킬 목록
make list

# 현재 상태 확인
make status

# 프로젝트에 배포
make deploy-cursor PROJECT=/path/to/project    # Cursor
make deploy-claude PROJECT=/path/to/project    # Claude Code
make deploy-codex  PROJECT=/path/to/project    # Codex
make deploy-all    PROJECT=/path/to/project    # 전체

# 글로벌 설치
make deploy-claude-global    # -> ~/.claude/skills/
make deploy-codex-global     # -> ~/.agents/skills/

# 배포 제거
make undeploy-cursor PROJECT=/path/to/project
```

## 도구별 스킬 경로

| 도구 | 프로젝트 경로 | 글로벌 경로 |
|------|-------------|------------|
| Cursor | `.cursor/skills/` | N/A |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.agents/skills/` |

## 새 스킬팩 추가

### 외부 레포 (git submodule)

```bash
make add-source NAME=my-skills URL=https://github.com/user/repo.git
```

자동으로 `sources/`에 submodule 추가 + 모든 도구 디렉토리에 심볼릭 링크 생성.

### 직접 생성

`sources/` 아래에 디렉토리를 만들고 스킬 추가:

```bash
mkdir -p sources/my-pack/my-skill
```

그 후 도구 디렉토리에 링크:

```bash
ln -s ../sources/my-pack cursor/my-pack
ln -s ../sources/my-pack claude-code/my-pack
ln -s ../sources/my-pack codex/my-pack
```

## 커스텀 스킬 작성

`custom/` 디렉토리에 Agent Skills 표준 형식으로 작성:

```
custom/
└── my-skill/
    └── SKILL.md
```

**SKILL.md 템플릿:**

```yaml
---
name: my-skill
description: 이 스킬이 언제, 어떤 상황에서 사용되는지 설명.
---

# My Skill

## 이 스킬을 사용하는 경우
- ...

## 워크플로우
1. ...
2. ...
```

### Agent Skills 표준 규칙
- `name`: 소문자, 숫자, 하이픈만 사용 (최대 64자)
- `name`은 디렉토리 이름과 일치해야 함
- `description`: 에이전트가 자동 발견할 때 사용하는 키워드 포함
- SKILL.md는 500줄 이하 권장, 상세 내용은 별도 파일로 분리

## 스킬팩 제거

```bash
make remove-source NAME=my-skills
```
