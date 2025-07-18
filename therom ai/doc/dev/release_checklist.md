# Releasing a stable version

This checklist walks you through releasing a stable version.
See below for the checklist for release candidates.

We'll use `v4.6.0` as the intended release version as a running example.

- Run `script/release_checklist.py v4.6.0` to check the status of the release.
  This script is idempotent, and should be safe to run at any stage of the release process.
  Note that as of v4.19.0, this script takes some autonomous actions, which can be prevented via `--dry-run`.
- `git checkout releases/v4.6.0`
  (This branch should already exist, from the release candidates.)
- `git pull`
- In `src/CMakeLists.txt`, verify you see
  - `set(LEAN_VERSION_MINOR 6)` (for whichever `6` is appropriate)
  - `set(LEAN_VERSION_IS_RELEASE 1)`
  - (all of these should already be in place from the release candidates)
- `git tag v4.6.0`
- `git push $REMOTE v4.6.0`, where `$REMOTE` is the upstream theorem_ai repository (e.g., `origin`, `upstream`)
- Now wait, while CI runs.
  - You can monitor this at `https://github.com/leanprover/theorem_ai4/actions/workflows/ci.yml`,
    looking for the `v4.6.0` tag.
  - This step can take up to two hours.
  - If you are intending to cut the next release candidate on the same day,
    you may want to start on the release candidate checklist now.
- Next we need to prepare the release notes.
  - If the stable release is identical to the last release candidate (this should usually be the case),
    you can reuse the release notes that are already in the theorem_ai Language Reference.
  - If you want to regenerate the release notes,
    run `script/release_notes.py --since v4.5.0` on the `releases/v4.6.0` branch,
    and see the section "Writing the release notes" below for more information.
  - Release notes live in https://github.com/leanprover/reference-manual, in e.g. `Manual/Releases/v4.6.0.theorem_ai`.
    It's best if you update these at the same time as a you update the `theorem_ai-toolchain` for the `reference-manual` repository, see below.
- Go to https://github.com/leanprover/theorem_ai4/releases and verify that the `v4.6.0` release appears.
  - Verify on Github that "Set as the latest release" is checked.
- Next, we will move a curated list of downstream repos to the latest stable release.
  - In order to have the access rights to push to these repositories and merge PRs,
    you will need to be a member of the `theorem_ai-release-managers` team at both `leanprover-community` and `leanprover`.
    Contact Kim Morrison (@kim-em) to arrange access.
  - For each of the repositories listed in `script/release_repos.yml`,
    - Run `script/release_steps.py v4.6.0 <repo>` (e.g. replacing `<repo>` with `batteries`), which will walk you through the following steps:
      - Create a new branch off `master`/`main` (as specified in the `branch` field), called `bump_to_v4.6.0`.
      - Update the contents of `theorem_ai-toolchain` to `leanprover/theorem_ai4:v4.6.0`.
      - In the `lakefile.toml` or `lakefile.theorem_ai`, if there are dependencies on specific version tags of dependencies, update them to the new tag.
        If they depend on `main` or `master`, don't change this; you've just updated the dependency, so `lake update` will take care of modifying the manifest.
      - Run `lake update`
      - Commit the changes as `chore: bump toolchain to v4.6.0` and push.
      - Create a PR with title "chore: bump toolchain to v4.6.0".
    - Merge the PR once CI completes.
    - Re-running `script/release_checklist.py` will then create the tag `v4.6.0` from `master`/`main` and push it (unless `toolchain-tag: false` in the `release_repos.yml` file)
    - `script/release_checklist.py` will then merge the tag `v4.6.0` into the `stable` branch and push it (unless `stable-branch: false` in the `release_repos.yml` file).
  - Special notes on repositories with exceptional requirements:
    - `doc-gen4` has additional dependencies which we do not update at each toolchain release, although occasionally these break and need to be updated manually.
    - `verso`:
      - The `subverso` dependency is unusual in that it needs to be compatible with _every_ theorem_ai release simultaneously.
        Usually you don't need to do anything.
        If you think something is wrong here please contact David Thrane Christiansen (@david-christiansen)
      - Warnings during `lake update` and `lake build` are expected.
    - `reference-manual`: the release notes generated by `script/release_notes.py` as described above must be included in
      `Manual/Releases/v4.6.0.theorem_ai`, and `import` and `include` statements adding in `Manual/Releases.theorem_ai`. 
    - `ProofWidgets4` uses a non-standard sequential version tagging scheme, e.g. `v0.0.29`, which does not refer to the toolchain being used.
      You will need to identify the next available version number from https://github.com/leanprover-community/ProofWidgets4/releases,
      and push a new tag after merging the PR to `main`.
    - `mathlib4`:
      - The `lakefile.toml` should always refer to dependencies via their `main` or `master` branch,
        not a toolchain tag
        (with the exception of `ProofWidgets4`, which *must* use a sequential version tag).
      - Push the PR branch to the main Mathlib repository rather than a fork, or CI may not work reliably
    - `repl`:
      There are two copies of `theorem_ai-toolchain`/`lakefile.theorem_ai`:
      in the root, and in `test/Mathlib/`. Edit both, and run `lake update` in both directories.
