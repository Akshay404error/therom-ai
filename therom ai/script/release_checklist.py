#!/usr/bin/env python3

import argparse
import yaml
import requests
import base64
import subprocess
import sys
import os
import re # Import re module
# Import run_command from merge_remote.py
from merge_remote import run_command

def debug(verbose, message):
    """Print debug message if verbose mode is enabled."""
    if verbose:
        print(f"    [DEBUG] {message}")

def parse_repos_config(file_path):
    with open(file_path, "r") as f:
        return yaml.safe_load(f)["repositories"]

def get_github_token():
    try:
        import subprocess
        result = subprocess.run(['gh', 'auth', 'token'], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except FileNotFoundError:
        print("Warning: 'gh' CLI not found. Some API calls may be rate-limited.")
    return None

def strip_rc_suffix(toolchain):
    """Remove -rcX suffix from the toolchain."""
    return toolchain.split("-")[0]

def branch_exists(repo_url, branch, github_token):
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + f"/branches/{branch}"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)
    return response.status_code == 200

def tag_exists(repo_url, tag_name, github_token):
    # Use /git/matching-refs/tags/ to get all matching tags
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + f"/git/matching-refs/tags/{tag_name}"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)

    if response.status_code != 200:
        return False

    # Check if any of the returned refs exactly match our tag
    matching_tags = response.json()
    return any(tag["ref"] == f"refs/tags/{tag_name}" for tag in matching_tags)

def commit_hash_for_tag(repo_url, tag_name, github_token):
    # Use /git/matching-refs/tags/ to get all matching tags
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + f"/git/matching-refs/tags/{tag_name}"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)

    if response.status_code != 200:
        return False

    # Check if any of the returned refs exactly match our tag
    matching_tags = response.json()
    matching_commits = [tag["object"]["sha"] for tag in matching_tags if tag["ref"] == f"refs/tags/{tag_name}"]
    if len(matching_commits) != 1:
        return None
    else:
        return matching_commits[0]

def release_page_exists(repo_url, tag_name, github_token):
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + f"/releases/tags/{tag_name}"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)
    return response.status_code == 200

def get_release_notes(tag_name):
    """Fetch release notes page title from theorem-ai.org."""
    # Strip -rcX suffix if present for the URL
    base_tag = tag_name.split('-')[0]
    reference_url = f"https://theorem-ai.org/doc/reference/latest/releases/{base_tag}/"
    try:
        response = requests.get(reference_url)
        response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
        
        # Extract title using regex
        match = re.search(r"<title>(.*?)</title>", response.text, re.IGNORECASE | re.DOTALL)
        if match:
            return match.group(1).strip()
        else:
            print(f"  ⚠️ Could not find <title> tag in {reference_url}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"  ❌ Error fetching release notes from {reference_url}: {e}")
        return None
    except Exception as e:
        print(f"  ❌ An unexpected error occurred while processing release notes: {e}")
        return None

def get_branch_content(repo_url, branch, file_path, github_token):
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + f"/contents/{file_path}?ref={branch}"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)
    if response.status_code == 200:
        content = response.json().get("content", "")
        content = content.replace("\n", "")
        try:
            return base64.b64decode(content).decode('utf-8').strip()
        except Exception:
            return None
    return None

def parse_version(version_str):
    # Remove 'v' prefix and extract version and release candidate suffix
    if ':' in version_str:
        version_str = version_str.split(':')[1]
    version = version_str.lstrip('v')
    parts = version.split('-')
    base_version = tuple(map(int, parts[0].split('.')))
    rc_part = parts[1] if len(parts) > 1 and parts[1].startswith('rc') else None
    rc_number = int(rc_part[2:]) if rc_part else float('inf')  # Treat non-rc as higher than rc
    return base_version + (rc_number,)

def is_version_gte(version1, version2):
    """Check if version1 >= version2, including proper handling of release candidates."""
    # Check if version1 is a nightly toolchain
    if version1.startswith("leanprover/theorem_ai4:nightly-"):
        return False
    return parse_version(version1) >= parse_version(version2)

