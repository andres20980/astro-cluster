#!/usr/bin/env node
/**
 * SEO Auto-PR script for carta-astral-gratis.es
 * Adapted from licitago — applies top SEO recommendations to index.html
 * and updates sitemap lastmod.
 */
const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();
const RECS_PATH = path.join(ROOT, 'docs', 'SEO_AGENT_RECOMMENDATIONS.json');
const RULES_PATH = path.join(ROOT, '.github', 'config', 'seo-autopatch-rules.json');
const STATE_PATH = path.join(ROOT, 'docs', 'SEO_AGENT_STATE.json');
const SITEMAP_PATH = path.join(ROOT, 'public', 'sitemap.xml');
const MAX_CHANGES = Number(process.env.SEO_AUTO_PR_MAX_CHANGES || 2);

function readJson(fp, fallback) {
  try { return JSON.parse(fs.readFileSync(fp, 'utf8')); } catch { return fallback; }
}

function replaceTag(content, regex, replacement) {
  if (!regex.test(content)) return { next: content, changed: false };
  const next = content.replace(regex, replacement);
  return { next, changed: next !== content };
}

function updateSitemapLastmod(dateStr) {
  if (!fs.existsSync(SITEMAP_PATH)) return false;
  let sitemap = fs.readFileSync(SITEMAP_PATH, 'utf8');
  const regex = /(<loc>https:\/\/carta-astral-gratis\.es\/<\/loc>\s*<lastmod>)[^<]*(<\/lastmod>)/;
  if (regex.test(sitemap)) {
    sitemap = sitemap.replace(regex, `$1${dateStr}$2`);
    fs.writeFileSync(SITEMAP_PATH, sitemap, 'utf8');
    return true;
  }
  return false;
}

function optimizeFile(rule) {
  const fp = path.join(ROOT, rule.file);
  if (!fs.existsSync(fp)) return { file: rule.file, changed: false, reason: 'file_missing' };

  let content = fs.readFileSync(fp, 'utf8');
  let changed = false;
  const nowDate = new Date().toISOString().slice(0, 10);

  const titleRes = replaceTag(content, /<title>[^<]*<\/title>/, `<title>${rule.title}</title>`);
  content = titleRes.next; changed = changed || titleRes.changed;

  const descTag = `<meta name="description" content="${rule.description}">`;
  const descRes = replaceTag(content, /<meta name="description" content="[^"]*">/, descTag);
  content = descRes.next; changed = changed || descRes.changed;

  if (changed) {
    fs.writeFileSync(fp, content, 'utf8');
    updateSitemapLastmod(nowDate);
  }

  return { file: rule.file, changed, reason: changed ? 'optimized' : 'already_ok' };
}

function main() {
  const rulesData = readJson(RULES_PATH, { rulesByQuery: {}, targetKeywords: [] });
  const rules = rulesData.rulesByQuery || {};
  const state = readJson(STATE_PATH, { lastRun: null, lastQuery: null, actions: {} });

  // Build recommendations from targetKeywords (rotating through them each week)
  // If SEO_AGENT_RECOMMENDATIONS.json exists, prefer it; otherwise auto-generate
  let recs;
  const payload = readJson(RECS_PATH, null);
  if (payload && Array.isArray(payload.topRecommendations) && payload.topRecommendations.length > 0) {
    recs = payload.topRecommendations;
  } else {
    // Auto-rotate through keywords sorted by priority
    const keywords = (rulesData.targetKeywords || [])
      .filter(k => rules[k.query])
      .sort((a, b) => (a.priority || 99) - (b.priority || 99));
    // Pick the next keyword after last applied one
    const lastIdx = keywords.findIndex(k => k.query === state.lastQuery);
    const startIdx = (lastIdx + 1) % Math.max(keywords.length, 1);
    recs = keywords.slice(startIdx, startIdx + MAX_CHANGES).map(k => ({ query: k.query }));
    if (recs.length === 0 && keywords.length > 0) {
      recs = keywords.slice(0, MAX_CHANGES).map(k => ({ query: k.query }));
    }
  }

  const runAt = new Date().toISOString();
  const results = [];
  let applied = 0;
  let lastQuery = state.lastQuery;

  for (const rec of recs) {
    if (applied >= MAX_CHANGES) break;
    const key = (rec.query || '').trim().toLowerCase();
    const rule = rules[key];
    if (!rule) continue;
    const res = optimizeFile(rule);
    results.push(res);
    if (res.changed) { applied++; lastQuery = key; }
  }

  state.lastRun = runAt;
  state.lastQuery = lastQuery;
  state.results = results;
  fs.mkdirSync(path.dirname(STATE_PATH), { recursive: true });
  fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2), 'utf8');

  const output = { changedCount: results.filter(r => r.changed).length, totalChecked: results.length, runAt };
  console.log(JSON.stringify(output));
}

main();