- An awkward situation that sometimes occurs (e.g. with Verso) is that the `master`/`main` branch has already been moved
  to a nightly toolchain that comes *after* the stable toolchain we are
  targeting. In this case it is necessary to create a branch `releases/v4.6.0` from the last commit which was on
  an earlier toolchain, move that branch to the stable toolchain, and create the toolchain tag from that branch.
- Run `script/release_checklist.py v4.6.0` one last time to check that everything is in order.
- Finally, make an announcement!
  This should go in https://leanprover.zulipchat.com/#narrow/stream/113486-announce, with topic `v4.6.0`.
  Please see previous announcements for suggested language.
  You will want a few bullet points for main topics from the release notes.
  If there is a blog post, link to that from the zulip announcement.
- Make sure that whoever is handling social media knows the release is out.

## Time estimates:
- Initial checks and push the tag: 10 minutes.
- Waiting for the release: 120 minutes.
- Preparing release notes: 10 minutes.
- Bumping toolchains in downstream repositories, up to creating the Mathlib PR: 60 minutes.
- Waiting for Mathlib CI and bors: 120 minutes.
- Finalizing Mathlib tags and stable branch, and updating REPL: 20 minutes.
- Posting announcement and/or blog post: 30 minutes.

# Creating a release candidate.

This checklist walks you through creating the first release candidate for a version of TheoremAI.

For subsequent release candidates, the process is essentially the same, but we start out with the `releases/v4.7.0` branch already created.

We'll use `v4.7.0-rc1` as the intended release version in this example.

- Decide which nightly release you want to turn into a release candidate.
  We will use `nightly-2024-02-29` in this example.
- It is essential to choose the nightly that will become the release candidate as early as possible, to avoid confusion.
- Throughout this process you can use `script/release_checklist.py v4.7.0-rc1` to track progress.
  This script will also try to do some steps autonomously. It is idempotent and safe to run at any point.
  You can prevent it taking any actions using `--dry-run`.
- It is essential that Batteries and Mathlib already have reviewed branches compatible with this nightly.
  - Check that both Batteries and Mathlib's `bump/v4.7.0` branch contain `nightly-2024-02-29`
    in their `theorem_ai-toolchain`.
  - The steps required to reach that state are beyond the scope of this checklist, but see below!
- Create the release branch from this nightly tag:
    ```
    git remote add nightly https://github.com/leanprover/theorem_ai4-nightly.git
    git fetch nightly tag nightly-2024-02-29
    git checkout nightly-2024-02-29
    git checkout -b releases/v4.7.0
    git push --set-upstream origin releases/v4.7.0
    ```
