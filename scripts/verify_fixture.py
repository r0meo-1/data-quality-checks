"""Check every query against known clean/anomalous fixture counts (read-only)."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


EXPECTED = {
    "check_01_duplicate_customer_emails.sql": 1,
    "check_02_orphan_bookings.sql": 1,
    "check_03_orphan_payments.sql": 1,
    "check_04_paid_without_succeeded_payment.sql": 1,
    "check_05_payment_amount_mismatch.sql": 2,
    "check_06_non_positive_amounts.sql": 1,
    "check_07_pax_sanity.sql": 1,
    "check_08_invalid_status.sql": 1,
    "check_09_refunded_without_refund_payment.sql": 1,
    "check_10_future_timestamps.sql": 1,
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fixture", choices=["clean", "anomalies"])
    args = parser.parse_args()
    database = os.environ.get("DATABASE_URL")
    if not database:
        parser.error("DATABASE_URL is required")
    checks = Path(__file__).resolve().parents[1] / "checks"
    files = sorted(checks.glob("check_*.sql"))
    if {p.name for p in files} != set(EXPECTED):
        print("Fixture expectations must cover exactly all check files", file=sys.stderr)
        return 1
    failed = False
    for path in files:
        query = path.read_text(encoding="utf-8").strip().removesuffix(";")
        try:
            result = subprocess.run(
                ["psql", "-X", database, "-v", "ON_ERROR_STOP=1", "-t", "-A", "-c",
                 f"SELECT count(*) FROM (\n{query}\n) AS violations;"],
                capture_output=True, text=True, timeout=30,
            )
        except (OSError, subprocess.TimeoutExpired):
            print(f"ERROR {path.name}: PostgreSQL client unavailable or timed out")
            return 1
        output = result.stdout.strip()
        if result.returncode or not output.isascii() or not output.isdigit():
            print(f"ERROR {path.name}: query failed or count was invalid")
            failed = True
            continue
        expected = 0 if args.fixture == "clean" else EXPECTED[path.name]
        actual = int(output)
        passed = actual == expected
        print(f"{'PASS' if passed else 'FAIL'} {path.name}: expected={expected}, actual={actual}")
        failed |= not passed
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
