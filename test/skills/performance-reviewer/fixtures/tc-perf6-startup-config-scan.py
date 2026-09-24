"""Load and validate the plugin manifest when the worker process starts."""

import json
import sys
from pathlib import Path

MANIFEST = Path(__file__).parent / "plugins.json"


def load_plugins(path: Path = MANIFEST) -> list[dict]:
    plugins = json.loads(path.read_text())

    for i, plugin in enumerate(plugins):
        for other in plugins[i + 1 :]:
            if plugin["name"] == other["name"]:
                sys.exit(f"duplicate plugin name: {plugin['name']}")
            if set(plugin["provides"]) & set(other["provides"]):
                clash = sorted(set(plugin["provides"]) & set(other["provides"]))
                sys.exit(
                    f"plugins {plugin['name']} and {other['name']} "
                    f"both provide: {', '.join(clash)}"
                )

    for plugin in plugins:
        for dep in plugin.get("requires", []):
            if not any(dep in p["provides"] for p in plugins):
                sys.exit(f"{plugin['name']} requires {dep}, which nothing provides")

    return sorted(plugins, key=lambda p: p.get("priority", 0), reverse=True)


if __name__ == "__main__":
    for p in load_plugins():
        print(f"{p['name']:<24} priority={p.get('priority', 0)}")
