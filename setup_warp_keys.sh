#!/usr/bin/env bash
set -e

# The default service name for Warp Stable.
# If you use Warp Preview, change this to "dev.warp.Warp-Preview"
SERVICE="dev.warp.Warp-Stable"

echo "=== Warp (Oz) BYOK Setup ==="

# 1. Try to load from a local .env file if it exists
if [ -f ".env" ]; then
    echo "📂 Found .env file, loading variables..."
    # Export all variables from the .env file
    set -a
    source .env
    set +a
fi

# 2. Prompt for missing keys (silently read passwords)
echo "🔑 Please provide your API keys. Leave blank to skip."

if [ -z "$OPENAI_API_KEY" ]; then
    read -s -p "OpenAI API Key: " OPENAI_API_KEY
    echo ""
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    read -s -p "Anthropic API Key: " ANTHROPIC_API_KEY
    echo ""
fi

if [ -z "$GEMINI_API_KEY" ]; then
    read -s -p "Gemini/Google API Key: " GEMINI_API_KEY
    echo ""
fi

if [ -z "$OPENROUTER_API_KEY" ]; then
    read -s -p "OpenRouter API Key: " OPENROUTER_API_KEY
    echo ""
fi

# 3. Format values as JSON strings or `null`
format_json_val() {
    if [ -z "$1" ]; then
        echo "null"
    else
        echo "\"$1\""
    fi
}

OAI_JSON=$(format_json_val "$OPENAI_API_KEY")
ANT_JSON=$(format_json_val "$ANTHROPIC_API_KEY")
GOO_JSON=$(format_json_val "$GEMINI_API_KEY")
OR_JSON=$(format_json_val "$OPENROUTER_API_KEY")

JSON_PAYLOAD="{\"openai\":${OAI_JSON},\"anthropic\":${ANT_JSON},\"google\":${GOO_JSON},\"open_router\":${OR_JSON}}"

# 4. Store in the OS's secure storage based on platform
OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then
    echo "🍎 macOS detected. Saving to Keychain..."
    security add-generic-password -a "AiApiKeys" -s "$SERVICE" -U -w "$JSON_PAYLOAD"
    echo "✅ Successfully saved keys for Warp!"
    
elif [ "$OS" = "Linux" ]; then
    echo "🐧 Linux detected."
    # Ensure secret-tool is installed
    if ! command -v secret-tool &> /dev/null; then
        echo "❌ Error: 'secret-tool' is required but not installed."
        echo "Please install it using: sudo apt install libsecret-tools"
        exit 1
    fi
    
    echo "Saving to Secret Service..."
    # Pipe the payload into secret-tool
    echo -n "$JSON_PAYLOAD" | secret-tool store --label="$SERVICE: AiApiKeys" service "$SERVICE" key AiApiKeys
    echo "✅ Successfully saved keys for Warp!"
    
else
    echo "❌ Unsupported operating system: $OS"
    exit 1
fi
