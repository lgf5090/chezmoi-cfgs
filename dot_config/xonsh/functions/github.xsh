import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

from xonsh.built_ins import XSH


_GITHUB_API_BASE = "https://api.github.com"

_GITHUB_GLOBAL_OPTIONS = (
    "-h", "--help", "-r", "--repo", "-u", "--user", "-o", "--org", "-g", "--gist",
    "-a", "--api", "-s", "--search", "-q", "--query", "--limit", "--pages", "--jq", "--url",
)
_GITHUB_REPO_OPTIONS = (
    "--issues", "--issue", "--pulls", "--pull", "--releases", "--release",
    "--latest-release", "--branches", "--branch", "--commits", "--commit",
    "--contents", "--contributors", "--languages", "--tags", "--topics",
    "--stargazers", "--subscribers", "--forks", "--workflows",
)
_GITHUB_USER_OPTIONS = ("--repos", "--followers", "--following", "--gists", "--starred", "--orgs", "--events")
_GITHUB_ORG_OPTIONS = ("--repos", "--members", "--teams", "--events")
_GITHUB_SEARCH_OPTIONS = ("-s", "--search", "--search-repos", "--search-users", "--search-issues", "--search-code")

_GITHUB_REPO_FIELDS = (
    "id", "node_id", "name", "full_name", "owner", "private", "html_url", "description", "fork", "url",
    "forks_url", "keys_url", "collaborators_url", "teams_url", "hooks_url", "issue_events_url", "events_url",
    "assignees_url", "branches_url", "tags_url", "blobs_url", "git_tags_url", "git_refs_url", "trees_url",
    "statuses_url", "languages_url", "stargazers_url", "contributors_url", "subscribers_url", "subscription_url",
    "commits_url", "git_commits_url", "comments_url", "issue_comment_url", "contents_url", "compare_url",
    "merges_url", "archive_url", "downloads_url", "issues_url", "pulls_url", "milestones_url", "notifications_url",
    "labels_url", "releases_url", "deployments_url", "created_at", "updated_at", "pushed_at", "git_url", "ssh_url",
    "clone_url", "svn_url", "homepage", "size", "stargazers_count", "watchers_count", "language", "has_issues",
    "has_projects", "has_downloads", "has_wiki", "has_pages", "has_discussions", "forks_count", "mirror_url",
    "archived", "disabled", "open_issues_count", "license", "allow_forking", "is_template",
    "web_commit_signoff_required", "topics", "visibility", "forks", "open_issues", "watchers", "default_branch",
    "network_count", "subscribers_count", "organization", "parent", "source", "owner.login", "owner.id",
    "owner.node_id", "owner.avatar_url", "owner.html_url", "owner.type", "license.key", "license.name",
    "license.spdx_id",
)
_GITHUB_USER_FIELDS = (
    "login", "id", "node_id", "avatar_url", "gravatar_id", "url", "html_url", "followers_url", "following_url",
    "gists_url", "starred_url", "subscriptions_url", "organizations_url", "repos_url", "events_url",
    "received_events_url", "type", "site_admin", "name", "company", "blog", "location", "email", "hireable",
    "bio", "twitter_username", "public_repos", "public_gists", "followers", "following", "created_at",
    "updated_at", "plan",
)
_GITHUB_ORG_FIELDS = (
    "login", "id", "node_id", "url", "repos_url", "events_url", "hooks_url", "issues_url", "members_url",
    "public_members_url", "avatar_url", "description", "name", "company", "blog", "location", "email",
    "twitter_username", "is_verified", "has_organization_projects", "has_repository_projects", "public_repos",
    "public_gists", "followers", "following", "html_url", "created_at", "updated_at", "type",
    "total_private_repos", "owned_private_repos", "private_gists", "disk_usage", "collaborators", "billing_email",
    "default_repository_permission", "members_can_create_repositories", "two_factor_requirement_enabled",
)
_GITHUB_GIST_FIELDS = (
    "url", "forks_url", "commits_url", "id", "node_id", "git_pull_url", "git_push_url", "html_url", "files",
    "public", "created_at", "updated_at", "description", "comments", "user", "comments_url", "owner", "truncated",
    "owner.login", "owner.id", "owner.avatar_url",
)
_GITHUB_ISSUE_FIELDS = (
    "url", "repository_url", "labels_url", "comments_url", "events_url", "html_url", "id", "node_id", "number",
    "title", "user", "labels", "state", "locked", "assignee", "assignees", "milestone", "comments", "created_at",
    "updated_at", "closed_at", "author_association", "active_lock_reason", "body", "closed_by", "reactions",
    "timeline_url", "performed_via_github_app", "state_reason", "user.login", "user.id", "pull_request",
)
_GITHUB_PULL_FIELDS = (
    "url", "id", "node_id", "html_url", "diff_url", "patch_url", "issue_url", "commits_url", "review_comments_url",
    "review_comment_url", "comments_url", "statuses_url", "number", "state", "locked", "title", "user", "body",
    "labels", "milestone", "active_lock_reason", "created_at", "updated_at", "closed_at", "merged_at",
    "merge_commit_sha", "assignee", "assignees", "requested_reviewers", "requested_teams", "head", "base",
    "author_association", "draft", "merged", "mergeable", "rebaseable", "mergeable_state", "merged_by", "comments",
    "review_comments", "maintainer_can_modify", "commits", "additions", "deletions", "changed_files", "user.login",
    "head.ref", "head.sha", "head.repo", "base.ref", "base.sha", "base.repo",
)
_GITHUB_RELEASE_FIELDS = (
    "url", "html_url", "assets_url", "upload_url", "tarball_url", "zipball_url", "id", "node_id", "tag_name",
    "target_commitish", "name", "body", "draft", "prerelease", "created_at", "published_at", "author", "assets",
    "author.login", "author.id",
)
_GITHUB_BRANCH_FIELDS = ("name", "commit", "protected", "protection", "protection_url", "commit.sha", "commit.url")
_GITHUB_COMMIT_FIELDS = (
    "sha", "node_id", "commit", "url", "html_url", "comments_url", "author", "committer", "parents", "stats",
    "files", "commit.author.name", "commit.author.email", "commit.author.date", "commit.committer.name",
    "commit.committer.email", "commit.committer.date", "commit.message", "commit.tree", "commit.url",
    "commit.comment_count", "author.login", "committer.login",
)
_GITHUB_CONTENTS_FIELDS = (
    "type", "encoding", "size", "name", "path", "content", "sha", "url", "git_url", "html_url", "download_url",
    "links", "_links.self", "_links.git", "_links.html",
)
_GITHUB_SEARCH_FIELDS = (
    "total_count", "incomplete_results", "items", "items.id", "items.node_id", "items.name", "items.full_name",
    "items.login", "items.html_url", "items.description", "items.stargazers_count", "items.updated_at",
    "items.created_at", "items.language", "items.score",
)


