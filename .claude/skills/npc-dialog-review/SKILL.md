---
name: npc-dialog-review
description: Dialogue-quality review of a Break Escape scenario's ink — compiles the ink, runs the validator for the dialogue-facing checks, then applies the writing judgement in README_ink_best_practices.md (attribution, hub structure, player-choice phrasing, and above all whether choices actually matter). Trigger when the user asks for a "dialogue review", "NPC review", "ink review", "conversation critique", or wants to check whether an NPC's choices feel flat / consequential before finalising. Complements scenario-design-review, which owns structure/solvability.
---

# Break Escape NPC dialogue review skill

Two-phase check, scoped to what the characters *say and offer*: (1) compile + validate the ink, (2) apply the writing principles from `README_ink_best_practices.md` that require reading and reasoning about the dialogue itself.

This skill is the dialogue counterpart to `scenario-design-review`. Where that skill judges solvability, layout, and objectives scaffolding, this one judges conversation craft — and, most importantly, **whether player choices carry consequences**. Where the two overlap (KO resilience, player-choice phrasing), defer to `scenario-design-review` for the deep mechanical verdict and focus here on the writing.

Work from the repository root (`/home/cliffe/Files/Projects/Code/BreakEscape/BreakEscape`). Take a scenario name or path as argument (e.g. `m02_ransomed_trust`); if given a directory, its ink lives in `scenarios/<name>/ink/*.ink`.

## Step 1 — compile and validate

```bash
./scripts/compile-ink.sh <scenario_name>
ruby scripts/validate_scenario.rb scenarios/<scenario_name>/scenario.json.erb
```

**From the compile output**, report:
- Any `Failed:` count > 0 — a file that doesn't compile is a blocker; name it.
- **"Apparent loose end" warnings** — per `README_ink_best_practices.md`, these are usually real syntax errors (missing knot, bad divert, stray `**`/`*` at line start), not noise. List each.
- `-> END` warnings are expected only on closing debriefs / briefings that legitimately end the conversation; note them but don't escalate.

**From the validator**, surface only the **dialogue-facing** findings (leave layout/objectives/graph to `scenario-design-review`):
- `#speaker:narrator` used with no top-level `narrator` voice block defined.
- Player-choice / `You:`-echo phrasing flags.
- `#give_item:...` that doesn't match the speaking NPC's `itemsHeld`, and `#give_item` tags placed *after* their dialogue line (they fire on the wrong `story.Continue()`).
- **Speaker prefixes that resolve to no NPC** — ❌ INVALID for a name used 5+ times in a file, 💡 SUGGESTION for a one-off (prose labels like `Command: nmap ...` look identical to the check and render harmlessly).
- **Ink character hazards** — `//` inside dialogue (silently truncates the line as a comment), a standalone `*emote*` at line start (parses as a phantom choice), `**bold**`, unpaired `*`, unbalanced `[ ]` in a choice.
- KO-wiring warnings where a required task's only completion path is a KO-vulnerable conversation with no `taskOnKO` fallback (cross-reference in §2f, don't restate detail).

Present blockers first, then warnings. Omit empty groups.

## Step 2 — dialogue review against README_ink_best_practices.md

Read every `.ink` file in `scenarios/<name>/ink/`. Report each finding as **CONCERN**, **OK**, or **N/A**, and cite the file + knot. Do not restate Phase-1 items; cross-reference them.

### 2a. Attribution & narration

- **Every `Character Name:` prefix resolves to an NPC `id` or `displayName`, exactly.** This is the highest-value check in this skill. `normalizeSpeakerId()` matches only against id / displayName plus the specials `player`, `npc`, `you`, `Narrator`. A shortened name (`Marcus:` for `Marcus Webb`) or a role word (`Guard:`, `Nurse:`, `Dr. Kim:`) does **not** resolve — ink still compiles, and the engine renders the literal text `Marcus: ...` inside whichever character spoke last. Phase 1 flags this automatically; confirm each ❌ INVALID is a real speaker rather than a prose label, and check the fix used the NPC's exact `displayName` instead of shortening it further.
- **Emotes split by category, not wholesale.** Delivery cues the TTS can act on (`*quietly*`, `*sighs*`, `*pause*`, `*not looking up*`) stay inline; events in the scene (handing something over, crossing the room, looking up for the first time) become `Narrator:` beats. Flag a file that has promoted *every* gesture — each Narrator line is an extra click-through and conversations start to wade.

### 2a-bis. Is the dialogue supported by the scenario?

Ink can assert anything; the engine only renders what the scenario defines. Read each NPC's block in `scenario.json.erb` alongside its ink and flag contradictions — these are invisible until playtest:

