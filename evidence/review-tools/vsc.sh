#!/bin/bash
pkill -f /usr/share/code; sleep 3
mkdir -p ~/.config/Code/User; cat > ~/.config/Code/User/settings.json <<'J'
{ "workbench.startupEditor": "none", "security.workspace.trust.enabled": false, "telemetry.telemetryLevel": "off",
  "update.mode": "none", "chat.disableAIFeatures": true, "workbench.editor.empty.hint": "hidden",
  "editor.autoClosingBrackets": "never", "editor.autoClosingQuotes": "never", "editor.autoSurround": "never",
  "editor.acceptSuggestionOnEnter": "off", "editor.quickSuggestions": {"other": false, "comments": false, "strings": false},
  "editor.wordBasedSuggestions": "off", "editor.suggestOnTriggerCharacters": false, "editor.unicodeHighlight.ambiguousCharacters": false,
  "workbench.secondarySideBar.defaultVisibility": "hidden", "window.titleBarStyle": "custom" }
J
free -m > /tmp/mem.txt; wget -q --post-file=/tmp/mem.txt http://10.0.2.2:8001/mem.txt -O /dev/null
: > "/tmp/$1.txt"
code --skip-welcome --skip-release-notes --disable-extensions --password-store=basic "/tmp/$1.txt" &
