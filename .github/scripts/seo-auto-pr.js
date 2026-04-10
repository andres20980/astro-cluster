#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const SITE_ROOT = process.cwd();
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SITE_KEY = process.env.SITE_KEY || 'carta-astral';
const RECS_PATH = path.join(SITE_ROOT, 'docs', 'SEO_AGENT_RECOMMENDATIONS.json');
const RULES_PATH = path.join(REPO_ROOT, '.github', 'config', 'seo-autopatch-rules.json');
const STATE_PATH = path.join(SITE_ROOT, 'docs', 'SEO_AGENT_STATE.json');
const MAX_CHANGES = Number(process.env.SEO_AUTO_PR_MAX_CHANGES || 1);

function readJson(fp, fallback) {
  try {
    return JSON.parse(fs.readFileSync(fp, 'utf8'));
  } catch {
    return fallback;
  }
}

function writeJson(fp, data) {
  fs.mkdirSync(path.dirname(fp), { recursive: true });
  fs.writeFileSync(fp, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

function replaceWithFunction(content, regex, replacementFactory) {
  if (!regex.test(content)) return { next: content, changed: false };
  regex.lastIndex = 0;
  const next = content.replace(regex, (...args) => replacementFactory(...args));
  return { next, changed: next !== content };
}

function replaceTitleAndDescription(content, rule) {
  let next = content;
  let changed = false;

  const titleRes = replaceWithFunction(next, /<title>[^<]*<\/title>/, () => `<title>${rule.title}</title>`);
  next = titleRes.next;
  changed = changed || titleRes.changed;

  const descTag = `<meta name="description" content="${rule.description}">`;
  const descRes = replaceWithFunction(
    next,
    /<meta name="description" content="[^"]*">/,
    () => descTag
  );
  next = descRes.next;
  changed = changed || descRes.changed;

  return { next, changed };
}

function replaceGeneratorIndexMeta(content, rule) {
  let next = content;
  let changed = false;

  const titleRes = replaceWithFunction(
    next,
    /^INDEX_TITLE=".*"$/m,
    () => `INDEX_TITLE="${rule.title}"`
  );
  next = titleRes.next;
  changed = changed || titleRes.changed;

  const descRes = replaceWithFunction(
    next,
    /^INDEX_DESC=".*"$/m,
    () => `INDEX_DESC="${rule.description}"`
  );
  next = descRes.next;
  changed = changed || descRes.changed;

  return { next, changed };
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function updateSitemapLastmod(siteConfig, dateStr) {
  if (!siteConfig.sitemapFile || !siteConfig.homeUrl) return false;
  const sitemapPath = path.join(SITE_ROOT, siteConfig.sitemapFile);
  if (!fs.existsSync(sitemapPath)) return false;

  let sitemap = fs.readFileSync(sitemapPath, 'utf8');
  const loc = escapeRegex(siteConfig.homeUrl);
  const regex = new RegExp(`(<loc>${loc}<\\/loc>\\s*<lastmod>)[^<]*(<\\/lastmod>)`);
  if (!regex.test(sitemap)) return false;

  sitemap = sitemap.replace(regex, `$1${dateStr}$2`);
  fs.writeFileSync(sitemapPath, sitemap, 'utf8');
  return true;
}

function optimizeFile(siteConfig, rule) {
  const fp = path.join(SITE_ROOT, rule.file);
  if (!fs.existsSync(fp)) {
    return { file: rule.file, changed: false, reason: 'file_missing' };
  }

  const original = fs.readFileSync(fp, 'utf8');
  let result;

  if (fp.endsWith('.html')) {
    result = replaceTitleAndDescription(original, rule);
  } else if (fp.endsWith('.sh')) {
    result = replaceGeneratorIndexMeta(original, rule);
  } else {
    return { file: rule.file, changed: false, reason: 'unsupported_file' };
  }

  if (!result.changed) {
    return { file: rule.file, changed: false, reason: 'already_ok' };
  }

  fs.writeFileSync(fp, result.next, 'utf8');
  updateSitemapLastmod(siteConfig, new Date().toISOString().slice(0, 10));
  return { file: rule.file, changed: true, reason: 'optimized' };
}

function pickRecommendations(siteConfig, state, payload) {
  const rules = siteConfig.rulesByQuery || {};

  if (payload && Array.isArray(payload.topRecommendations) && payload.topRecommendations.length > 0) {
    return payload.topRecommendations;
  }

  const keywords = (siteConfig.targetKeywords || [])
    .filter((keyword) => rules[keyword.query])
    .sort((a, b) => (a.priority || 99) - (b.priority || 99));

  if (keywords.length === 0) return [];

  const lastIdx = keywords.findIndex((keyword) => keyword.query === state.lastQuery);
  const startIdx = (lastIdx + 1) % keywords.length;
  const rotated = keywords.slice(startIdx).concat(keywords.slice(0, startIdx));
  return rotated.slice(0, MAX_CHANGES).map((keyword) => ({ query: keyword.query }));
}

function getSiteConfig(rulesData) {
  if (rulesData.sites && rulesData.sites[SITE_KEY]) {
    return rulesData.sites[SITE_KEY];
  }

  return {
    domain: 'carta-astral-gratis.es',
    sitemapFile: 'public/sitemap.xml',
    homeUrl: 'https://carta-astral-gratis.es/',
    targetKeywords: rulesData.targetKeywords || [],
    rulesByQuery: rulesData.rulesByQuery || {},
  };
}

function main() {
  const rulesData = readJson(RULES_PATH, {});
  const siteConfig = getSiteConfig(rulesData);
  const rules = siteConfig.rulesByQuery || {};
  const state = readJson(STATE_PATH, { site: SITE_KEY, lastRun: null, lastQuery: null, results: [] });
  const payload = readJson(RECS_PATH, null);
  const recs = pickRecommendations(siteConfig, state, payload);

  const runAt = new Date().toISOString();
  const results = [];
  let applied = 0;
  let lastQuery = state.lastQuery;

  for (const rec of recs) {
    if (applied >= MAX_CHANGES) break;
    const key = String(rec.query || '').trim().toLowerCase();
    const rule = rules[key];
    if (!rule) continue;

    const res = optimizeFile(siteConfig, rule);
    results.push({ query: key, ...res });
    if (res.changed) {
      applied += 1;
      lastQuery = key;
    }
  }

  writeJson(STATE_PATH, {
    site: SITE_KEY,
    lastRun: runAt,
    lastQuery,
    results,
  });

  console.log(JSON.stringify({
    site: SITE_KEY,
    changedCount: results.filter((result) => result.changed).length,
    totalChecked: results.length,
    runAt,
  }));
}

main();
