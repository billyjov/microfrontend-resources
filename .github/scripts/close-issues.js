#!/usr/bin/env node
// Script to close fixed dead link issues

const { Octokit } = require('@octokit/rest');

// Initialize GitHub client
const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

// Parse repository info
const [owner, repo] = process.env.GITHUB_REPOSITORY.split('/');

async function main() {
  try {
    console.log('🎉 All links are working! Closing dead-links issues...');
    
    const totalFiles = process.env.TOTAL_FILES || '0';
    const today = new Date().toISOString().split('T')[0];
    
    // Find all open dead-links issues
    console.log('🔍 Searching for open dead-links issues...');
    const issues = await octokit.rest.issues.listForRepo({
      owner,
      repo,
      state: 'open',
      labels: 'dead-links'
    });
    
    console.log(`Found ${issues.data.length} open dead-links issues`);
    
    if (issues.data.length === 0) {
      console.log('✅ No open dead-links issues to close');
      return;
    }
    
    // Close all open dead-links issues since all links are now working
    for (const issue of issues.data) {
      console.log(`🔒 Closing issue #${issue.number}: ${issue.title}`);
      
      await octokit.rest.issues.update({
        owner,
        repo,
        issue_number: issue.number,
        state: 'closed'
      });
      
      await octokit.rest.issues.createComment({
        owner,
        repo,
        issue_number: issue.number,
        body: `✅ **All links are now working!**

The link checker found no broken links in the latest check. Automatically closing this issue.

📊 **Final Check Results:**
- 📄 Files checked: ${totalFiles}
- ✅ All links working
- 📅 Fixed on: ${today}

*Closed by link checker workflow on ${today}*`
      });
      
      console.log(`✅ Closed issue #${issue.number}`);
    }
    
    console.log(`🎯 Successfully closed ${issues.data.length} dead-links issue(s)`);
    
  } catch (error) {
    console.error('❌ Error closing issues:', error.message);
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