# domain name for the serve to use, ie github, bitbucket, gitlab
#
# use github
# use bitbucket
# use gitlab
use=github.com

# Returns a package url
-zpm-ext-resolve-package () {
    local url="$1"
    # HACK disable channing calling to hooked function -zpm-resolve-package-url
    -captured--zpm-resolve-package-url () {}

    # Expand short github url syntax: `username/reponame`.
    if [[ $url != git://* &&
            $url != https://* &&
            $url != http://* &&
            $url != ssh://* &&
            $url != /* &&
            $url != git@$use:*/*
            ]]; then
        url="https://$use/${url%.git}.git"
    fi

    echo "$url"
}

# hooks into antigen-bundle to have access to all 'antigen bundle *' runs
-zpm-ext-hook "-zpm-resolve-package-url" "-zpm-ext-resolve-package"

# use bitbucket, github, gitlab
zpm-use () {
    use=$1
    # support short name for these services
    # TODO think of a better way to handle this
    if [[ use == github || use == gitlab || use == bitbucket ]]; then
        use=$use.com
    fi
}

# add a completion for the extension
-zpm-ext-compadd "use"
