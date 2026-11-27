"""XUID obfuscation helper. Must match hashXuid() in maps/mp/CenturyPackage/string_utils.gsc.

Not a security boundary: the salt is public and the output space is only ~2^32,
so any candidate XUID can be checked instantly.
"""

import argparse

SALT: str = "c3ntury_bo1"


def hash_xuid(xuid: str) -> str:
    a: int = 7
    b: int = 13

    for char in SALT + xuid.lower():
        a = (a * 31 + ord(char)) % 65521
        b = (b * 37 + ord(char)) % 65519

    return f"{a}_{b}"


def main() -> None:
    parser = argparse.ArgumentParser(description="XUID Hasher")
    parser.add_argument("-x", "--xuid", type=str, required=True, action="append",
                        help="XUID to hash (can be given multiple times)")
    args = parser.parse_args()

    for xuid in args.xuid:
        print(f"{xuid}: {hash_xuid(xuid)}")


if __name__ == "__main__":
    main()
