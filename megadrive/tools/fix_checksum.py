#!/usr/bin/env python3
"""Write the standard Mega Drive checksum at 0x18E."""
from __future__ import annotations

import sys
from pathlib import Path


def checksum(data: bytes) -> int:
    total = 0
    for i in range(0x200, len(data) - 1, 2):
        total = (total + int.from_bytes(data[i : i + 2], "big")) & 0xFFFF
    return total


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "out/rom.bin")
    data = bytearray(path.read_bytes())
    if data[0x100:0x110] != b"SEGA MEGA DRIVE ":
        raise SystemExit(f"{path}: missing SEGA MEGA DRIVE header")
    ck = checksum(data)
    data[0x18E:0x190] = ck.to_bytes(2, "big")
    end = len(data) - 1
    data[0x1A4:0x1A8] = end.to_bytes(4, "big")
    path.write_bytes(data)
    print(f"{path}: checksum={ck:04X} size={len(data)} header={data[0x120:0x150].split(b'  ')[0].decode('ascii', 'ignore')}")


if __name__ == "__main__":
    main()