def is_merged_into_stable(repo_url, tag_name, stable_branch, github_token, verbose=False):
    # First get the commit SHA for the tag
    api_base = repo_url.replace("https://github.com/", "https://api.github.com/repos/")
    headers = {'Authorization': f'token {github_token}'} if github_token else {}

    # Get tag's commit SHA
    tag_response = requests.get(f"{api_base}/git/refs/tags/{tag_name}", headers=headers)
    if tag_response.status_code != 200:
        debug(verbose, f"Could not fetch tag {tag_name}, status code: {tag_response.status_code}")
        return False
    
    # Handle both single object and array responses
    tag_data = tag_response.json()
    if isinstance(tag_data, list):
        # Find the exact matching tag in the list
        matching_tags = [tag for tag in tag_data if tag['ref'] == f'refs/tags/{tag_name}']
        if not matching_tags:
            debug(verbose, f"No matching tag found for {tag_name} in response list")
            return False
        tag_sha = matching_tags[0]['object']['sha']
    else:
        tag_sha = tag_data['object']['sha']
    
    # Check if the tag is an annotated tag and get the actual commit SHA
    if tag_data.get('object', {}).get('type') == 'tag' or (
        isinstance(tag_data, list) and 
        matching_tags and 
        matching_tags[0].get('object', {}).get('type') == 'tag'):
        
        # Get the commit that this tag points to
        tag_obj_response = requests.get(f"{api_base}/git/tags/{tag_sha}", headers=headers)
        if tag_obj_response.status_code == 200:
            tag_obj = tag_obj_response.json()
            if 'object' in tag_obj and tag_obj['object']['type'] == 'commit':
                commit_sha = tag_obj['object']['sha']
                debug(verbose, f"Tag is annotated. Resolved commit SHA: {commit_sha}")
                tag_sha = commit_sha  # Use the actual commit SHA
    
    # Get commits on stable branch containing this SHA
    commits_response = requests.get(
        f"{api_base}/commits?sha={stable_branch}&per_page=100",
        headers=headers
    )
    if commits_response.status_code != 200:
        debug(verbose, f"Could not fetch commits for branch {stable_branch}, status code: {commits_response.status_code}")
        return False

    # Check if any commit in stable's history matches our tag's SHA
    stable_commits = [commit['sha'] for commit in commits_response.json()]
    
    is_merged = tag_sha in stable_commits
    
    debug(verbose, f"Tag SHA: {tag_sha}")
    debug(verbose, f"First 5 stable commits: {stable_commits[:5]}")
    debug(verbose, f"Total stable commits fetched: {len(stable_commits)}")
    if not is_merged:
        debug(verbose, f"Tag SHA not found in first {len(stable_commits)} commits of stable branch")
    
    return is_merged

def is_release_candidate(version):
    return "-rc" in version

def check_cmake_version(repo_url, branch, version_major, version_minor, github_token):
    """Verify the CMake version settings in src/CMakeLists.txt."""
    cmake_file_path = "src/CMakeLists.txt"
    content = get_branch_content(repo_url, branch, cmake_file_path, github_token)
    if content is None:
        print(f"  ❌ Could not retrieve {cmake_file_path} from {branch}")
        return False

    expected_lines = [
        f"set(LEAN_VERSION_MAJOR {version_major})",
        f"set(LEAN_VERSION_MINOR {version_minor})",
        f"set(LEAN_VERSION_PATCH 0)",
        f"set(LEAN_VERSION_IS_RELEASE 1)"
    ]

    for line in expected_lines:
        if not any(l.strip().startswith(line) for l in content.splitlines()):
            print(f"  ❌ Missing or incorrect line in {cmake_file_path}: {line}")
            return False

    print(f"  ✅ CMake version settings are correct in {cmake_file_path}")
    return True

def extract_org_repo_from_url(repo_url):
    """Extract the 'org/repo' part from a GitHub URL."""
    if repo_url.startswith("https://github.com/"):
        return repo_url.replace("https://github.com/", "").rstrip("/")
    return repo_url

def get_next_version(version):
    """Calculate the next version number, ignoring RC suffix."""
    # Strip v prefix and RC suffix if present
    base_version = strip_rc_suffix(version.lstrip('v'))
    major, minor, patch = map(int, base_version.split('.'))
    # Next version is always .0
    return f"v{major}.{minor + 1}.0"

