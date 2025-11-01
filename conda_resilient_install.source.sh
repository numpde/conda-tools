conda_resilient_install() {
    # How long to sleep between retries (seconds)
    local delay="${CONDA_RETRY_DELAY:-10}"

    # Max attempts before giving up.
    # 0 (default) means "try forever".
    local max_attempts="${CONDA_RETRY_MAX:-0}"

    # Internal counter
    local attempt=1

    # No args? be kind and explain.
    if [ "$#" -eq 0 ]; then
        echo "Usage: conda_resilient_install <pkg> [pkg2 pkg3 ...]" >&2
        echo "Installs into the CURRENT active conda env, retrying on failure." >&2
        return 1
    fi

    # Show where we're about to install, for sanity
    local env_name
    env_name="$(conda info --json 2>/dev/null | grep -m1 '"active_prefix_name"' | sed -E 's/.*: "([^"]+)".*/\1/')" 
    if [ -z "$env_name" ]; then
        env_name="(base or unknown)"
    fi

    while true; do
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] conda install attempt ${attempt}${max_attempts:+/${max_attempts}} into env '${env_name}': $*" >&2

        # -y = auto-confirm, -q = quiet-ish
        # We intentionally do NOT pin channels/flags here so it respects
        # whatever channel config the env/user already has.
        if conda install -y -q "$@"; then
            echo "conda_resilient_install: success after ${attempt} attempt(s) ✨" >&2
            return 0
        fi

        # Failed:
        echo "conda_resilient_install: install failed for [$*]" >&2

        # Exceeded attempts?
        if [ "$max_attempts" -ne 0 ] && [ "$attempt" -ge "$max_attempts" ]; then
            echo "conda_resilient_install: giving up after ${attempt} attempts 😵" >&2
            return 1
        fi

        # Otherwise, retry after delay
        echo "Retrying in ${delay}s..." >&2
        sleep "$delay"

        attempt=$(( attempt + 1 ))
    done
}
