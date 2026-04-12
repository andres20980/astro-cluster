#!/usr/bin/env python3
import json
import os
import sys
import urllib.request


sites = json.loads(os.environ["GSC_SITES_JSON"])
token = os.environ["OAUTH_TOKEN"]


def inspect(site_url, inspect_url):
    req = urllib.request.Request(
        "https://searchconsole.googleapis.com/v1/urlInspection/index:inspect",
        data=json.dumps(
            {"inspectionUrl": inspect_url, "siteUrl": site_url}
        ).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except Exception as exc:
        return {"error": str(exc)}


results = []

for site_key, domain, site_url in sites:
    inspected_url = f"https://{domain}/"
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
    or item["veredicto"] not in {"PASS", "NEUTRAL", "-"}
    or item["indexacion"] not in {"INDEXING_ALLOWED", "-", "INDEXING_STATE_UNSPECIFIED"}
]

print("")
if problems:
    print("### ⚠️ Incidencias detectadas")
    for item in problems:
        reason = item["error"] or f"{item['cobertura']} / {item['indexacion']}"
        print(f"- `{item['domain']}`: {reason}")
else:
    print("### ✅ Sin incidencias críticas en las home del cluster")

print("")
print("```json")
print(json.dumps(results, ensure_ascii=False, indent=2))
print("```")
