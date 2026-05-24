#!/usr/bin/env node
/**
 * self-learn.mjs v3.0 — OpenClaw 自学代理
 * 每周日 10:00 自动运行
 * 搜索 GitHub OpenClaw 高星项目 → 分析 → 更新知识库
 */

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const HOME = process.env.HOME;
process.env.PATH = `${HOME}/.nvm/versions/node/v24.15.0/bin:${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${process.env.PATH || ''}`;

const WORKSPACE = join(HOME, '.openclaw', 'workspace');
const MEMORY_FILE = join(WORKSPACE, 'MEMORY.md');
const KNOWLEDGE_DIR = join(WORKSPACE, 'knowledge');

// ── 搜索 GitHub ──
function searchGitHub() {
  try {
    const cmd = `gh search repos "openclaw" --sort stars --limit 25 --json name,owner,description,url,stargazersCount,updatedAt,isFork`;
    const raw = execSync(cmd, { timeout: 30000, encoding: 'utf8', shell: '/bin/bash' });
    if (!raw || !raw.trim()) return [];
    const data = JSON.parse(raw);
    return data.filter(r =>
      !['openclaw', 'zengbaocheng1'].includes(r.owner.login) &&
      !r.isFork &&
      (r.stargazersCount || 0) >= 10
    ).sort((a, b) => (b.stargazersCount || 0) - (a.stargazersCount || 0));
  } catch (e) {
    console.error('GitHub search error:', e.message?.substring(0, 100));
    return [];
  }
}

// ── 检查已知项目 ──
function getKnownProjects() {
  const known = new Set();
  try {
    if (existsSync(KNOWLEDGE_DIR)) {
      const dirs = execSync(`ls ${KNOWLEDGE_DIR} 2>/dev/null`, { encoding: 'utf8', shell: '/bin/bash' }).trim();
      dirs.split('\n').filter(Boolean).forEach(d => known.add(d));
    }
  } catch (e) { /* ignore */ }
  return known;
}

// ── 分析 README ──
function analyzeReadme(repoFullName) {
  for (const branch of ['main', 'master']) {
    try {
      const url = `https://raw.githubusercontent.com/${repoFullName}/${branch}/README.md`;
      const cmd = `curl -sL --max-time 15 '${url}' | head -100`;
      const content = execSync(cmd, { timeout: 20000, encoding: 'utf8', shell: '/bin/bash' });
      if (content && content.trim()) return content.trim();
    } catch (e) { /* try next branch */ }
  }
  return null;
}

// ── 提取技术模式 ──
function extractPatterns(readme) {
  if (!readme) return [];
  const lower = readme.toLowerCase();
  const patterns = [];
  if (lower.includes('pipeline') || lower.includes('workflow')) patterns.push('pipeline_orchestration');
  if (lower.includes('mcp') || lower.includes('model context protocol')) patterns.push('mcp_integration');
  if (lower.includes('skill') || lower.includes('plugin')) patterns.push('skill_architecture');
  if (lower.includes('memory') || lower.includes('knowledge graph')) patterns.push('memory_management');
  if (lower.includes('deploy') || lower.includes('docker') || lower.includes('nix')) patterns.push('deployment');
  if (lower.includes('cli') || lower.includes('command line')) patterns.push('cli_tool');
  if (lower.includes('screenshot') || lower.includes('vision')) patterns.push('visual_perception');
  if (lower.includes('self') && (lower.includes('improv') || lower.includes('heal'))) patterns.push('self_improvement');
  if (lower.includes('security') || lower.includes('guard') || lower.includes('audit')) patterns.push('security');
  if (lower.includes('openclaw') && (lower.includes('skill') || lower.includes('agent'))) patterns.push('openclaw_native');
  return patterns;
}

// ── 过滤真正相关的项目 ──
function isOpenClawRelated(readme, repo) {
  if (!readme) return false;
  const desc = (repo.description || '').toLowerCase();
  const name = repo.name.toLowerCase();
  const lower = readme.toLowerCase();

  // 名称或描述含 openclaw → 直接相关
  if (name.includes('openclaw') || desc.includes('openclaw')) return true;

  // README 中多次提及 openclaw
  const mentions = (lower.match(/openclaw/gi) || []).length;
  if (mentions >= 3) return true;

  return false;
}

