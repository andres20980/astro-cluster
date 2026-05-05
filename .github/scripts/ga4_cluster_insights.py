#!/usr/bin/env python3
import argparse
import json
import re
import sys
import urllib.error
import urllib.request


PRIMARY_DAYS = 7
UI_DAYS = 30
KEY_EVENTS = {
    "tool_start",
    "chart_calculated",
    "compatibility_view",
    "numerology_calculated",
    "tarot_reading_complete",
    "internal_tool_click",
    "advertiser_cta_click",
    "interpretation_requested",
    "interpretation_generated",
    "upload_certificate",
}


def run_report(property_name, token, payload):
    req = urllib.request.Request(
        f"https://analyticsdata.googleapis.com/v1beta/{property_name}:runReport",
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode()
        try:
            detail = json.loads(raw)
        except json.JSONDecodeError:
            detail = {"error": raw}
        raise RuntimeError(json.dumps(detail, ensure_ascii=False)) from exc


def metric(row, index):
    values = row.get("metricValues") or []
    if index >= len(values):
        return 0.0
    return float(values[index].get("value", 0) or 0)


def dimension(row, index):
    values = row.get("dimensionValues") or []
    if index >= len(values):
        return ""
    return values[index].get("value", "")


def total_row(data):
    rows = data.get("rows") or []
    return rows[0] if rows else {"metricValues": []}


def fmt_num(value):
    if value is None:
        return "N/D"
    return f"{value:,.0f}".replace(",", ".")


def fmt_float(value, digits=1):
    if value is None:
        return "N/D"
    return f"{value:.{digits}f}"


def fmt_pct(value):
    if value is None:
        return "N/D"
    return f"{value * 100:.1f}%"


def md(value):
    text = str(value or "(not set)")
    return text.replace("|", "\\|").replace("\n", " ")


def env_key(name):
    return re.sub(r"[^A-Z0-9_]", "_", name.upper())


def date_range(days):
    return {"startDate": f"{days}daysAgo", "endDate": "today"}


def fetch_totals(property_name, token, days):
    data = run_report(
        property_name,
        token,
        {
            "dateRanges": [date_range(days)],
            "metrics": [
                {"name": "sessions"},
                {"name": "activeUsers"},
                {"name": "totalUsers"},
                {"name": "newUsers"},
                {"name": "screenPageViews"},
                {"name": "eventCount"},
                {"name": "engagedSessions"},
                {"name": "engagementRate"},
                {"name": "averageSessionDuration"},
                {"name": "bounceRate"},
            ],
        },
    )
    row = total_row(data)
    return {
        "sessions": metric(row, 0),
        "active_users": metric(row, 1),
        "total_users": metric(row, 2),
        "new_users": metric(row, 3),
        "views": metric(row, 4),
        "events": metric(row, 5),
        "engaged_sessions": metric(row, 6),
        "engagement_rate": metric(row, 7),
        "avg_session_duration": metric(row, 8),
        "bounce_rate": metric(row, 9),
    }


def fetch_breakdown(property_name, token, days, dimensions, metrics, order_metric, limit=10):
    return run_report(
        property_name,
        token,
        {
            "dateRanges": [date_range(days)],
            "dimensions": [{"name": item} for item in dimensions],
            "metrics": [{"name": item} for item in metrics],
            "orderBys": [{"metric": {"metricName": order_metric}, "desc": True}],
            "limit": limit,
        },
    ).get("rows") or []


def event_counts(rows):
    out = {}
    for row in rows:
        name = dimension(row, 0)
        if name:
            out[name] = metric(row, 0)
    return out


def print_totals_table(label, totals):
    print(f"#### {label}")
    print("| Métrica | Valor |")
    print("|---------|-------|")
    print(f"| Sesiones | {fmt_num(totals['sessions'])} |")
    print(f"| Usuarios activos | {fmt_num(totals['active_users'])} |")
    print(f"| Usuarios totales | {fmt_num(totals['total_users'])} |")
    print(f"| Usuarios nuevos | {fmt_num(totals['new_users'])} |")
    print(f"| Vistas / visitas de página | {fmt_num(totals['views'])} |")
    print(f"| Eventos | {fmt_num(totals['events'])} |")
    print(f"| Sesiones con interacción | {fmt_num(totals['engaged_sessions'])} |")
    print(f"| Engagement rate | {fmt_pct(totals['engagement_rate'])} |")
    print(f"| Duración media | {fmt_float(totals['avg_session_duration'])}s |")
    print(f"| Rebote | {fmt_pct(totals['bounce_rate'])} |")
    print("")


def print_rows(title, headers, rows, dims_count, metric_formatters=None):
    print(f"#### {title}")
    print("| " + " | ".join(headers) + " |")
    print("|" + "|".join(["---"] * len(headers)) + "|")
    if not rows:
        print("| Sin datos | " + " | ".join(["-"] * (len(headers) - 1)) + " |")
        print("")
        return
    metric_formatters = metric_formatters or []
    for row in rows:
        cells = [md(dimension(row, index)) for index in range(dims_count)]
        for index in range(len(row.get("metricValues") or [])):
            value = metric(row, index)
            formatter = metric_formatters[index] if index < len(metric_formatters) else fmt_num
            cells.append(formatter(value))
        print("| " + " | ".join(cells) + " |")
    print("")


def write_env(path, values):
    if not path:
        return
    with open(path, "w", encoding="utf-8") as fh:
        for key in sorted(values):
            value = values[key]
            if value is None:
                continue
            if isinstance(value, float):
                fh.write(f"{env_key(key)}={value:.6f}\n")
            else:
                fh.write(f"{env_key(key)}={value}\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--property", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--primary-days", type=int, default=PRIMARY_DAYS)
    parser.add_argument("--ui-days", type=int, default=UI_DAYS)
    parser.add_argument("--env-output")
    args = parser.parse_args()

    primary = fetch_totals(args.property, args.token, args.primary_days)
    ui = fetch_totals(args.property, args.token, args.ui_days)

    channels = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["sessionDefaultChannelGroup"],
        ["sessions", "activeUsers", "screenPageViews"],
        "sessions",
        limit=12,
    )
    hosts = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["hostName"],
        ["sessions", "activeUsers", "screenPageViews", "eventCount"],
        "sessions",
        limit=20,
    )
    pages = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["hostName", "pagePath", "pageTitle"],
        ["screenPageViews", "activeUsers", "eventCount"],
        "screenPageViews",
        limit=15,
    )
    sources = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["sessionSourceMedium"],
        ["sessions", "activeUsers"],
        "sessions",
        limit=12,
    )
    countries = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["country"],
        ["activeUsers", "sessions"],
        "activeUsers",
        limit=10,
    )
    devices = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["deviceCategory"],
        ["sessions", "activeUsers", "screenPageViews"],
        "sessions",
        limit=10,
    )
    events = fetch_breakdown(
        args.property,
        args.token,
        args.primary_days,
        ["eventName"],
        ["eventCount"],
        "eventCount",
        limit=50,
    )
    events_by_name = event_counts(events)
    organic_sessions = sum(
        metric(row, 0)
        for row in channels
        if "organic" in dimension(row, 0).lower()
    )

    print("### Lectura ejecutiva GA4 del cluster")
    print("")
    print(
        "> El milestone usa sesiones de 7 días como métrica de avance. "
        "Para reconciliar la UI de GA4, esta sección incluye también usuarios activos, vistas/visitas de página y eventos a 30 días."
    )
    print("")
    print_totals_table(f"Tracción primaria ({args.primary_days} días)", primary)
    print_totals_table(f"Reconciliación GA4 UI ({args.ui_days} días)", ui)
    print_rows(
        f"Dominio del cluster ({args.primary_days} días)",
        ["Dominio", "Sesiones", "Usuarios activos", "Vistas", "Eventos"],
        hosts,
        1,
    )
    print_rows(
        f"Canales ({args.primary_days} días)",
        ["Canal", "Sesiones", "Usuarios activos", "Vistas"],
        channels,
        1,
    )
    print_rows(
        f"Fuente / medio ({args.primary_days} días)",
        ["Fuente / medio", "Sesiones", "Usuarios activos"],
        sources,
        1,
    )
    print_rows(
        f"Páginas principales ({args.primary_days} días)",
        ["Dominio", "Ruta", "Título", "Vistas", "Usuarios activos", "Eventos"],
        pages,
        3,
    )
    print_rows(
        f"Países ({args.primary_days} días)",
        ["País", "Usuarios activos", "Sesiones"],
        countries,
        1,
    )
    print_rows(
        f"Dispositivos ({args.primary_days} días)",
        ["Dispositivo", "Sesiones", "Usuarios activos", "Vistas"],
        devices,
        1,
    )
    print_rows(
        f"Eventos ({args.primary_days} días)",
        ["Evento", "Total"],
        events[:20],
        1,
    )

    env = {
        "sessions": primary["sessions"],
        "active_users": primary["active_users"],
        "users": primary["total_users"],
        "new_users": primary["new_users"],
        "views": primary["views"],
        "event_count": primary["events"],
        "engaged_sessions": primary["engaged_sessions"],
        "engagement_rate": primary["engagement_rate"],
        "duration": primary["avg_session_duration"],
        "bounce": primary["bounce_rate"],
        "organic_sessions": organic_sessions,
        "chart_calculated": events_by_name.get("chart_calculated", 0),
        "interpretation_generated": events_by_name.get("interpretation_generated", 0),
        "internal_tool_click": events_by_name.get("internal_tool_click", 0),
        "advertiser_cta_click": events_by_name.get("advertiser_cta_click", 0),
        "sessions_30d": ui["sessions"],
        "active_users_30d": ui["active_users"],
        "users_30d": ui["total_users"],
        "new_users_30d": ui["new_users"],
        "views_30d": ui["views"],
        "event_count_30d": ui["events"],
        "engaged_sessions_30d": ui["engaged_sessions"],
        "engagement_rate_30d": ui["engagement_rate"],
    }
    write_env(args.env_output, env)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ga4_cluster_insights failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
