import pytest


@pytest.fixture(autouse=True)
def _isolate_from_real_or_floci_aws(monkeypatch):
    """Unit tests rely on moto's @mock_aws to intercept boto3 calls in-memory.

    moto can't intercept requests aimed at a custom, non-AWS endpoint (e.g.
    AWS_ENDPOINT_URL pointing at floci on localhost:4566) - boto3 will try
    to actually connect there instead. This env var is commonly set in the
    shell after running scripts/dev-up.sh, and CI sets it too (just not for
    this job) - so it's removed here for every test, regardless of what the
    surrounding environment happens to have configured.
    """
    monkeypatch.delenv("AWS_ENDPOINT_URL", raising=False)