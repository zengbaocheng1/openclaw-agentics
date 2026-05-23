#!/usr/bin/env node

/**
 * self-learn.mjs — OpenClaw 自学脚本
 * 
 * 每周运行：搜索 GitHub 高星 OpenClaw 项目
 * → 对比已有知识库
 * → 新项目写入 MEMORY.md 待学列表
 * → 通知主人有新发现
 */

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || join(process.env.HOME, '.openclaw', 'workspace');
const MEMORY_FILE = join(WORKSPACE, 'MEMORY.md');
const TOOLS_FILE = join(WORKSPACE, 'TOOLS.md');
const KNOWLEDGE_DIR = join(WORKSPACE, 'knowledge');
const EXTERNAL_DIR = join(WORKSPACE, 'tmp-oc-agentics/external');  // agentics clone dir

// ── 1. 搜索 GitHub 高星 OpenClaw 项目 ──
function searchGitHub() {
  const query = 'openclaw agent OR openclaw skill OR openclaw plugin OR openclaw tool';
  const cmd = `gh search repos "${query}" --sort stars --limit 20 --json name,owner,description,url,stars,updatedAt,fork 2>/dev/null`;
  
  try {
    const raw = execSync(cmd, { timeout: 30000, encoding: 'utf8' });
    const data = JSON.parse(raw);
    return data.filter(r => 
      !['openclaw','zengbaocheng1'].includes(r.owner.login) && 
      !r.fork &&
      r.stars >= 10
    );
  } catch (e) {
    console.error('GitHub search failed:', e.message);
    return [];
  }
}

// ── 2. 检查已有项目列表 ──
function getKnownProjects() {
  const known = new Set();
  
  // Check knowledge dir
  if (existsSync(KNOWLEDGE_DIR)) {
    const dirs = execSync(`ls ${KNOWLEDGE_DIR} 2>/dev/null`, { encoding: 'utf8' }).trim();
    dirs.split('\n').filter(Boolean).forEach(d => known.add(d));
  }
  
  // Check external dir (from agentics clone)
  if (existsSync(EXTERNAL_DIR)) {
    const dirs = execSync(`ls ${EXTERNAL_DIR} 2>/dev/null`, { encoding: 'utf8' }).trim();
    dirs.split('\n').filter(Boolean).forEach(d => known.add(d));
  }
  
  return known;
}

// ── 3. 分析 README（高分项目）──
function analyzeReadme(repoFullName, url) {
  try {
    const readmeUrl = `https://raw.githubusercontent.com/${repoFullName}/main/README.md`;
    const cmd = `curl -sL --max-time 10 "${readmeUrl}" | head -80`;
    const content = execSync(cmd, { timeout: 15000, encoding: 'utf8' });
    return content;
  } catch (e) {
    try {
      // Try master branch
      const readmeUrl = `https://raw.githubusercontent.com/${repoFullName}/master/README.md`;
      const cmd = `curl -sL --max-time 10 "${readmeUrl}" | head -80`;
      return execSync(cmd, { timeout: 15000, encoding: 'utf8' });
    } catch (e2) {
      return null;
    }
  }
}

// ── 4. 提取技术模式 ──
function extractPatterns(readme) {
  const patterns = [];
  
  if (!readme) return patterns;
  
  const lower = readme.toLowerCase();
  
  // Pattern detection
  if (lower.includes('pipeline') || lower.includes('workflow')) 
    patterns.push('pipeline_orchestration');
  if (lower.includes('mcp') || lower.includes('model context protocol'))
    patterns.push('mcp_integration');
  if (lower.includes('skill') || lower.includes('plugin'))
    patterns.push('skill_architecture');
  if (lower.includes('memory') || lower.includes('knowledge graph'))
    patterns.push('memory_management');
  if (lower.includes('deploy') || lower.includes('docker') || lower.includes('nix'))
    patterns.push('deployment');
  if (lower.includes('cli') || lower.includes('command line'))
    patterns.push('cli_tool');
  if (lower.includes('json') || lower.includes('typed'))
    patterns.push('typed_output');
  if (lower.includes('screenshot') || lower.includes('vision') || lower.includes('capture'))
    patterns.push('visual_perception');
  if (lower.includes('self') && (lower.includes('improve') || lower.includes('heal')))
    patterns.push('self_improvement');
  if (lower.includes('security') || lower.includes('guard') || lower.includes('audit'))
    patterns.push('security');
  
  return patterns;
}

