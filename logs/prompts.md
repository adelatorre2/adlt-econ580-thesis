# Thesis AI Prompt Library

# 1. Start a New ChatGPT Session

```
Please read `logs/thesis_context.md` first.

Treat it as the authoritative project context for my ECON 580 thesis.

After reading it, help me with the following task:

[TASK]
```

---

# 2. Extract Context From an Old Chat

Use this when migrating context from a previous conversation.

```
Please read this entire conversation.

Then update my thesis project logs.

You have access to the open files in my editor:

logs/thesis_context.md
logs/thesis_decisions.md

Instructions:

1. Read both files first so you understand the current project state.
2. Only update sections that require changes.
3. Do NOT rewrite existing content unnecessarily.
4. Append new information rather than replacing existing material.

Updates to perform:

A. If core project context has changed:
   update the appropriate section of `thesis_context.md`.

B. Add a new decision entry at the TOP of the
   `logs/thesis_decisions.md` log.

C. If new limitations or risks were discovered,
   add them to the appropriate section of `thesis_context.md`.

D. If new open questions emerged,
   add them to the "Open Questions" section.

Keep edits minimal and preserve the existing structure.
```

---

# 3. End‑of‑Session Log Update

Use this at the end of a productive session.

```
Based on this conversation, generate a new entry for
`logs/thesis_decisions.md`.

Follow the template in that file and include:

• decision or progress made
• reasoning
• implications for the thesis
• limitations or risks
• next steps
```

---

# 4. Codex Session Startup

Use this before asking Codex to work on code.

```
Please read `logs/thesis_context.md` first.

Treat it as the authoritative context for this thesis project.

Then inspect the repository and determine which files are relevant
for the following task.

Do not make unnecessary architectural changes.

Task:
[TASK]
```

---

# 5. Codex Post‑Task Log Update

```
Please review the work completed in this session.

Then update my thesis project logs directly.

You have access to the open files in my editor:

logs/thesis_context.md
logs/thesis_decisions.md

Instructions:

1. Read both files first so you understand the current project state.
2. Only update sections that require changes.
3. Do NOT rewrite existing content unnecessarily.
4. Append new information rather than replacing existing material.

Updates to perform:

A. Add a new decision entry at the TOP of `logs/thesis_decisions.md` summarizing:
   • task completed
   • files created or modified
   • data work performed
   • methodological or coding decisions
   • limitations or risks
   • suggested next steps

B. If the session revealed changes to the overall project state,
   update the appropriate section of `logs/thesis_context.md`.

C. If new limitations, risks, or open questions emerged,
   add them to the relevant sections in `thesis_context.md`.

Keep edits minimal and preserve the existing structure of both files.

If no meaningful decisions or context updates occurred,
make no changes.
```
