---
name: safe-agile
description: "SAFe rules for Azure DevOps: use whenever creating or planning PIs, iterations, sprints, PODs, capacity, or Epics, Features, User Stories or Tasks in Azure DevOps, whenever setting a work item's Area Path or Iteration Path (Epics/Features on the ART team and PI, Stories/Tasks on the POD and iteration), whenever logging a Bug or an Issue (bug = broken or not working; issue = working but has an issue), and whenever executing backlog work (code, docs, config for a story or task) so work item states are kept current as the work happens."
---

# SAFe Agile for Azure DevOps

These rules apply to every Agile artefact Claude plans or creates in Azure DevOps (ADO): PI calendars, iteration paths, teams/PODs, capacity, and work items. If a user request conflicts with a rule here, point out the conflict and ask before deviating.

> Project-specific approved deviations are recorded in the repository's `CLAUDE.md`. Where `CLAUDE.md` lists an approved deviation, follow it; everything else here still applies.

## 1. Operating model

- Delivery teams are **PODs**: `POD 1`, `POD 2`, ... Each POD = **1 human developer + Claude**.
- **Claude writes the code**; the human developer owns direction, review, integration, testing sign-off and anything Claude cannot do (access, environments, approvals).
- Development follows **Spec Anchored Development** (section 5): the ADO work items *are* the spec.

## 2. Cadence

### Iterations (sprints)
- Length: **1 calendar week = 5 working days**, spanning the weekend.
- Starts **Thursday 00:00 IST**, ends **Wednesday 23:59 IST**. In ADO set Start = Thursday, Finish = following Wednesday.
- Working days: Thu, Fri, Mon, Tue, Wed. Sat/Sun are non-working (team settings > working days = Mon–Fri).

### Program Increments (PIs)
- A PI = **5 iterations** (5 weeks), numbered `Iteration <PI>.<n>` (1.1–1.5, 2.1–2.5 ...).
- PI names are zero-padded: `PI_01`, `PI_02`, ...
- PI dates = first day of its first iteration to last day of its last iteration.
- Gaps between PIs (holiday shutdowns, Innovation & Planning week) are allowed. Ask the user about known holidays/shutdowns before generating a calendar; never assume none.
- Dates are written **M/D/YYYY**.

