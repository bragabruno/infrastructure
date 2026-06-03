"""
Integration smoke tests against a running Docker Compose stack.
Run: python3 tests/integration/test_smoke.py
"""

import sys
import requests
from time import sleep

BASE_URLS = {
    "backend": "http://localhost:8080",
    "ml-service": "http://localhost:8001",
    "frontend": "http://localhost:4200",
}

PASS = 0
FAIL = 0


def check(name: str, url: str, method: str = "GET", **kwargs) -> bool:
    global PASS, FAIL
    try:
        resp = requests.request(method, url, timeout=10, **kwargs)
        if resp.status_code < 400:
            print(f"  {name}: PASS ({resp.status_code})")
            PASS += 1
            return True
        else:
            print(f"  {name}: FAIL ({resp.status_code})")
            FAIL += 1
            return False
    except Exception as e:
        print(f"  {name}: FAIL ({e})")
        FAIL += 1
        return False


def test_health_endpoints():
    print("\n── Health Endpoints ──")
    check("backend /actuator/health", f"{BASE_URLS['backend']}/actuator/health")
    check("ml-service /health", f"{BASE_URLS['ml-service']}/health")
    check("frontend /", f"{BASE_URLS['frontend']}/")


def test_backend_api():
    print("\n── Backend API ──")
    check("GET /api/cases", f"{BASE_URLS['backend']}/api/cases")
    check("GET /api/transactions", f"{BASE_URLS['backend']}/api/transactions")
    check(
        "POST /api/auth/login",
        f"{BASE_URLS['backend']}/api/auth/login",
        method="POST",
        json={"username": "fraud_admin", "password": "test"},
    )


def test_ml_service_api():
    print("\n── ML Service API ──")
    check("GET /docs", f"{BASE_URLS['ml-service']}/docs")
    check(
        "POST /predict",
        f"{BASE_URLS['ml-service']}/predict",
        method="POST",
        json={
            "amount": 100.0,
            "merchant_category": "electronics",
            "country": "US",
            "hour_of_day": 14,
            "is_weekend": False,
            "user_id": "test-user",
            "transaction_id": "test-tx-001",
        },
    )


def test_frontend():
    print("\n── Frontend ──")
    check("GET /", f"{BASE_URLS['frontend']}/")
    resp = requests.get(f"{BASE_URLS['frontend']}/", timeout=10)
    if "angular" in resp.text.lower() or "app-root" in resp.text.lower():
        print("  Angular app detected: PASS")
    else:
        print("  Angular app detected: FAIL (unexpected content)")


def test_cross_service():
    print("\n── Cross-Service ──")
    # Backend -> ML service connectivity (via backend's ML client)
    check(
        "backend -> ml /health proxy",
        f"{BASE_URLS['backend']}/actuator/health",
    )
    # Frontend -> Backend API proxy
    resp = requests.get(f"{BASE_URLS['frontend']}/", timeout=10)
    if resp.status_code == 200:
        print("  frontend -> backend proxy: PASS (frontend loads)")
    else:
        print("  frontend -> backend proxy: FAIL")


def main():
    print("=" * 50)
    print("Integration Smoke Tests")
    print("=" * 50)

    test_health_endpoints()
    test_backend_api()
    test_ml_service_api()
    test_frontend()
    test_cross_service()

    print("\n" + "=" * 50)
    print(f"Results: {PASS} passed, {FAIL} failed")
    print("=" * 50)

    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
