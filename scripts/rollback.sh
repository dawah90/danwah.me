#!/usr/bin/env bash
set -euo pipefail

environment="${1:-}"

case "$environment" in
    dev)
        image_key=DEV_IMAGE
        version_key=DEV_VERSION
        commit_key=DEV_COMMIT_SHA
        ;;
    test)
        image_key=TEST_IMAGE
        version_key=TEST_VERSION
        commit_key=TEST_COMMIT_SHA
        ;;
    prod)
        image_key=PROD_IMAGE
        version_key=PROD_VERSION
        commit_key=PROD_COMMIT_SHA
        ;;
    *)
        printf 'Environment must be dev, test or prod.\n' >&2
        exit 2
        ;;
esac

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
state_dir="${DANWAH_STATE_DIR:-$repo_dir/deploy/state}"
previous_file="$state_dir/$environment.previous.env"

if [ ! -f "$previous_file" ]; then
    printf 'No previous deployment exists for %s.\n' "$environment" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$previous_file"
set +a

image="${!image_key}"
version="${!version_key}"
commit_sha="${!commit_key}"

exec "$script_dir/deploy.sh" "$environment" "$image" "$version" "$commit_sha"
