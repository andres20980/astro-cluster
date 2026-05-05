#!/usr/bin/env python3
import argparse
import json
import os
import sys
import urllib.error
import urllib.request


def api_json(url, token, method="GET", body=None):
    data = None
    headers = {"Authorization": f"Bearer {token}"}
    quota_project = os.environ.get("GOOGLE_CLOUD_QUOTA_PROJECT", "").strip()
    include_quota_project = os.environ.get("GOOGLE_INCLUDE_QUOTA_PROJECT_HEADER", "").strip() == "1"
    if include_quota_project and quota_project:
        headers["x-goog-user-project"] = quota_project
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(raw)
        except Exception:
            payload = {"error": {"message": raw or str(exc)}}
        return exc.code, payload


def update_display_name(resource, token, wanted_name, apply):
    base_url = f"https://analyticsadmin.googleapis.com/v1beta/{resource}"
    status, current = api_json(base_url, token)
    if status >= 400:
        raise RuntimeError(current.get("error", {}).get("message", f"HTTP {status}"))

    current_name = current.get("displayName", "")
    if current_name == wanted_name:
        print(f"OK    {resource} -> {wanted_name}")
        return False

    if not apply:
        print(f"MISS  {resource} -> {current_name!r} != {wanted_name!r}")
        return False

    status, updated = api_json(
        f"{base_url}?updateMask=displayName",
        token,
        method="PATCH",
        body={"displayName": wanted_name},
    )
    if status >= 400:
        raise RuntimeError(updated.get("error", {}).get("message", f"HTTP {status}"))

    print(f"UPDATED {resource} -> {updated.get('displayName', wanted_name)}")
    return True


def main():
    parser = argparse.ArgumentParser(description="Keep GA4 property and stream names aligned.")
    parser.add_argument("--token", required=True)
    parser.add_argument("--property", required=True)
    parser.add_argument("--property-display-name", required=True)
    parser.add_argument("--stream", required=True)
    parser.add_argument("--stream-display-name", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    print("━━━ GA4 Property / Stream Names ━━━")
    changed = 0
    changed += update_display_name(
        args.property,
        args.token,
        args.property_display_name,
        args.apply,
    )
    changed += update_display_name(
        args.stream,
        args.token,
        args.stream_display_name,
        args.apply,
    )
    print("")
    print(f"Cambios aplicados: {changed}" if args.apply else "Dry run completado.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
