# conftest.py – shared pytest configuration for EventSphere E2E tests

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


def pytest_runtest_makereport(item, call):
    """Attach screenshot to HTML report on failure."""
    if call.when == "call" and call.excinfo is not None:
        driver = item.funcargs.get("fresh_driver") or item.funcargs.get("driver", None)
        if driver:
            screenshot_path = f"screenshots/{item.name}.png"
            try:
                import os
                os.makedirs("screenshots", exist_ok=True)
                driver.save_screenshot(screenshot_path)
                print(f"\n📸 Screenshot saved: {screenshot_path}")
            except Exception as e:
                print(f"Could not capture screenshot: {e}")
