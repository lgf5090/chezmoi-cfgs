const github_api_base = 'https://api.github.com'

const github_global_options = [
    -h --help -r --repo -u --user -o --org -g --gist -a --api -s --search
    -q --query --limit --pages --jq --url
]
const github_repo_options = [
    --issues --issue --pulls --pull --releases --release --latest-release
    --branches --branch --commits --commit --contents --contributors --languages
    --tags --topics --stargazers --subscribers --forks --workflows
]
const github_user_options = [--repos --followers --following --gists --starred --orgs --events]
const github_org_options = [--repos --members --teams --events]
const github_search_options = [-s --search --search-repos --search-users --search-issues --search-code]

const github_repo_fields = [
    id node_id name full_name owner private html_url description fork url forks_url keys_url
    collaborators_url teams_url hooks_url issue_events_url events_url assignees_url branches_url
    tags_url blobs_url git_tags_url git_refs_url trees_url statuses_url languages_url stargazers_url
    contributors_url subscribers_url subscription_url commits_url git_commits_url comments_url
    issue_comment_url contents_url compare_url merges_url archive_url downloads_url issues_url pulls_url
    milestones_url notifications_url labels_url releases_url deployments_url created_at updated_at pushed_at
    git_url ssh_url clone_url svn_url homepage size stargazers_count watchers_count language has_issues
    has_projects has_downloads has_wiki has_pages has_discussions forks_count mirror_url archived disabled
    open_issues_count license allow_forking is_template web_commit_signoff_required topics visibility forks
    open_issues watchers default_branch network_count subscribers_count organization parent source owner.login
    owner.id owner.node_id owner.avatar_url owner.html_url owner.type license.key license.name license.spdx_id
]
const github_user_fields = [
    login id node_id avatar_url gravatar_id url html_url followers_url following_url gists_url starred_url
    subscriptions_url organizations_url repos_url events_url received_events_url type site_admin name company
    blog location email hireable bio twitter_username public_repos public_gists followers following created_at
    updated_at plan
]
const github_org_fields = [
    login id node_id url repos_url events_url hooks_url issues_url members_url public_members_url avatar_url
    description name company blog location email twitter_username is_verified has_organization_projects
    has_repository_projects public_repos public_gists followers following html_url created_at updated_at type
    total_private_repos owned_private_repos private_gists disk_usage collaborators billing_email
    default_repository_permission members_can_create_repositories two_factor_requirement_enabled
]
const github_gist_fields = [
    url forks_url commits_url id node_id git_pull_url git_push_url html_url files public created_at updated_at
    description comments user comments_url owner truncated owner.login owner.id owner.avatar_url
]
const github_issue_fields = [
    url repository_url labels_url comments_url events_url html_url id node_id number title user labels state
    locked assignee assignees milestone comments created_at updated_at closed_at author_association active_lock_reason
    body closed_by reactions timeline_url performed_via_github_app state_reason user.login user.id pull_request
]
const github_pull_fields = [
    url id node_id html_url diff_url patch_url issue_url commits_url review_comments_url review_comment_url
    comments_url statuses_url number state locked title user body labels milestone active_lock_reason created_at
    updated_at closed_at merged_at merge_commit_sha assignee assignees requested_reviewers requested_teams head base
    author_association draft merged mergeable rebaseable mergeable_state merged_by comments review_comments
    maintainer_can_modify commits additions deletions changed_files user.login head.ref head.sha head.repo base.ref
    base.sha base.repo
]
const github_release_fields = [
    url html_url assets_url upload_url tarball_url zipball_url id node_id tag_name target_commitish name body draft
    prerelease created_at published_at author assets author.login author.id
]
const github_branch_fields = [name commit protected protection protection_url commit.sha commit.url]
const github_commit_fields = [
    sha node_id commit url html_url comments_url author committer parents stats files commit.author.name
    commit.author.email commit.author.date commit.committer.name commit.committer.email commit.committer.date
    commit.message commit.tree commit.url commit.comment_count author.login committer.login
]
const github_contents_fields = [
    type encoding size name path content sha url git_url html_url download_url links _links.self _links.git _links.html
]
const github_search_fields = [
    total_count incomplete_results items items.id items.node_id items.name items.full_name items.login items.html_url
    items.description items.stargazers_count items.updated_at items.created_at items.language items.score
]

