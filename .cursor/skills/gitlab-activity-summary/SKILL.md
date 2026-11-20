---
name: gitlab-activity-summary
description: Summarizes the user's GitLab activity (merged and opened merge requests, pushes, tags, reviews) for a given day or date range using the GitLab MCP server. Use when the user asks to summarize their GitLab work, what they did on GitLab, their contributions for a day or week, or wants a standup or status update based on GitLab activity.
---

# GitLab Activity Summary

## Defaults

- GitLab username: `knutakir` (do not ask for it; use another username only if the user names one).
- Timezone: the user's local timezone from the session (currently UTC+1). GitLab returns UTC timestamps.
- Date: if none is given, use yesterday's date (or the previous working day if today is Monday).

## Workflow

1. **Fetch events** with `plugin-gitlab-GitLab` → `list_user_events`:
   - `id`: the username
   - `after`: two days before the start date (`after` is exclusive and matches UTC dates, so this covers local midnight in any positive offset)
   - `before`: two days after the end date (exclusive; covers negative offsets)
   - `sort: "asc"`, `per_page: 100`
   - If 100 events come back, fetch the next `page` until fewer than 100 are returned.

2. **Filter to local dates.** Convert each `created_at` to local time and drop events outside the requested local range.

3. **Resolve project paths.** Group the events by `project_id`. For each project, call `get_project` once to get `path_with_namespace` and `web_url`. Do these calls in parallel.

4. **Classify events:**

   | `action_name` / data                                                                         | Meaning                                                                            |
   | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
   | `opened` + `MergeRequest`                                                                    | MR opened                                                                          |
   | `accepted` + `MergeRequest`                                                                  | MR merged                                                                          |
   | `approved` + `MergeRequest`                                                                  | Review approval (if the author is the user, this is a review of someone else's MR) |
   | `pushed to` on a feature branch                                                              | Work-in-progress commits; use `push_data.commit_title` and `commit_count`          |
   | `pushed new` with `ref_type: tag`                                                            | Build/release tag (`ref`)                                                          |
   | `deleted` branch, `pushed new` branch with 0 commits, push to `main` right before `accepted` | Noise from the merge flow; leave these out                                         |
   | `commented on` / `note`                                                                      | Discussion; mention only if it's substantive                                       |

   Link each MR to its tag(s): tags whose `commit_to` matches the merge commit that was pushed to `main`.

5. **Write the summary** using the template below.

## Output template

Lead with a one-sentence outcome (counts of MRs merged, tags cut, reviews), then the local time span of the activity.

```markdown
**<Project name>** (`<path_with_namespace>`)

- Merged [<MR title> (!<iid>)](<web_url>/-/merge_requests/<iid>) and tagged it `<tag>`.
- Opened [<MR title> (!<iid>)](...) — still open.
- Pushed N commits to the unmerged `<branch>` branch: "<commit title>", ...

**Reviews**

- Approved [<MR title> (<project short name> !<iid>)](...).
```

Then close with one or two sentences on the day's themes.

Rules:

- Always render MRs as markdown links built from the project's `web_url`.
- Use local times, not UTC.
- Group several tags from one merge on a single line (e.g. "tagged builds for `service-a`, `service-b` (all `_b.123`)").
- Point out anything odd that's worth knowing, such as duplicate approvals or typos in titles that landed on `main`, in a short clause.
- For multi-day ranges, group by project first, then list days within each project only if it helps.
