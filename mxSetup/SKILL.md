---
name: mxSetup
description: "Developer-Onboarding: MCP-Verbindung, Skills, Proxy, Config. Ausfuehren auf neuem PC oder nach Updates."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
argument-hint: "<api-key> | --update"
---

# /mxSetup — Developer Onboarding (~30 Sekunden)

> ⚡ **!Python !jq !sed fuer Datei-Operationen.** Nur Write/Read/Edit-Tools + Bash fuer `claude mcp` und `curl`.
> ⚡ **Bash: Einzeilig.** !Mehrzeiler !Heredocs !Newlines in Befehlen.

## Voraussetzungen
- **Node.js** — Erforderlich fuer 5 von 8 Hooks (Orchestrate, Recall-Gate, Recall-Outcome). Ohne Node.js funktioniert die Session nur eingeschraenkt (kein State-Tracking, kein Recall-Gate). Installation: https://nodejs.org/

## Erstinstallation (mit API-Key)

### Phase 1: MCP-Verbindung

1. Pruefe `claude mcp list` → bereits `mxai-knowledge`? → "Verwende `--update`"
2. ?user: "Server-URL? (z.B. http://localhost:8080/mcp)"
   - URL muss auf `/mcp` enden
3. MCP registrieren:
```bash
claude mcp add -s user --transport http mxai-knowledge "<SERVER-URL>" --header "Authorization: Bearer <API-KEY>"
```
4. `mx_ping()` → Erfolg? admin_port merken. Fehler? → Abbruch.

### Phase 2: Skills von GitHub installieren (~5 Sekunden)

⚡ **EXAKTE URL — NICHT erfinden!**
`https://github.com/MicrotronX/mxLore-skills/archive/main.zip`
!mxai-org !mxai-tech !andere Repos. NUR `MicrotronX/mxLore-skills`.

**Alle Plattformen (curl + unzip, funktioniert in Bash/Git-Bash/Linux/macOS):**
```bash
curl -L -o /tmp/mxLore-skills.zip https://github.com/MicrotronX/mxLore-skills/archive/main.zip && unzip -o /tmp/mxLore-skills.zip -d /tmp/mxLore-skills
```

Dann kopieren:
```bash
cp -r /tmp/mxLore-skills/mxLore-skills-main/mx* ~/.claude/skills/
mkdir -p ~/.claude/hooks && cp -r /tmp/mxLore-skills/mxLore-skills-main/hooks/* ~/.claude/hooks/
mkdir -p ~/.claude/reference && cp -r /tmp/mxLore-skills/mxLore-skills-main/reference/* ~/.claude/reference/
cp /tmp/mxLore-skills/mxLore-skills-main/CLAUDE.md /tmp/mxLore-skills-CLAUDE.md 2>/dev/null
rm -rf /tmp/mxLore-skills /tmp/mxLore-skills.zip
```

⚡ !PowerShell !Invoke-WebRequest — immer curl+unzip in Bash verwenden (funktioniert ueberall).

### Phase 3: Proxy installieren

1. **Admin-URL bauen:** Aus mx_ping `admin_port` + `proxy_download_path`.
   ⚡ Host = gleicher Host wie MCP-Verbindung (aus Phase 1 Server-URL). Server kennt seinen externen Zugriffsweg nicht (IIS Reverse Proxy).
   → `http://<MCP-HOST>:<admin_port><proxy_download_path>`
   Falls kein admin_port: Server-URL Port+1 (8080→8081). Falls admin_port nicht erreichbar: Warnung, Proxy-Update ueberspringen.
2. Download:
```bash
curl -f -o ~/.claude/mxMCPProxy.exe "http://<MCP-HOST>:<admin_port>/api/download/proxy"
```
3. Dateigroesse pruefen (>100KB). Falls kleiner: Warnung, skip Proxy.
4. Proxy-INI erzeugen (Write-Tool → `~/.claude/mxMCPProxy.ini`):
```ini
[Server]
Url=<SERVER-URL>
ApiKey=<API-KEY>
ConnectionTimeout=10000
ReadTimeout=120000

[Agent]
Polling=1
PollInterval=15
```

### Phase 4: MCP auf Proxy umstellen

```bash
claude mcp remove mxai-knowledge -s user
claude mcp add -s user mxai-knowledge -- "<HOME>/.claude/mxMCPProxy.exe"
```
`mx_ping()` → Erfolg? Weiter. Fehler? HTTP-Fallback anbieten.

### Phase 5: Config

⚡ `~/.claude/settings.json` mit Read-Tool lesen, dann per Edit-Tool ergaenzen. !Bestehende Eintraege loeschen/ueberschreiben. Nur fehlende hinzufuegen.