def _github-usage []: nothing -> nothing {
    [
        'github - small GitHub REST API helper'
        ''
        'usage:'
        '  github -h | --help'
        '  github [field ...]'
        '  github -r OWNER/REPO [repo-option] [field ...]'
        '  github -u USER [user-option] [field ...]'
        '  github -o ORG [org-option] [field ...]'
        '  github -g GIST_ID [field ...]'
        '  github --api PATH [field ...]'
        '  github -s QUERY [--limit N] [--pages N] [field ...]'
        '  github --search-repos QUERY [field ...]'
        '  github --search-users QUERY [field ...]'
        '  github --search-issues QUERY [field ...]'
        '  github --search-code QUERY [field ...]'
        ''
        'authentication:'
        '  Uses GITHUB_TOKEN as Authorization: Bearer $GITHUB_TOKEN when set.'
        '  Else uses GH_TOKEN as Authorization: Bearer $GH_TOKEN when set.'
        ''
        'defaults:'
        '  github'
        '      GET /repos/ollama/ollama'
        '  github -r ollama/ollama'
        '      GET /repos/ollama/ollama'
        ''
        'common options:'
        '  -r, --repo OWNER/REPO       repo endpoint, default: ollama/ollama'
        '  -u, --user USER             user endpoint'
        '  -o, --org ORG               organization endpoint'
        '  -g, --gist GIST_ID          gist endpoint'
        '  -a, --api PATH              raw GitHub API path'
        '  -s, --search QUERY          search repositories and show a ranked summary'
        '  -q, --query KEY=VALUE       append query parameter, repeatable'
        '  --limit N                   limit displayed search rows, default: 15'
        '  --pages N                   fetch N search result pages before ranking, default: 1'
        '  --jq FILTER                 run a raw jq filter against the response'
        '  --url                       print the API URL instead of requesting it'
        '  -h, --help                  show this help'
        ''
        'repo options:'
        '  --issues, --issue NUMBER, --pulls, --pull NUMBER'
        '  --releases, --release TAG, --latest-release'
        '  --branches, --branch NAME, --commits, --commit SHA'
        '  --contents PATH, --contributors, --languages, --tags, --topics'
        '  --stargazers, --subscribers, --forks, --workflows'
        ''
        'user options:'
        '  --repos, --followers, --following, --gists, --starred, --orgs, --events'
        ''
        'org options:'
        '  --repos, --members, --teams, --events'
        ''
        'search options:'
        '  -s, --search QUERY          ranked repo search, default: --limit 15 --pages 1'
        '  github -s wsl --limit 30 --pages 2'
        '      Fetch two search pages, rank locally by stars, updated_at, created_at.'
        '  --search-repos QUERY, --search-users QUERY, --search-issues QUERY, --search-code QUERY'
        ''
        'fields:'
        '  Field names are Nushell cell paths. Examples: id, name, owner.login, created_at'
    ] | str join (char nl) | print
}

def _github-query-pair [value: string]: nothing -> string {
    let parts = ($value | split row '=' --number 2)
    if (($parts | length) != 2) or (($parts | get 0 | is-empty)) {
        error make {msg: $'github: query requires KEY=VALUE: ($value)'}
    }

    let key = (_github-urlencode ($parts | get 0))
    let val = (_github-urlencode ($parts | get 1))
    $'($key)=($val)'
}

def _github-urlencode [value: string]: nothing -> string {
    $value
    | url encode --all
    | str replace --all '%5F' '_'
    | str replace --all '%2E' '.'
    | str replace --all '%2D' '-'
    | str replace --all '%7E' '~'
}

def _github-join-query [url: string, query: string]: nothing -> string {
    if ($query | is-empty) {
        $url
    } else if ($url | str contains '?') {
        $'($url)&($query)'
    } else {
        $'($url)?($query)'
    }
}

def _github-headers []: nothing -> record {
    let base = {
        Accept: 'application/vnd.github+json'
        'X-GitHub-Api-Version': '2022-11-28'
    }

    if (($env.GITHUB_TOKEN? | default '') | is-not-empty) {
        $base | insert Authorization $'Bearer ($env.GITHUB_TOKEN)'
    } else if (($env.GH_TOKEN? | default '') | is-not-empty) {
        $base | insert Authorization $'Bearer ($env.GH_TOKEN)'
    } else {
        $base
    }
}

def _github-get-field [data: any, field: string]: nothing -> any {
    $data | get ($field | split row '.' | into cell-path)
}

def _github-select-fields [data: any, fields: list<string>]: nothing -> any {
    if (($fields | length) == 1) {
        _github-get-field $data ($fields | first)
    } else {
        $fields | reduce --fold {} {|field, acc|
            $acc | insert $field (_github-get-field $data $field)
        }
    }
}

