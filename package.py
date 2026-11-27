# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Build the PS3 release zip in the folder layout described in README.md.

Usage: uv run package.py X.Y.Z
   or: python package.py X.Y.Z   (Python 3.10+, standard library only)

X.Y.Z must be an existing git tag. Files are read from that tag with
`git archive`, never from the working folder, so untracked, ignored or
uncommitted files cannot end up in the zip.
"""

import argparse
import io
import re
import subprocess
import sys
import tarfile
import time
import zipfile
from pathlib import Path, PurePosixPath

REPO_ROOT: Path = Path(__file__).resolve().parent
MOD_NAME: str = "CenturyPackageBO1"
MOD_PREFIX: PurePosixPath = PurePosixPath("mp", MOD_NAME)
MOD_FILE: str = f"mp/{MOD_NAME}.mod"
SILINIUM_DIR: PurePosixPath = PurePosixPath("silinium", "maps")
SILINIUM_STUBS: PurePosixPath = SILINIUM_DIR / "mp" / "centurypackage" / "stubs.gsc"
ZIP_MAPS_DIR: PurePosixPath = MOD_PREFIX / "maps"
# Source folder in the repo -> folder in the zip. Later entries override earlier ones,
# so silinium/maps comes second and its stubs.gsc replaces the PC no-op version.
SOURCE_DIRS: dict[PurePosixPath, PurePosixPath] = {
    PurePosixPath("maps"): ZIP_MAPS_DIR,
    SILINIUM_DIR: ZIP_MAPS_DIR,
}
VERSION_PATTERN: re.Pattern[str] = re.compile(r"\d+\.\d+\.\d+")


class PackageError(Exception):
    """A release zip could not be built or failed verification."""


def git(*args: str) -> list[str]:
    """Return a git command line that runs in the repository root."""
    return ["git", "-C", str(REPO_ROOT), *args]


def check_version(version: str) -> None:
    """Raise PackageError unless `version` is MAJOR.MINOR.PATCH, which also keeps it safe in the zip filename."""
    if not VERSION_PATTERN.fullmatch(version):
        raise PackageError(f"Invalid version {version!r}: expected MAJOR.MINOR.PATCH, e.g. 3.0.0 (no v prefix)")


def check_changelog(version: str) -> None:
    """Raise PackageError unless CHANGELOG.md at tag `version` has a `## [version]` section."""
    result = subprocess.run(
        git("show", f"refs/tags/{version}:CHANGELOG.md"),
        capture_output=True,
        check=False
    )
    heading = re.compile(rf"^## \[{re.escape(version)}\]", re.MULTILINE)
    if result.returncode != 0 or not heading.search(result.stdout.decode(errors="replace")):
        raise PackageError(f"CHANGELOG.md at tag {version} has no `## [{version}]` section (see RELEASING.md step 1)")


def resolve_tag(version: str) -> None:
    """Raise PackageError unless `version` is an existing tag pointing to a commit."""
    result = subprocess.run(
        git("rev-parse", "--verify", "--quiet", f"refs/tags/{version}^{{commit}}"),
        capture_output=True,
        check=False
    )
    if result.returncode != 0:
        raise PackageError(f"Tag {version} not found (run `git fetch --tags` if it was created on GitHub)")


def read_tree(version: str) -> dict[PurePosixPath, bytes]:
    """Return the contents of every file under SOURCE_DIRS at tag `version`."""
    result = subprocess.run(
        git("archive", "--format=tar", f"refs/tags/{version}", "--", *map(str, SOURCE_DIRS)),
        capture_output=True,
        check=False
    )
    if result.returncode != 0:
        raise PackageError(f"git archive failed: {result.stderr.decode(errors='replace').strip()}")
    files: dict[PurePosixPath, bytes] = {}
    with tarfile.open(fileobj=io.BytesIO(result.stdout), mode="r") as tar:
        for member in tar:
            if not member.isfile():
                continue
            data = tar.extractfile(member)
            assert data is not None
            files[PurePosixPath(member.name)] = data.read()
    return files


def arcname(path: PurePosixPath, source_dir: PurePosixPath) -> str:
    """Zip entry name for `path` from `source_dir`, e.g. silinium/maps/x -> mp/CenturyPackageBO1/maps/x."""
    return str(SOURCE_DIRS[source_dir] / path.relative_to(source_dir))


def collect_entries(files: dict[PurePosixPath, bytes]) -> dict[str, bytes]:
    """Map zip entry names to file contents; later SOURCE_DIRS override earlier ones."""
    entries: dict[str, bytes] = {}
    for source_dir in SOURCE_DIRS:
        matched = sorted(path for path in files if path.is_relative_to(source_dir))
        if not matched:
            raise PackageError(f"No files under {source_dir} in the tag")
        for path in matched:
            entries[arcname(path, source_dir)] = files[path]
    return entries


def commit_time(rev: str) -> time.struct_time:
    """Return the commit time of `rev` in UTC, used as the timestamp of every zip entry."""
    result = subprocess.run(
        git("log", "-1", "--format=%ct", f"{rev}^{{commit}}"),
        capture_output=True,
        check=False
    )
    if result.returncode != 0:
        raise PackageError(f"Could not read the commit time of {rev}: {result.stderr.decode(errors='replace').strip()}")
    return time.gmtime(int(result.stdout))


def zip_info(name: str, timestamp: time.struct_time) -> zipfile.ZipInfo:
    """Zip entry header with fixed time, OS and permissions, so builds are reproducible."""
    date_time = (timestamp.tm_year, timestamp.tm_mon, timestamp.tm_mday,
                 timestamp.tm_hour, timestamp.tm_min, timestamp.tm_sec)
    info = zipfile.ZipInfo(name, date_time=date_time)
    info.create_system = 3  # Unix, regardless of the OS that builds the zip
    if name.endswith("/"):
        info.external_attr = (0o40755 << 16) | 0x10  # directory
    else:
        info.external_attr = 0o644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
    return info


def write_zip(zip_path: Path, entries: dict[str, bytes], timestamp: time.struct_time) -> None:
    """Write folder entries, the empty .mod marker file and all entries to `zip_path`.

    Every entry gets `timestamp` and fixed metadata, and entries are sorted, so the
    same tag always produces the same zip.
    """
    contents = {MOD_FILE: b"", **entries}
    folders = {
        f"{parent}/"
        for name in contents
        for parent in PurePosixPath(name).parents
        if parent != PurePosixPath(".")
    }
    with zipfile.ZipFile(zip_path, "w") as archive:
        for name in sorted(folders | contents.keys()):
            archive.writestr(zip_info(name, timestamp), contents.get(name, b""))


def verify_zip(zip_path: Path, files: dict[PurePosixPath, bytes]) -> None:
    """Reopen the written zip and check the PS3 layout; delete it and raise PackageError if it is wrong."""
    problems: list[str] = []
    if SILINIUM_STUBS not in files:
        problems.append(f"{SILINIUM_STUBS} is missing from the tag, so the zip would ship the PC stubs")
    with zipfile.ZipFile(zip_path) as archive:
        names = set(archive.namelist())
        if MOD_FILE not in names:
            problems.append(f"{MOD_FILE} is missing")
        for path in sorted(p for p in files if p.is_relative_to(SILINIUM_DIR)):
            name = arcname(path, SILINIUM_DIR)
            if name not in names:
                problems.append(f"{name} is missing")
            elif archive.read(name) != files[path]:
                problems.append(f"{name} is not the version from {path}")
    if problems:
        zip_path.unlink()
        raise PackageError(f"Deleted {zip_path}, verification failed:\n  " + "\n  ".join(problems))


def build_zip(version: str, output_dir: Path) -> Path:
    """Build and verify CenturyPackageBO1-X.Y.Z-PS3.zip in `output_dir` from tag `version`.

    Checks the version format, that the tag exists and that its CHANGELOG.md has a
    section for it. Returns the zip path; raises PackageError if any step fails.
    """
    check_version(version)
    resolve_tag(version)
    check_changelog(version)
    files = read_tree(version)
    entries = collect_entries(files)

    output_dir.mkdir(parents=True, exist_ok=True)
    zip_path = output_dir / f"{MOD_NAME}-{version}-PS3.zip"
    write_zip(zip_path, entries, commit_time(f"refs/tags/{version}"))
    verify_zip(zip_path, files)

    print(f"Wrote and verified {zip_path} ({len(entries) + 1} files from tag {version})")
    return zip_path


def main() -> None:
    """Command-line entry point: report errors as messages instead of tracebacks."""
    parser = argparse.ArgumentParser(description="Build the PS3 release zip from a git tag")
    parser.add_argument("version", type=str, help="Existing release tag as MAJOR.MINOR.PATCH without a v prefix, e.g. 3.0.0")
    parser.add_argument("-o", "--output", type=Path, default=REPO_ROOT,
                        help="Output directory (default: repository root)")
    args = parser.parse_args()
    try:
        check_version(args.version)
    except PackageError as error:
        parser.error(str(error))

    try:
        build_zip(args.version, args.output)
    except PackageError as error:
        sys.exit(f"error: {error}")


if __name__ == "__main__":
    main()
