import argparse

# Must match hashXuid() in maps/mp/gametypes/string_utils.gsc
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
