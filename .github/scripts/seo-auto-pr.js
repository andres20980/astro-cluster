#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const SITE_ROOT = process.cwd();
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SITE_KEY = process.env.SITE_KEY || 'carta-astral';
const RECS_PATH = path.join(SITE_ROOT, 'docs', 'SEO_AGENT_RECOMMENDATIONS.json');
const COMPETITOR_INTEL_PATH = path.join(SITE_ROOT, 'docs', 'SEO_COMPETITOR_INTEL.json');
const GSC_SIGNAL_PATH = path.join(SITE_ROOT, 'docs', 'SEO_GSC_QUERIES.json');
const TEMPLATE_SIGNAL_PATH = path.join(SITE_ROOT, 'docs', 'SEO_TEMPLATE_FAMILIES.json');
const RULES_PATH = path.join(REPO_ROOT, '.github', 'config', 'seo-autopatch-rules.json');
const STATE_PATH = path.join(SITE_ROOT, 'docs', 'SEO_AGENT_STATE.json');
const MAX_CHANGES = Number(process.env.SEO_AUTO_PR_MAX_CHANGES || 1);
const MAX_SIGNAL_AGE_DAYS = Number(process.env.SEO_SIGNAL_MAX_AGE_DAYS || 21);
const MIN_HOURS_BETWEEN_PATCHES = Number(process.env.SEO_MIN_HOURS_BETWEEN_PATCHES || 18);
const MIN_TITLE_LENGTH = Number(process.env.SEO_MIN_TITLE_LENGTH || 35);
const MAX_TITLE_LENGTH = Number(process.env.SEO_MAX_TITLE_LENGTH || 70);
const MIN_DESCRIPTION_LENGTH = Number(process.env.SEO_MIN_DESCRIPTION_LENGTH || 70);
const MAX_DESCRIPTION_LENGTH = Number(process.env.SEO_MAX_DESCRIPTION_LENGTH || 165);
const HOLDOUT_RATIO = Math.max(0, Math.min(1, Number(process.env.SEO_HOLDOUT_RATIO || 0)));

function readJson(fp, fallback) {
  try {
    return JSON.parse(fs.readFileSync(fp, 'utf8'));
  } catch {
    return fallback;
  }
}

