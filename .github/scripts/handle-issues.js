#!/usr/bin/env node
// Issue handling script for dead links

const fs = require('fs');
const { Octokit } = require('@octokit/rest');

// Initialize GitHub client
const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

// Parse repository info
const [owner, repo] = process.env.GITHUB_REPOSITORY.split('/');

async function main() {
  try {
    console.log('🔧 Handling dead links issue...');
    
    const resultsPath = 'link-check-results/results.md';
    
    if (!fs.existsSync(resultsPath)) {
      console.log('❌ No results file found');
      return;
    }
    
    const results = fs.readFileSync(resultsPath, 'utf8');
    const today = new Date().toISOString().split('T')[0];
    const totalFiles = process.env.TOTAL_FILES || '0';
    const filesWithIssues = process.env.FILES_WITH_ISSUES || '0';
    const brokenLinks = process.env.BROKEN_LINKS || '0';
    
    // Search for existing open issues with dead-links label
    console.log('🔍 Searching for existing dead-links issues...');
    const issues = await octokit.rest.issues.listForRepo({
      owner,
      repo,
      state: 'open',
      labels: 'dead-links',
      sort: 'updated',
      direction: 'desc'
    });
    
    // Check if there's a recent issue (within last 7 days)
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentIssue = issues.data.find(issue => {
      const issueDate = new Date(issue.updated_at);
      return issueDate > sevenDaysAgo && issue.title.includes('Dead Links Found');
    });
    
    const issueTitle = `🔗 Dead Links Found - ${today}`;
    const issueBody = `## 🚨 Dead Links Detected in README Files

**Summary:**
- 📄 Files checked: ${totalFiles}
- ❌ Files with issues: ${filesWithIssues}
- 🔗 Total broken links: ${brokenLinks}
- 📅 Check date: ${today}

${results}

---

### 🔧 How to fix:
1. Review the broken links listed above
2. Update or remove the dead links from your README files
3. The link checker will automatically close this issue when all links are fixed

### ⚡ Quick Actions:
- [Re-run link check](../../actions/workflows/${process.env.GITHUB_WORKFLOW || 'link-check'})
- [View all link check results](../../actions)

---
*This issue was automatically created by the link checker workflow. The check runs daily and on README changes.*`;

    if (recentIssue) {
      // Update existing issue
      console.log(`🔄 Updating existing issue #${recentIssue.number}...`);
      
      await octokit.rest.issues.update({
        owner,
        repo,
        issue_number: recentIssue.number,
        title: issueTitle,
        body: issueBody
      });
      
      // Add a comment about the update
      await octokit.rest.issues.createComment({
        owner,
        repo,
        issue_number: recentIssue.number,
        body: `## 🔄 Updated Results - ${today}

📊 **Current Status:**
- Files with issues: ${filesWithIssues}/${totalFiles}
- Broken links: ${brokenLinks}

*Issue updated with latest findings.*`
      });
      
      console.log(`✅ Updated existing issue #${recentIssue.number}`);
    } else {
      // Create new issue
      console.log('📝 Creating new issue for dead links...');
      
      const newIssue = await octokit.rest.issues.create({
        owner,
        repo,
        title: issueTitle,
        body: issueBody,
        labels: ['dead-links', 'maintenance', 'bug']
      });
      
      console.log(`✅ Created new issue #${newIssue.data.number} for dead links`);
    }
    
  } catch (error) {
    console.error('❌ Error handling dead links issue:', error.message);
    process.exit(1);
  }
}

// Install @octokit/rest if not available and run
const { execSync } = require('child_process');

try {
  require('@octokit/rest');
} catch (e) {
  console.log('📦 Installing @octokit/rest...');
  execSync('npm install @octokit/rest', { stdio: 'inherit' });
}

main().catch(error => {
  console.error('💥 Script failed:', error);
  process.exit(1);
});