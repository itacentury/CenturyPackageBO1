# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Build the PS3 release zip in the folder layout described in README.md.

Usage: uv run package.py X.Y.Z
"""

import argparse
import sys
import zipfile
from pathlib import Path, PurePosixPath

REPO_ROOT: Path = Path(__file__).resolve().parent
MOD_NAME: str = "CenturyPackageBO1"
MOD_PREFIX: PurePosixPath = PurePosixPath("mp", MOD_NAME)


def collect_files(source_dirs: list[Path]) -> dict[str, Path]:
    """Map zip entry names to source files; later directories override earlier ones."""
    entries: dict[str, Path] = {}
    for source_dir in source_dirs:
        for path in sorted(source_dir.rglob("*")):
            if not path.is_file():
                continue
            relative = path.relative_to(source_dir.parent).as_posix()
            entries[str(MOD_PREFIX / relative)] = path
    return entries


def build_zip(version: str, output_dir: Path) -> Path:
    # silinium/maps comes second so its stubs.gsc replaces the PC no-op version
    source_dirs = [REPO_ROOT / "maps", REPO_ROOT / "silinium" / "maps"]
    for source_dir in source_dirs:
        if not source_dir.is_dir():
            sys.exit(f"Missing directory: {source_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    zip_path = output_dir / f"{MOD_NAME}-{version}-PS3.zip"
    entries = collect_files(source_dirs)

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(f"mp/{MOD_NAME}.mod", "")
        for arcname, path in entries.items():
            archive.write(path, arcname)

    print(f"Wrote {zip_path} ({len(entries) + 1} files)")
    return zip_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the PS3 release zip")
    parser.add_argument("version", type=str, help="Release version, e.g. 3.0.0")
    parser.add_argument("-o", "--output", type=Path, default=REPO_ROOT,
                        help="Output directory (default: repository root)")
    args = parser.parse_args()

    build_zip(args.version, args.output)


if __name__ == "__main__":
    main()
