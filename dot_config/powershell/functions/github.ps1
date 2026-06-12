$script:GitHubApiBase = 'https://api.github.com'

$script:GitHubGlobalOptions = @('-h', '--help', '-r', '--repo', '-u', '--user', '-o', '--org', '-g', '--gist', '-a', '--api', '-s', '--search', '-q', '--query', '--limit', '--pages', '--jq', '--url')
$script:GitHubRepoOptions = @('--issues', '--issue', '--pulls', '--pull', '--releases', '--release', '--latest-release', '--branches', '--branch', '--commits', '--commit', '--contents', '--contributors', '--languages', '--tags', '--topics', '--stargazers', '--subscribers', '--forks', '--workflows')
$script:GitHubUserOptions = @('--repos', '--followers', '--following', '--gists', '--starred', '--orgs', '--events')
$script:GitHubOrgOptions = @('--repos', '--members', '--teams', '--events')
$script:GitHubSearchOptions = @('-s', '--search', '--search-repos', '--search-users', '--search-issues', '--search-code')

$script:GitHubRepoFields = @('id', 'node_id', 'name', 'full_name', 'owner', 'private', 'html_url', 'description', 'fork', 'url', 'forks_url', 'keys_url', 'collaborators_url', 'teams_url', 'hooks_url', 'issue_events_url', 'events_url', 'assignees_url', 'branches_url', 'tags_url', 'blobs_url', 'git_tags_url', 'git_refs_url', 'trees_url', 'statuses_url', 'languages_url', 'stargazers_url', 'contributors_url', 'subscribers_url', 'subscription_url', 'commits_url', 'git_commits_url', 'comments_url', 'issue_comment_url', 'contents_url', 'compare_url', 'merges_url', 'archive_url', 'downloads_url', 'issues_url', 'pulls_url', 'milestones_url', 'notifications_url', 'labels_url', 'releases_url', 'deployments_url', 'created_at', 'updated_at', 'pushed_at', 'git_url', 'ssh_url', 'clone_url', 'svn_url', 'homepage', 'size', 'stargazers_count', 'watchers_count', 'language', 'has_issues', 'has_projects', 'has_downloads', 'has_wiki', 'has_pages', 'has_discussions', 'forks_count', 'mirror_url', 'archived', 'disabled', 'open_issues_count', 'license', 'allow_forking', 'is_template', 'web_commit_signoff_required', 'topics', 'visibility', 'forks', 'open_issues', 'watchers', 'default_branch', 'network_count', 'subscribers_count', 'organization', 'parent', 'source', 'owner.login', 'owner.id', 'owner.node_id', 'owner.avatar_url', 'owner.html_url', 'owner.type', 'license.key', 'license.name', 'license.spdx_id')
$script:GitHubUserFields = @('login', 'id', 'node_id', 'avatar_url', 'gravatar_id', 'url', 'html_url', 'followers_url', 'following_url', 'gists_url', 'starred_url', 'subscriptions_url', 'organizations_url', 'repos_url', 'events_url', 'received_events_url', 'type', 'site_admin', 'name', 'company', 'blog', 'location', 'email', 'hireable', 'bio', 'twitter_username', 'public_repos', 'public_gists', 'followers', 'following', 'created_at', 'updated_at', 'plan')
$script:GitHubOrgFields = @('login', 'id', 'node_id', 'url', 'repos_url', 'events_url', 'hooks_url', 'issues_url', 'members_url', 'public_members_url', 'avatar_url', 'description', 'name', 'company', 'blog', 'location', 'email', 'twitter_username', 'is_verified', 'has_organization_projects', 'has_repository_projects', 'public_repos', 'public_gists', 'followers', 'following', 'html_url', 'created_at', 'updated_at', 'type', 'total_private_repos', 'owned_private_repos', 'private_gists', 'disk_usage', 'collaborators', 'billing_email', 'default_repository_permission', 'members_can_create_repositories', 'two_factor_requirement_enabled')
$script:GitHubGistFields = @('url', 'forks_url', 'commits_url', 'id', 'node_id', 'git_pull_url', 'git_push_url', 'html_url', 'files', 'public', 'created_at', 'updated_at', 'description', 'comments', 'user', 'comments_url', 'owner', 'truncated', 'owner.login', 'owner.id', 'owner.avatar_url')
$script:GitHubIssueFields = @('url', 'repository_url', 'labels_url', 'comments_url', 'events_url', 'html_url', 'id', 'node_id', 'number', 'title', 'user', 'labels', 'state', 'locked', 'assignee', 'assignees', 'milestone', 'comments', 'created_at', 'updated_at', 'closed_at', 'author_association', 'active_lock_reason', 'body', 'closed_by', 'reactions', 'timeline_url', 'performed_via_github_app', 'state_reason', 'user.login', 'user.id', 'pull_request')
$script:GitHubPullFields = @('url', 'id', 'node_id', 'html_url', 'diff_url', 'patch_url', 'issue_url', 'commits_url', 'review_comments_url', 'review_comment_url', 'comments_url', 'statuses_url', 'number', 'state', 'locked', 'title', 'user', 'body', 'labels', 'milestone', 'active_lock_reason', 'created_at', 'updated_at', 'closed_at', 'merged_at', 'merge_commit_sha', 'assignee', 'assignees', 'requested_reviewers', 'requested_teams', 'head', 'base', 'author_association', 'draft', 'merged', 'mergeable', 'rebaseable', 'mergeable_state', 'merged_by', 'comments', 'review_comments', 'maintainer_can_modify', 'commits', 'additions', 'deletions', 'changed_files', 'user.login', 'head.ref', 'head.sha', 'head.repo', 'base.ref', 'base.sha', 'base.repo')
$script:GitHubReleaseFields = @('url', 'html_url', 'assets_url', 'upload_url', 'tarball_url', 'zipball_url', 'id', 'node_id', 'tag_name', 'target_commitish', 'name', 'body', 'draft', 'prerelease', 'created_at', 'published_at', 'author', 'assets', 'author.login', 'author.id')
$script:GitHubBranchFields = @('name', 'commit', 'protected', 'protection', 'protection_url', 'commit.sha', 'commit.url')
$script:GitHubCommitFields = @('sha', 'node_id', 'commit', 'url', 'html_url', 'comments_url', 'author', 'committer', 'parents', 'stats', 'files', 'commit.author.name', 'commit.author.email', 'commit.author.date', 'commit.committer.name', 'commit.committer.email', 'commit.committer.date', 'commit.message', 'commit.tree', 'commit.url', 'commit.comment_count', 'author.login', 'committer.login')
$script:GitHubContentsFields = @('type', 'encoding', 'size', 'name', 'path', 'content', 'sha', 'url', 'git_url', 'html_url', 'download_url', 'links', '_links.self', '_links.git', '_links.html')
$script:GitHubSearchFields = @('total_count', 'incomplete_results', 'items', 'items.id', 'items.node_id', 'items.name', 'items.full_name', 'items.login', 'items.html_url', 'items.description', 'items.stargazers_count', 'items.updated_at', 'items.created_at', 'items.language', 'items.score')

