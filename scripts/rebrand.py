#!/usr/bin/env python3
"""
Rebrand script: replace all Monero references with Velkavo in file contents.
Run from the repo root: python3 scripts/rebrand.py
"""

import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Directories and files to skip entirely
SKIP_PATHS = {
    os.path.join(REPO_ROOT, "build"),
    os.path.join(REPO_ROOT, ".git"),
    os.path.join(REPO_ROOT, "utils", "gpg_keys", "moneromooo.asc"),
    os.path.join(REPO_ROOT, "scripts", "rebrand.py"),  # don't rewrite ourselves
}

# File extensions to process (text files only)
TEXT_EXTENSIONS = {
    ".cpp", ".h", ".c", ".cc", ".cxx", ".inl", ".ipp", ".tpp", ".txx",
    ".py", ".sh", ".bash",
    ".md", ".txt", ".rst",
    ".conf", ".service", ".plist",
    ".cmake", ".ts", ".proto",
    ".json", ".yaml", ".yml",
    ".fish", ".supp", ".toml",
    ".iss", ".in", ".am",
}
# Also process files named exactly CMakeLists.txt or Makefile
TEXT_FILENAMES = {"CMakeLists.txt", "Makefile", "Dockerfile"}

# Ordered replacement pairs — most specific first to avoid partial matches
# Each entry is (plain_string, replacement) OR (re_pattern, replacement, re.flags)
REPLACEMENTS = [
    # --- Phase 1: Specific compound identifiers ---
    # moneropulse URLs (longest first)
    ("checkpoints.moneropulse.co",  "checkpoints.velkavo.com"),
    ("checkpoints.moneropulse.net", "checkpoints.velkavo.com"),
    ("checkpoints.moneropulse.org", "checkpoints.velkavo.com"),
    ("testpoints.moneropulse.co",   "testpoints.velkavo.com"),
    ("testpoints.moneropulse.net",  "testpoints.velkavo.com"),
    ("testpoints.moneropulse.org",  "testpoints.velkavo.com"),
    ("updates.moneropulse.ch",      "updates.velkavo.com"),
    ("updates.moneropulse.co",      "updates.velkavo.com"),
    ("updates.moneropulse.de",      "updates.velkavo.com"),
    ("updates.moneropulse.fr",      "updates.velkavo.com"),
    ("updates.moneropulse.net",     "updates.velkavo.com"),
    ("updates.moneropulse.org",     "updates.velkavo.com"),
    ("updates.moneropulse.se",      "updates.velkavo.com"),
    ("moneropulse",                 "velkavopulse"),
    # Daemon name (before generic monero)
    ("MONEROD",                     "VELKAROD"),
    ("Monerod",                     "Velkarod"),
    ("monerod",                     "velkarod"),
    # Tool names
    ("monero-wallet-cli",           "velkavo-wallet-cli"),
    ("monero-wallet-rpc",           "velkavo-wallet-rpc"),
    ("monero-gen-multisig",         "velkavo-gen-multisig"),
    ("monero-blockchain",           "velkavo-blockchain"),
    # Crypto layer
    ("monero-crypto",               "velkavo-crypto"),
    ("monero_crypto",               "velkavo_crypto"),
    # Protobuf / trezor
    ("messages-monero",             "messages-velkavo"),
    ("messages_monero",             "messages_velkavo"),
    ("hw.trezor.messages.monero",   "hw.trezor.messages.velkavo"),
    # Subunit names
    ("millinero",                   "millivkavo"),
    ("micronero",                   "microvkavo"),
    ("nanonero",                    "nanovkavo"),
    ("piconero",                    "picovkavo"),
    # Transaction file default name
    ("unsigned_monero_tx",          "unsigned_velkavo_tx"),
    # Copyright
    ("The Monero Project",          "Velkavo"),
    # --- Phase 2: General case replacements ---
    ("MONERO",                      "VELKAVO"),
    ("Monero",                      "Velkavo"),
    ("monero",                      "velkavo"),
    # --- Phase 3: Ticker (word-boundary regex) ---
    # Stored as tuple of 3 to signal regex mode
    (r"\bXMR\b",                    "VKV",          re.MULTILINE),
]

# Binary file sniff: if first 8KB contains a null byte, skip
def is_binary(path):
    try:
        with open(path, "rb") as f:
            chunk = f.read(8192)
            return b"\x00" in chunk
    except Exception:
        return True

def should_process(path):
    # Check skip paths
    for skip in SKIP_PATHS:
        if path == skip or path.startswith(skip + os.sep):
            return False
    # Check extension or filename
    basename = os.path.basename(path)
    ext = os.path.splitext(basename)[1].lower()
    if basename in TEXT_FILENAMES or ext in TEXT_EXTENSIONS:
        return True
    return False

def apply_replacements(text):
    for entry in REPLACEMENTS:
        if len(entry) == 3:
            pattern, repl, flags = entry
            text = re.sub(pattern, repl, text, flags=flags)
        else:
            old, new = entry
            text = text.replace(old, new)
    return text

def process_file(path):
    if is_binary(path):
        return False
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            original = f.read()
    except Exception as e:
        print(f"  SKIP (read error): {path}: {e}")
        return False

    updated = apply_replacements(original)
    if updated == original:
        return False

    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(updated)
    except Exception as e:
        print(f"  ERROR (write): {path}: {e}")
        return False

    return True

def main():
    changed = []
    skipped = 0

    for dirpath, dirnames, filenames in os.walk(REPO_ROOT):
        # Prune skip directories in-place so os.walk doesn't descend
        dirnames[:] = [
            d for d in dirnames
            if not any(
                os.path.join(dirpath, d) == skip or
                os.path.join(dirpath, d).startswith(skip + os.sep)
                for skip in SKIP_PATHS
            )
        ]

        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            if not should_process(filepath):
                skipped += 1
                continue
            if process_file(filepath):
                rel = os.path.relpath(filepath, REPO_ROOT)
                changed.append(rel)
                print(f"  updated: {rel}")

    print(f"\nDone. {len(changed)} file(s) updated, {skipped} skipped.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
