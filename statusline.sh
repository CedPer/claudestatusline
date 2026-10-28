#!/usr/bin/env bash
# Claude Code status line — compact, two-line, multicolor dark-blue style.
# Install globally at ~/.claude/statusline.sh and configure ~/.claude/settings.json.
# Claude Code sends status data as JSON on stdin.

set -o pipefail
input="$(cat)"

json_get() {
  python3 -c '
import json, sys
try:
    d=json.load(sys.stdin)
    for p in sys.argv[1].split("."):
        if isinstance(d, dict): d=d.get(p)
        elif isinstance(d, list) and p.isdigit() and int(p)<len(d): d=d[int(p)]
        else: d=None; break
    if d is None: print("")
    elif isinstance(d, (dict, list)): print(json.dumps(d, ensure_ascii=False))
    else: print(d)
except Exception: print("")
' "$1" <<<"$input"
}

# ANSI palette: deep navy background and category-specific accents.
BG=$'\033[48;5;17m'
RESET=$'\033[0m'
CYAN=$'\033[38;5;45m'
PURPLE=$'\033[38;5;141m'
GREEN=$'\033[38;5;114m'
YELLOW=$'\033[38;5;220m'
GRAY=$'\033[38;5;245m'
SEP="${GRAY}│${RESET}"

cwd="$(json_get workspace.current_dir)"
[ -n "$cwd" ] || cwd="$(json_get cwd)"
[ -n "$cwd" ] || cwd="$PWD"
project="${cwd##*/}"
[ -n "$project" ] || project="$cwd"

branch="$(json_get git.branch)"
[ -n "$branch" ] || branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
[ -n "$branch" ] || branch="—"

dirty="$(json_get git.is_dirty)"
if [ -z "$dirty" ]; then
  if git -C "$cwd" diff --quiet --ignore-submodules -- 2>/dev/null &&
     git -C "$cwd" diff --cached --quiet --ignore-submodules -- 2>/dev/null &&
     [ -z "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    dirty="false"
  else
    dirty="true"
  fi
fi
if [ "$dirty" = "true" ] || [ "$dirty" = "1" ]; then
  git_status="${YELLOW}✎${RESET}"
else
  git_status="${GREEN}✓${RESET}"
fi

model="$(json_get model.display_name)"
[ -z "$model" ] && model="$(json_get model)"
[ -z "$model" ] && model="Opus"
case "$model" in
  *opus*|*Opus*) model="Opus" ;;
  *sonnet*|*Sonnet*) model="Sonnet" ;;
  *haiku*|*Haiku*) model="Haiku" ;;
esac

effort="$(json_get effort.level)"
[ -z "$effort" ] && effort="$(json_get model.effort)"
case "$effort" in
  high) effort="élevé" ;;
  medium) effort="moyen" ;;
  low) effort="faible" ;;
  max) effort="max" ;;
  "") effort="élevé" ;;
esac

context_pct="$(json_get context_window.used_percentage)"
if [ -z "$context_pct" ]; then
  used="$(json_get context_window.used_tokens)"
  max="$(json_get context_window.context_window_size)"
  if [[ "$used" =~ ^[0-9]+$ && "$max" =~ ^[0-9]+$ && "$max" -gt 0 ]]; then
    context_pct=$((used * 100 / max))
  else
    context_pct="—"
  fi