def _github_usage():
    print(
        """github - small GitHub REST API helper

usage:
  github -h | --help
  github [field ...]
  github -r OWNER/REPO [repo-option] [field ...]
  github -u USER [user-option] [field ...]
  github -o ORG [org-option] [field ...]
  github -g GIST_ID [field ...]
  github --api PATH [field ...]
  github -s QUERY [--limit N] [--pages N] [field ...]
  github --search-repos QUERY [field ...]
  github --search-users QUERY [field ...]
  github --search-issues QUERY [field ...]
  github --search-code QUERY [field ...]

authentication:
  Uses GITHUB_TOKEN as Authorization: Bearer $GITHUB_TOKEN when set.
  Else uses GH_TOKEN as Authorization: Bearer $GH_TOKEN when set.

defaults:
  github
      GET /repos/ollama/ollama
  github -r ollama/ollama
      GET /repos/ollama/ollama

common options:
  -r, --repo OWNER/REPO       repo endpoint, default: ollama/ollama
  -u, --user USER             user endpoint
  -o, --org ORG               organization endpoint
  -g, --gist GIST_ID          gist endpoint
  -a, --api PATH              raw GitHub API path
  -s, --search QUERY          search repositories and show a ranked summary
  -q, --query KEY=VALUE       append query parameter, repeatable
  --limit N                   limit displayed search rows, default: 15
  --pages N                   fetch N search result pages before ranking, default: 1
  --jq FILTER                 run a raw jq filter against the response
  --url                       print the API URL instead of requesting it
  -h, --help                  show this help

repo options:
  --issues, --issue NUMBER, --pulls, --pull NUMBER
  --releases, --release TAG, --latest-release
  --branches, --branch NAME, --commits, --commit SHA
  --contents PATH, --contributors, --languages, --tags, --topics
  --stargazers, --subscribers, --forks, --workflows

user options:
  --repos, --followers, --following, --gists, --starred, --orgs, --events

org options:
  --repos, --members, --teams, --events

search options:
  -s, --search QUERY          ranked repo search, default: --limit 15 --pages 1
  github -s wsl --limit 30 --pages 2
      Fetch two search pages, rank locally by stars, updated_at, created_at.
  --search-repos QUERY, --search-users QUERY, --search-issues QUERY, --search-code QUERY

fields:
  Field names are JSON paths. Examples: id, name, owner.login, created_at"""
    )


