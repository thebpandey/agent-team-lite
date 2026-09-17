# Installation Instructions

## Agent Team Lite: install from this ZIP

This ZIP contains one complete `agent-team-lite` folder. Install that whole folder, including its subfolders. Do not copy only `SKILL.md` and do not flatten the directory structure.

You do not need to clone the public GitHub repository to install this package. Read LICENSE before installation. Lite is free to use without a paid subscription; the license restricts modification and redistribution of the skill while preserving GitHub and statutory rights.

## Before you begin

- Have Codex CLI or Claude Code installed and signed in.
- Use an environment with Git, a standard Unix-compatible shell, and native agent dispatch available to the host. Lite's reservation helper is a shell script.
- On Windows, the straightforward approach for this package is to run the host and Git inside the same WSL Linux environment. WSL runs a Linux environment on Windows. Use that Linux user's home directory for the installation below. Native PowerShell alone cannot execute the bundled shell helper.
- Work in a Git repository that already has an initial commit. Do not create a commit without the project's required permission.
- The skill adds no external plugin, skill, or package dependencies. Your target project may have its own prerequisites.

## 1. Extract the archive

Use your file manager's Extract command. Open the extracted result and locate the folder named `agent-team-lite` that directly contains `SKILL.md`.

If extraction creates an extra outer folder, open it first. The folder you install must have `SKILL.md` immediately inside it, not inside another nested `agent-team-lite` folder.

## 2. Choose the installation location

| Host | Personal installation: all your projects | Project-only installation: relative to repository root |
| --- | --- | --- |
| Codex CLI / local IDE environment | `~/.agents/skills/agent-team-lite/` | `.agents/skills/agent-team-lite/` |
| Claude Code | `~/.claude/skills/agent-team-lite/` | `.claude/skills/agent-team-lite/` |