### Iteration path structure
```
<Project or Product Name>
  PI_01                 11/19/2026 - 12/23/2026
    Iteration 1.1       11/19/2026 - 11/25/2026
    Iteration 1.2       11/26/2026 - 12/2/2026
    Iteration 1.3       12/3/2026  - 12/9/2026
    Iteration 1.4       12/10/2026 - 12/16/2026
    Iteration 1.5       12/17/2026 - 12/23/2026
  PI_02                 ...
```
(Example dates only. Always compute real Thursday-start dates from the user's chosen start and verify each start is a Thursday and each end a Wednesday.)

All PODs share the same iteration tree. Each POD is an ADO team with its own area path: `<Project>\POD 1`, `<Project>\POD 2`, ...

The project also has an **ART-level team** (the Agile Release Train that the PODs belong to). It owns the Epics and Features, so its area path is the parent of the POD areas (usually the project's root area `<Project>`, or `<Project>\<ART name>` where the project defines one). Its iteration selection must include the PI nodes (`PI_01`, `PI_02`, ...) so Epics and Features show on its backlog. Check the actual team and area names in ADO before using them; never invent them.

## 3. Estimation and capacity

- **1 Story Point (SP) = work one person could complete in one ideal day** (SAFe normalised estimation).
- Allowed story sizes: **1, 2, 3, 5**. Anything estimated at 8+ must be split before it enters an iteration.
- **Hybrid POD velocity: 12 SP per working day** → **60 SP per iteration** → **300 SP per PI** (before holidays).
- Human working day: **6 productive hours + 2 hours planning/review/sync**. Occasional overtime is allowed but never planned into capacity.
- Holidays and leave reduce capacity by **12 SP per lost day**; record days off in ADO team capacity.
- Tasks are estimated in **hours** (Original Estimate / Remaining Work). The human's assigned task hours must not exceed 6 h per working day. If its coded by claude then there is no limit 

## 4. Work item hierarchy

`Epic → Feature → User Story → Task` (ADO Agile process). Every item has a parent except Epics. Create top-down so parent links exist.

| Type | Scope | Sized in | Area Path | Iteration Path |
|---|---|---|---|---|
| Epic | Business initiative, may span PIs | T-shirt (S/M/L/XL) + optional SP rollup | **ART-level team** | **The PI** it starts in: `<Project>\PI_xx` |
| Feature | Deliverable capability, **must fit in one PI** | SP (sum of stories) | **ART-level team** | **The PI**: `<Project>\PI_xx` |
| User Story | Vertical slice, **must fit in one iteration** | SP (1,2,3,5) | Its **POD** | **The iteration**: `<Project>\PI_xx\Iteration x.y` |
| Task | Concrete technical step | Hours | Its **POD** (same as its story) | **The iteration** (same as its story) |

### Area and iteration rule (Epics and Features vs Stories and Tasks)
Whenever a project is created, or an Epic or Feature is added to an existing project:
- **Epics and Features** go to the **ART-level team's area** and to the **PI node** (`PI_01`, `PI_02`, ...). Never set them to an iteration (`Iteration x.y`) and never to a POD's area. They are planned at PI level, owned by the train, and delivered by one or more PODs through their stories.
- **User Stories and Tasks** go to the **POD team's area** (`<Project>\POD n`) and to the **iteration** they are planned in (`Iteration x.y`, under the same PI as their Feature).
- A Task always has the same area and iteration as its parent story. If a story moves to another POD or iteration, move its tasks with it.
- If an Epic spans PIs, set the PI it starts in and move it to the current PI when the next PI begins, if it is still open.
- When fixing an existing backlog, correct Epics/Features that sit on a POD area or an iteration, and add a short comment saying why they were moved.

Every work item gets: Area Path and Iteration Path as in the table above, tags (`POD-n` on Stories and Tasks, `spec-anchored`, a **batch tag**, plus `claude` or `human` on Tasks for who executes), and a priority.

### Batch tag on every newly added item
- Every item Claude creates in one request (Epics, Features, Stories, Tasks, Bugs, Issues, in every project touched) gets the same tag `batch-YYYYMMDD-NN`, for example `batch-20261116-01`: the date the batch is created and a two-digit counter for that day (01, 02, ...). Check the existing tags of the day before choosing the counter.
- The reviewer filters the board by that tag to see exactly what was added in the batch.
- Existing items that are only moved or re-parented do not get the tag; list them separately in the report.
- Report the batch tag with the created item IDs.

### Bug or Issue: pick the right type when logging a finding

| Type | Use it when | Examples |
|---|---|---|
| **Bug** | Something is **broken or not working**: a function fails, gives a wrong result, blocks the user, or breaks a rule the spec requires. | A scan is refused when it should be accepted; a step is accepted at the wrong station; a screen crashes; a safety check is not enforced. |
| **Issue** | Something **works but has an issue**: usability, look and feel, missing convenience, non-compliance with a standard or rule, documentation, demo data, a gap against the design system. | Labels are cut off but the menu works; raw codes are shown instead of readable labels; a mandatory Apex element (Wall, Dashboard) is missing; docs don't match the screens. |

- When in doubt, ask: "can the user still finish the task?" Yes, so it's an **Issue**; no, or it gives a wrong result, so it's a **Bug**.
- Both get: a title naming the screen or component and the problem, where it was found (version or commit), steps to see it, actual vs expected, and a severity or priority. Bugs use **Repro Steps**; Issues use **Description**.
- Tag findings from a demo or review with the same tag (e.g. `found-in-demo`), so they can be filtered together.
- Log findings only. Don't start fixing until the user says so.
- **Screenshots go into the item.** When the user (or a test) provides a screenshot for a Bug or Issue, attach it to that work item **and** show it inline at the top of the Description (Bugs: also in Repro Steps):
  1. Upload the file (`POST _apis/wit/attachments?fileName=<name>.png`), then add it as an `AttachedFile` relation with a short comment.
  2. Embed it with the attachment URL **plus `?fileName=<name>.png`** (`![Screenshot](<url>?fileName=<name>.png)` in Markdown, or `<img src="<url>?fileName=<name>.png">` in HTML). Without `fileName` Azure DevOps does not render the image inline.
  3. Check the image URL loads (HTTP 200, image content type) before reporting the item as logged.
  4. One screenshot used for several items is attached to each of them.

## 5. Spec Anchored Development

- The ADO work item is the **single source of truth**. Code, tests and docs are derived from it.
- No code is written for behaviour that isn't in a work item. If the behaviour needs to change, **update the work item first**, then the code.
- Every commit and PR references its item (`AB#<id>`); PRs link to the User Story.
- Before Claude implements a story, it reads the story, its parent Feature/Epic and acceptance criteria, and flags gaps or contradictions instead of guessing.
- Specs are written precisely enough that a reviewer could verify the code against them without asking anyone.

## 6. Mandatory content for every work item

No work item is created with an empty or one-line description. Each must have **Description, Acceptance Criteria, and Definition of Done**. Acceptance Criteria go in the ADO Acceptance Criteria field where the type has one; otherwise in the description under a heading. DoD goes in the description under `## Definition of Done` unless the project has a custom field.

### Epic
- **Description**: problem / opportunity, business outcome, target users, in-scope / out-of-scope, dependencies, risks, success metrics (measurable).
- **Acceptance Criteria**: outcome-level criteria tied to the metrics.
- **DoD**: all child Features done, metrics instrumented, stakeholder sign-off.

### Feature
- **Description**: benefit hypothesis ("We believe <capability> will result in <outcome>; we'll know when <measure>"), functional scope, NFRs (performance, security, accessibility), integrations, dependencies on other PODs.
- **Acceptance Criteria**: capability-level, testable.
- **DoD**: all stories done, end-to-end tested, documented, demoed at System Demo, deployable.

### User Story
- **Description**: `As a <role>, I want <goal>, so that <benefit>.` followed by detailed spec: business rules, data/fields with validations, UI/UX behaviour, API contracts, error handling, edge cases, NFRs, assumptions.
- **Acceptance Criteria**: Gherkin, one scenario per behaviour, including negative paths:
  ```
  Scenario: <name>
    Given <context>
    When <action>
    Then <observable result>
  ```
- **DoD** (standard, extend per story):
  - Code implemented to spec, peer-reviewed by the POD's human developer
  - Unit tests written and passing; agreed coverage met
  - All acceptance criteria verified
  - No open critical/high defects
  - Commits/PR linked with `AB#<id>`; PR merged
  - Docs / API specs updated
  - Deployed to the test environment
  - Work item spec matches what was built

### Task
- **Description**: exactly what to do, files/components touched, technical approach, inputs/outputs.
- **Acceptance Criteria**: how to verify the task is complete.
- **DoD**: done when its criteria pass and changes are committed with `AB#<id>`.
- Typical task set per story: design/spec clarification, implementation (claude), unit tests (claude), code review (human), integration/QA (human), docs.

## 7. Ceremonies (per iteration)

| When | Ceremony |
|---|---|
| Thursday morning | Iteration planning: confirm capacity, pull stories to 48 SP committed + stretch |
| Daily (inside the 2 h planning block) | Stand-up + Claude work-briefing: human reviews yesterday's output, sets today's tasks |
| Wednesday | Iteration review/demo, retrospective, backlog refinement for next iteration |
| End of PI | System demo, Inspect & Adapt, PI planning for next PI |

PI planning output: PI objectives per POD (committed + uncommitted, with business value 1–10), Features assigned to PODs and iterations, dependency/risk list (ROAM: Resolved, Owned, Accepted, Mitigated).

## 8. How Claude carries out a request

1. **Gather**: project name, number of PODs, PI start date (or derive the next Thursday), holidays/leave, and the scope/requirements source.
2. **Plan before writing**: produce the iteration calendar and/or the work item tree (titles, SP, POD, iteration) and a capacity check per POD per iteration (committed SP ≤ 48, total ≤ 60).
3. **Confirm** the plan with the user before creating anything in ADO; creating items in bulk is hard to undo.
4. **Create** top-down (iterations → area paths → Epics → Features → Stories → Tasks) using the Azure DevOps connector if available; otherwise `az boards` / `az devops` CLI commands or an ADO-importable CSV.
5. **Verify**: every item has parent, area and iteration per section 4 (Epics/Features on the ART team and PI; Stories/Tasks on the POD and iteration), SP/hours, description, acceptance criteria and DoD; iteration dates are Thu–Wed; no POD is over capacity.
6. **Report** what was created with item IDs and any assumptions made.

## 8a. Keeping work item states current while executing

Whenever Claude, or an agent Claude starts, **executes** backlog work (writes code, docs or configuration for a story or task), it updates the ADO states of the work items **as the work happens**. It does not leave this for the end.

**Before writing a state, check which states the project's process allows** for each type, and any custom rules (for example a required DoD declaration). The usual Agile process states are:
- Epic, Feature, User Story: New → Active → Resolved → Closed (Removed for dropped work).
- Task: New → Active → Closed (Removed for dropped work).

| Moment | Task | User Story | Feature / Epic |
|---|---|---|---|
| Work starts | Active | Active | Active, if still New |
| Work committed and pushed, build/tests green | Closed | stays Active | — |
| Story's work merged to `main` (PR completed) | — | Closed: all its acceptance criteria verified, all tasks Closed or Removed | — |
| All children Closed or Removed | — | — | Closed |
| Work dropped or replaced | Removed (comment says why and what replaces it) | Removed | — |
| Waiting on an external dependency (another team or platform) | New, with a tag (for example `waits-on-<team>`) and a comment naming the dependency | New | — |

Rules:
- **Evidence on every state change:** add a short comment naming what proves it (commit SHA, PR number, pipeline or release run, test result). A state without evidence is not trusted.
- **Closing needs authority.** Claude closes items only when the user has authorised it (standing authorisation counts, for example "you can close the items").
  - Where the process requires a Definition-of-Done declaration, write it truthfully: "Closed by Claude under <user>'s authorisation of <date>; evidence: …".
  - Never word it as if the person typed it, and never invent a confirmation.
  - Without authorisation, stop at Resolved (stories) or leave tasks Active, and list what awaits the person.
- **Roll up:** after changing a child, re-check its parent Feature and Epic and move them as the table says.
- **Unmerged work:** work pushed to a branch but not yet merged to `main` keeps its story Active. Its tasks may be Closed.
- **Batch the updates** (one call per group of items where the tools allow), and keep the spec or backlog file, if the project keeps one, in step with ADO.
- **Hand-offs:** when several agents share a backlog, every agent's brief must include these rules. The last agent of a batch closes the stories once the batch PR has merged.

## 9. Validation checklist

- [ ] Iterations start Thursday, end Wednesday, 7 calendar days, 5 iterations per PI
- [ ] Names follow `PI_0n` / `Iteration n.m`; dates M/D/YYYY
- [ ] Every POD = 1 human + Claude, own area path
- [ ] Stories sized 1/2/3/5 SP; none ≥ 8
- [ ] Committed ≤ 48 SP and total ≤ 60 SP per POD per iteration (minus 12 SP per lost day)
- [ ] Every item has description, acceptance criteria (Gherkin for stories) and DoD
- [ ] Features fit within one PI; stories within one iteration
- [ ] Epics and Features: ART-level team area + PI iteration (`PI_xx`), not a POD area or `Iteration x.y`; Stories and Tasks: POD area + `Iteration x.y`
- [ ] Findings logged as **Bug** (broken / not working) or **Issue** (working but has an issue), per section 4
- [ ] Any screenshot provided for a finding is attached to the item and shown inline in its description (URL with `?fileName=`)
- [ ] While executing: states kept current (section 8a), each change has an evidence comment, and closing only under the user's authorisation
- [ ] Tags `POD-n`, `spec-anchored`; tasks tagged `claude` or `human`
- [ ] Every newly created item carries the request's batch tag `batch-YYYYMMDD-NN`