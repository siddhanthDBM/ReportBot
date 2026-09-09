# DBM Weekly Report Bot

Prompts you Monday-Friday at 5:00 PM for what you did that day, and builds a
polished weekly PDF report automatically every Friday.

## Setup (one time)

1. Clone this repo.
2. Install dependencies:
   ```
   npm install
   ```
3. Run `setup.ps1` (right-click -> Run with PowerShell, or `powershell -ExecutionPolicy Bypass -File setup.ps1`).
   It will ask for your name, job title, and an OpenRouter API key (free, from
   https://openrouter.ai/keys) used to turn your rough daily notes into proper
   report language. Leaving the key blank just uses your notes as typed.
4. That's it - it also registers the Mon-Fri 5:00 PM prompt on this PC.

## What gets created locally (not in git)

- `config.json` - your name/title
- `.env` - your OpenRouter API key
- `data/` - your raw daily notes, one file per week
- `Weekly Reports/` - the finished PDFs, one folder per week

## Notes

- The 5:00 PM prompt only fires while you're logged into Windows (it's a
  popup, so it can't run headless). If your PC is off or asleep at 5:00 PM,
  it runs as soon as you're next logged in.
- To re-run setup (e.g. change your name or API key), just run `setup.ps1` again.
