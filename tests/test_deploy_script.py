import subprocess
from pathlib import Path

DEPLOY_SCRIPT = Path(__file__).parents[1] / "scripts" / "deploy.sh"


def test_deploy_rejects_unknown_environment() -> None:
    assert DEPLOY_SCRIPT.exists(), "deploy.sh is not implemented yet"

    result = subprocess.run(
        [str(DEPLOY_SCRIPT), "qa", "danwah.me:local", "local", "abc123"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 2
    assert "dev, test or prod" in result.stderr


def test_deploy_requires_digest_for_test_and_prod() -> None:
    result = subprocess.run(
        [str(DEPLOY_SCRIPT), "prod", "ghcr.io/dawah90/danwah.me:latest", "v1", "abc123"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 2
    assert "digest" in result.stderr
