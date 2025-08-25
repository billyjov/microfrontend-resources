#!/bin/bash
# Link checking script
# Place this file at: .github/scripts/check-links.sh

set -e

echo "🔍 Starting README link check..."

# Find all README files (case insensitive)
README_FILES=$(find . -maxdepth 3 -iname "readme.md" -type f | head -10)

if [ -z "$README_FILES" ]; then
    echo "ℹ️ No README files found"
    echo "dead_links_found=false" >> $GITHUB_OUTPUT
    echo "total_files=0" >> $GITHUB_OUTPUT
    echo "files_with_issues=0" >> $GITHUB_OUTPUT  
    echo "broken_links=0" >> $GITHUB_OUTPUT
    exit 0
fi

# Create output directory
mkdir -p link-check-results

# Initialize variables
DEAD_LINKS_FOUND=false
RESULTS_FILE="link-check-results/results.md"
SUMMARY_FILE="link-check-results/summary.json"

# Initialize results file
echo "# 🔗 Link Check Results" > $RESULTS_FILE
echo "*Generated on: $(date -u '+%Y-%m-%d %H:%M:%S UTC')*" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Initialize summary
echo '{"total_files": 0, "files_with_issues": 0, "total_links_checked": 0, "broken_links": 0}' > $SUMMARY_FILE

TOTAL_FILES=0
FILES_WITH_ISSUES=0
TOTAL_BROKEN_LINKS=0

# Check each README file
for file in $README_FILES; do
    echo "📄 Checking links in: $file"
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    echo "## 📄 $file" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Run lychee and capture output
    if lychee --config .github/lychee.toml --format markdown "$file" > temp_output.txt 2>&1; then
        # Check if there were any failures in the output
        if grep -q "✗" temp_output.txt || grep -q "ERROR" temp_output.txt; then
            echo "❌ **Issues found in $file:**" >> $RESULTS_FILE
            echo "" >> $RESULTS_FILE
            echo '```' >> $RESULTS_FILE
            cat temp_output.txt >> $RESULTS_FILE
            echo '```' >> $RESULTS_FILE
            
            # Count broken links in this file
            BROKEN_IN_FILE=$(grep -c "✗" temp_output.txt || echo "0")
            TOTAL_BROKEN_LINKS=$((TOTAL_BROKEN_LINKS + BROKEN_IN_FILE))
            FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
            DEAD_LINKS_FOUND=true
        else
            echo "✅ **All links working in $file**" >> $RESULTS_FILE
            echo "" >> $RESULTS_FILE
            if [ -s temp_output.txt ]; then
                echo '<details><summary>Details</summary>' >> $RESULTS_FILE
                echo "" >> $RESULTS_FILE
                echo '```' >> $RESULTS_FILE
                cat temp_output.txt >> $RESULTS_FILE
                echo '```' >> $RESULTS_FILE  
                echo '</details>' >> $RESULTS_FILE
            fi
        fi
    else
        echo "❌ **Error checking $file:**" >> $RESULTS_FILE
        echo "" >> $RESULTS_FILE
        echo '```' >> $RESULTS_FILE
        cat temp_output.txt >> $RESULTS_FILE
        echo '```' >> $RESULTS_FILE
        FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
        DEAD_LINKS_FOUND=true
    fi
    
    echo "" >> $RESULTS_FILE
    echo "---" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    
    # Clean up temp file
    rm -f temp_output.txt
done

# Add summary to results
echo "## 📊 Summary" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE
echo "- **Total README files checked:** $TOTAL_FILES" >> $RESULTS_FILE
echo "- **Files with issues:** $FILES_WITH_ISSUES" >> $RESULTS_FILE
echo "- **Total broken links found:** $TOTAL_BROKEN_LINKS" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

# Update summary JSON
if command -v jq >/dev/null 2>&1; then
    jq --arg tf "$TOTAL_FILES" --arg fwi "$FILES_WITH_ISSUES" --arg tbl "$TOTAL_BROKEN_LINKS" \
       '.total_files = ($tf | tonumber) | .files_with_issues = ($fwi | tonumber) | .broken_links = ($tbl | tonumber)' \
       $SUMMARY_FILE > temp_summary.json && mv temp_summary.json $SUMMARY_FILE
fi

# Set output for GitHub Actions
echo "dead_links_found=$DEAD_LINKS_FOUND" >> $GITHUB_OUTPUT
echo "total_files=$TOTAL_FILES" >> $GITHUB_OUTPUT
echo "files_with_issues=$FILES_WITH_ISSUES" >> $GITHUB_OUTPUT
echo "broken_links=$TOTAL_BROKEN_LINKS" >> $GITHUB_OUTPUT

# Display results summary
echo "📋 Results summary:"
echo "   Files checked: $TOTAL_FILES"
echo "   Files with issues: $FILES_WITH_ISSUES"  
echo "   Broken links: $TOTAL_BROKEN_LINKS"
echo "   Status: $([ "$DEAD_LINKS_FOUND" = "true" ] && echo "❌ Issues found" || echo "✅ All good")"

echo "🎯 Link check complete!"