- **Movement vs `behavior`.** An NPC with no `behavior.patrol` never moves. Stage directions like *"without stopping"*, *"takes you down the row"*, *"comes back with"* describe something the player will never see. Either the NPC needs a patrol, or the stillness should become the characterisation.
- **Props.** Anything the dialogue draws attention to should exist as an object in that room. If it must not be takeable (it would bypass a puzzle), it still wants to exist as `takeable: false`.
- **Handovers.** "Take it, it's yours" needs a `#give_item` tag *and* a matching `itemsHeld` entry. Phase 1 validates the tag; only reading the prose catches an offer that was never tagged at all.
- **Geography.** Directions in dialogue go stale whenever connections change. Cross-check every "east of", "down the corridor", "first door" against the current `connections`.
- **Sprites vs narration.** If a knot says a character has been taken away or their post is empty, an event mapping should `setVisible: false`.
- **Off-screen intentions.** A stationary NPC saying "I go in in five minutes" is still standing there hours later. Intentions must stay true for an unbounded night.

Off-map events and post-mission debriefs are legitimate exceptions.

### 2a-ter. Voices

- Every speaking NPC has a `voice` block (terminals/computer phone NPCs excepted).
- No `voice.name` is reused by two characters who appear together — reuse is correct only for the *same* character across multiple NPC entries.
- Each `style` names its accent explicitly and says "consistent ... throughout"; the cast is not uniformly RP.

- Dialogue uses inline `Character Name:` prefixes (primary method); `#speaker:` tags only as a fallback for tag-less lines. (Both styles are valid — `#speaker:` keys resolve to NPCs by **prefix**, e.g. `#speaker:dr_kim` → NPC `dr_sarah_kim`, matching the shipped m01 `derek` → `derek_lawson` convention. A speaker key that matches no NPC by prefix is a real bug.)
- Standalone scene-setting / third-person action beats are spoken as `Narrator:` lines, and a top-level `narrator` voice block exists. Inline emotes inside a character's own line (`Nurse: *sighs* Right.`) are fine.

### 2b. Player choices are spoken dialogue
Per `§Player Choice Formatting`. Scan every `*`/`+` choice bracket:
- **CONCERN** if a bracket is a third-person menu label (`[Ask about security]`, `[Sympathize with Marcus]`, `[Express readiness]`) instead of the player's actual first-person words.
- **CONCERN** on the `You:`-echo tell — a short label bracket immediately followed by a `You: <the real line>` on the next line. Fix: fold the real line into the bracket, delete the echo. (m01 convention: no NPC ink file follows a choice with a `You:` line.) The one legitimate exception is a genuinely non-verbal choice (`[Stay silent]`) followed by `You: …` representing the silence.
- Same rule for `#speaker:computer` decision terminals: `[Confirmed. Send it all.]`, not `[Confirm — upload everything]`.

### 2c. Hub structure integrity
Per `§Recommended NPC Structure`:
- `=== start ===` and `=== hub ===` present; topic knots `-> hub`.
- At least one **sticky (`+`) exit** choice tagged `#exit_conversation` always reachable in the hub.
- Exit conversations are 1–2 lines (`§Keep Exit Conversations Brief`).
- No hard `-> END` except deliberate scenario endpoints (debrief/briefing).

### 2d. Choices that matter — the core check (`§Making Choices Matter`)
This is the reason the skill exists. For **each NPC**, judge whether its choices are consequential or flat.

1. **Flat-choice detection.** Find sets of choices that all divert to the same knot with **no variable set and no distinct line** in between — the player gets identical content regardless of pick. Grep aid: look for multiple choices under one knot whose bodies are a bare `-> same_target`. Report each cluster as a CONCERN with the knot name. If deleting the choices would lose nothing, they're decoration. **Note the spectrum:** choices that expose *different information* per branch are **not** flat — that's a valid lightweight consequence and is entirely appropriate in briefings / info-gathering (the player chooses what to learn); mark those OK. Only *identical content regardless of pick* is the anti-pattern. Judge in-mission and debrief choices harder — they should tend toward *different state the story pays back later*, not just different info.

2. **Convergent-but-legitimate.** Before flagging convergence, ask whether the character is **immovable for a story reason** (an ideological antagonist who cannot be swayed — e.g. Ghost, a committed inside asset). Convergent choices are correct there because the player picks a *stance*, not an *outcome* — but the choice should still set a stance variable so the convergence reads as authored. Mark these **OK** (note the stance var) rather than CONCERN.