fi
if [[ "$context_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  context_pct="${context_pct%.*}%"
elif [ "$context_pct" != "—" ] && [[ "$context_pct" != *% ]]; then
  context_pct="${context_pct}%"
fi

duration="$(json_get session.duration_minutes)"
if [ -z "$duration" ]; then
  started="$(json_get session.start_time)"
  [ -z "$started" ] && started="$(json_get session.started_at)"
  if [[ "$started" =~ ^[0-9]+$ ]]; then
    [ "$started" -gt 100000000000 ] && started=$((started / 1000))
    mins=$(( ($(date +%s) - started) / 60 ))
    [ "$mins" -lt 0 ] && mins=0
    if [ "$mins" -ge 60 ]; then duration="$((mins / 60)) h $((mins % 60)) min"; else duration="$mins min"; fi
  else
    duration="—"
  fi
fi
if [[ "$duration" =~ ^[0-9]+$ ]]; then
  mins="$duration"
  if [ "$mins" -ge 60 ]; then duration="$((mins / 60)) h $((mins % 60)) min"; else duration="$mins min"; fi
fi

# Quota/reset fields are version-dependent; omit these sections when unavailable.
five_pct="$(json_get rate_limits.five_hour.used_percentage)"
[ -z "$five_pct" ] && five_pct="$(json_get usage.five_hour.used_percentage)"
[ -z "$five_pct" ] && five_pct="$(json_get rate_limits.five_hour.utilization)"
week_pct="$(json_get rate_limits.seven_day.used_percentage)"
[ -z "$week_pct" ] && week_pct="$(json_get usage.seven_day.used_percentage)"
[ -z "$week_pct" ] && week_pct="$(json_get rate_limits.seven_day.utilization)"
five_reset="$(json_get rate_limits.five_hour.resets_at)"
[ -z "$five_reset" ] && five_reset="$(json_get usage.five_hour.resets_at)"
week_reset="$(json_get rate_limits.seven_day.resets_at)"
[ -z "$week_reset" ] && week_reset="$(json_get usage.seven_day.resets_at)"

format_pct() {
  local v="$1"
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]]; then printf '%s%%' "${v%.*}"; else printf '—'; fi
}
format_reset() {
  local v="$1" now delta
  [[ "$v" =~ ^[0-9]+$ ]] || { printf '—'; return; }
  [ "$v" -gt 100000000000 ] && v=$((v / 1000))
  now="$(date +%s)"
  delta=$((v - now))
  [ "$delta" -lt 0 ] && delta=0
  if [ "$delta" -ge 86400 ]; then printf '%s j' "$((delta / 86400))"
  elif [ "$delta" -ge 3600 ]; then printf '%s h %s min' "$((delta / 3600))" "$(((delta % 3600) / 60))"
  else printf '%s min' "$((delta / 60))"
  fi
}

bar=""
if [[ "$context_pct" =~ ^[0-9]+%$ ]]; then
  pct="${context_pct%%%}"
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  filled=$(( (pct + 5) / 10 ))
  for ((i=0; i<10; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+="${GREEN}━${RESET}"; else bar+="${GRAY}─${RESET}"; fi
  done
else
  bar="${GRAY}──────────${RESET}"
fi

# Line 1: project, branch/dirty state, model, effort.
line1="${BG}${CYAN} ${project}${RESET} ${SEP} ${PURPLE} ${branch}${RESET} ${git_status} ${SEP} ${YELLOW} ${model}${RESET} ${SEP} ${PURPLE}Effort : ${effort}${RESET}"
# Line 2: context, session duration, and available usage windows.
line2="${BG}${CYAN}󰧑 Context${RESET} ${bar} ${GREEN}${context_pct}${RESET} ${SEP} ${YELLOW}◷ ${duration}${RESET}"
if [ -n "$five_pct" ] || [ -n "$five_reset" ]; then
  line2+=" ${SEP} ${YELLOW}◴ 5 h :${RESET} ${GREEN}$(format_pct "$five_pct")${RESET}"
  [ -n "$five_reset" ] && line2+=" ${GRAY}(↻ $(format_reset "$five_reset"))${RESET}"
fi
if [ -n "$week_pct" ] || [ -n "$week_reset" ]; then
  line2+=" ${SEP} Week : ${GREEN}$(format_pct "$week_pct")${RESET}"
  [ -n "$week_reset" ] && line2+=" ${GRAY}(↻ $(format_reset "$week_reset"))${RESET}"
fi
printf '%s\n%s\n' "$line1" "$line2${RESET}"
