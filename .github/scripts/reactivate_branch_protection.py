#!/usr/bin/env python3
"""
Reactivate master branch protection with required SEO checks.
Run from GitHub Actions or manually after SEO automation is in place.
"""
import subprocess
import json
import sys

def apply_branch_protection():
    protection_config = {
        "required_status_checks": {
            "strict": True,
            "contexts": [
                "seo-required-gate",
                "seo-config-guard",
                "seo-rules-guard",
                "seo-python-sanity"
            ]
        },
        "enforce_admins": True,
        "required_pull_request_reviews": None,
        "restrictions": None,
        "allow_force_pushes": False,
        "allow_deletions": False,
        "required_linear_history": False,
        "block_creations": False,
        "required_conversation_resolution": False,
        "lock_branch": False,
        "allow_fork_syncing": True
    }

    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(protection_config, f)
        config_file = f.name

    try:
        result = subprocess.run([
            'gh', 'api', '-X', 'PUT',
            'repos/andres20980/astro-cluster/branches/master/protection',
            '--input', config_file
        ], capture_output=True, text=True)

        if result.returncode != 0:
            print(f"Error: {result.stderr}", file=sys.stderr)
            return False

        print("✅ Branch protection reactivated with required SEO checks")
        return True
    finally:
        import os
        os.unlink(config_file)

if __name__ == "__main__":
    sys.exit(0 if apply_branch_protection() else 1)
