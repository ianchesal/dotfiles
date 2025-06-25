# AI Shit

## Anthropic
CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true

## Google Gemini
function gemini() {
  GOOGLE_CLOUD_PROJECT=${GEMINI_CLOUD_PROJECT} ~/.npm-global/bin/gemini "$@"
}