// ── 创建知识文档 ──
function createKnowledgeDoc(repo, readme) {
  const dirName = repo.name;
  const docDir = join(KNOWLEDGE_DIR, dirName);
  if (!existsSync(docDir)) mkdirSync(docDir, { recursive: true });
  const patterns = extractPatterns(readme);
  const stars = repo.stargazersCount || 0;

  const doc = `# ${repo.owner.login}/${repo.name}
- **星标**: ⭐${stars}
- **URL**: ${repo.url}
- **描述**: ${repo.description || '无描述'}
- **首次发现**: ${new Date().toISOString().split('T')[0]}

## 技术模式
${patterns.map(p => `- [${p}]`).join('\n') || '- 待分析'}

## README 摘要
${readme ? readme.substring(0, 500) + '...' : '未获取到 README'}
`;
  writeFileSync(join(docDir, 'README.md'), doc);
  return patterns.length > 0 ? patterns : null;
}

// ── 更新 MEMORY.md ──
function updateMemoryFile(newProjects) {
  if (!existsSync(MEMORY_FILE)) {
    writeFileSync(MEMORY_FILE, '# MEMORY.md — 长期记忆\n\n## 📚 待学项目\n\n');
  }
  let memory = readFileSync(MEMORY_FILE, 'utf8');
  if (!memory.includes('## 📚 待学项目')) {
    memory += '\n## 📚 待学项目\n\n';
  }
  for (const p of newProjects) {
    const stars = p.stargazersCount || 0;
    const entry = `- [ ] **${p.owner.login}/${p.name}** (⭐${stars}): ${p.description || '无描述'} — ${p.url}\n`;
    if (!memory.includes(`**${p.owner.login}/${p.name}**`)) {
      memory += entry;
    }
  }
  writeFileSync(MEMORY_FILE, memory);
}

// ── 主流程 ──
async function main() {
  console.log(`[${new Date().toISOString()}] 🧠 self-learn.mjs — OpenClaw 自学代理`);
  console.log('─'.repeat(50));

  if (!existsSync(KNOWLEDGE_DIR)) mkdirSync(KNOWLEDGE_DIR, { recursive: true });

  console.log('🔍 搜索 GitHub OpenClaw 项目...');
  const projects = searchGitHub();
  console.log(`   原始结果: ${projects.length} 个`);

  if (projects.length === 0) {
    console.log('✅ 搜索无结果（可能 gh 不可用）');
    return;
  }

  const known = getKnownProjects();
  const trulyNew = projects.filter(p => !known.has(p.name));
  console.log(`   已知: ${projects.length - trulyNew.length} 个 | 新: ${trulyNew.length} 个`);

  if (trulyNew.length === 0) {
    console.log('✅ 无新项目');
    return;
  }

  // 分析高分新项目
  const highValue = trulyNew.filter(p => (p.stargazersCount || 0) >= 50);
  const learned = [];

  for (const p of highValue) {
    console.log(`📖 分析: ${p.owner.login}/${p.name} (⭐${p.stargazersCount})...`);
    const readme = analyzeReadme(`${p.owner.login}/${p.name}`);
    if (readme && isOpenClawRelated(readme, p)) {
      const patterns = createKnowledgeDoc(p, readme);
      learned.push({ ...p, patterns });
      console.log(`   ✅ 相关！模式: ${patterns?.join(', ') || '待定'}`);
    } else if (readme) {
      console.log(`   ⏭️ 跳过（非 OpenClaw 直接相关）`);
    } else {
      console.log(`   ⚠️ README 无法获取`);
    }
  }

  // 更新 MEMORY.md
  if (learned.length > 0) {
    updateMemoryFile(learned);
    console.log('📝 MEMORY.md 已更新');
  }

  // 汇报
  console.log(`\n📊 本次学习: 发现${trulyNew.length}个新项目, 学习${learned.length}个`);
  if (learned.length > 0) {
    learned.forEach(p => console.log(`   ✅ ${p.owner.login}/${p.name} ⭐${p.stargazersCount}`));
  } else if (trulyNew.length > 0) {
    console.log('   (高分项目均不相关，低星项目已记录到 MEMORY.md)');
    updateMemoryFile(trulyNew);
  }

  // 自动同步到 GitHub
  console.log('\n🔄 同步到 GitHub...');
  try {
    execSync('bash scripts/mirror-sync.sh dev 2>&1', { 
      cwd: WORKSPACE, 
      timeout: 60000,
      encoding: 'utf8',
      shell: '/bin/bash'
    });
    console.log(execSync('tail -2 ~/.openclaw-backups/openclaw-*.tar.gz 2>/dev/null | head -1 || echo "备份检查"', { timeout: 5000, encoding: 'utf8' }));
  } catch(e) {
    // mirror-sync failure is non-fatal
  }

  console.log('─'.repeat(50));
  console.log('✅ 完成');
}

main().catch(e => {
  console.error('❌ 失败:', e.message);
  process.exit(1);
});
