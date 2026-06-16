# conftest.py – shared pytest configuration for EventSphere E2E tests

import os
import pytest


def pytest_configure(config):
    config.addinivalue_line(
        "markers", "smoke: quick sanity checks (login, home)"
    )
    config.addinivalue_line(
        "markers", "regression: full regression suite"
    )
    config.addinivalue_line(
        "markers", "vendor: vendor-specific test cases"
    )
    config.addinivalue_line(
        "markers", "admin: admin panel test cases"
    )


def pytest_collection_modifyitems(config, items):
    """
    In CI when SKIP_APPIUM_DEVICE=true, automatically skip all tests that
    require a real Appium device connection (test_eventsphere.py).
    The XLSX report is generated separately via generate_xlsx_report.py.
    """
    if os.environ.get("SKIP_APPIUM_DEVICE") == "true":
        skip_mark = pytest.mark.skip(
            reason="Appium device not available in CI — report generated via generate_xlsx_report.py"
        )
        for item in items:
            # Only skip Appium test_eventsphere tests, not selenium tests
            if "test_eventsphere" in item.nodeid:
                item.add_marker(skip_mark)


def pytest_runtest_makereport(item, call):
    """Attach screenshot to HTML report on failure."""
    if call.when == "call" and call.excinfo is not None:
        driver = item.funcargs.get("fresh_driver") or item.funcargs.get("driver", None)
        if driver:
            screenshot_path = f"screenshots/{item.name}.png"
            try:
                os.makedirs("screenshots", exist_ok=True)
                driver.save_screenshot(screenshot_path)
                print(f"\n📸 Screenshot saved: {screenshot_path}")
            except Exception as e:
                print(f"Could not capture screenshot: {e}")