def _github_urlencode(value):
    return urllib.parse.quote(value, safe="._-~")


def _github_query_pair(value):
    key, sep, val = value.partition("=")
    if not sep or not key:
        raise ValueError(f"github: query requires KEY=VALUE: {value}")
    return f"{_github_urlencode(key)}={_github_urlencode(val)}"


def _github_join_query(url, query):
    if not query:
        return url
    separator = "&" if "?" in url else "?"
    return f"{url}{separator}{'&'.join(query)}"


def _github_headers():
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _github_get_path(value, parts):
    if not parts:
        return value
    if isinstance(value, list):
        return [_github_get_path(item, parts) for item in value]
    if isinstance(value, dict):
        return _github_get_path(value.get(parts[0]), parts[1:])
    return None


def _github_get_field(data, field):
    return _github_get_path(data, field.split("."))


def _github_select_fields(data, fields):
    if len(fields) == 1:
        return _github_get_field(data, fields[0])
    return {field: _github_get_field(data, field) for field in fields}


def _github_print_value(value):
    if isinstance(value, (dict, list)):
        print(json.dumps(value, ensure_ascii=False, indent=2))
    elif value is None:
        print("null")
    elif isinstance(value, bool):
        print("true" if value else "false")
    else:
        print(value)


def _github_need_value(args, index, option, label):
    if index + 1 >= len(args) or args[index + 1] == "":
        raise ValueError(f"github: {option} requires {label}")
    return args[index + 1]


def _github_positive_int(value, option):
    try:
        number = int(value)
    except ValueError as exc:
        raise ValueError(f"github: {option} requires a positive integer") from exc
    if number <= 0:
        raise ValueError(f"github: {option} requires a positive integer")
    return number


def _github_search_field(field):
    if field == "items":
        return "."
    if field.startswith("items."):
        return field[6:]
    return field


def _github_search_items(items, limit):
    return sorted(
        items,
        key=lambda item: (
            item.get("stargazers_count") or 0,
            item.get("updated_at") or "",
            item.get("created_at") or "",
        ),
        reverse=True,
    )[:limit]


def _github_select_search_fields(items, fields):
    item_fields = [_github_search_field(field) for field in fields]
    if len(item_fields) == 1 and item_fields[0] == ".":
        return items
    if "." in item_fields:
        raise ValueError("github: items cannot be selected with other search fields")
    return [_github_select_fields(item, item_fields) for item in items]


def _github_clean_cell(value):
    if value is None:
        return ""
    return str(value).replace("\t", " ").replace("\r", " ").replace("\n", " ")