3. **End-to-end consequence wiring.** For choices that *do* set state via `#set_global:<name>:<value>`, verify all three legs (§2e) and confirm **something actually branches on it later** (another NPC, or the closing debrief). A `#set_global` that is set but never read is a broken promise — CONCERN.

4. **Critical-path safety.** Where a choice *withholds* something (an item, a code, a task completion), confirm the withheld thing has a **redundant source** so a "cold"/"wrong" pick can't soft-lock. Consequence choices may change flavour, tone, richness, and side rewards freely; anything the mission requires needs another path. A gate on the critical path with no alternate source is a **Must-fix**.

5. **Reward for engagement.** Does curiosity pay? Optional questions that yield real foreknowledge (a breadcrumb toward a later reveal, an early warning, a name) make exploration worthwhile without blocking players who skip them. Note where an NPC could offer this and doesn't, if it would strengthen the scene.

6. **Lossy opening choices.** Flag briefings/debriefs where a few big opening choices each divert into a *different slice* of content, so picking one **skips** the others. Recommend the question-hub pattern: stance choices set state → hub offers each topic as its own repeatable option → routes into the shared spine. Nobody misses content.

7. **Continuity callbacks.** Note where the dialogue could reward attention by remembering events beyond the scene (prior missions, named characters, canon) — and check any existing callback is phrased for whatever state actually persists between missions (don't assert an outcome the player may not have produced).

### 2e. Cross-file state integrity
For every `#set_global:<name>:…` found in the ink:
- Is `<name>` declared in `scenario.json.erb` → `globalVariables`? (Undeclared = silently dead.)
- Is `<name>` `VAR`-declared in **every** ink file that reads it (so the engine syncs it at open)?
- Is it read *somewhere* (a conditional, a callback)? Set-but-never-read is a CONCERN.
Grep aids: `grep -rho '#set_global:[a-z_]*' ink/ | sort -u` vs the `globalVariables` block and each file's `VAR` declarations.

### 2f. Influence variable & feedback tags
Per `§NPC Influence System`:
- **Tags are mandatory:** every `influence +=` (or `<name>_influence`/`rapport`/`favour +=`) must be immediately followed by `# influence_increased`, and every `-=` by `# influence_decreased`. Missing tags = no visual feedback — list every offender (this is a Should-fix). A `+= 0` no-op needs no tag.
- **Coverage:** does every NPC the player can build rapport with (allies, gatekeepers, witnesses, suspects) actually *have* an influence variable? Flag conversational NPCs that gate or colour behaviour on ad-hoc booleans but expose no influence feedback at all. (Pure ambient one-liners, in-bed patients, terminals, and knowledge-gated cutscene handlers legitimately have none.)
- **No parallel scalars:** flag any second numeric rapport track (`trust_level`, `relationship_score`, `friendliness`) competing with influence — collapse into one influence var. A derived boolean threshold (`marcus_trusts_player`) is fine.

### 2g. Syntax & readability anti-patterns
Per `§Common Syntax Errors`:
- No markdown bold `**text**` (renders literally).
- No bullet-list dialogue — convert lists to flowing sentences (players click line-by-line).
- No lines starting with `*` except valid choices.
- Investigate every "apparent loose end" from Phase 1.

### 2h. KO-resilience (dialogue side, cross-ref)
Because KO is permanent and any NPC can be attacked, a conversation that is the **only** way to complete a required task or hand over a gating item is a latent soft-lock. Confirm such NPCs have `taskOnKO` (complete the stranded task) and `globalVarOnKO` (so the debrief can acknowledge the KO instead of contradicting it). `scenario-design-review §2h` owns the full mechanical verdict and the critical-vs-side classification — cross-reference it; here just confirm the *writing* accounts for the KO branch (no line assumes an NPC is alive/at-large whose body may be on the floor).

## Step 3 — prioritised action list

Short, one line per item, grouped:

**Must fix (blocks play or breaks a promise)**
- Ink that fails to compile; unresolved "apparent loose end" warnings.
- A consequence choice that gates the **critical path** with no redundant source (soft-lock).
- A `#set_global` gating progress that is undeclared or never read.

**Should fix (degrades the story)**
- Flat choices (identical content regardless of pick) that aren't legitimate stance-convergence.
- Menu-label / `You:`-echo choice phrasing; missing influence tags; narration not on the Narrator voice.
- Lossy opening choices that skip content (recommend question-hub).

**Worth considering (polish)**
- Convergent choices that would read as authored if they set a stance variable.
- Places to reward curiosity or add a continuity callback.
- Exit-conversation trims, list-to-sentence conversions.

Keep it concise; don't repeat detail already given in the review sections above.
