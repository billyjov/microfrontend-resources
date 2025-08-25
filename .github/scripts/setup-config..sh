#!/bin/bash
# Setup configuration script

set -e

echo "🔧 Setting up lychee configuration..."

# Create .github directory if it doesn't exist
mkdir -p .github

# Check if lychee.toml already exists in the repo
if [ ! -f ".github/lychee.toml" ]; then
    echo "📝 Creating lychee configuration file..."
    
    cat > .github/lychee.toml << 'EOF'
# Lychee link checker configuration
max_concurrency = 8
insecure = false
user_agent = "Mozilla/5.0 (compatible; Lychee)"
timeout = 20
retry_wait_time = 2
max_redirects = 5
scheme = [ "https", "http" ]
accept = [ 200, 206, 301, 302, 307, 308, 403, 999 ]

exclude = [
    "^mailto:",
    "^http://localhost",
    "^https://localhost", 
    "^http://127.0.0.1",
    "^https://127.0.0.1",
    "^file://",
    "linkedin.com/in/",
    "facebook.com",
    "twitter.com", 
    "instagram.com"
]

include_file = [ "md", "html", "htm" ]
exclude_private = true
exclude_loopback = true
exclude_link_local = true
exclude_mail = false
EOF
    
    echo "✅ Configuration file created at .github/lychee.toml"
else
    echo "✅ Configuration file already exists at .github/lychee.toml"
fi

echo "🎯 Configuration setup complete!"