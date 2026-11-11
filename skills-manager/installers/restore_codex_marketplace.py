#!/usr/bin/env python3
"""Restore a missing Ponytail registration from a verified Codex cache."""

import argparse
import copy
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

try:
    import tomllib
except ImportError:
    sys.exit("ERROR: Ponytail marketplace recovery requires Python 3.11 or newer")


NOT_NEEDED = 3
OFFICIAL_SOURCES = {
    "dietrichgebert/ponytail",
    "https://github.com/dietrichgebert/ponytail",
    "https://github.com/dietrichgebert/ponytail.git",
    "git@github.com:dietrichgebert/ponytail.git",
    "ssh://git@github.com/dietrichgebert/ponytail.git",
}


def read_config(path):
    try:
        return path.read_bytes()
    except FileNotFoundError:
        return None


def restore(codex_dir, check=False):
    config = codex_dir / "config.toml"
    target = config.resolve()
    before = read_config(target)
    data = tomllib.loads((before or b"").decode("utf-8"))
    if "ponytail" in data.get("marketplaces", {}):
        return NOT_NEEDED

    cache = codex_dir / ".tmp" / "marketplaces" / "ponytail"
    if not cache.is_dir():
        return NOT_NEEDED
    record = json.loads((cache / ".codex-marketplace-install.json").read_text())
    source = record.get("source")
    if record.get("source_type") != "git" or not isinstance(source, str) or source.lower() not in OFFICIAL_SOURCES:
        raise ValueError("cached marketplace is not the official Ponytail Git source; registration was not changed")

    catalog = cache / ".agents" / "plugins" / "marketplace.json"
    if not catalog.exists():
        catalog = cache / ".claude-plugin" / "marketplace.json"
    if json.loads(catalog.read_text()).get("name") != "ponytail":
        raise ValueError("cached marketplace name is not ponytail")

    registration = {"source_type": "git", "source": source}
    ref = record.get("ref_name")
    sparse = record.get("sparse_paths", [])
    if ref is not None:
        if not isinstance(ref, str) or not ref:
            raise ValueError("cached Git ref is invalid")
        registration["ref"] = ref
    if not isinstance(sparse, list) or any(not isinstance(p, str) or not p for p in sparse):
        raise ValueError("cached sparse checkout paths are invalid")
    if sparse:
        registration["sparse_paths"] = sparse

    addition = "\n[marketplaces.ponytail]\n" + "".join(
        f"{key} = {json.dumps(value)}\n" for key, value in registration.items()
    )
    original = before or b""
    separator = b"" if not original or original.endswith(b"\n") else b"\n"
    after = original + separator + addition.encode("utf-8")
    expected = copy.deepcopy(data)
    expected.setdefault("marketplaces", {})["ponytail"] = registration
    if tomllib.loads(after.decode("utf-8")) != expected:
        raise ValueError("registration would change unrelated configuration")
    if check:
        return 0

    mode = stat.S_IMODE(target.stat().st_mode) if before is not None else 0o600
    backup = None
    if before is not None:
        backups = codex_dir / "backups"
        backups.mkdir(mode=0o700, parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix="ponytail-registration-", dir=backups)) / "config.toml"
        backup.write_bytes(before)
        backup.chmod(0o600)

    fd, temporary = tempfile.mkstemp(prefix=".ponytail-config-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            os.fchmod(output.fileno(), mode)
            output.write(after)
            output.flush()
            os.fsync(output.fileno())
        if config.resolve() != target or read_config(target) != before:
            raise ValueError("configuration changed during recovery; retry after the other writer finishes")
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)

    print("  Codex marketplace registration restored from cache: ponytail")
    if backup:
        print(f"  Configuration backup: {backup}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("codex_dir", type=Path)
    parser.add_argument("--check", action="store_true", help="validate recovery without writing")
    args = parser.parse_args()
    try:
        return restore(args.codex_dir, args.check)
    except (OSError, ValueError, TypeError, AttributeError) as error:
        print(f"ERROR: Ponytail marketplace recovery: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
