#!/usr/bin/env node
/**
 * check-and-push-brain.mjs
 * 检测 OpenClaw 版本变化 → 有变化则自动推送到 GitHub
 * 每4小时由 cron 自动运行
 */

import { execSync } from 'child_process';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const HOME = process.env.HOME || '/home/zbc';
const WORKSPACE = `${HOME}/.openclaw/workspace`;
const STATE_FILE = `${HOME}/.openclaw/maintenance/state/version-state.json`;
const AGENTICS_TMP = '/tmp/oc-agentics-check';

const GITHUB_USER = 'zengbaocheng1';
const BRANCH = 'dev';

// 获取当前 OpenClaw 版本
function getCurrentVersion() {
  try {
    const output = execSync('openclaw --version', { encoding: 'utf8', timeout: 10000 });
    const match = output.match(/\d+\.\d+\.\d+/);
    return match ? match[0] : null;
  } catch (e) {
    console.error('[check] 获取版本失败:', e.message);
    return null;
  }
}

// 读取上次记录的版本
function getLastVersion() {
  try {
    if (existsSync(STATE_FILE)) {
      const data = JSON.parse(readFileSync(STATE_FILE, 'utf8'));
      return data.version;
    }
  } catch (e) { /* ignore */ }
  return null;
}

// 保存当前版本
function saveVersion(version) {
  try {
    mkdirSync(dirname(STATE_FILE), { recursive: true });
    writeFileSync(STATE_FILE, JSON.stringify({
      version,
      checkedAt: new Date().toISOString()
    }, null, 2));
  } catch (e) {
    console.error('[check] 保存版本失败:', e.message);
  }
}

// 核心文件列表
const CORE_FILES = [
  'MEMORY.md',
  'AGENTS.md',
  'SOUL.md',
  'IDENTITY.md',
  'USER.md',
  'TOOLS.md',
  'TROUBLESHOOTING.md',
  'HEARTBEAT.md'
];

const SCRIPTS = [
  'bootstrap.sh',
  'mirror-sync.sh',
  'self-learn.mjs'
];

const CONFIG = [
  'openclaw-config-health-check.sh'
];

// 推送到 GitHub
function pushToGitHub(message) {
  try {
    // 克隆仓库
    execSync(`rm -rf ${AGENTICS_TMP}`, { stdio: 'ignore' });
    execSync(`git clone --depth=1 -b ${BRANCH} https://github.com/${GITHUB_USER}/openclaw-agentics.git ${AGENTICS_TMP}`, {
      stdio: 'ignore',
      timeout: 30000
    });

    // 同步核心文件
    CORE_FILES.forEach(f => {
      const src = `${WORKSPACE}/${f}`;
      const dst = `${AGENTICS_TMP}/${f}`;
      if (existsSync(src)) {
        execSync(`cp -p "${src}" "${dst}"`, { stdio: 'ignore' });
      }
    });

    // 同步脚本
    mkdirSync(`${AGENTICS_TMP}/scripts`, { recursive: true });
    SCRIPTS.forEach(f => {
      const src = `${WORKSPACE}/scripts/${f}`;
      const dst = `${AGENTICS_TMP}/scripts/${f}`;
      if (existsSync(src)) {
        execSync(`cp -p "${src}" "${dst}"`, { stdio: 'ignore' });
      }
    });

    // 同步配置
    mkdirSync(`${AGENTICS_TMP}/config`, { recursive: true });
    CONFIG.forEach(f => {
      const src = `${WORKSPACE}/config/${f}`;
      const dst = `${AGENTICS_TMP}/config/${f}`;
      if (existsSync(src)) {
        execSync(`cp -p "${src}" "${dst}"`, { stdio: 'ignore' });
      }
    });

    // 提交并推送
    execSync(`cd ${AGENTICS_TMP} && git add -A && git commit -m "${message}" && git push origin ${BRANCH}`, {
      timeout: 30000
    });

    console.log(`[check] ✅ 已推送: ${message}`);
    return true;
  } catch (e) {
    console.error('[check] ❌ 推送失败:', e.message);
    return false;
  } finally {
    execSync(`rm -rf ${AGENTICS_TMP}`, { stdio: 'ignore' });
  }
}

// 主流程
function main() {
  console.log(`[$(date '+%H:%M:%S')] 🔍 检查 OpenClaw 版本...`);

  const current = getCurrentVersion();
  if (!current) {
    console.log('[check] ⚠️ 无法获取版本，退出');
    return;
  }

  const last = getLastVersion();
  console.log(`[check] 当前版本: ${current} | 上次版本: ${last || '未知'}`);

  if (current === last) {
    console.log('[check] ⏭️ 版本无变化，静默跳过');
    return;
  }

  // 版本变了！
  console.log(`[check] 🆕 版本变化: ${last || '首次'} → ${current}`);
  saveVersion(current);

  const msg = `🧠 分身同步: OpenClaw ${current} (${new Date().toLocaleDateString('zh-CN')})`;
  pushToGitHub(msg);
}

main();