function Show-GitHubHelp {
    @'
github - small GitHub REST API helper

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
  Field names are property paths. Examples: id, name, owner.login, created_at
'@
}

function ConvertTo-GitHubQueryValue {
    param([Parameter(Mandatory)][string]$Value)
    [System.Uri]::EscapeDataString($Value)
}

function New-GitHubQueryPair {
    param([Parameter(Mandatory)][string]$Value)
    $parts = $Value.Split('=', 2)
    if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0])) {
        throw "github: query requires KEY=VALUE: $Value"
    }
    "$(ConvertTo-GitHubQueryValue $parts[0])=$(ConvertTo-GitHubQueryValue $parts[1])"
}

function Join-GitHubQuery {
    param(
        [Parameter(Mandatory)][string]$Url,
        [string[]]$Query
    )
    if (-not $Query -or $Query.Count -eq 0) { return $Url }
    $separator = if ($Url.Contains('?')) { '&' } else { '?' }
    "$Url$separator$($Query -join '&')"
}

function Get-GitHubHeaders {
    $headers = @{
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $headers.Authorization = "Bearer $env:GITHUB_TOKEN"
    } elseif (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
        $headers.Authorization = "Bearer $env:GH_TOKEN"
    }
    $headers
}

function Get-GitHubPropertyValue {
    param(
        [Parameter(Mandatory)]$InputObject,
        [Parameter(Mandatory)][string]$Field
    )

    $value = $InputObject
    foreach ($part in $Field -split '\.') {
        if ($null -eq $value) { return $null }
        if ($value -is [System.Collections.IDictionary]) {
            $value = $value[$part]
            continue
        }
        $property = $value.PSObject.Properties[$part]
        if ($null -eq $property) { return $null }
        $value = $property.Value
    }
    $value
}