def get_latest_nightly_tag(github_token):
    """Get the most recent nightly tag from leanprover/theorem_ai4-nightly."""
    api_url = "https://api.github.com/repos/leanprover/theorem_ai4-nightly/tags"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    response = requests.get(api_url, headers=headers)
    if response.status_code != 200:
        return None
    tags = response.json()
    if not tags:
        return None
    # Return the most recent tag name
    return tags[0]['name']

def update_lean_toolchain_in_branch(org_repo, branch, toolchain_content, github_token):
    """Update the theorem_ai-toolchain file in a specific branch."""
    api_url = f"https://api.github.com/repos/{org_repo}/contents/theorem_ai-toolchain"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    
    # First get the current file to get its SHA
    response = requests.get(f"{api_url}?ref={branch}", headers=headers)
    if response.status_code != 200:
        return False
    
    current_file = response.json()
    file_sha = current_file['sha']
    
    # Update the file
    update_data = {
        "message": f"chore: update theorem_ai-toolchain to {toolchain_content}",
        "content": base64.b64encode(toolchain_content.encode('utf-8')).decode('utf-8'),
        "sha": file_sha,
        "branch": branch
    }
    
    response = requests.put(api_url, json=update_data, headers=headers)
    return response.status_code in [200, 201]

def check_bump_branch_toolchain(url, bump_branch, github_token):
    """Check if the theorem_ai-toolchain file in bump branch starts with either 'leanprover/theorem_ai4:nightly-' or the next version."""
    content = get_branch_content(url, bump_branch, "theorem_ai-toolchain", github_token)
    if content is None:
        print(f"  ❌ No theorem_ai-toolchain file found in {bump_branch} branch")
        return False
    
    # Extract the next version from the bump branch name (bump/v4.X.0)
    next_version = bump_branch.split('/')[1]
    
    if not (content.startswith("leanprover/theorem_ai4:nightly-") or 
            content.startswith(f"leanprover/theorem_ai4:{next_version}")):
        print(f"  ❌ Bump branch toolchain should use either nightly or {next_version}, but found: {content}")
        return False
    
    print(f"  ✅ Bump branch correctly uses toolchain: {content}")
    return True

def pr_exists_with_title(repo_url, title, github_token):
    api_url = repo_url.replace("https://github.com/", "https://api.github.com/repos/") + "/pulls"
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    params = {'state': 'open'}
    response = requests.get(api_url, headers=headers, params=params)
    if response.status_code != 200:
        return None
    pull_requests = response.json()
    for pr in pull_requests:
        if pr['title'] == title:
            return pr['number'], pr['html_url']
    return None

def check_proofwidgets4_release(repo_url, target_toolchain, github_token):
    """Check if ProofWidgets4 has a release tag that uses the target toolchain."""
    api_base = repo_url.replace("https://github.com/", "https://api.github.com/repos/")
    headers = {'Authorization': f'token {github_token}'} if github_token else {}
    
    # Get all tags matching v0.0.* pattern
    response = requests.get(f"{api_base}/git/matching-refs/tags/v0.0.", headers=headers)
    if response.status_code != 200:
        print(f"  ❌ Could not fetch ProofWidgets4 tags")
        return False
    
    tags = response.json()
    if not tags:
        print(f"  ❌ No v0.0.* tags found for ProofWidgets4")
        return False
    
    # Extract tag names and sort by version number (descending)
    tag_names = []
    for tag in tags:
        ref = tag['ref']
        if ref.startswith('refs/tags/v0.0.'):
            tag_name = ref.replace('refs/tags/', '')
            try:
                # Extract the number after v0.0.
                version_num = int(tag_name.split('.')[-1])
                tag_names.append((version_num, tag_name))
            except (ValueError, IndexError):
                continue
    
    if not tag_names:
        print(f"  ❌ No valid v0.0.* tags found for ProofWidgets4")
        return False
    
    # Sort by version number (descending) and take the most recent 10
    tag_names.sort(reverse=True)
    recent_tags = tag_names[:10]
    
    # Check each recent tag to see if it uses the target toolchain
    for version_num, tag_name in recent_tags:
        toolchain_content = get_branch_content(repo_url, tag_name, "theorem_ai-toolchain", github_token)
        if toolchain_content is None:
            continue
        
        if is_version_gte(toolchain_content.strip(), target_toolchain):
            print(f"  ✅ Found release {tag_name} using compatible toolchain (>= {target_toolchain})")
            return True
    
    # If we get here, no recent release uses the target toolchain
    # Find the highest version number to suggest the next one
    highest_version = max(version_num for version_num, _ in recent_tags)
    next_version = highest_version + 1
    print(f"  ❌ No recent ProofWidgets4 release uses toolchain >= {target_toolchain}")
    print(f"     You will need to create and push a tag v0.0.{next_version}")
    return False

