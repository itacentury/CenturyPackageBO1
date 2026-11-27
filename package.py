# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Build the PS3 release zip in the folder layout described in README.md.

Usage: uv run package.py X.Y.Z

X.Y.Z must be an existing git tag. Files are read from that tag with
`git archive`, never from the working folder, so untracked, ignored or
uncommitted files cannot end up in the zip.
"""

import argparse
import subprocess
import sys
import tarfile
import zipfile
from pathlib import Path, PurePosixPath

REPO_ROOT: Path = Path(__file__).resolve().parent
MOD_NAME: str = "CenturyPackageBO1"
MOD_PREFIX: PurePosixPath = PurePosixPath("mp", MOD_NAME)
# silinium/maps comes second so its stubs.gsc replaces the PC no-op version
SOURCE_DIRS: list[PurePosixPath] = [PurePosixPath("maps"), PurePosixPath("silinium", "maps")]


def git(*args: str) -> list[str]:
    return ["git", "-C", str(REPO_ROOT), *args]


def resolve_tag(version: str) -> None:
    """Exit unless `version` is an existing tag pointing to a commit."""
    result = subprocess.run(
        git("rev-parse", "--verify", "--quiet", f"refs/tags/{version}^{{commit}}"),
        capture_output=True,
        check=False
    )
    if result.returncode != 0:
        sys.exit(f"Tag {version} not found (run `git fetch --tags` if it was created on GitHub)")


def read_tree(version: str) -> dict[PurePosixPath, bytes]:
    """Return the contents of every file under SOURCE_DIRS at tag `version`."""
    proc = subprocess.Popen(
        git("archive", "--format=tar", version, "--", *map(str, SOURCE_DIRS)),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert proc.stdout is not None and proc.stderr is not None
    files: dict[PurePosixPath, bytes] = {}
    with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
        for member in tar:
            if not member.isfile():
                continue
            data = tar.extractfile(member)
            assert data is not None
            files[PurePosixPath(member.name)] = data.read()
    stderr = proc.stderr.read().decode(errors="replace")
    if proc.wait() != 0:
        sys.exit(f"git archive failed: {stderr.strip()}")
    return files


def collect_entries(files: dict[PurePosixPath, bytes]) -> dict[str, bytes]:
    """Map zip entry names to file contents; later SOURCE_DIRS override earlier ones."""
    entries: dict[str, bytes] = {}
    for source_dir in SOURCE_DIRS:
        matched = sorted(path for path in files if path.is_relative_to(source_dir))
        if not matched:
            sys.exit(f"No files under {source_dir} in the tag")
        for path in matched:
            relative = path.relative_to(source_dir.parent)
            entries[str(MOD_PREFIX / relative)] = files[path]
    return entries


def build_zip(version: str, output_dir: Path) -> Path:
    resolve_tag(version)
    entries = collect_entries(read_tree(version))

    output_dir.mkdir(parents=True, exist_ok=True)
    zip_path = output_dir / f"{MOD_NAME}-{version}-PS3.zip"

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(f"mp/{MOD_NAME}.mod", "")
        for arcname in sorted(entries):
            archive.writestr(arcname, entries[arcname])

    print(f"Wrote {zip_path} ({len(entries) + 1} files from tag {version})")
    return zip_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the PS3 release zip from a git tag")
    parser.add_argument("version", type=str, help="Existing release tag, e.g. 3.0.0")
    parser.add_argument("-o", "--output", type=Path, default=REPO_ROOT,
                        help="Output directory (default: repository root)")
    args = parser.parse_args()

    build_zip(args.version, args.output)


if __name__ == "__main__":
    main()
