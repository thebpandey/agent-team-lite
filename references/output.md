# Lite messages and installed version

Frame every user-facing Lite message (progress, help, settings, status, questions, recovery, completion, and relayed teammate messages) with exactly this top and bottom border, with blank lines around content:

```text
==========================================================================

Agent-Team Lite / Orchestrator

Message content.

==========================================================================
```

Use `Agent-Team Lite / Developer` or `Agent-Team Lite / Reviewer` for teammate messages. No named teams, IDs, or multi-team namespace. Use one frame for a report/table; never nest frames. A relay may have separate frames for separate messages, or role-labeled text within one report frame. Native tool/widget payloads remain unchanged; frame accompanying prose. Do not fence the whole response in Markdown; only the wordmark uses a text fence.

For each user-invoked supported help, start, resume, settings, or status action, put this wordmark inside the first frame, before the role and body. Combined commands show it once total. Never repeat for progress, teammate replies, quoted commands, or internal continuous iterations. Resolve actions, not substrings in task descriptions.

```text
 ███   █████  █████  ██  ██  ██████        ██████  █████   ███   ██   ██
██ ██  ██     ██     ███ ██    ██            ██    ██     ██ ██  ███ ███
██ ██  ██     ████   ██████    ██    ████    ██    ████   ██ ██  ███████
█████  ██ ██  ██     ██ ███    ██    ████    ██    ██     █████  ██ █ ██
██ ██  ██ ██  ██     ██  ██    ██            ██    ██     ██ ██  ██   ██
██ ██  █████  █████  ██  ██    ██            ██    █████  ██ ██  ██   ██  lite
```

Immediately below the closing fence display `Agent-Team Lite v<installed version>`, using `metadata.version` in the installed SKILL.md as authority, then:

Created by [thebpandey](https://github.com/thebpandey) · [Lite source](https://github.com/thebpandey/agent-team-lite)

The smaller lowercase `lite` remains ordinary text beside the solid letters. If Unicode blocks are unavailable, replace each `█` with `#`, preserving spaces and lowercase lite. Plain-text hosts display the same creator and Lite source URL without Markdown links. No fonts, images, packages, or network access are required. Missing version metadata displays `Agent-Team Lite — version unknown (unversioned copy)`. Never infer remote freshness from a displayed installed version.
