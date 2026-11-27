# Releasing

Releases are done manually. `master` is protected, so every change to it goes through a pull request. Tags can currently be pushed directly.

## Versioning

Versions follow [Semantic Versioning](https://semver.org/) as `MAJOR.MINOR.PATCH`, without a `v` prefix (e.g. `3.0.0`, `3.1.0`, `3.1.1`).

Tags older than `2.1` (`V1`, `1.51`, `2`, ...) are kept as they are.

## Steps

In the examples below, `X.Y.Z` stands for the new version.

### 1. Prepare the release PR

```sh
git switch master
git pull
git switch -c release/X.Y.Z
```

In `CHANGELOG.md`:

- Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` and add a new empty `## [Unreleased]` above it.
- Remove any "Planned as `X.Y.Z`" note from the released section, since it would otherwise end up in the release text. Keep the information it carries as a normal sentence, e.g. "The new folder layout requires a fresh install when upgrading from `2.1`."
- Update the link references at the bottom:

  ```md
  [Unreleased]: https://github.com/itacentury/CenturyPackageBO1/compare/X.Y.Z...HEAD
  [X.Y.Z]: https://github.com/itacentury/CenturyPackageBO1/compare/<previous>...X.Y.Z
  ```

```sh
git commit -am "Release X.Y.Z"
git push -u origin release/X.Y.Z
```

Open a pull request titled `Release X.Y.Z` against `master` and merge it.

### 2. Tag the merge commit

```sh
git switch master
git pull
git tag -a X.Y.Z -m "Century Package X.Y.Z"
git push origin X.Y.Z
```

Always tag with `git tag -a` so every release tag is annotated (GitHub's release form would create a lightweight tag instead); step 3 builds from this tag.

### 3. Build the PS3 package

Build the folder layout described in the README from the tag:

```sh
git fetch --tags
uv run package.py X.Y.Z
```

`package.py` reads `maps` and `silinium/maps` straight from the tag `X.Y.Z` with `git archive`, so it can run from any branch and untracked, ignored or uncommitted files (`.DS_Store`, editor backups, local edits) never end up in the zip. It refuses versions that aren't `MAJOR.MINOR.PATCH` and tags whose `CHANGELOG.md` has no `## [X.Y.Z]` section. It only uses the Python standard library, so instead of `uv run` ([uv](https://docs.astral.sh/uv/) picks a suitable Python automatically) you can also run `python package.py X.Y.Z` with Python 3.10 or newer. It works the same on Windows, Linux and macOS. It writes `CenturyPackageBO1-X.Y.Z-PS3.zip` to the repository root, with `silinium/maps` overwriting `stubs.gsc` from `maps`.

After writing the zip, the script reopens it and checks that it contains `mp/CenturyPackageBO1.mod` and that every file from `silinium/maps` (including `stubs.gsc` with the Silinium implementation) replaced the PC version. If a check fails, it deletes the zip and stops, so there is nothing to check by hand.

PC users install by cloning the repository (see README), so no PC package is needed.

### 4. Publish the GitHub release

On GitHub: **Releases → Draft a new release**

- Tag: choose the existing `X.Y.Z` tag pushed in step 2
- Title: `Century Package X.Y.Z`
- Description: the `X.Y.Z` section from `CHANGELOG.md`
- Attach `CenturyPackageBO1-X.Y.Z-PS3.zip`

## Checklist

- [ ] `CHANGELOG.md` section renamed, dated, "Planned as" note removed and links updated
- [ ] Release PR merged into `master`
- [ ] Tag `X.Y.Z` points to the merge commit and is pushed
- [ ] PS3 zip built from the tag
- [ ] GitHub release published with changelog text and zip attached