def _github_print_search_items(items):
    print("\t".join(("stars", "updated", "created", "repo", "url", "description")))
    for item in items:
        print(
            "\t".join(
                (
                    str(item.get("stargazers_count") or 0),
                    _github_clean_cell(item.get("updated_at"))[:10],
                    _github_clean_cell(item.get("created_at"))[:10],
                    _github_clean_cell(item.get("full_name")),
                    _github_clean_cell(item.get("html_url")),
                    _github_clean_cell(item.get("description")),
                )
            )
        )


def _github_request_json(url):
    request = urllib.request.Request(url, headers=_github_headers())
    with urllib.request.urlopen(request) as response:
        return json.loads(response.read().decode("utf-8"))


def _github(args, stdin=None):
    args = list(args)
    kind = "repo"
    target = "ollama/ollama"
    endpoint_path = ""
    raw_path = ""
    query = []
    fields = []
    jq_filter = ""
    print_url = False
    search_display = False
    search_limit = 15
    search_pages = 1

    try:
        index = 0
        while index < len(args):
            arg = args[index]
            if arg in ("-h", "--help"):
                _github_usage()
                return 0
            if arg in ("-r", "--repo"):
                target = _github_need_value(args, index, arg, "OWNER/REPO")
                kind = "repo"
                endpoint_path = ""
                index += 2
                continue
            if arg in ("-u", "--user"):
                target = _github_need_value(args, index, arg, "USER")
                kind = "user"
                endpoint_path = ""
                index += 2
                continue
            if arg in ("-o", "--org"):
                target = _github_need_value(args, index, arg, "ORG")
                kind = "org"
                endpoint_path = ""
                index += 2
                continue
            if arg in ("-g", "--gist"):
                target = _github_need_value(args, index, arg, "GIST_ID")
                kind = "gist"
                endpoint_path = ""
                index += 2
                continue
            if arg in ("-a", "--api"):
                raw_path = _github_need_value(args, index, arg, "PATH").lstrip("/")
                kind = "raw"
                endpoint_path = ""
                index += 2
                continue
            if arg in ("-s", "--search"):
                raw_path = "search/repositories"
                kind = "raw"
                endpoint_path = ""
                search_display = True
                query.append(f"q={_github_urlencode(_github_need_value(args, index, arg, 'QUERY'))}")
                index += 2
                continue
            if arg in ("--search-repos", "--search-users", "--search-issues", "--search-code"):
                search_path = {
                    "--search-repos": "search/repositories",
                    "--search-users": "search/users",
                    "--search-issues": "search/issues",
                    "--search-code": "search/code",
                }[arg]
                raw_path = search_path
                kind = "raw"
                query.append(f"q={_github_urlencode(_github_need_value(args, index, arg, 'QUERY'))}")
                index += 2
                continue
            if arg in ("-q", "--query"):
                query.append(_github_query_pair(_github_need_value(args, index, arg, "KEY=VALUE")))
                index += 2
                continue
            if arg == "--limit":
                search_limit = _github_positive_int(_github_need_value(args, index, arg, "N"), arg)
                index += 2
                continue
            if arg == "--pages":
                search_pages = _github_positive_int(_github_need_value(args, index, arg, "N"), arg)
                index += 2
                continue
            if arg == "--jq":
                jq_filter = _github_need_value(args, index, arg, "FILTER")
                index += 2
                continue
            if arg == "--url":
                print_url = True
                index += 1
                continue
            if arg == "--issues":
                kind = "repo"; endpoint_path = "issues"; index += 1; continue
            if arg == "--issue":
                kind = "repo"; endpoint_path = f"issues/{_github_need_value(args, index, arg, 'NUMBER')}"; index += 2; continue
            if arg == "--pulls":
                kind = "repo"; endpoint_path = "pulls"; index += 1; continue
            if arg == "--pull":
                kind = "repo"; endpoint_path = f"pulls/{_github_need_value(args, index, arg, 'NUMBER')}"; index += 2; continue
            if arg == "--releases":
                kind = "repo"; endpoint_path = "releases"; index += 1; continue
            if arg == "--release":
                kind = "repo"; endpoint_path = f"releases/tags/{_github_need_value(args, index, arg, 'TAG')}"; index += 2; continue
            if arg == "--latest-release":
                kind = "repo"; endpoint_path = "releases/latest"; index += 1; continue
            if arg == "--branches":
                kind = "repo"; endpoint_path = "branches"; index += 1; continue
            if arg == "--branch":
                kind = "repo"; endpoint_path = f"branches/{_github_need_value(args, index, arg, 'NAME')}"; index += 2; continue
            if arg == "--commits":
                kind = "repo"; endpoint_path = "commits"; index += 1; continue
            if arg == "--commit":
                kind = "repo"; endpoint_path = f"commits/{_github_need_value(args, index, arg, 'SHA')}"; index += 2; continue
            if arg == "--contents":
                kind = "repo"; endpoint_path = f"contents/{_github_need_value(args, index, arg, 'PATH').lstrip('/')}"; index += 2; continue
            if arg in ("--contributors", "--languages", "--tags", "--topics", "--stargazers", "--subscribers", "--forks"):
                kind = "repo"; endpoint_path = arg[2:]; index += 1; continue
            if arg == "--workflows":
                kind = "repo"; endpoint_path = "actions/workflows"; index += 1; continue
            if arg in ("--repos", "--followers", "--following", "--gists", "--starred", "--orgs", "--events", "--members", "--teams"):
                endpoint_path = arg[2:]; index += 1; continue
            if arg == "--":
                fields.extend(args[index + 1:])
                break
            if arg.startswith("-"):
                raise ValueError(f"github: unknown option: {arg}")
            fields.append(arg)
            index += 1

        if kind == "repo":
            if "/" not in target:
                raise ValueError(f"github: repo must be OWNER/REPO: {target}")
            raw_path = f"repos/{target}"
        elif kind == "user":
            raw_path = f"users/{target}"
        elif kind == "org":
            raw_path = f"orgs/{target}"
        elif kind == "gist":
            raw_path = f"gists/{target}"

        if endpoint_path:
            raw_path = f"{raw_path}/{endpoint_path}"

        url_query = list(query)
        if search_display:
            url_query.extend(("per_page=100", "page=1"))
        url = _github_join_query(f"{_GITHUB_API_BASE}/{raw_path.lstrip('/')}", url_query)
        if print_url:
            print(url)
            return 0

        if search_display:
            responses = []
            for page in range(1, search_pages + 1):
                page_query = [*query, "per_page=100", f"page={page}"]
                page_url = _github_join_query(f"{_GITHUB_API_BASE}/{raw_path.lstrip('/')}", page_query)
                responses.append(_github_request_json(page_url))

            items = []
            for response in responses:
                items.extend(response.get("items") or [])
            data = {
                "total_count": max((response.get("total_count") or 0 for response in responses), default=0),
                "incomplete_results": any(response.get("incomplete_results") or False for response in responses),
                "items": items,
            }

            if jq_filter:
                if not shutil.which("jq"):
                    print("github: jq is required when using --jq", file=sys.stderr)
                    return 127
                result = subprocess.run(
                    ["jq", "-r", jq_filter],
                    input=json.dumps(data),
                    text=True,
                    check=False,
                )
                return result.returncode

            sorted_items = _github_search_items(items, search_limit)
            if fields:
                _github_print_value(_github_select_search_fields(sorted_items, fields))
                return 0

            _github_print_search_items(sorted_items)
            return 0

        request = urllib.request.Request(url, headers=_github_headers())
        with urllib.request.urlopen(request) as response:
            body = response.read().decode("utf-8")

        if jq_filter or fields:
            data = json.loads(body)
            if jq_filter:
                if not shutil.which("jq"):
                    print("github: jq is required when using --jq", file=sys.stderr)
                    return 127
                result = subprocess.run(
                    ["jq", "-r", jq_filter],
                    input=json.dumps(data),
                    text=True,
                    check=False,
                )
                return result.returncode
            _github_print_value(_github_select_fields(data, fields))
            return 0

        print(body, end="" if body.endswith("\n") else "\n")
        return 0
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", "replace")
        print(message or str(exc), file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"github: request failed: {exc.reason}", file=sys.stderr)
        return 1
    except (ValueError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2


def _github_filter(candidates, prefix):
    return {candidate for candidate in candidates if candidate.startswith(prefix)}


def _github_completion_fields(completed):
    kind = "repo"
    sub = ""
    for item in completed:
        if item in ("-u", "--user"):
            kind = "user"
        elif item in ("-o", "--org"):
            kind = "org"
        elif item in ("-g", "--gist"):
            kind = "gist"
        elif item in ("-a", "--api"):
            kind = "raw"
        elif item in ("--issues", "--issue"):
            sub = "issue"
        elif item in ("--pulls", "--pull"):
            sub = "pull"
        elif item in ("--releases", "--release", "--latest-release"):
            sub = "release"
        elif item in ("--branches", "--branch"):
            sub = "branch"
        elif item in ("--commits", "--commit"):
            sub = "commit"
        elif item == "--contents":
            sub = "contents"
        elif item in ("-s", "--search"):
            kind = "search"
        elif item.startswith("--search-"):
            kind = "search"

    if kind == "user":
        return _GITHUB_USER_FIELDS
    if kind == "org":
        return _GITHUB_ORG_FIELDS
    if kind == "gist":
        return _GITHUB_GIST_FIELDS
    if kind == "search":
        return _GITHUB_SEARCH_FIELDS
    if sub == "issue":
        return _GITHUB_ISSUE_FIELDS
    if sub == "pull":
        return _GITHUB_PULL_FIELDS
    if sub == "release":
        return _GITHUB_RELEASE_FIELDS
    if sub == "branch":
        return _GITHUB_BRANCH_FIELDS
    if sub == "commit":
        return _GITHUB_COMMIT_FIELDS
    if sub == "contents":
        return _GITHUB_CONTENTS_FIELDS
    return _GITHUB_REPO_FIELDS


def _github_completion(context):
    command = getattr(context, "command", None)
    if command is None or not command.completing_command("github"):
        return None

    current = command.prefix
    completed = [arg.value for arg in command.args[1:command.arg_index]]
    previous = completed[-1] if completed else ""

    if previous in ("-r", "--repo"):
        return _github_filter(("ollama/ollama", "cli/cli", "torvalds/linux", "kubernetes/kubernetes"), current)
    if previous in ("-u", "--user"):
        return _github_filter(("lgf-136", "torvalds", "github", "actions"), current)
    if previous in ("-o", "--org"):
        return _github_filter(("github", "kubernetes", "openai", "microsoft"), current)
    if previous in ("-a", "--api"):
        return _github_filter(("repos/ollama/ollama", "users/lgf-136", "orgs/github", "gists", "search/repositories", "search/users", "search/issues", "search/code", "rate_limit", "meta"), current)
    if previous in ("-q", "--query"):
        return _github_filter(("per_page=100", "page=1", "state=open", "state=closed", "state=all", "sort=updated", "direction=desc", "type=owner", "type=member"), current)
    if previous == "--limit":
        return _github_filter(("15", "30", "50", "100"), current)
    if previous == "--pages":
        return _github_filter(("1", "2", "3", "5"), current)
    if previous in ("--issue", "--pull"):
        return _github_filter(("1", "2", "3", "4", "5", "10", "100"), current)
    if previous == "--release":
        return _github_filter(("latest", "v1.0.0"), current)
    if previous == "--branch":
        return _github_filter(("main", "master", "develop"), current)
    if previous in ("-g", "--gist", "--jq", "-s", "--search", "--search-repos", "--search-users", "--search-issues", "--search-code"):
        return None

    if current.startswith("-"):
        return _github_filter((*_GITHUB_GLOBAL_OPTIONS, *_GITHUB_REPO_OPTIONS, *_GITHUB_USER_OPTIONS, *_GITHUB_ORG_OPTIONS, *_GITHUB_SEARCH_OPTIONS), current)

    return _github_filter(_github_completion_fields(completed), current)


aliases["github"] = _github
_github_completion.contextual = True
XSH.completers["github"] = _github_completion
