"""
EventSphere – CI Test Runner
============================
This script is the single entry-point used by GitHub Actions to:
  1. Generate the styled XLSX E2E test-execution report (all 105 TCs).
  2. Run the Selenium web E2E tests headless via pytest.
  3. Print a final summary so the Actions log is easy to read.

Usage (from repo root):
    python "frontend/apium testing/run_selenium_tests.py"
"""

import os
import sys
import subprocess
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── Step 1 · Generate XLSX Report ────────────────────────────────────────────
print("=" * 60)
print("STEP 1 · Generating E2E XLSX Test Report")
print("=" * 60)

report_gen = os.path.join(SCRIPT_DIR, "generate_xlsx_report.py")
result = subprocess.run(
    [sys.executable, report_gen],
    cwd=SCRIPT_DIR,
    capture_output=True,
    text=True
)
print(result.stdout)
if result.returncode != 0:
    print("ERROR generating report:", result.stderr)
    sys.exit(result.returncode)

# Confirm the file was created
today = datetime.now().strftime("%Y-%m-%d")
xlsx_name = f"E2E_Test_Report_EventSphere_{today}.xlsx"
xlsx_path = os.path.join(SCRIPT_DIR, xlsx_name)

if os.path.exists(xlsx_path):
    size_kb = os.path.getsize(xlsx_path) / 1024
    print(f"✔  Report created: {xlsx_name}  ({size_kb:.1f} KB)")
else:
    print(f"✘  Expected report not found at: {xlsx_path}")
    sys.exit(1)

# ── Step 2 · Run Selenium E2E Tests via pytest ───────────────────────────────
print()
print("=" * 60)
print("STEP 2 · Running Selenium E2E Tests (headless Chrome)")
print("=" * 60)

html_report = os.path.join(SCRIPT_DIR, "selenium_report.html")
selenium_tests = os.path.join(SCRIPT_DIR, "selenium_e2e_tests.py")

pytest_cmd = [
    sys.executable, "-m", "pytest",
    selenium_tests,
    "-v",
    "--tb=short",
    f"--html={html_report}",
    "--self-contained-html",
    "--no-header",
]

test_result = subprocess.run(pytest_cmd, cwd=SCRIPT_DIR)

# ── Final Summary ─────────────────────────────────────────────────────────────
print()
print("=" * 60)
print("ARTIFACTS GENERATED")
print("=" * 60)
for f in [xlsx_name, "selenium_report.html"]:
    full = os.path.join(SCRIPT_DIR, f)
    if os.path.exists(full):
        print(f"  ✔  {f}  ({os.path.getsize(full)/1024:.1f} KB)")
    else:
        print(f"  ✘  {f}  — NOT FOUND")

# Exit with pytest's return code so GitHub Actions marks the job correctly
sys.exit(test_result.returncode)
