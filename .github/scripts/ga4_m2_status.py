#!/usr/bin/env python3
import argparse
import json
import sys
import urllib.error
import urllib.request


M2_SESSIONS_TARGET = 1500
ORGANIC_TACTICAL_TARGET = 120
RECIRCULATION_EVENT_TARGET = 6
MEDITATION_HOST = "meditacion-chakras.es"


def run_report(property_name, token, payload):
    url = f"https://analyticsdata.googleapis.com/v1beta/{property_name}:runReport"
    req = urllib.request.Request(
        url,
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


def pct(value):
    return f"{value * 100:.1f}%"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--property", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--days", type=int, default=7)
    args = parser.parse_args()

    date_range = {"startDate": f"{args.days}daysAgo", "endDate": "today"}

    totals = run_report(
        args.property,
        args.token,
        {
            "dateRanges": [date_range],
            "metrics": [
                {"name": "sessions"},
                {"name": "totalUsers"},
                {"name": "screenPageViews"},
                {"name": "averageSessionDuration"},
                {"name": "bounceRate"},
            ],
        },
    )
    channels = run_report(
        args.property,
        args.token,
        {
            "dateRanges": [date_range],
            "dimensions": [{"name": "sessionDefaultChannelGroup"}],
            "metrics": [{"name": "sessions"}, {"name": "totalUsers"}],
            "orderBys": [{"metric": {"metricName": "sessions"}, "desc": True}],
            "limit": 20,
        },
    )
    events = run_report(
        args.property,
        args.token,
        {
            "dateRanges": [date_range],
            "dimensions": [{"name": "eventName"}],
            "metrics": [{"name": "eventCount"}],
            "orderBys": [{"metric": {"metricName": "eventCount"}, "desc": True}],
            "limit": 50,
        },
    )
    hosts = run_report(
        args.property,
        args.token,
        {
            "dateRanges": [date_range],
            "dimensions": [{"name": "hostName"}],
            "metrics": [
                {"name": "sessions"},
                {"name": "totalUsers"},
                {"name": "screenPageViews"},
            ],
            "orderBys": [{"metric": {"metricName": "sessions"}, "desc": True}],
            "limit": 20,
        },
    )

    row = total_row(totals)
    sessions = metric(row, 0)
    users = metric(row, 1)
    views = metric(row, 2)
    avg_duration = metric(row, 3)
    bounce_rate = metric(row, 4)

    organic_sessions = 0.0
    for channel_row in channels.get("rows") or []:
        if dimension(channel_row, 0) == "Organic Search":
            organic_sessions += metric(channel_row, 0)

    recirculation_events = 0.0
    for event_row in events.get("rows") or []:
        if dimension(event_row, 0) == "internal_tool_click":
            recirculation_events += metric(event_row, 0)

    meditation_sessions = 0.0
    meditation_seen = False
    for host_row in hosts.get("rows") or []:
        host = dimension(host_row, 0)
        if host == MEDITATION_HOST or host.endswith(f".{MEDITATION_HOST}"):
            meditation_seen = True
            meditation_sessions += metric(host_row, 0)

    organic_share = organic_sessions / sessions if sessions else 0
    m2_progress = sessions / M2_SESSIONS_TARGET if M2_SESSIONS_TARGET else 0

    print(f"GA4 M2 status ({args.days} days)")
    print("")
    print(f"- Sessions: {sessions:.0f} / {M2_SESSIONS_TARGET} ({pct(m2_progress)})")
    print(f"- Users: {users:.0f}")
    print(f"- Pageviews: {views:.0f}")
    print(f"- Avg session duration: {avg_duration:.1f}s")
    print(f"- Bounce rate: {pct(bounce_rate)}")
    print(f"- Organic sessions: {organic_sessions:.0f} / {ORGANIC_TACTICAL_TARGET} tactical ({pct(organic_sessions / ORGANIC_TACTICAL_TARGET)})")
    print(f"- Organic share: {pct(organic_share)}")
    print(f"- internal_tool_click: {recirculation_events:.0f} / {RECIRCULATION_EVENT_TARGET}")
    print(f"- {MEDITATION_HOST} in GA4: {'yes' if meditation_seen else 'no'}")
    if meditation_seen:
        print(f"- {MEDITATION_HOST} sessions: {meditation_sessions:.0f}")
    print("")
    print("Channels")
    for channel_row in channels.get("rows") or []:
        print(f"- {dimension(channel_row, 0)}: sessions={metric(channel_row, 0):.0f}, users={metric(channel_row, 1):.0f}")
    print("")
    print("Hosts")
    for host_row in hosts.get("rows") or []:
        print(
            f"- {dimension(host_row, 0)}: "
            f"sessions={metric(host_row, 0):.0f}, users={metric(host_row, 1):.0f}, views={metric(host_row, 2):.0f}"
        )
    print("")
    print("Top events")
    for event_row in (events.get("rows") or [])[:15]:
        print(f"- {dimension(event_row, 0)}: {metric(event_row, 0):.0f}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ga4_m2_status failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