`~` means the home directory of the user running the host. Use one installation scope per host to avoid duplicate discovery. These locations follow the [official Codex skill documentation](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills) and [official Claude Code skill documentation](https://code.claude.com/docs/en/skills#where-skills-live).

If a destination already exists, keep it intact until you compare versions and preserve your changes. Do not merge the ZIP blindly into an older folder.

## 3. Install in Codex

Copy the extracted `agent-team-lite` folder into `~/.agents/skills/` using your file manager. Create the parent folders if needed.

Alternatively, in macOS, Linux, or WSL, open a terminal in the directory that contains the extracted `agent-team-lite` folder and run:

```sh
mkdir -p "$HOME/.agents/skills"
if [ -e "$HOME/.agents/skills/agent-team-lite" ]; then
  echo 'An installation already exists. Inspect it before updating.'
else
  cp -R agent-team-lite "$HOME/.agents/skills/agent-team-lite"
fi
```

For project-only installation, copy the same folder into `.agents/skills/` at the repository root instead.

In Codex's prompt input, use `/skills` or type `$` to find Agent Team Lite. First request:

```text
$agent-team-lite status
```

This reads saved state without starting development. Then, from the target Git project, provide a real task:

```text
$agent-team-lite start Add an email preference setting
```

Skill selection and invocation are described in the [official Codex skill guide](https://learn.chatgpt.com/docs/build-skills#how-chatgpt-and-codex-use-skills).

## 4. Install in Claude Code

Copy the extracted `agent-team-lite` folder into `~/.claude/skills/` using your file manager. Create the parent folders if needed.

Alternatively, from the directory containing the extracted folder, run:

```sh
mkdir -p "$HOME/.claude/skills"
if [ -e "$HOME/.claude/skills/agent-team-lite" ]; then
  echo 'An installation already exists. Inspect it before updating.'
else
  cp -R agent-team-lite "$HOME/.claude/skills/agent-team-lite"
fi
```

For project-only installation, use `.claude/skills/` at the repository root instead.

Open Claude Code in the target Git project and enter:

```text
/agent-team-lite status
```

To start a real task:

```text
/agent-team-lite start Add an email preference setting
```

Keep the supporting `agents`, `assets`, `references`, and `scripts` folders. The `agents/openai.yaml` file supplies OpenAI display metadata; it is not a separate Claude agent to install. Claude uses the skill's native-dispatch instructions. See [Claude Code skills](https://code.claude.com/docs/en/skills).

## 5. Check that all files are present

Paths below are relative to the installed `agent-team-lite` folder:

| File | Purpose |
| --- | --- |
| `SKILL.md` | Complete operating instructions. |
| `LICENSE` | Proprietary free-use terms. |
| `README.md` | Architecture, features, limits, and command reference. |
| `Installation Instructions.md` | This installation guide. |
| `agents/openai.yaml` | Display and discovery metadata. |
| `assets/icon.svg` | Icon referenced by the metadata. |
| `scripts/team-slot.sh` | Per-team reservation helper. |
| `references/hosts.md` | Codex and Claude Code dispatch rules. |
| `references/state.md` | Ownership, pause, resume, and recovery rules. |
| `references/integration.md` | Integration by the orchestrator. |

The host invokes the helper through `sh`, so execution does not depend on a ZIP extractor retaining its executable permission. Keep the script's Unix line endings; do not convert it to Windows CRLF.

Install all reference files, including `commands.md`, `output.md`, and `runs.md`, and keep `CHANGELOG.md`. No full agent-team package, plugin, paid service, or additional runtime dependency is needed. The package version is **6.2.0**, authoritative in SKILL.md metadata. Refresh the host after replacing a complete installation. `help` displays the installed version without checking for remote updates; it works without reserving a slot or starting work.

## 6. Use the limited command set

| Action | Codex | Claude Code |
| --- | --- | --- |
| Read help/version | `$agent-team-lite help` | `/agent-team-lite help` |
| Read defaults | `$agent-team-lite settings` | `/agent-team-lite settings` |
| Save defaults | `$agent-team-lite settings continuous=on auto-deploy=off` | `/agent-team-lite settings continuous=on auto-deploy=off` |
| Per-team serial queue | `$agent-team-lite start continuous` | `/agent-team-lite start continuous` |
| Start one task | `$agent-team-lite start [task]` | `/agent-team-lite start [task]` |
| Read progress | `$agent-team-lite status` | `/agent-team-lite status` |
| Pause a team | `$agent-team-lite pause` | `/agent-team-lite pause` |
| Continue that team | `$agent-team-lite resume` | `/agent-team-lite resume` |

An active, paused, or interrupted team consumes one of the repository's two team reservations. A pause preserves its worktree. Resume continues that team. Do not delete reservation files to force a new task.

Lite does not provide `with-preview`, `approve`, named-team targeting, or `all` actions. It does not add feature testing or documentation agents. Limited per-task auto-deploy and serial continuous mode are optional and default to off. The README explains the full scope.

Plain language `agent-team-lite start continuous` works too. Use `start continuous auto-deploy` for explicit run-only deployment through the established project mechanism/target. `start no-continuous no-auto-deploy` overrides saved preferences. Only leading exact modifiers are parsed; use `start -- task text` for literal scope. Both settings default to off in the primary checkout's `.agent-team-lite/settings.json`; explicit run choices override saved defaults, then built-in defaults. Saved deployment on requires a keep/disable choice before start. Reading/saving settings never starts or deploys. See [command rules](references/commands.md).

## Troubleshooting

- **Skill is missing:** Check the exact installation path and look for an accidental double-nested folder. Refresh the host's skill selector. Confirm the host reads the same machine or WSL environment where you copied the files.
- **Helper cannot run:** Confirm `sh` and Git are available in the host's environment, the script is present, and the working directory is the target Git repository.
- **Another team is reported:** Read `status`, then resume the existing task or use the remaining reservation for an independent team. A paused team intentionally retains its reservation.
- **Agent dispatch is unavailable:** Installation alone does not create host capabilities. Lite must report that blocker instead of pretending it started a team.
- **Managed ChatGPT installation:** The filesystem instructions above target your own local CLI/IDE environment. They do not install the skill into a separate ChatGPT-managed environment.

The 6.2.0 release ZIP is built from an exact integrated commit. Before publishing, maintainers run `sh checks/package.sh` on the source checkout and `sh scripts/build-release.sh <integrated-commit> <output-directory>`; the resulting archive contains the installable `agent-team-lite/` folder but not repository-only checks or CI files. Verify the published ZIP with `sha256sum -c SHA256SUMS` and compare `RELEASE_REVISION` with the intended integrated commit. A complete development run on every host and operating system has not been performed.
