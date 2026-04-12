#!/usr/bin/env python3
import json
import os
import urllib.error
import urllib.request


token = os.environ["OAUTH_TOKEN"]
account = os.environ["ADSENSE_ACCOUNT"]
expected_domains = json.loads(os.environ["EXPECTED_DOMAINS_JSON"])
include_raw = os.environ.get("ADSENSE_INCLUDE_RAW_JSON", "1") != "0"
heading_level = os.environ.get("ADSENSE_HEADING_LEVEL", "##")
heading_title = os.environ.get("ADSENSE_REPORT_TITLE", "💰 Vigilancia de sitios AdSense del cluster")
subheading_level = heading_level + "#"


def fetch(url):
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode()), None
    except urllib.error.HTTPError as exc:
        body = exc.read().decode()
        try:
            payload = json.loads(body)
        except Exception:
            payload = {"error": {"code": exc.code, "message": body.strip() or str(exc)}}
        return payload, payload.get("error") or {"code": exc.code, "message": str(exc)}
    except Exception as exc:
        return {}, {"message": str(exc)}


def state_label(value):
    labels = {
        "READY": "Listo",
        "GETTING_READY": "Preparando",
        "REQUIRES_REVIEW": "Debe revisarse",
        "NEEDS_ATTENTION": "Requiere atención",
        "STATE_UNSPECIFIED": "Sin estado",
        "": "Sin estado",
    }
    return labels.get(value, value)


sites_payload, sites_error = fetch(f"https://adsense.googleapis.com/v2/{account}/sites")
alerts_payload, alerts_error = fetch(f"https://adsense.googleapis.com/v2/{account}/alerts")

sites = sites_payload.get("sites", [])
alerts = alerts_payload.get("alerts", [])
by_domain = {item.get("domain", ""): item for item in sites}


def error_message(error):
    if not error:
        return ""
    message = error.get("message", "Error desconocido")
    status = error.get("status")
    code = error.get("code")
    prefix = " / ".join(str(part) for part in [code, status] if part)
    return f"{prefix}: {message}" if prefix else message

print(f"{heading_level} {heading_title}")
print("")
if sites_error:
    print(f"> No se pudo consultar la API de sitios de AdSense: {error_message(sites_error)}")
else:
    print("| Dominio | Estado AdSense | Auto Ads | Detectado en API |")
    print("|---------|----------------|----------|------------------|")
    for domain in expected_domains:
        item = by_domain.get(domain)
        state = item.get("state", "") if item else ""
        auto_ads = "Sí" if item and item.get("autoAdsEnabled") else "No"
        detected = "Sí" if item else "No"
        print(f"| {domain} | {state_label(state)} | {auto_ads} | {detected} |")

extra_domains = sorted(d for d in by_domain.keys() if d and d not in expected_domains) if not sites_error else []

print("")
if alerts_error:
    print(f"{subheading_level} ⚠️ No se pudieron consultar las alertas de AdSense")
    print(f"- {error_message(alerts_error)}")
elif alerts:
    print(f"{subheading_level} ⚠️ Alertas activas de AdSense")
    for alert in alerts:
        message = alert.get("message", "Sin mensaje")
        severity = alert.get("severity", "SIN_GRAVEDAD")
        print(f"- `{severity}`: {message}")
else:
    print(f"{subheading_level} ✅ Sin alertas activas de AdSense")

pending = [
    domain
    for domain in expected_domains
    if by_domain.get(domain, {}).get("state") in {"GETTING_READY", "REQUIRES_REVIEW", "NEEDS_ATTENTION"} or domain not in by_domain
] if not sites_error else []

print("")
if sites_error:
    print(f"{subheading_level} 🧭 Estado del cluster en AdSense")
    print("- No se pudo determinar el estado por dominio porque la API de sitios no devolvió datos válidos.")
elif pending:
    print(f"{subheading_level} 🧭 Sitios del cluster pendientes en AdSense")
    for domain in pending:
        item = by_domain.get(domain)
        state = state_label(item.get("state", "") if item else "")
        print(f"- `{domain}`: {state or 'No detectado en API'}")
else:
    print(f"{subheading_level} ✅ Todos los sitios del cluster están listos en AdSense")

if extra_domains:
    print("")
    print(f"{subheading_level} ℹ️ Dominios adicionales detectados en la cuenta")
    for domain in extra_domains:
        print(f"- `{domain}`")

if include_raw:
    print("")
    print("```json")
    print(
        json.dumps(
            {
                "sites": sites,
                "alerts": alerts,
                "sites_error": sites_error,
                "alerts_error": alerts_error,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    print("```")