def _github-positive-int [value: string, option: string]: nothing -> int {
    let parsed = try {
        $value | into int
    } catch {
        error make {msg: $'github: ($option) requires a positive integer'}
    }

    if $parsed <= 0 {
        error make {msg: $'github: ($option) requires a positive integer'}
    }

    $parsed
}

def _github-search-field [field: string]: nothing -> string {
    if $field == 'items' {
        '.'
    } else if ($field | str starts-with 'items.') {
        $field | str replace --regex '^items\.' ''
    } else {
        $field
    }
}

def _github-sort-search-items [items: list, limit: int]: nothing -> list {
    $items | sort-by stargazers_count updated_at created_at | reverse | first $limit
}

def _github-select-search-fields [items: list, fields: list<string>]: nothing -> any {
    let item_fields = ($fields | each {|field| _github-search-field $field })

    if (($item_fields | length) == 1) and (($item_fields | first) == '.') {
        $items
    } else {
        if ($item_fields | where {|field| $field == '.' } | is-not-empty) {
            error make {msg: 'github: items cannot be selected with other search fields'}
        }

        $items | each {|item| _github-select-fields $item $item_fields }
    }
}

def _github-format-search-items [items: list]: nothing -> list {
    $items | each {|repo| {
        stars: ($repo.stargazers_count? | default 0)
        updated_at: ($repo.updated_at? | default '')
        created_at: ($repo.created_at? | default '')
        full_name: ($repo.full_name? | default '')
        html_url: ($repo.html_url? | default '')
        description: ($repo.description? | default '')
    }}
}

def "nu-complete github-args" [context: string]: nothing -> list<string> {
    let words = ($context | split row ' ' | where {|word| $word != '' })
    let prev = (if ($words | is-empty) { '' } else { $words | last })

    match $prev {
        '-r' | '--repo' => { [ollama/ollama cli/cli torvalds/linux kubernetes/kubernetes] }
        '-u' | '--user' => { [lgf-136 torvalds github actions] }
        '-o' | '--org' => { [github kubernetes openai microsoft] }
        '-a' | '--api' => { [repos/ollama/ollama users/lgf-136 orgs/github gists search/repositories search/users search/issues search/code rate_limit meta] }
        '-q' | '--query' => { [per_page=100 page=1 state=open state=closed state=all sort=updated direction=desc type=owner type=member] }
        '--limit' => { [15 30 50 100] }
        '--pages' => { [1 2 3 5] }
        '--issue' | '--pull' => { [1 2 3 4 5 10 100] }
        '--release' => { [latest v1.0.0] }
        '--branch' => { [main master develop] }
        _ => {
            mut kind = 'repo'
            mut sub = ''
            for word in $words {
                match $word {
                    '-u' | '--user' => { $kind = 'user' }
                    '-o' | '--org' => { $kind = 'org' }
                    '-g' | '--gist' => { $kind = 'gist' }
                    '-a' | '--api' => { $kind = 'raw' }
                    '--issues' | '--issue' => { $sub = 'issue' }
                    '--pulls' | '--pull' => { $sub = 'pull' }
                    '--releases' | '--release' | '--latest-release' => { $sub = 'release' }
                    '--branches' | '--branch' => { $sub = 'branch' }
                    '--commits' | '--commit' => { $sub = 'commit' }
                    '--contents' => { $sub = 'contents' }
                    '-s' | '--search' | '--search-repos' | '--search-users' | '--search-issues' | '--search-code' => { $kind = 'search' }
                    _ => {}
                }
            }

            let fields = (
                match [$kind $sub] {
                    [user _] => $github_user_fields
                    [org _] => $github_org_fields
                    [gist _] => $github_gist_fields
                    [search _] => $github_search_fields
                    [_ issue] => $github_issue_fields
                    [_ pull] => $github_pull_fields
                    [_ release] => $github_release_fields
                    [_ branch] => $github_branch_fields
                    [_ commit] => $github_commit_fields
                    [_ contents] => $github_contents_fields
                    _ => $github_repo_fields
                }
            )
            $github_global_options ++ $github_repo_options ++ $github_user_options ++ $github_org_options ++ $github_search_options ++ $fields
        }
    }
}