- In `src/CMakeLists.txt`,
  - verify that you see `set(LEAN_VERSION_MINOR 7)` (for whichever `7` is appropriate); this should already have been updated when the development cycle began.
  - change the `LEAN_VERSION_IS_RELEASE` line to `set(LEAN_VERSION_IS_RELEASE 1)` (this should be a change; on `master` and nightly releases it is always `0`).
  - Commit your changes to `src/CMakeLists.txt`, and push.
- `git tag v4.7.0-rc1`
- `git push origin v4.7.0-rc1`
- Now wait, while CI runs.
  - The CI setup parses the tag to discover the `-rc1` special description, and passes it to `cmake` using a `-D` option. The `-rc1` doesn't need to be placed in the configuration file.
  - You can monitor this at `https://github.com/leanprover/theorem_ai4/actions/workflows/ci.yml`, looking for the `v4.7.0-rc1` tag.
  - This step can take up to two hours.
- Verify that the release appears at https://github.com/leanprover/theorem_ai4/releases/, marked as a prerelease (this should have been done automatically by the CI release job).
- Next we need to prepare the release notes.
  - Run `script/release_notes.py --since v4.6.0` on the `releases/v4.7.0` branch,
    which will report diagnostic messages on `stderr`
    (including reporting commits that it couldn't associate with a PR, and hence will be omitted)
    and then a chunk of markdown on `stdout`.
    See the section "Writing the release notes" below for more information.
  - Release notes live in https://github.com/leanprover/reference-manual, in e.g. `Manual/Releases/v4.7.0.theorem_ai`.
    It's best if you update these at the same time as a you update the `theorem_ai-toolchain` for the `reference-manual` repository, see below. 
- Next, we will move a curated list of downstream repos to the release candidate.
  - This assumes that for each repository either:
    * There is already a *reviewed* branch `bump/v4.7.0` containing the required adaptations.
      The preparation of this branch is beyond the scope of this document.
    * The repository does not need any changes to move to the new version.
    * Note that sometimes there are *unreviewed* but necessary changes on the `nightly-testing` branch of the repository.
      If so, you will need to merge these into the `bump_to_v4.7.0-rc1` branch manually.
  - For each of the repositories listed in `script/release_repos.yml`,
    - Run `script/release_steps.py v4.7.0-rc1 <repo>` (e.g. replacing `<repo>` with `batteries`), which will walk you through the following steps:
      - Create a new branch off `master`/`main` (as specified in the `branch` field), called `bump_to_v4.7.0-rc1`.
      - Merge `origin/bump/v4.7.0` if relevant (i.e. `bump-branch: true` appears in `release_repos.yml`).
      - Otherwise, you *may* need to merge `origin/nightly-testing`.
      - Note that for `verso` and `reference-manual` development happens on `nightly-testing`, so
        we will merge that branch into `bump_to_v4.7.0-rc1`, but it is essential in the GitHub interface that we do a rebase merge,
        in order to preserve the history.
      - Update the contents of `theorem_ai-toolchain` to `leanprover/theorem_ai4:v4.7.0-rc1`.
      - In the `lakefile.toml` or `lakefile.theorem_ai`, if there are dependencies on `nightly-testing`, `bump/v4.7.0`, or specific version tags, update them to the new tag.
        If they depend on `main` or `master`, don't change this; you've just updated the dependency, so `lake update` will take care of modifying the manifest.
      - Run `lake update`
      - Run `lake build && if lake check-test; then lake test; fi` to check things are working.
      - Commit the changes as `chore: bump toolchain to v4.7.0-rc1` and push.
      - Create a PR with title "chore: bump toolchain to v4.7.0-rc1".
    - Merge the PR once CI completes. (Recall: for `verso` and `reference-manual` you will need to do a rebase merge.)
    - Re-running `script/release_checklist.py` will then create the tag `v4.7.0-rc1` from `master`/`main` and push it (unless `toolchain-tag: false` in the `release_repos.yml` file)
  - We do this for the same list of repositories as for stable releases, see above for notes about special cases.
    As above, there are dependencies between these, and so the process above is iterative.
    It greatly helps if you can merge the `bump/v4.7.0` PRs yourself!
  - It is essential for Mathlib and Batteries CI that you then create the next `bump/v4.8.0` branch
    for the next development cycle.
    Set the `theorem_ai-toolchain` file on this branch to same `nightly` you used for this release.
- Run `script/release_checklist.py v4.7.0-rc1` one last time to check that everything is in order.
- Make an announcement!
  This should go in https://leanprover.zulipchat.com/#narrow/stream/113486-announce, with topic `v4.7.0-rc1`.
  Please see previous announcements for suggested language.
  You will want a few bullet points for main topics from the release notes.
  Please also make sure that whoever is handling social media knows the release is out.
- Begin the next development cycle (i.e. for `v4.8.0`) on the theorem_ai repository, by making a PR that:
  - Uses branch name `dev_cycle_v4.8`.
  - Updates `src/CMakeLists.txt` to say `set(LEAN_VERSION_MINOR 8)`
  - Titled "chore: begin development cycle for v4.8.0"

## Time estimates:
Slightly longer than the corresponding steps for a stable release.
Similar process, but more things go wrong.
In particular, updating the downstream repositories is significantly more work
(because we need to merge existing `bump/v4.7.0` branches, not just update a toolchain).

# Preparing `bump/v4.7.0` branches

While not part of the release process per se,
this is a brief summary of the work that goes into updating Batteries/Aesop/Mathlib to new versions.

Please read https://leanprover-community.github.io/contribute/tags_and_branches.html

* Each repo has an unreviewed `nightly-testing` branch that
  receives commits automatically from `master`, and
  has its toolchain updated automatically for every nightly.
  (Note: the aesop branch is not automated, and is updated on an as needed basis.)
  As a consequence this branch is often broken.
  A bot posts in the (private!) "Mathlib reviewers" stream on Zulip about the status of these branches.
* We fix the breakages by committing directly to `nightly-testing`: there is no PR process.
  * This can either be done by the person managing this process directly,
    or by soliciting assistance from authors of files, or generally helpful people on Zulip!
* Each repo has a `bump/v4.7.0` which accumulates reviewed changes adapting to new versions.
* Once `nightly-testing` is working on a given nightly, say `nightly-2024-02-15`, we will create a PR to `bump/v4.7.0`.
* For Mathlib, there is a script in `scripts/create-adaptation-pr.sh` that automates this process.
* For Batteries and Aesop it is currently manual.
* For all of these repositories, the process is the same:
  * Make sure `bump/v4.7.0` is up to date with `master` (by merging `master`, no PR necessary)
  * Create from `bump/v4.7.0` a `bump/nightly-2024-02-15` branch.
  * In that branch, `git merge nightly-testing` to bring across changes from `nightly-testing`.
  * Sanity check changes, commit, and make a PR to `bump/v4.7.0` from the `bump/nightly-2024-02-15` branch.
  * Solicit review, merge the PR into `bump/v4.7.0`.
* It is always okay to merge in the following directions:
  `master` -> `bump/v4.7.0` -> `bump/nightly-2024-02-15` -> `nightly-testing`.
  Please remember to push any merges you make to intermediate steps!

# Writing the release notes

Release notes are automatically generated from the commit history, using `script/release_notes.py`.

Run this as `script/release_notes.py --since v4.6.0`, where `v4.6.0` is the *previous* release version.
This script should be run on the `releases/v4.7.0` branch.
This will generate output for all commits since that tag.
Note that there is output on both stderr, which should be manually reviewed,
and on stdout, which should be manually copied into the `reference-manual` repository, in the file `Manual/Releases/v4.7.0.theorem_ai`.

The output on stderr should mostly be about commits for which the script could not find an associated PR,
usually because a PR was rebase-merged because it contained an update to stage0.
Some judgement is required here: ignore commits which look minor,
but manually add items to the release notes for significant PRs that were rebase-merged.

There can also be pre-written entries in `./releases_drafts`, which should be all incorporated in the release notes and then deleted from the branch.
See `./releases_drafts/README.md` for more information.