function isFreshSignal(payload) {
  if (!payload || !payload.generatedAt) return false;
  const generatedAt = new Date(payload.generatedAt).getTime();
  if (!Number.isFinite(generatedAt)) return false;
  const ageDays = (Date.now() - generatedAt) / (1000 * 60 * 60 * 24);
  return ageDays <= MAX_SIGNAL_AGE_DAYS;
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

function replaceShellVariables(content, shellVariables) {
  let next = content;
  let changed = false;

  for (const [name, value] of Object.entries(shellVariables || {})) {
    const res = replaceWithFunction(
      next,
      new RegExp(`^${escapeRegex(name)}=".*"$`, 'm'),
      () => `${name}="${value}"`
    );
    next = res.next;
    changed = changed || res.changed;
  }

  return { next, changed };
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function recentlyPatched(lastRunIso) {
  if (!lastRunIso) return false;
  const ts = new Date(lastRunIso).getTime();
  if (!Number.isFinite(ts)) return false;
  const ageHours = (Date.now() - ts) / (1000 * 60 * 60);
  return ageHours < MIN_HOURS_BETWEEN_PATCHES;
}

function deterministicBucket(seed) {
  let hash = 0;
  for (let i = 0; i < seed.length; i += 1) {
    hash = ((hash << 5) - hash) + seed.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash % 1000) / 1000;
}

function shouldHoldout() {
  if (HOLDOUT_RATIO <= 0) return false;
  const now = new Date();
  const weekKey = `${now.getUTCFullYear()}-W${Math.ceil((now.getUTCDate()) / 7)}`;
  const bucket = deterministicBucket(`${SITE_KEY}-${weekKey}`);
  return bucket < HOLDOUT_RATIO;
}

function isLengthSafe(value, min, max) {
  const len = String(value || '').trim().length;
  return len >= min && len <= max;
}

function hasKeywordStuffing(value) {
  const tokens = tokenize(value);
  if (tokens.length === 0) return false;
  const counts = new Map();
  for (const token of tokens) {
    counts.set(token, (counts.get(token) || 0) + 1);
  }
  return [...counts.values()].some((count) => count >= 4);
}

function isSafeRule(rule) {
  const titleOk = isLengthSafe(rule.title, MIN_TITLE_LENGTH, MAX_TITLE_LENGTH);
  const descriptionOk = isLengthSafe(rule.description, MIN_DESCRIPTION_LENGTH, MAX_DESCRIPTION_LENGTH);
  const stuffingRisk = hasKeywordStuffing(rule.title) || hasKeywordStuffing(rule.description);
  return titleOk && descriptionOk && !stuffingRisk;
}

function classifyPathForSite(siteKey, rawPath) {
  const p = String(rawPath || '/').split('?', 1)[0] || '/';
  if (p === '/') return 'home';
  if (siteKey === 'carta-astral') {
    if (p.startsWith('/signos/') && p !== '/signos/') return 'sign_profiles';
    if (p.startsWith('/signos/')) return 'sign_hub';
  }
  if (siteKey === 'compatibilidad-signos') return 'pair_pages';
  if (siteKey === 'tarot-del-dia') {
    if (p.startsWith('/arcanos-mayores/') && p !== '/arcanos-mayores/') return 'major_arcana';
    if (p.startsWith('/arcanos-mayores/')) return 'major_arcana_hub';
    if (p.startsWith('/arcanos-menores/')) return 'minor_arcana';
  }
  if (siteKey === 'calcular-numerologia') {
    if (p.startsWith('/numero-de-vida/') && p !== '/numero-de-vida/') return 'number_pages';
    if (p.startsWith('/numero-de-vida/')) return 'number_hub';
  }
  if (siteKey === 'horoscopo-de-hoy') return 'sign_pages';
  if (siteKey === 'meditacion-chakras') {
    if (p.startsWith('/chakras/') && p !== '/chakras/') return 'chakra_steps';
    return 'home';
  }
  return 'content';
}

function tokenize(value) {
  return normalizeText(value)
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length > 2);
}

function scoreKeywordByCompetitorIntel(keyword, competitorIntel) {
  const query = String(keyword.query || '').trim();
  const normalizedQuery = normalizeText(query);
  const queryTokens = tokenize(query);
  const insights = competitorIntel && competitorIntel.insights ? competitorIntel.insights : null;

  if (!insights || queryTokens.length === 0) {
    return {
      score: (keyword.priority || 99) * 100,
      matchedSignals: [],
    };
  }

  const topKeywords = (insights.topKeywords || []).map((item) => normalizeText(item.keyword));
  const contextKeywords = (competitorIntel.keywordsContext || []).map((item) => normalizeText(item));
  const h2Patterns = (insights.commonH2Patterns || []).map((item) => normalizeText(item.text));
  const matchedSignals = [];
  let score = (keyword.priority || 99) * 100;

  if (topKeywords.includes(normalizedQuery)) {
    score -= 60;
    matchedSignals.push('top_keyword_exact');
  } else if (contextKeywords.includes(normalizedQuery)) {
    score -= 35;
    matchedSignals.push('context_keyword_exact');
  }

  let overlapHits = 0;
  const signalPools = [...topKeywords, ...contextKeywords, ...h2Patterns];
  for (const signal of signalPools) {
    const signalTokens = tokenize(signal);
    const overlap = queryTokens.filter((token) => signalTokens.includes(token)).length;
    if (overlap > 0) {
      overlapHits = Math.max(overlapHits, overlap);
    }
  }

  if (overlapHits > 0) {
    score -= overlapHits * 10;
    matchedSignals.push(`token_overlap_${overlapHits}`);
  }

  return { score, matchedSignals };
}

function scoreKeywordByGsc(keyword, gscSignals) {
  const query = String(keyword.query || '').trim();
  const normalizedQuery = normalizeText(query);
  const rows = [
    ...((gscSignals && Array.isArray(gscSignals.queries)) ? gscSignals.queries : []),
    ...((gscSignals && Array.isArray(gscSignals.strikingDistanceQueries)) ? gscSignals.strikingDistanceQueries : []),
  ];
  if (!normalizedQuery || rows.length === 0) {
    return { score: (keyword.priority || 99) * 100, matchedSignals: [] };
  }

  const match = rows.find((row) => normalizeText(row.query) === normalizedQuery);
  if (!match) {
    return { score: (keyword.priority || 99) * 100, matchedSignals: [] };
  }

  const impressions = Number(match.impressions || 0);
  const ctr = Number(match.ctr || 0);
  const position = Number(match.position || 0);
  let boost = 0;
  const matchedSignals = [];

  if (impressions >= 50 && ctr < 0.01) {
    boost += 40;
    matchedSignals.push('gsc_low_ctr_50');
  }
  if (impressions >= 200 && ctr < 0.005) {
    boost += 40;
    matchedSignals.push('gsc_low_ctr_200');
  }
  if (position >= 8 && position <= 20) {
    boost += 20;
    matchedSignals.push('gsc_mid_position');
  }
  if (impressions >= 2 && ctr === 0 && position >= 4 && position <= 20) {
    boost += 12;
    matchedSignals.push('gsc_striking_distance_early');
  }

  const base = (keyword.priority || 99) * 100;
  return { score: base - boost, matchedSignals };
}

function scoreKeywordByTemplateFamily(keyword, templateSignals) {
  const family = String(keyword.templateFamily || '').trim();
  const base = (keyword.priority || 99) * 100;
  if (!family || !templateSignals || !Array.isArray(templateSignals.families)) {
    return { score: base, matchedSignals: [] };
  }

  const match = templateSignals.families.find((item) => item.family === family);
  if (!match) {
    return { score: base, matchedSignals: [] };
  }

  let boost = 0;
  const matchedSignals = [];
  if (Number(match.gscOpportunity || 0) > 0) {
    boost += Math.min(50, Number(match.gscOpportunity || 0) / 5);
    matchedSignals.push(`family_gsc_${family}`);
  }
  if (Number(match.ga4LowEngagementViews || 0) > 0) {
    boost += Math.min(40, Number(match.ga4LowEngagementViews || 0) * 5);
    matchedSignals.push(`family_ga4_${family}`);
  }

  return { score: base - boost, matchedSignals };
}

function scoreKeywordByPageOpportunities(keyword, gscSignals) {
  const base = (keyword.priority || 99) * 100;
  const pages = (gscSignals && Array.isArray(gscSignals.topPageOpportunities)) ? gscSignals.topPageOpportunities : [];
  if (!keyword.templateFamily || pages.length === 0) {
    return { score: base, matchedSignals: [], matchedPages: [] };
  }

  const matchingPages = pages.filter((row) => classifyPathForSite(SITE_KEY, row.path) === keyword.templateFamily);
  if (matchingPages.length === 0) {
    return { score: base, matchedSignals: [], matchedPages: [] };
  }

  const aggregate = matchingPages.reduce((sum, row) => sum + Number(row.opportunity || 0), 0);
  const ctrGap = matchingPages.reduce((sum, row) => sum + Number(row.ctrGap || 0), 0);
  const boost = Math.min(80, (aggregate / 10) + (ctrGap * 300));
  return {
    score: base - boost,
    matchedSignals: [`page_opportunity_${keyword.templateFamily}`],
    matchedPages: matchingPages.slice(0, 3).map((row) => row.path),
  };
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
    result = rule.shellVariables
      ? replaceShellVariables(original, rule.shellVariables)
      : replaceGeneratorIndexMeta(original, rule);
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

function pickRecommendations(siteConfig, state, payload, competitorIntel, gscSignals, templateSignals) {
  const rules = siteConfig.rulesByQuery || {};

  if (payload && Array.isArray(payload.topRecommendations) && payload.topRecommendations.length > 0) {
    return payload.topRecommendations;
  }

  const keywords = (siteConfig.targetKeywords || [])
    .filter((keyword) => rules[keyword.query])
    .map((keyword) => {
      const competitorScore = scoreKeywordByCompetitorIntel(keyword, competitorIntel);
      const gscScore = scoreKeywordByGsc(keyword, gscSignals);
      const familyScore = scoreKeywordByTemplateFamily(keyword, templateSignals);
      const pageScore = scoreKeywordByPageOpportunities(keyword, gscSignals);
      const combinedScore = Math.min(competitorScore.score, gscScore.score, familyScore.score, pageScore.score);
      return {
        ...keyword,
        competitorScore: competitorScore.score,
        gscScore: gscScore.score,
        familyScore: familyScore.score,
        pageScore: pageScore.score,
        combinedScore,
        matchedPages: pageScore.matchedPages || [],
        matchedSignals: [
          ...(competitorScore.matchedSignals || []),
          ...(gscScore.matchedSignals || []),
          ...(familyScore.matchedSignals || []),
          ...(pageScore.matchedSignals || []),
        ],
      };
    })
    .sort((a, b) => {
      if (a.combinedScore !== b.combinedScore) return a.combinedScore - b.combinedScore;
      return (a.priority || 99) - (b.priority || 99);
    });

  if (keywords.length === 0) return [];

  const lastIdx = keywords.findIndex((keyword) => keyword.query === state.lastQuery);
  const startIdx = (lastIdx + 1) % keywords.length;
  const rotated = keywords.slice(startIdx).concat(keywords.slice(0, startIdx));
  return rotated.slice(0, MAX_CHANGES).map((keyword) => ({
    query: keyword.query,
    matchedSignals: keyword.matchedSignals || [],
    matchedPages: keyword.matchedPages || [],
  }));
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
  const competitorIntelRaw = readJson(COMPETITOR_INTEL_PATH, null);
  const gscSignalsRaw = readJson(GSC_SIGNAL_PATH, null);
  const templateSignalsRaw = readJson(TEMPLATE_SIGNAL_PATH, null);
  const competitorIntel = isFreshSignal(competitorIntelRaw) ? competitorIntelRaw : null;
  const gscSignals = isFreshSignal(gscSignalsRaw) ? gscSignalsRaw : null;
  const templateSignals = isFreshSignal(templateSignalsRaw) ? templateSignalsRaw : null;
  const recs = pickRecommendations(siteConfig, state, payload, competitorIntel, gscSignals, templateSignals);

  if (recentlyPatched(state.lastRun)) {
    console.log(JSON.stringify({
      site: SITE_KEY,
      changedCount: 0,
      totalChecked: 0,
      skipped: 'recent_patch_cooldown',
      runAt: new Date().toISOString(),
    }));
    return;
  }

  if (shouldHoldout()) {
    console.log(JSON.stringify({
      site: SITE_KEY,
      changedCount: 0,
      totalChecked: 0,
      skipped: 'holdout_experiment',
      holdoutRatio: HOLDOUT_RATIO,
      runAt: new Date().toISOString(),
    }));
    return;
  }

  const runAt = new Date().toISOString();
  const results = [];
  let applied = 0;
  let lastQuery = state.lastQuery;

  for (const rec of recs) {
    if (applied >= MAX_CHANGES) break;
    const key = String(rec.query || '').trim().toLowerCase();
    const rule = rules[key];
    if (!rule) continue;
    if (!isSafeRule(rule)) {
      results.push({
        query: key,
        matchedSignals: rec.matchedSignals || [],
        matchedPages: rec.matchedPages || [],
        file: rule.file,
        changed: false,
        reason: 'rule_quality_guard',
      });
      continue;
    }

    const targets = [rule, ...(Array.isArray(rule.extraTargets) ? rule.extraTargets : [])];
    const ruleResults = targets.map((target) => optimizeFile(siteConfig, target));
    const changed = ruleResults.some((result) => result.changed);

    for (const res of ruleResults) {
      results.push({
        query: key,
        matchedSignals: rec.matchedSignals || [],
        matchedPages: rec.matchedPages || [],
        ...res,
      });
    }

    if (changed) {
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
    competitorIntelLoaded: Boolean(competitorIntel && competitorIntel.insights),
    gscSignalsLoaded: Boolean(gscSignals && Array.isArray(gscSignals.queries)),
    templateSignalsLoaded: Boolean(templateSignals && Array.isArray(templateSignals.families)),
    staleSignalsIgnored: {
      competitorIntel: Boolean(competitorIntelRaw && !competitorIntel),
      gscSignals: Boolean(gscSignalsRaw && !gscSignals),
      templateSignals: Boolean(templateSignalsRaw && !templateSignals),
    },
    qualityGuards: {
      minTitleLength: MIN_TITLE_LENGTH,
      maxTitleLength: MAX_TITLE_LENGTH,
      minDescriptionLength: MIN_DESCRIPTION_LENGTH,
      maxDescriptionLength: MAX_DESCRIPTION_LENGTH,
      minHoursBetweenPatches: MIN_HOURS_BETWEEN_PATCHES,
    },
    holdout: {
      ratio: HOLDOUT_RATIO,
    },
    runAt,
  }));
}

main();