def --wrapped github [
    ...args: string@"nu-complete github-args"
]: nothing -> any {
    mut rest = $args
    mut kind = 'repo'
    mut target = 'ollama/ollama'
    mut endpoint_path = ''
    mut raw_path = ''
    mut query_params = []
    mut fields = []
    mut jq_filter = ''
    mut print_url = false
    mut search_display = false
    mut search_limit = 15
    mut search_pages = 1

    while (($rest | length) > 0) {
        let arg = ($rest | first)
        match $arg {
            '-h' | '--help' => {
                _github-usage
                return
            }
            '-r' | '--repo' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires OWNER/REPO'}
                }
                $kind = 'repo'
                $target = ($rest | get 1)
                $endpoint_path = ''
                $rest = ($rest | skip 2)
            }
            '-u' | '--user' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires USER'}
                }
                $kind = 'user'
                $target = ($rest | get 1)
                $endpoint_path = ''
                $rest = ($rest | skip 2)
            }
            '-o' | '--org' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires ORG'}
                }
                $kind = 'org'
                $target = ($rest | get 1)
                $endpoint_path = ''
                $rest = ($rest | skip 2)
            }
            '-g' | '--gist' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires GIST_ID'}
                }
                $kind = 'gist'
                $target = ($rest | get 1)
                $endpoint_path = ''
                $rest = ($rest | skip 2)
            }
            '-a' | '--api' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires PATH'}
                }
                $kind = 'raw'
                $raw_path = ($rest | get 1 | str replace --regex '^/+' '')
                $endpoint_path = ''
                $rest = ($rest | skip 2)
            }
            '-s' | '--search' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires QUERY'}
                }
                $kind = 'raw'
                $raw_path = 'search/repositories'
                $endpoint_path = ''
                $search_display = true
                $query_params = ($query_params | append $'q=(_github-urlencode ($rest | get 1))')
                $rest = ($rest | skip 2)
            }
            '--search-repos' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --search-repos requires QUERY'}
                }
                $kind = 'raw'
                $raw_path = 'search/repositories'
                $query_params = ($query_params | append $'q=(_github-urlencode ($rest | get 1))')
                $rest = ($rest | skip 2)
            }
            '--search-users' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --search-users requires QUERY'}
                }
                $kind = 'raw'
                $raw_path = 'search/users'
                $query_params = ($query_params | append $'q=(_github-urlencode ($rest | get 1))')
                $rest = ($rest | skip 2)
            }
            '--search-issues' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --search-issues requires QUERY'}
                }
                $kind = 'raw'
                $raw_path = 'search/issues'
                $query_params = ($query_params | append $'q=(_github-urlencode ($rest | get 1))')
                $rest = ($rest | skip 2)
            }
            '--search-code' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --search-code requires QUERY'}
                }
                $kind = 'raw'
                $raw_path = 'search/code'
                $query_params = ($query_params | append $'q=(_github-urlencode ($rest | get 1))')
                $rest = ($rest | skip 2)
            }
            '-q' | '--query' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: $'github: ($arg) requires KEY=VALUE'}
                }
                $query_params = ($query_params | append (_github-query-pair ($rest | get 1)))
                $rest = ($rest | skip 2)
            }
            '--limit' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --limit requires a positive integer'}
                }
                $search_limit = (_github-positive-int ($rest | get 1) '--limit')
                $rest = ($rest | skip 2)
            }
            '--pages' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --pages requires a positive integer'}
                }
                $search_pages = (_github-positive-int ($rest | get 1) '--pages')
                $rest = ($rest | skip 2)
            }
            '--jq' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --jq requires FILTER'}
                }
                $jq_filter = ($rest | get 1)
                $rest = ($rest | skip 2)
            }
            '--url' => {
                $print_url = true
                $rest = ($rest | skip 1)
            }
            '--issues' => {
                $kind = 'repo'
                $endpoint_path = 'issues'
                $rest = ($rest | skip 1)
            }
            '--issue' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --issue requires NUMBER'}
                }
                $kind = 'repo'
                $endpoint_path = $'issues/($rest | get 1)'
                $rest = ($rest | skip 2)
            }
            '--pulls' => {
                $kind = 'repo'
                $endpoint_path = 'pulls'
                $rest = ($rest | skip 1)
            }
            '--pull' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --pull requires NUMBER'}
                }
                $kind = 'repo'
                $endpoint_path = $'pulls/($rest | get 1)'
                $rest = ($rest | skip 2)
            }
            '--releases' => {
                $kind = 'repo'
                $endpoint_path = 'releases'
                $rest = ($rest | skip 1)
            }
            '--release' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --release requires TAG'}
                }
                $kind = 'repo'
                $endpoint_path = $'releases/tags/($rest | get 1)'
                $rest = ($rest | skip 2)
            }
            '--latest-release' => {
                $kind = 'repo'
                $endpoint_path = 'releases/latest'
                $rest = ($rest | skip 1)
            }
            '--branches' => {
                $kind = 'repo'
                $endpoint_path = 'branches'
                $rest = ($rest | skip 1)
            }
            '--branch' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --branch requires NAME'}
                }
                $kind = 'repo'
                $endpoint_path = $'branches/($rest | get 1)'
                $rest = ($rest | skip 2)
            }
            '--commits' => {
                $kind = 'repo'
                $endpoint_path = 'commits'
                $rest = ($rest | skip 1)
            }
            '--commit' => {
                if (($rest | length) < 2) or (($rest | get 1 | is-empty)) {
                    error make {msg: 'github: --commit requires SHA'}
                }
                $kind = 'repo'
                $endpoint_path = $'commits/($rest | get 1)'
                $rest = ($rest | skip 2)
            }
            '--contents' => {
                if (($rest | length) < 2) {
                    error make {msg: 'github: --contents requires PATH'}
                }
                $kind = 'repo'
                $endpoint_path = $'contents/(($rest | get 1 | str replace --regex "^/+" ""))'
                $rest = ($rest | skip 2)
            }
            '--contributors' | '--languages' | '--tags' | '--topics' | '--stargazers' | '--subscribers' | '--forks' => {
                $kind = 'repo'
                $endpoint_path = ($arg | str replace '--' '')
                $rest = ($rest | skip 1)
            }
            '--workflows' => {
                $kind = 'repo'
                $endpoint_path = 'actions/workflows'
                $rest = ($rest | skip 1)
            }
            '--repos' | '--followers' | '--following' | '--gists' | '--starred' | '--orgs' | '--events' | '--members' | '--teams' => {
                $endpoint_path = ($arg | str replace '--' '')
                $rest = ($rest | skip 1)
            }
            '--' => {
                $rest = ($rest | skip 1)
                $fields = ($fields | append $rest)
                $rest = []
            }
            _ => {
                if ($arg | str starts-with '-') {
                    error make {msg: $'github: unknown option: ($arg)'}
                }
                $fields = ($fields | append $arg)
                $rest = ($rest | skip 1)
            }
        }
    }

    match $kind {
        repo => {
            if not ($target | str contains '/') {
                error make {msg: $'github: repo must be OWNER/REPO: ($target)'}
            }
            $raw_path = $'repos/($target)'
        }
        user => { $raw_path = $'users/($target)' }
        org => { $raw_path = $'orgs/($target)' }
        gist => { $raw_path = $'gists/($target)' }
        raw => {}
        _ => { error make {msg: $'github: unknown endpoint kind: ($kind)'} }
    }

    if ($endpoint_path | is-not-empty) {
        $raw_path = $'($raw_path)/($endpoint_path)'
    }

    $raw_path = ($raw_path | str replace --regex '^/+' '')
    let url_query_params = if $search_display {
        $query_params | append 'per_page=100' | append 'page=1'
    } else {
        $query_params
    }
    let query = ($url_query_params | str join '&')
    let url = (_github-join-query $'($github_api_base)/($raw_path)' $query)

    if $print_url {
        return $url
    }

    if $search_display {
        let search_query_params = $query_params
        let search_base_url = $'($github_api_base)/($raw_path)'
        let pages = (1..$search_pages | each {|page|
            let page_query = ($search_query_params | append 'per_page=100' | append $'page=($page)' | str join '&')
            let page_url = (_github-join-query $search_base_url $page_query)
            http get --headers (_github-headers) $page_url
        })
        let items = ($pages | each {|page| $page.items? | default [] } | flatten)
        let response = {
            total_count: (($pages | each {|page| $page.total_count? | default 0 } | math max) | default 0)
            incomplete_results: ($pages | each {|page| $page.incomplete_results? | default false } | where {|value| $value == true } | is-not-empty)
            items: $items
        }

        if ($jq_filter | is-not-empty) {
            if (which jq | is-empty) {
                error make {msg: 'github: jq is required when using --jq'}
            }
            return ($response | to json | ^jq -r $jq_filter)
        }

        let sorted = (_github-sort-search-items $items $search_limit)
        if (($fields | length) > 0) {
            return (_github-select-search-fields $sorted $fields)
        }

        return (_github-format-search-items $sorted)
    }

    let response = (http get --headers (_github-headers) $url)

    if ($jq_filter | is-not-empty) {
        if (which jq | is-empty) {
            error make {msg: 'github: jq is required when using --jq'}
        }
        return ($response | to json | ^jq -r $jq_filter)
    }

    if (($fields | length) > 0) {
        return (_github-select-fields $response $fields)
    }

    $response
}