**5a. Permissions** — Folgende in `permissions.allow` ergaenzen (falls nicht vorhanden):
```json
"mcp__mxai-knowledge__*",
"Skill(mxSave)",
"Skill(mxDecision)",
"Skill(mxPlan)",
"Skill(mxSpec)",
"Skill(mxDesignChecker)",
"Skill(mxBugChecker)"
```

**5b. Hooks** — Jeden Hook-Block pruefen. Falls Eintrag fehlt, hinzufuegen. Falls vorhanden, nicht duplizieren.

⚡ **Node.js-Check VOR Hook-Installation:**
```bash
node --version 2>/dev/null
```
Falls `node` nicht gefunden: Warnung anzeigen:
> "Node.js nicht gefunden. 5 von 8 Hooks (Orchestrate, Recall-Gate, Recall-Outcome) werden ohne Node.js nicht funktionieren. Session laeuft eingeschraenkt (kein State-Tracking, kein Recall-Gate). Installation: https://nodejs.org/"
→ Nur die Bash-Hooks und PreCompact-Prompt installieren, JS-Hooks ueberspringen.

| Event | Hooks (in Reihenfolge) | Braucht |
|-------|----------------------|---------|
| `SessionStart` | `node ~/.claude/hooks/orchestrate-reconcile.js` (2000ms) + `node ~/.claude/hooks/orchestrate-status.js` (2000ms) | Node.js |
| `UserPromptSubmit` | `bash ~/.claude/hooks/agent_inbox_check.sh` (2000ms) + `node ~/.claude/hooks/orchestrate-status.js` (2000ms) | Bash + Node.js |
| `Stop` | `node ~/.claude/hooks/orchestrate-step-check.js` (3000ms) | Node.js |
| `PreToolUse` (matcher: `Edit\|Write`) | `node ~/.claude/hooks/recall-gate.js` (2000ms) | Node.js |
| `PostToolUse` (matcher: `Edit\|Write`) | `node ~/.claude/hooks/recall-outcome-hook.js` (2000ms) | Node.js |
| `PreCompact` | prompt: (Auto-ADR + /mxSave, siehe unten) | — |

**PreCompact prompt** (exakt uebernehmen):
```
CONTEXT-COMPACTING STEHT BEVOR! Fuehre diese 2 Schritte SOFORT aus:

1. AUTO-ADR EXTRACT (VOR mxSave!): Analysiere den Chat-Verlauf nach signifikanten Entscheidungen (Signal-Woerterbuch: ~/.claude/reference/auto-adr.md). Pro erkannter Entscheidung (Stufe 1+2): mx_create_doc(project, doc_type='note', title='ADR-Kandidat: <Zusammenfassung>', content=<Template aus auto-adr.md>, tags='adr-candidate'). Vorher Deduplizierung via mx_search(tag='adr-candidate') + mx_search(doc_type='decision'). Keine User-Rueckfrage. Output: 'Auto-ADR: N Kandidaten extrahiert'.

2. /mxSave ausfuehren um den aktuellen Projektzustand zu persistieren.

Keine Rueckfragen, keine Erklaerungen — einfach ausfuehren und dann das Compacting zulassen.
```

**5c. CLAUDE.md** — Verwende `/tmp/mxLore-skills-CLAUDE.md` (in Phase 2 gesichert):
   - Falls `~/.claude/CLAUDE.md` nicht existiert: kopieren
   - Falls existiert und mx-rules Marker hat: Block zwischen `<!-- mx-rules-start -->` und `<!-- mx-rules-end -->` durch neuen ersetzen
   - Falls existiert ohne Marker: mx-rules Block am Ende anhaengen
   - Danach: `rm /tmp/mxLore-skills-CLAUDE.md`

**5d. Agent Inbox:** `mkdir -p ~/.claude/agent_inbox`

### Phase 6: Fertig

```
=== mxLore Setup abgeschlossen ===

| Komponente | Status |
|------------|--------|
| MCP | Verbunden (<URL>) |
| Skills | X installiert |
| Hooks | Y installiert |
| Proxy | OK / FEHLT |
| CLAUDE.md | OK |

Naechste Schritte:
1. Claude Code neu starten
2. In Projekt-Verzeichnis wechseln
3. /mxInitProject ausfuehren
```

## Update-Modus (--update)

1. Phase 2 ausfuehren (Skills von GitHub)
2. Phase 5 ausfuehren (Config aktualisieren)
3. Proxy-Update: Download neue EXE → Rename alte → Move neue → Delete alte
4. Zusammenfassung zeigen

## Regeln

- **!mx_onboard_developer** — Skills kommen von GitHub, nicht vom Server
- **!Python !jq** — Write/Edit-Tools fuer Dateien, Bash nur fuer curl/claude-mcp
- **API-Key nie anzeigen** — nur letzte 4 Zeichen (`mxk_****15c`)
- **Skills immer ueberschreiben** — GitHub = Source of Truth
- **Encoding:** UTF-8 ohne BOM
- **MCP-Scope:** IMMER `-s user`
