#!/usr/bin/env bash
# PreToolUse guard for Edit/Write: allow edits only under the path prefixes given as arguments
# (relative to the project root). Exit 2 blocks the call and returns stderr to the agent.
# Note: this guards the Edit/Write tools only; it cannot see file changes made through Bash.
exec python3 -I -c '
import json, os, sys
root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
try:
    path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
except Exception:
    sys.exit(0)
if not path:
    sys.exit(0)
target = os.path.realpath(path if os.path.isabs(path) else os.path.join(root, path))
for prefix in sys.argv[1:]:
    allowed = os.path.realpath(os.path.join(root, prefix))
    if target == allowed or target.startswith(allowed.rstrip("/") + "/"):
        sys.exit(0)
rel = os.path.relpath(target, root)
sys.stderr.write("Blocked: %s is outside this agent allowed paths (%s). Report the needed change to the Engineering Lead instead.\n" % (rel, ", ".join(sys.argv[1:])))
sys.exit(2)
' "$@"
