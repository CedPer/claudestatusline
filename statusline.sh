#!/usr/bin/env bash
# Claude Code statusline — two lines, emoji labels and compact quota indicators.
# Install at ~/.claude/statusline.sh and configure ~/.claude/settings.json.

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

# ANSI colors
RESET=$'\033[0m'
CYAN=$'\033[38;5;45m'
PURPLE=$'\033[38;5;141m'
GREEN=$'\033[38;5;114m'
YELLOW=$'\033[38;5;220m'
GRAY=$'\033[38;5;245m'
SEP="${GRAY}║${RESET}"

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
  git_status="${YELLOW}✏️${RESET}"
else
  git_status="${GREEN}✓${RESET}"
fi

model="$(json_get model.display_name)"
[ -z "$model" ] && model="$(json_get model.id)"
[ -z "$model" ] && model="$(json_get model)"
[ -z "$model" ] && model="Sonnet"
lower_model="$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')"
if [[ "$lower_model" == *sonnet* ]]; then
  if [[ "$lower_model" == *3.5* ]]; then model="Sonnet 3.5"
  elif [[ "$lower_model" == *3-5* ]]; then model="Sonnet 3.5"
  elif [[ "$model" =~ [Ss]onnet[[:space:]]+([0-9]+([.][0-9]+)?) ]]; then model="Sonnet ${BASH_REMATCH[1]}"
  else model="Sonnet"
  fi
elif [[ "$lower_model" == *opus* ]]; then
  if [[ "$model" =~ [Oo]pus[[:space:]]+([0-9]+([.][0-9]+)?) ]]; then model="Opus ${BASH_REMATCH[1]}"; else model="Opus"; fi
elif [[ "$lower_model" == *haiku* ]]; then
  if [[ "$model" =~ [Hh]aiku[[:space:]]+([0-9]+([.][0-9]+)?) ]]; then model="Haiku ${BASH_REMATCH[1]}"; else model="Haiku"; fi
fi

effort="$(json_get effort.level)"
[ -z "$effort" ] && effort="$(json_get model.effort)"
case "$effort" in
  high|High) effort="Élevé" ;;
  medium|Medium) effort="Moyen" ;;
  low|Low) effort="Faible" ;;
  max|Max) effort="Max" ;;
  *) effort="Moyen" ;;
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
  context_pct="${context_pct%.*}"
elif [[ "$context_pct" != "—" ]]; then
  context_pct="${context_pct%%%}"
fi

# Session duration as HH:MM:SS. Prefer an explicit seconds/minutes value,
# otherwise calculate elapsed time from the session start timestamp.
duration=""
duration_seconds="$(json_get session.duration_seconds)"
if [[ "$duration_seconds" =~ ^[0-9]+$ ]]; then
  duration="$duration_seconds"
else
  duration_minutes="$(json_get session.duration_minutes)"
  if [[ "$duration_minutes" =~ ^[0-9]+$ ]]; then
    duration=$((duration_minutes * 60))
  else
    started="$(json_get session.start_time)"
    [ -z "$started" ] && started="$(json_get session.started_at)"
    if [[ "$started" =~ ^[0-9]+$ ]]; then
      [ "$started" -gt 100000000000 ] && started=$((started / 1000))
      duration=$(($(date +%s) - started))
      [ "$duration" -lt 0 ] && duration=0
    else
      duration=""
    fi
  fi
fi
if [[ "$duration" =~ ^[0-9]+$ ]]; then
  printf -v duration '%02d:%02d:%02d' "$((duration / 3600))" "$(((duration % 3600) / 60))" "$((duration % 60))"
else
  duration="--:--:--"
fi

# Usage field names vary by Claude Code version; show windows only when available.
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
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]]; then printf '%s' "${v%.*}"; else printf '—'; fi
}
format_reset() {
  local v="$1" now delta
  [[ "$v" =~ ^[0-9]+$ ]] || { printf '—'; return; }
  [ "$v" -gt 100000000000 ] && v=$((v / 1000))
  now="$(date +%s)"
  delta=$((v - now))
  [ "$delta" -lt 0 ] && delta=0
  if [ "$delta" -ge 86400 ]; then printf '%dj' "$((delta / 86400))"
  elif [ "$delta" -ge 3600 ]; then printf '%dh%02dm' "$((delta / 3600))" "$(((delta % 3600) / 60))"
  else printf '%dm' "$((delta / 60))"
  fi
}

bar=""
if [[ "$context_pct" =~ ^[0-9]+$ ]]; then
  pct="$context_pct"
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  filled=$(( (pct + 5) / 10 ))
  for ((i=0; i<10; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+="${GREEN}█${RESET}"; else bar+="${GRAY}░${RESET}"; fi
  done
  context_label="${GREEN}${pct}% ctx${RESET}"
else
  bar="${GRAY}░░░░░░░░░░${RESET}"
  context_label="${GRAY}— ctx${RESET}"
fi

line1="${CYAN}📁 ${project}${RESET}${SEP}${PURPLE}🌿 ${branch} ${RESET}${git_status}${SEP}${YELLOW}🧠 ${model}${RESET}${SEP}${PURPLE}⚡ Effort: ${effort}${RESET}"
line2="${CYAN}📊 ${bar} ${context_label}${RESET}${SEP}${YELLOW}⏱️ ${duration}${RESET}"
if [ -n "$five_pct" ] || [ -n "$five_reset" ]; then
  line2+="${SEP}${YELLOW}🪟 5h : ${GREEN}$(format_pct "$five_pct")%${RESET}"
  [ -n "$five_reset" ] && line2+=" ${GRAY}($(format_reset "$five_reset"))${RESET}"
fi
if [ -n "$week_pct" ] || [ -n "$week_reset" ]; then
  line2+="${SEP}${YELLOW}📅 7j : ${GREEN}$(format_pct "$week_pct")%${RESET}"
  [ -n "$week_reset" ] && line2+=" ${GRAY}($(format_reset "$week_reset"))${RESET}"
fi
printf '%s\n%s\n' "$line1" "$line2${RESET}"
