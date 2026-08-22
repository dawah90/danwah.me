#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s {dev|test|prod} IMAGE VERSION COMMIT_SHA\n' "$0" >&2
}

if [ "$#" -ne 4 ]; then
    usage
    exit 2
fi

environment="$1"
image="$2"
version="$3"
commit_sha="$4"

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

if [ "$environment" != "dev" ] && [[ "$image" != *@sha256:* ]]; then
    printf 'Test and prod deployments require an immutable image digest.\n' >&2
    exit 2
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
compose_file="$repo_dir/deploy/compose.yaml"
state_dir="${DANWAH_STATE_DIR:-$repo_dir/deploy/state}"
current_file="$state_dir/$environment.env"
previous_file="$state_dir/$environment.previous.env"
temporary_file="$state_dir/$environment.env.tmp"
container_name="danwah-$environment"

mkdir -p "$state_dir"
chmod 700 "$state_dir"

if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker pull "$image"
fi

if [ -f "$current_file" ]; then
    cp "$current_file" "$previous_file"
fi

printf '%s=%s\n%s=%s\n%s=%s\n' \
    "$image_key" "$image" \
    "$version_key" "$version" \
    "$commit_key" "$commit_sha" > "$temporary_file"
chmod 600 "$temporary_file"
mv "$temporary_file" "$current_file"

restore_previous() {
    exit_code=$?
    trap - ERR
    printf 'Deployment failed for %s.\n' "$environment" >&2
    if [ -f "$previous_file" ]; then
        printf 'Restoring previous %s deployment.\n' "$environment" >&2
        cp "$previous_file" "$current_file"
        docker compose --env-file "$current_file" -f "$compose_file" \
            up -d --no-deps "$environment" || true
    fi
    exit "$exit_code"
}
trap restore_previous ERR

docker compose --env-file "$current_file" -f "$compose_file" \
    up -d --no-deps "$environment"

for _ in $(seq 1 60); do
    status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "$container_name")
    if [ "$status" = healthy ]; then
        break
    fi
    if [ "$status" = unhealthy ]; then
        docker logs "$container_name" >&2
        exit 1
    fi
    sleep 1
done

status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
    "$container_name")
if [ "$status" != healthy ]; then
    printf 'Container %s did not become healthy.\n' "$container_name" >&2
    exit 1
fi

"$script_dir/healthcheck.sh" "$environment"
trap - ERR
printf 'Deployed %s using %s\n' "$environment" "$image"