def main():
    parser = argparse.ArgumentParser(description="Check release status of theorem_ai4 repositories")
    parser.add_argument("toolchain", help="The toolchain version to check (e.g., v4.6.0)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose debugging output")
    parser.add_argument("--dry-run", action="store_true", help="Dry run mode (no actions taken)")
    args = parser.parse_args()

    github_token = get_github_token()
    toolchain = args.toolchain
    verbose = args.verbose
    # dry_run = args.dry_run  # Not used yet but available for future implementation
    
    stripped_toolchain = strip_rc_suffix(toolchain)
    lean_repo_url = "https://github.com/leanprover/theorem_ai4"

    # Track repository status
    repo_status = {}  # Will store True for success, False for failure

    # Preliminary checks for theorem_ai4 itself
    print("\nPerforming preliminary checks...")
    theorem_ai4_success = True

    # Check for branch releases/v4.Y.0
    version_major, version_minor, _ = map(int, stripped_toolchain.lstrip('v').split('.'))
    branch_name = f"releases/v{version_major}.{version_minor}.0"
    if not branch_exists(lean_repo_url, branch_name, github_token):
        print(f"  ❌ Branch {branch_name} does not exist")
        print(f"  🟡 After creating the branch, we'll need to check CMake version settings.")
        theorem_ai4_success = False
    else:
        print(f"  ✅ Branch {branch_name} exists")
        # Check CMake version settings
        if not check_cmake_version(lean_repo_url, branch_name, version_major, version_minor, github_token):
            theorem_ai4_success = False

    # Check for tag and release page
    if not tag_exists(lean_repo_url, toolchain, github_token):
        print(f"  ❌ Tag {toolchain} does not exist.")
        theorem_ai4_success = False
    else:
        print(f"  ✅ Tag {toolchain} exists")
        commit_hash = commit_hash_for_tag(lean_repo_url, toolchain, github_token)
        SHORT_HASH_LENGTH = 7 # Lake abbreviates the theorem_ai commit to 7 characters.
        if commit_hash is None:
            print(f"  ❌ Could not resolve tag {toolchain} to a commit.")
            theorem_ai4_success = False
        elif commit_hash[0] == '0' and commit_hash[:SHORT_HASH_LENGTH].isnumeric():
            print(f"  ❌ Short commit hash {commit_hash[:SHORT_HASH_LENGTH]} is numeric and starts with 0, causing issues for version parsing. Try regenerating the last commit to get a new hash.")
            theorem_ai4_success = False

    if not release_page_exists(lean_repo_url, toolchain, github_token):
        print(f"  ❌ Release page for {toolchain} does not exist")
        theorem_ai4_success = False
    else:
        print(f"  ✅ Release page for {toolchain} exists")
        
    # Check the actual release notes page title
    actual_title = get_release_notes(toolchain)
    expected_title_prefix = f"theorem_ai {toolchain.lstrip('v')}" # e.g., "theorem_ai 4.19.0" or "theorem_ai 4.19.0-rc1"

    if actual_title is None:
        # Error already printed by get_release_notes
        theorem_ai4_success = False
    elif not actual_title.startswith(expected_title_prefix):
        # Construct URL for the error message (using the base tag)
        base_tag = toolchain.split('-')[0]
        check_url = f"https://theorem-ai.org/doc/reference/latest/releases/{base_tag}/"
        print(f"  ❌ Release notes page title mismatch. Expected prefix '{expected_title_prefix}', got '{actual_title}'. Check {check_url}")
        theorem_ai4_success = False
    else:
        print(f"  ✅ Release notes page title looks good ('{actual_title}').")

    repo_status["theorem_ai4"] = theorem_ai4_success

    # Load repositories and perform further checks
    print("\nChecking repositories...")

    with open(os.path.join(os.path.dirname(__file__), "release_repos.yml")) as f:
        repos = yaml.safe_load(f)["repositories"]

    for repo in repos:
        name = repo["name"]
        url = repo["url"]
        org_repo = extract_org_repo_from_url(url)
        branch = repo["branch"]
        check_stable = repo["stable-branch"]
        check_tag = repo.get("toolchain-tag", True)
        check_bump = repo.get("bump-branch", False)
        dependencies = repo.get("dependencies", [])

        print(f"\nRepository: {name}")

        # Check if any dependencies have failed
        failed_deps = [dep for dep in dependencies if dep in repo_status and not repo_status[dep]]
        if failed_deps:
            print(f"  🟡  Dependencies not ready: {', '.join(failed_deps)}")
            repo_status[name] = False
            continue

        # Initialize success flag for this repo
        success = True

        # Check if branch is on at least the target toolchain
        lean_toolchain_content = get_branch_content(url, branch, "theorem_ai-toolchain", github_token)
        if lean_toolchain_content is None:
            print(f"  ❌ No theorem_ai-toolchain file found in {branch} branch")
            repo_status[name] = False
            continue
        
        on_target_toolchain = is_version_gte(lean_toolchain_content.strip(), toolchain)
        if not on_target_toolchain:
            print(f"  ❌ Not on target toolchain (needs ≥ {toolchain}, but {branch} is on {lean_toolchain_content.strip()})")
            pr_title = f"chore: bump toolchain to {toolchain}"
            pr_info = pr_exists_with_title(url, pr_title, github_token)
            if pr_info:
                pr_number, pr_url = pr_info
                print(f"  ✅ PR with title '{pr_title}' exists: #{pr_number} ({pr_url})")
            else:
                print(f"  ❌ PR with title '{pr_title}' does not exist")
                print(f"     Run `script/release_steps.py {toolchain} {name}` to create it")
            repo_status[name] = False
            continue
        print(f"  ✅ On compatible toolchain (>= {toolchain})")

        # Special handling for ProofWidgets4
        if name == "ProofWidgets4":
            if not check_proofwidgets4_release(url, toolchain, github_token):
                repo_status[name] = False
                continue

        if check_tag:
            tag_exists_initially = tag_exists(url, toolchain, github_token)
            if not tag_exists_initially:                
                if args.dry_run:
                    print(f"  ❌ Tag {toolchain} does not exist. Run `script/push_repo_release_tag.py {org_repo} {branch} {toolchain}`.")
                    repo_status[name] = False
                    continue
                else:
                    print(f"  ⮕ Tag {toolchain} does not exist. Running `script/push_repo_release_tag.py {org_repo} {branch} {toolchain}`...")
                    
                    # Run the script to create the tag
                    subprocess.run(["script/push_repo_release_tag.py", org_repo, branch, toolchain])
                    
                    # Check again if the tag exists now
                    if not tag_exists(url, toolchain, github_token):
                        print(f"  ❌ Manual intervention required.")
                        repo_status[name] = False
                        continue
            
            # This will print in all successful cases - whether tag existed initially or was created successfully
            print(f"  ✅ Tag {toolchain} exists")

        if check_stable and not is_release_candidate(toolchain):
            if not is_merged_into_stable(url, toolchain, "stable", github_token, verbose):
                org_repo = extract_org_repo_from_url(url)
                if args.dry_run:
                    print(f"  ❌ Tag {toolchain} is not merged into stable")
                    print(f"     Run `script/merge_remote.py {org_repo} stable {toolchain}` to merge it")
                    repo_status[name] = False
                    continue
                else:
                    print(f"  ⮕ Tag {toolchain} is not merged into stable. Running `script/merge_remote.py {org_repo} stable {toolchain}`...")
                    
                    # Run the script to merge the tag
                    subprocess.run(["script/merge_remote.py", org_repo, "stable", toolchain])
                    
                    # Check again if the tag is merged now
                    if not is_merged_into_stable(url, toolchain, "stable", github_token, verbose):
                        print(f"  ❌ Manual intervention required.")
                        repo_status[name] = False
                        continue
            
            # This will print in all successful cases - whether tag was merged initially or was merged successfully
            print(f"  ✅ Tag {toolchain} is merged into stable")

        if check_bump:
            next_version = get_next_version(toolchain)
            bump_branch = f"bump/{next_version}"
            
            # For mathlib4, use the nightly-testing fork for bump branches
            bump_org_repo = org_repo
            bump_url = url
            if name == "mathlib4":
                bump_org_repo = "leanprover-community/mathlib4-nightly-testing"
                bump_url = "https://github.com/leanprover-community/mathlib4-nightly-testing"
            
            branch_created = False
            if not branch_exists(bump_url, bump_branch, github_token):
                if args.dry_run:
                    latest_nightly = get_latest_nightly_tag(github_token)
                    nightly_note = f" (will set theorem_ai-toolchain to {latest_nightly})" if name in ["batteries", "mathlib4"] and latest_nightly else ""
                    print(f"  ❌ Bump branch {bump_branch} does not exist. Run `gh api -X POST /repos/{bump_org_repo}/git/refs -f ref=refs/heads/{bump_branch} -f sha=$(gh api /repos/{org_repo}/git/refs/heads/{branch} --jq .object.sha)` to create it{nightly_note}.")
                    repo_status[name] = False
                    continue
                print(f"  ⮕ Bump branch {bump_branch} does not exist. Creating it...")
                result = run_command(f"gh api -X POST /repos/{bump_org_repo}/git/refs -f ref=refs/heads/{bump_branch} -f sha=$(gh api /repos/{org_repo}/git/refs/heads/{branch} --jq .object.sha)", check=False)
                if result.returncode != 0:
                    print(f"  ❌ Failed to create bump branch {bump_branch}")
                    repo_status[name] = False
                    continue
                branch_created = True
            
            print(f"  ✅ Bump branch {bump_branch} exists")
            
            # For batteries and mathlib4, update the theorem_ai-toolchain to the latest nightly
            if branch_created and name in ["batteries", "mathlib4"]:
                latest_nightly = get_latest_nightly_tag(github_token)
                if latest_nightly:
                    nightly_toolchain = f"leanprover/theorem_ai4:{latest_nightly}"
                    print(f"  ⮕ Updating theorem_ai-toolchain to {nightly_toolchain}...")
                    if update_lean_toolchain_in_branch(bump_org_repo, bump_branch, nightly_toolchain, github_token):
                        print(f"  ✅ Updated theorem_ai-toolchain to {nightly_toolchain}")
                    else:
                        print(f"  ❌ Failed to update theorem_ai-toolchain to {nightly_toolchain}")
                        repo_status[name] = False
                        continue
                else:
                    print(f"  ❌ Could not fetch latest nightly tag")
                    repo_status[name] = False
                    continue
            if not check_bump_branch_toolchain(bump_url, bump_branch, github_token):
                repo_status[name] = False
                continue

        repo_status[name] = success

    # Final check for theorem_ai4 master branch
    print("\nChecking theorem_ai4 master branch configuration...")
    next_version = get_next_version(toolchain)
    next_minor = int(next_version.split('.')[1])
    
    cmake_content = get_branch_content(lean_repo_url, "master", "src/CMakeLists.txt", github_token)
    if cmake_content is None:
        print("  ❌ Could not retrieve CMakeLists.txt from master")
    else:
        cmake_lines = cmake_content.splitlines()
        # Find the actual minor version in CMakeLists.txt
        for line in cmake_lines:
            if line.strip().startswith("set(LEAN_VERSION_MINOR "):
                actual_minor = int(line.split()[-1].rstrip(")"))
                version_minor_correct = actual_minor >= next_minor
                break
        else:
            version_minor_correct = False
            
        is_release_correct = any(
            l.strip().startswith("set(LEAN_VERSION_IS_RELEASE 0)") 
            for l in cmake_lines
        )
        
        if not (version_minor_correct and is_release_correct):
            print("  ❌ theorem_ai4 needs a \"begin dev cycle\" PR")
        else:
            print("  ✅ theorem_ai4 master branch is configured for next development cycle")

if __name__ == "__main__":
    main()
