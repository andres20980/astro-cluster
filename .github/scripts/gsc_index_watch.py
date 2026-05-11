#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request


sites = json.loads(os.environ["GSC_SITES_JSON"])
token = os.environ["OAUTH_TOKEN"]
quota_project = os.environ.get("GOOGLE_CLOUD_QUOTA_PROJECT", "").strip()
skip_domains_raw = os.environ.get("GSC_INDEX_SKIP_DOMAINS", "")
skip_domains = {
    domain.strip().lower()
    for domain in skip_domains_raw.split(",")
    if domain.strip()
}


def inspect(site_url, inspect_url):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    if quota_project:
        headers["X-Goog-User-Project"] = quota_project

    req = urllib.request.Request(
        "https://searchconsole.googleapis.com/v1/urlInspection/index:inspect",
        data=json.dumps(
            {"inspectionUrl": inspect_url, "siteUrl": site_url}
        ).encode(),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        if exc.code == 403:
            return {"error": f"403 Acceso denegado — dominio no verificado en Search Console (añadir en https://search.google.com/search-console/welcome)"}
        return {"error": f"HTTP Error {exc.code}: {exc.reason}"}
    except Exception as exc:
        return {"error": str(exc)}


results = []

for site_key, domain, site_url in sites:
    inspected_url = f"https://{domain}/"
    if domain.lower() in skip_domains:
        raw = {
            "error": (
                "SKIPPED por configuración (dominio no verificado o en pausa). "
                "Quita el dominio de GSC_INDEX_SKIP_DOMAINS cuando quede verificado."
            )
        }
    else:
        raw = inspect(site_url, inspected_url)
    inspection = raw.get("inspectionResult", {})
    index = inspection.get("indexStatusResult", {})
    mobile = inspection.get("mobileUsabilityResult", {})
    rich = inspection.get("richResultsResult", {})

    results.append(
        {
            "site_key": site_key,
            "domain": domain,
            "url": inspected_url,
            "veredicto": index.get("verdict", "-"),
            "cobertura": index.get("coverageState", "-"),
            "indexacion": index.get("indexingState", "-"),
            "ultimo_rastreo": index.get("lastCrawlTime", "-"),
            "robots": index.get("robotsTxtState", "-"),
            "fetch": index.get("pageFetchState", "-"),
            "movil": mobile.get("verdict", "-"),
            "rich": rich.get("verdict", "-") if rich else "-",
            "error": raw.get("error", ""),
        }
    )


print("## 🔎 Vigilancia de indexación del cluster")
print("")
print("| Dominio | Veredicto | Cobertura | Estado de indexación | Robots | Fetch | Móvil |")
print("|---------|-----------|-----------|----------------------|--------|-------|-------|")
for item in results:
    print(
        f"| {item['domain']} | {item['veredicto']} | {item['cobertura']} | "
        f"{item['indexacion']} | {item['robots']} | {item['fetch']} | {item['movil']} |"
    )

problems = [
    item
    for item in results
    if item["error"]
    and not item["error"].startswith("SKIPPED por configuración")
]

non_error_problems = [
    item
    for item in results
    if (
        not item["error"]
        and (
            item["veredicto"] not in {"PASS", "NEUTRAL", "-"}
            or item["indexacion"] not in {"INDEXING_ALLOWED", "-", "INDEXING_STATE_UNSPECIFIED"}
        )
    )
]

problems.extend(non_error_problems)

skipped = [item for item in results if item["error"].startswith("SKIPPED por configuración")]

print("")
if problems:
    print("### ⚠️ Incidencias detectadas")
    for item in problems:
        reason = item["error"] or f"{item['cobertura']} / {item['indexacion']}"
        print(f"- `{item['domain']}`: {reason}")
else:
    print("### ✅ Sin incidencias críticas en las home del cluster")

if skipped:
    print("")
    print("### ⏭️ Dominios omitidos por configuración")
    for item in skipped:
        print(f"- `{item['domain']}`: {item['error']}")

print("")
print("```json")
print(json.dumps(results, ensure_ascii=False, indent=2))
print("```")