// ── 5. 创建知识文档 ──
function createKnowledgeDoc(repo, readme) {
  const dirName = repo.name;
  const docDir = join(KNOWLEDGE_DIR, dirName);
  
  if (!existsSync(docDir)) {
    mkdirSync(docDir, { recursive: true });
  }
  
  const patterns = extractPatterns(readme);
  
  const doc = `# ${repo.owner.login}/${repo.name}

- **星标**: ⭐${repo.stars}
- **URL**: ${repo.url}
- **描述**: ${repo.description || '无描述'}
- **首次发现**: ${new Date().toISOString().split('T')[0]}

## 技术模式
${patterns.map(p => `- [${p}]`).join('\n') || '- 待分析'}

## README 摘要
${readme ? readme.substring(0, 500).replace(/</g, '&lt;') + '...' : '未获取到README'}
`;
  
  writeFileSync(join(docDir, 'README.md'), doc);
  return true;
}

// ── 6. 写入 MEMORY.md 待学列表 ──
function updateMemoryFile(newProjects) {
  if (!existsSync(MEMORY_FILE)) {
    writeFileSync(MEMORY_FILE, '# MEMORY.md — 长期记忆\n\n');
  }
  
  let memory = readFileSync(MEMORY_FILE, 'utf8');
  
  // Find or create "待学项目" section
  const section = '\n## 📚 待学项目\n\n';
  if (!memory.includes('## 📚 待学项目')) {
    memory += section;
  }
  
  for (const p of newProjects) {
    const entry = `- [ ] **${p.owner.login}/${p.name}** (⭐${p.stars}): ${p.description || '无描述'} — ${p.url}\n`;
    if (!memory.includes(`**${p.owner.login}/${p.name}**`)) {
      memory += entry;
    }
  }
  
  writeFileSync(MEMORY_FILE, memory);
}

// ── 7. 主流程 ──
async function main() {
  console.log('🧠 self-learn.mjs — OpenClaw 自学代理');
  console.log('─'.repeat(50));
  
  // 确保目录存在
  if (!existsSync(KNOWLEDGE_DIR)) {
    mkdirSync(KNOWLEDGE_DIR, { recursive: true });
  }
  
  // 搜索
  console.log('🔍 搜索 GitHub OpenClaw 项目...');
  const projects = searchGitHub();
  console.log(`   发现 ${projects.length} 个项目`);
  
  // 对比已有
  const known = getKnownProjects();
  const newProjects = projects.filter(p => !known.has(p.name));
  
  if (newProjects.length === 0) {
    console.log('✅ 无新项目发现');
    console.log('HEARTBEAT_OK');
    return;
  }
  
  console.log(`🆕 新项目: ${newProjects.length} 个`);
  
  // 分析高星项目
  const highValue = newProjects.filter(p => p.stars >= 50);
  const learned = [];
  
  for (const p of highValue) {
    console.log(`📖 分析: ${p.owner.login}/${p.name} (⭐${p.stars})`);
    const readme = analyzeReadme(`${p.owner.login}/${p.name}`, p.url);
    if (readme) {
      createKnowledgeDoc(p, readme);
      learned.push(p);
    }
  }
  
  // 更新 MEMORY.md
  if (newProjects.length > 0) {
    updateMemoryFile(newProjects);
    console.log('📝 MEMORY.md 已更新');
  }
  
  // 汇报
  console.log('');
  console.log('📊 本次学习报告:');
  console.log(`  新发现: ${newProjects.length} 个`);
  console.log(`  已学习: ${learned.length} 个`);
  
  if (learned.length > 0) {
    console.log('  项目列表:');
    learned.forEach(p => console.log(`    - ${p.owner.login}/${p.name} ⭐${p.stars}`));
  } else if (newProjects.length > 0) {
    console.log('  低星项目（未深度学习）:');
    newProjects.forEach(p => console.log(`    - ${p.owner.login}/${p.name} ⭐${p.stars} — ${(p.description ||'').substring(0,50)}`));
  }
  
  console.log('─'.repeat(50));
  console.log('✅ 自学完成');
}

main().catch(e => {
  console.error('❌ 自学失败:', e.message);
  process.exit(1);
});
