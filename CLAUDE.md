# Claude Instructions

## Model Convention

- **Main agent (this conversation):** Sonnet — default, no override needed.
- **Advisor:** Opus — always used by `advisor()`, no override needed.
- **Subagents:** Haiku — always pass `model: "haiku"` when spawning via the `Agent` tool.

## Token & Context Hygiene

- **Lean commits:** After each edit, stage only the changed files by name and commit immediately. Write the message from what you just changed — do NOT run `git diff`, `git log`, or `git status` first.
- **Don't re-read files in context:** If a file was already read this session, use it — don't re-read it.
- **Compact proactively:** Once a decision is reached, `/compact` immediately — carry forward only the decision, not the back-and-forth. Use `/clear` when prior context won't help the next task at all.
- **Cache awareness:** Prompt cache TTL is 5 minutes. Keep turns within that window to avoid cache misses. Cached context costs far fewer tokens.

## Project Conventions

- **Plan before vague/architectural tasks:** If a request lacks specifics on *how* to do something (e.g. "refactor", "restructure"), present a plan and wait for approval before making any changes.
- **No unprompted TODO analysis:** Don't summarize TODOs or propose next steps unless explicitly asked.