function Select-GitHubFields {
    param(
        [Parameter(Mandatory)]$InputObject,
        [Parameter(Mandatory)][string[]]$Fields
    )

    if ($Fields.Count -eq 1) {
        return (Get-GitHubPropertyValue -InputObject $InputObject -Field $Fields[0])
    }

    $selected = [ordered]@{}
    foreach ($field in $Fields) {
        $selected[$field] = Get-GitHubPropertyValue -InputObject $InputObject -Field $field
    }
    [pscustomobject]$selected
}

function Convert-GitHubPositiveInt {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Option
    )

    $number = 0
    if (-not [int]::TryParse($Value, [ref]$number) -or $number -le 0) {
        throw "github: $Option requires a positive integer"
    }
    $number
}

function Convert-GitHubSearchField {
    param([Parameter(Mandatory)][string]$Field)

    if ($Field -eq 'items') { return '.' }
    if ($Field.StartsWith('items.')) { return $Field.Substring(6) }
    $Field
}

function Get-GitHubSearchItems {
    param(
        $Items,
        [Parameter(Mandatory)][int]$Limit
    )

    @($Items) |
        Sort-Object `
            @{ Expression = { if ($null -ne $_.stargazers_count) { [int]$_.stargazers_count } else { 0 } }; Descending = $true }, `
            @{ Expression = { if ($null -ne $_.updated_at) { [string]$_.updated_at } else { '' } }; Descending = $true }, `
            @{ Expression = { if ($null -ne $_.created_at) { [string]$_.created_at } else { '' } }; Descending = $true } |
        Select-Object -First $Limit
}

function Select-GitHubSearchFields {
    param(
        [Parameter(Mandatory)]$Items,
        [Parameter(Mandatory)][string[]]$Fields
    )

    $itemFields = @($Fields | ForEach-Object { Convert-GitHubSearchField $_ })
    if ($itemFields.Count -eq 1 -and $itemFields[0] -eq '.') {
        return $Items
    }
    if ($itemFields -contains '.') {
        throw 'github: items cannot be selected with other search fields'
    }

    foreach ($item in @($Items)) {
        Select-GitHubFields -InputObject $item -Fields $itemFields
    }
}

function Format-GitHubSearchResults {
    param([Parameter(Mandatory)]$Items)

    foreach ($item in @($Items)) {
        [pscustomobject]([ordered]@{
            stars       = if ($null -ne $item.stargazers_count) { [int]$item.stargazers_count } else { 0 }
            updated_at  = if ($null -ne $item.updated_at) { [string]$item.updated_at } else { '' }
            created_at  = if ($null -ne $item.created_at) { [string]$item.created_at } else { '' }
            full_name   = if ($null -ne $item.full_name) { [string]$item.full_name } else { '' }
            html_url    = if ($null -ne $item.html_url) { [string]$item.html_url } else { '' }
            description = if ($null -ne $item.description) { [string]$item.description } else { '' }
        })
    }
}

function Get-GitHubCompletionFields {
    param([string[]]$Tokens)

    $kind = 'repo'
    $sub = ''
    foreach ($token in $Tokens) {
        switch -Wildcard ($token) {
            '-u' { $kind = 'user'; break }
            '--user' { $kind = 'user'; break }
            '-o' { $kind = 'org'; break }
            '--org' { $kind = 'org'; break }
            '-g' { $kind = 'gist'; break }
            '--gist' { $kind = 'gist'; break }
            '-a' { $kind = 'raw'; break }
            '--api' { $kind = 'raw'; break }
            '--issues' { $sub = 'issue'; break }
            '--issue' { $sub = 'issue'; break }
            '--pulls' { $sub = 'pull'; break }
            '--pull' { $sub = 'pull'; break }
            '--releases' { $sub = 'release'; break }
            '--release' { $sub = 'release'; break }
            '--latest-release' { $sub = 'release'; break }
            '--branches' { $sub = 'branch'; break }
            '--branch' { $sub = 'branch'; break }
            '--commits' { $sub = 'commit'; break }
            '--commit' { $sub = 'commit'; break }
            '--contents' { $sub = 'contents'; break }
            '-s' { $kind = 'search'; break }
            '--search' { $kind = 'search'; break }
            '--search-*' { $kind = 'search'; break }
        }
    }

    if ($kind -eq 'user') { return $script:GitHubUserFields }
    if ($kind -eq 'org') { return $script:GitHubOrgFields }
    if ($kind -eq 'gist') { return $script:GitHubGistFields }
    if ($kind -eq 'search') { return $script:GitHubSearchFields }
    switch ($sub) {
        'issue' { return $script:GitHubIssueFields }
        'pull' { return $script:GitHubPullFields }
        'release' { return $script:GitHubReleaseFields }
        'branch' { return $script:GitHubBranchFields }
        'commit' { return $script:GitHubCommitFields }
        'contents' { return $script:GitHubContentsFields }
        default { return $script:GitHubRepoFields }
    }
}

function github {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $kind = 'repo'
    $target = 'ollama/ollama'
    $endpointPath = ''
    $rawPath = ''
    $query = New-Object System.Collections.Generic.List[string]
    $fields = New-Object System.Collections.Generic.List[string]
    $jqFilter = ''
    $printUrl = $false
    $searchDisplay = $false
    $searchLimit = 15
    $searchPages = 1

    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-GitHubHelp
                return
            }
            { $_ -in @('-r', '--repo') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires OWNER/REPO" }
                $kind = 'repo'; $target = $Arguments[$i]; $endpointPath = ''
                continue
            }
            { $_ -in @('-u', '--user') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires USER" }
                $kind = 'user'; $target = $Arguments[$i]; $endpointPath = ''
                continue
            }
            { $_ -in @('-o', '--org') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires ORG" }
                $kind = 'org'; $target = $Arguments[$i]; $endpointPath = ''
                continue
            }
            { $_ -in @('-g', '--gist') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires GIST_ID" }
                $kind = 'gist'; $target = $Arguments[$i]; $endpointPath = ''
                continue
            }
            { $_ -in @('-a', '--api') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires PATH" }
                $kind = 'raw'; $rawPath = $Arguments[$i].TrimStart('/'); $endpointPath = ''
                continue
            }
            { $_ -in @('-s', '--search') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires QUERY" }
                $kind = 'raw'; $rawPath = 'search/repositories'; $endpointPath = ''; $searchDisplay = $true
                $query.Add("q=$(ConvertTo-GitHubQueryValue $Arguments[$i])")
                continue
            }
            '--search-repos' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --search-repos requires QUERY' }
                $kind = 'raw'; $rawPath = 'search/repositories'; $query.Add("q=$(ConvertTo-GitHubQueryValue $Arguments[$i])")
                continue
            }
            '--search-users' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --search-users requires QUERY' }
                $kind = 'raw'; $rawPath = 'search/users'; $query.Add("q=$(ConvertTo-GitHubQueryValue $Arguments[$i])")
                continue
            }
            '--search-issues' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --search-issues requires QUERY' }
                $kind = 'raw'; $rawPath = 'search/issues'; $query.Add("q=$(ConvertTo-GitHubQueryValue $Arguments[$i])")
                continue
            }
            '--search-code' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --search-code requires QUERY' }
                $kind = 'raw'; $rawPath = 'search/code'; $query.Add("q=$(ConvertTo-GitHubQueryValue $Arguments[$i])")
                continue
            }
            { $_ -in @('-q', '--query') } {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw "github: $arg requires KEY=VALUE" }
                $query.Add((New-GitHubQueryPair $Arguments[$i]))
                continue
            }
            '--limit' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --limit requires a positive integer' }
                $searchLimit = Convert-GitHubPositiveInt -Value $Arguments[$i] -Option '--limit'
                continue
            }
            '--pages' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --pages requires a positive integer' }
                $searchPages = Convert-GitHubPositiveInt -Value $Arguments[$i] -Option '--pages'
                continue
            }
            '--jq' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --jq requires FILTER' }
                $jqFilter = $Arguments[$i]
                continue
            }
            '--url' { $printUrl = $true; continue }
            '--issues' { $kind = 'repo'; $endpointPath = 'issues'; continue }
            '--issue' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --issue requires NUMBER' }
                $kind = 'repo'; $endpointPath = "issues/$($Arguments[$i])"; continue
            }
            '--pulls' { $kind = 'repo'; $endpointPath = 'pulls'; continue }
            '--pull' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --pull requires NUMBER' }
                $kind = 'repo'; $endpointPath = "pulls/$($Arguments[$i])"; continue
            }
            '--releases' { $kind = 'repo'; $endpointPath = 'releases'; continue }
            '--release' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --release requires TAG' }
                $kind = 'repo'; $endpointPath = "releases/tags/$($Arguments[$i])"; continue
            }
            '--latest-release' { $kind = 'repo'; $endpointPath = 'releases/latest'; continue }
            '--branches' { $kind = 'repo'; $endpointPath = 'branches'; continue }
            '--branch' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --branch requires NAME' }
                $kind = 'repo'; $endpointPath = "branches/$($Arguments[$i])"; continue
            }
            '--commits' { $kind = 'repo'; $endpointPath = 'commits'; continue }
            '--commit' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrWhiteSpace($Arguments[$i])) { throw 'github: --commit requires SHA' }
                $kind = 'repo'; $endpointPath = "commits/$($Arguments[$i])"; continue
            }
            '--contents' {
                if (++$i -ge $Arguments.Count) { throw 'github: --contents requires PATH' }
                $kind = 'repo'; $endpointPath = "contents/$($Arguments[$i].TrimStart('/'))"; continue
            }
            { $_ -in @('--contributors', '--languages', '--tags', '--topics', '--stargazers', '--subscribers', '--forks') } {
                $kind = 'repo'; $endpointPath = $arg.TrimStart('-'); continue
            }
            '--workflows' { $kind = 'repo'; $endpointPath = 'actions/workflows'; continue }
            { $_ -in @('--repos', '--followers', '--following', '--gists', '--starred', '--orgs', '--events', '--members', '--teams') } {
                $endpointPath = $arg.TrimStart('-'); continue
            }
            '--' {
                for ($j = $i + 1; $j -lt $Arguments.Count; $j++) { $fields.Add($Arguments[$j]) }
                $i = $Arguments.Count
                continue
            }
            default {
                if ($arg.StartsWith('-')) { throw "github: unknown option: $arg" }
                $fields.Add($arg)
            }
        }
    }

    switch ($kind) {
        'repo' {
            if ($target -notlike '*/*') { throw "github: repo must be OWNER/REPO: $target" }
            $rawPath = "repos/$target"
        }
        'user' { $rawPath = "users/$target" }
        'org' { $rawPath = "orgs/$target" }
        'gist' { $rawPath = "gists/$target" }
        'raw' {}
    }
    if (-not [string]::IsNullOrEmpty($endpointPath)) {
        $rawPath = "$rawPath/$endpointPath"
    }

    $urlQuery = @($query.ToArray())
    if ($searchDisplay) {
        $urlQuery += 'per_page=100'
        $urlQuery += 'page=1'
    }
    $url = Join-GitHubQuery -Url "$script:GitHubApiBase/$($rawPath.TrimStart('/'))" -Query $urlQuery
    if ($printUrl) {
        $url
        return
    }

    if ($searchDisplay) {
        $headers = Get-GitHubHeaders
        $responses = for ($page = 1; $page -le $searchPages; $page++) {
            $pageQuery = @($query.ToArray())
            $pageQuery += 'per_page=100'
            $pageQuery += "page=$page"
            $pageUrl = Join-GitHubQuery -Url "$script:GitHubApiBase/$($rawPath.TrimStart('/'))" -Query $pageQuery
            Invoke-RestMethod -Method Get -Uri $pageUrl -Headers $headers
        }

        $items = @($responses | ForEach-Object { @($_.items) })
        $totalCount = @($responses | ForEach-Object {
            if ($null -ne $_.total_count) { [int]$_.total_count } else { 0 }
        } | Measure-Object -Maximum).Maximum
        if ($null -eq $totalCount) { $totalCount = 0 }
        $response = [pscustomobject]@{
            total_count = $totalCount
            incomplete_results = [bool](@($responses | Where-Object { $_.incomplete_results }).Count)
            items = $items
        }

        if (-not [string]::IsNullOrWhiteSpace($jqFilter)) {
            if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { throw 'github: jq is required when using --jq' }
            $response | ConvertTo-Json -Depth 100 | jq -r $jqFilter
            return
        }

        $sortedItems = @(Get-GitHubSearchItems -Items $items -Limit $searchLimit)
        if ($fields.Count -gt 0) {
            Select-GitHubSearchFields -Items $sortedItems -Fields $fields.ToArray()
            return
        }

        Format-GitHubSearchResults -Items $sortedItems
        return
    }

    $response = Invoke-RestMethod -Method Get -Uri $url -Headers (Get-GitHubHeaders)
    if (-not [string]::IsNullOrWhiteSpace($jqFilter)) {
        if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { throw 'github: jq is required when using --jq' }
        $response | ConvertTo-Json -Depth 100 | jq -r $jqFilter
        return
    }
    if ($fields.Count -gt 0) {
        Select-GitHubFields -InputObject $response -Fields $fields.ToArray()
        return
    }
    $response
}

Register-ArgumentCompleter -CommandName github -ParameterName Arguments -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $elements = @($commandAst.CommandElements | ForEach-Object { $_.ToString() })
    $tokens = if ($elements.Count -gt 1) { @($elements[1..($elements.Count - 1)]) } else { @() }
    $isCompletingCurrent = ($tokens.Count -gt 0) -and ($tokens[-1] -eq $wordToComplete)
    $completed = if ($isCompletingCurrent) {
        if ($tokens.Count -gt 1) { @($tokens[0..($tokens.Count - 2)]) } else { @() }
    } else {
        $tokens
    }
    $prev = if ($completed.Count -gt 0) { $completed[-1] } else { '' }

    $candidates = switch ($prev) {
        { $_ -in @('-r', '--repo') } { @('ollama/ollama', 'cli/cli', 'torvalds/linux', 'kubernetes/kubernetes'); break }
        { $_ -in @('-u', '--user') } { @('lgf-136', 'torvalds', 'github', 'actions'); break }
        { $_ -in @('-o', '--org') } { @('github', 'kubernetes', 'openai', 'microsoft'); break }
        { $_ -in @('-a', '--api') } { @('repos/ollama/ollama', 'users/lgf-136', 'orgs/github', 'gists', 'search/repositories', 'search/users', 'search/issues', 'search/code', 'rate_limit', 'meta'); break }
        { $_ -in @('-q', '--query') } { @('per_page=100', 'page=1', 'state=open', 'state=closed', 'state=all', 'sort=updated', 'direction=desc', 'type=owner', 'type=member'); break }
        '--limit' { @('15', '30', '50', '100'); break }
        '--pages' { @('1', '2', '3', '5'); break }
        { $_ -in @('-s', '--search', '--search-repos', '--search-users', '--search-issues', '--search-code') } { @(); break }
        { $_ -in @('--issue', '--pull') } { @('1', '2', '3', '4', '5', '10', '100'); break }
        '--release' { @('latest', 'v1.0.0'); break }
        '--branch' { @('main', 'master', 'develop'); break }
        default {
            if ($wordToComplete.StartsWith('-')) {
                @($script:GitHubGlobalOptions + $script:GitHubRepoOptions + $script:GitHubUserOptions + $script:GitHubOrgOptions + $script:GitHubSearchOptions)
            } else {
                @(Get-GitHubCompletionFields -Tokens $completed)
            }
        }
    }

    $candidates |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object -Unique |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
