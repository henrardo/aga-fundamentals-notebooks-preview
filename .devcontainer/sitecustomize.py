"""
GraphAcademy AGA proxy — Python interpreter hook.

Drop this file in `/usr/local/lib/python3.11/sitecustomize.py` (or the
equivalent path for the Codespace's Python). The interpreter auto-loads
sitecustomize.py on EVERY start — including Jupyter kernel restarts and
new terminal Python sessions — so the patch lands without the lesson
code having to know about it.

What it does:
    Monkey-patches `graphdatascience.session.aura_api.AuraApi.base_uri` to
    return the GraphAcademy proxy URL instead of `api.neo4j.io`. Both the
    OAuth token endpoint and the sessions/instances/tenants endpoints
    derive from `base_uri`, so one patch redirects everything.

Why monkey-patching:
    The `AuraApi.__init__` doesn't take a `base_url` parameter, and the
    static `base_uri(aura_env)` only supports a small set of preset env
    names (production / staging / dev). Asking the lesson author to pass
    `aura_env=...` would put GA-specific syntax in lesson code; we want
    canonical Aura SDK code that copy-pastes to any notebook unchanged.

Failure modes:
    - GA_AGA_PROXY_URL not set → no patch, real Aura is used. Safe default.
    - graphdatascience not installed → ImportError silently ignored; the
      next thing the user does will surface the missing package itself.
"""
import os


def _install_aga_proxy_patch():
    proxy = os.environ.get('GA_AGA_PROXY_URL')
    if not proxy:
        return
    try:
        from graphdatascience.session.aura_api import AuraApi
    except ImportError:
        return
    AuraApi.base_uri = staticmethod(lambda aura_env=None: proxy)


_install_aga_proxy_patch()
