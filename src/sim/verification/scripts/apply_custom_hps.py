#!/usr/bin/env python3
"""Transplant only the hps_subsys module body from custom_hps.v into a
VDS-generated hps_subsys.v, preserving the generated module declaration/ports.
"""
from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract_module_body(text: str, module: str = "hps_subsys") -> str:
    # Find module ... ); then capture until endmodule
    m = re.search(
        rf"module\s+{re.escape(module)}\s*\(",
        text,
        flags=re.MULTILINE,
    )
    if not m:
        raise SystemExit(f"ERROR: module {module} declaration not found in source")
    # Find end of port list: first ");" that closes the module header
    rest = text[m.end() :]
    port_end = rest.find(");")
    if port_end < 0:
        raise SystemExit(f"ERROR: could not find end of port list for {module}")
    body_start = m.end() + port_end + 2
    endm = re.search(r"\bendmodule\b", text[body_start:])
    if not endm:
        raise SystemExit(f"ERROR: endmodule not found for {module}")
    body = text[body_start : body_start + endm.start()]
    return body


def replace_module_body(dest_text: str, new_body: str, module: str = "hps_subsys") -> tuple[str, str]:
    m = re.search(
        rf"module\s+{re.escape(module)}\s*\(",
        dest_text,
        flags=re.MULTILINE,
    )
    if not m:
        raise SystemExit(f"ERROR: module {module} not found in destination")
    rest = dest_text[m.end() :]
    port_end = rest.find(");")
    if port_end < 0:
        raise SystemExit(f"ERROR: could not find end of port list in destination")
    header_end = m.end() + port_end + 2
    header = dest_text[:header_end]
    endm = re.search(r"\bendmodule\b", dest_text[header_end:])
    if not endm:
        raise SystemExit("ERROR: endmodule not found in destination")
    trailer_start = header_end + endm.end()
    trailer = dest_text[trailer_start:]
    # Ensure body has leading/trailing newlines
    body = new_body
    if not body.startswith("\n"):
        body = "\n" + body
    if not body.endswith("\n"):
        body = body + "\n"
    out = header + body + "endmodule" + trailer
    return header, out


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(
            "usage: apply_custom_hps.py <custom_hps.v> <generated_hps_subsys.v>"
        )
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])
    if not src.is_file():
        raise SystemExit(f"ERROR: missing custom_hps source: {src}")
    if not dst.is_file():
        raise SystemExit(f"ERROR: missing generated hps_subsys: {dst}")

    before = sha256(dst)
    src_text = src.read_text(errors="replace")
    dst_text = dst.read_text(errors="replace")
    body = extract_module_body(src_text)
    header, out = replace_module_body(dst_text, body)
    header_hash = hashlib.sha256(header.encode()).hexdigest()

    # Idempotency: if already transformed with same body, skip rewrite
    _, current_out = replace_module_body(dst_text, body)
    if current_out == dst_text:
        print(f"OK: custom_hps body already applied (sha256={before})")
        print(f"header_sha256={header_hash}")
        return

    bak = dst.with_suffix(dst.suffix + ".pre_custom_hps")
    if not bak.exists():
        bak.write_text(dst_text)
    dst.write_text(out)
    after = sha256(dst)
    # Verify header unchanged
    new_header, _ = replace_module_body(out, body)
    new_header_hash = hashlib.sha256(new_header.encode()).hexdigest()
    if new_header_hash != header_hash:
        raise SystemExit("ERROR: generated module header changed after body transplant")
    print(f"OK: transplanted custom_hps body into {dst}")
    print(f"before_sha256={before}")
    print(f"after_sha256={after}")
    print(f"header_sha256={header_hash}")


if __name__ == "__main__":
    main()
