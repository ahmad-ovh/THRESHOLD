"""Run tests via pytest programmatically."""
import sys
import pytest

sys.path.insert(0, "c:/Users/User/Documents/THRESHOLD")

exit_code = pytest.main([
    "tests/",
    "-v",
    "--tb=short",
    "--no-header",
    "-p", "no:cacheprovider",
    "--asyncio-mode=auto",
])
sys.exit(exit_code)
