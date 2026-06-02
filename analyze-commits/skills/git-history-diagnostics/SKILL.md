---
name: git-history-diagnostics
description: The exact git commands, interpretation rules, data caveats, and output template for diagnosing a repository from its commit history (churn hotspots, contributors/bus factor, bug clusters, velocity, firefighting). Reference skill for analyze-commits and its five commit-* diagnostic subagents. Based on Ally Piechowski's "The Git Commands I Run Before Reading Any Code".
disable-model-invocation: true
---

# Git History Diagnostics

The exact commands and interpretation rules behind `/analyze-commits`, from Ally Piechowski's [The Git Commands I Run Before Reading Any Code](https://piechowski.io/post/git-commands-before-reading-code/). Five diagnostics, plus one cross-reference. Each is a single `git` invocation; the value is in how you read the output.

All commands are **read-only**. Run them from the repository root unless noted. If the repo is a shallow clone, history is truncated - flag it as a caveat.

## 1. What changes the most (churn hotspots)

```bash
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

The 20 most-changed files in the last year. **Run this from the source directory** (e.g. `app/` or `src/`), not the repo root - otherwise lockfiles, changelogs, and generated code dominate the list. Since this is a black-box repo, detect the likely source dir first (the largest top-level dir of source files; common names: `src`, `app`, `lib`, `pkg`, `internal`). If unclear, run from root but filter out obvious noise (lockfiles, `dist/`, `build/`, `vendor/`, `node_modules/`, generated files) and say so.

**Read it:** the file at the top is usually the one people warn you about ("everyone's afraid to touch that file"). High churn alone isn't bad - it can just be active development. High churn on a file **nobody wants to own** is the clearest signal of codebase drag. Churn-based metrics predict defects more reliably than complexity metrics alone. Take the top ~5 and cross-reference against the bug clusters (section 6).

## 2. Who built this (contributors & bus factor)

```bash
git shortlog -sn --no-merges
git shortlog -sn --no-merges --since="6 months ago"
```

Every contributor ranked by commit count, all-time and in the last 6 months.

**Read it:** if one person accounts for **60% or more** of commits, that's your bus factor - if they left, it's a crisis. Compare the two lists: if the **top all-time contributor does not appear in the last-6-months list**, the people who built the system aren't the ones maintaining it - flag it immediately. Look at the tail too (e.g. "30 contributors but only 3 active in the last year").

**Caveat:** squash-merge workflows compress authorship - the output then reflects who **merged**, not who **wrote**. Check the merge strategy before drawing conclusions and note it.

## 3. Where do bugs cluster (bug hotspots)

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

Same shape as churn, filtered to commits whose messages mention fixing bugs.

**Read it:** compare against the churn hotspots. Files on **both** lists are the highest-risk code - they keep breaking and keep getting patched but never properly fixed.

**Caveat:** depends entirely on commit-message discipline. "update stuff" for every commit yields nothing. Even a rough bug-density map beats no map - but state the limitation.

## 4. Is this project accelerating or dying (velocity)

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

Commit count per month, for the whole history.

**Read it:** look at the shape. Steady rhythm = healthy. A count that **halves in a single month** usually means someone left. A declining curve over 6-12 months = the team is losing momentum. Periodic spikes then quiet = batched releases rather than continuous shipping. This is **team** data, not code data.

## 5. How often is the team firefighting (crisis patterns)

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

Revert and hotfix frequency in the last year.

**Read it:** a handful over a year is normal. Reverts **every couple of weeks** mean the team doesn't trust its deploy process (unreliable tests, missing staging, painful rollbacks). **Zero** results is also a signal - either genuinely stable, or nobody writes descriptive commit messages.

## 6. Cross-reference (highest-risk files)

Not a command - the orchestrator computes it: intersect the **top ~5 churn files** (section 1) with the **bug-cluster files** (section 3). Files on both are the single biggest risk and what to read first.

---

## Subagent output fragments

Each diagnostic is run by its own subagent in parallel (`commit-churn-analyst`, `commit-contributors-analyst`, `commit-bug-cluster-analyst`, `commit-velocity-analyst`, `commit-firefighting-analyst`). Each returns **only its own fragment** (no preamble), and appends any data caveats it detected under `### Data caveats`. The orchestrator concatenates them and computes diagnostic 6.

`commit-churn-analyst` (diagnostic 1):

```
### 1. Churn hotspots (last 1y)
Source dir used: <path or "repo root (filtered)">
<count> <file>
... (top 20)

### Data caveats
- <e.g. shallow clone: history truncated at <date>; lockfiles/generated files filtered out>
```

`commit-contributors-analyst` (diagnostic 2):

```
### 2. Contributors
All-time: <author> <count>, ... | top share: <pct>%
Last 6 months: <author> <count>, ...

### Data caveats
- <e.g. squash-merge detected: authorship reflects mergers, not authors>
```

`commit-bug-cluster-analyst` (diagnostic 3):

```
### 3. Bug clusters
<count> <file>
... (top 20; or "none found")

### Data caveats
- <e.g. ~40% of commit subjects are non-descriptive: bug clustering is weak>
```

`commit-velocity-analyst` (diagnostic 4):

```
### 4. Velocity (commits per month)
<YYYY-MM> <count>
... (full history; or summarized shape + notable months if very long)

### Data caveats
- <e.g. shallow clone: history truncated at <date>>
```

`commit-firefighting-analyst` (diagnostic 5):

```
### 5. Firefighting (last 1y)
<count> matching commits; sample subjects: ...
Reading: <normal / deploy-trust problem / zero-and-why>
```

---

## Output template

Fill `assets/template.md`. Keep it concise and scannable - the verdict and the cross-reference are the point, not the raw lists.
