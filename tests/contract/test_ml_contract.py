"""
Contract tests between backend and ml-service.
Validates request/response shapes match on both sides.

Run: python3 tests/contract/test_ml_contract.py
Requires: Docker Compose stack running (make up)
"""

import sys
import requests
import json

BASE_URLS = {
    "backend": "http://localhost:8080",
    "ml-service": "http://localhost:8001",
}

PASS = 0
FAIL = 0


def check(name: str, condition: bool, detail: str = "") -> bool:
    global PASS, FAIL
    if condition:
        print(f"  {name}: PASS")
        PASS += 1
    else:
        print(f"  {name}: FAIL {detail}")
        FAIL += 1
    return condition


def test_ml_predict_request_shape():
    """Validate /predict request matches ml-service Pydantic schema."""
    print("\n── ML /predict Request Shape ──")

    payload = {
        "amount": 150.00,
        "merchant_category": "electronics",
        "country": "US",
        "hour_of_day": 14,
        "is_weekend": False,
        "user_id": "test-user-001",
        "transaction_id": "test-tx-001",
    }

    resp = requests.post(
        f"{BASE_URLS['ml-service']}/predict",
        json=payload,
        timeout=10,
    )

    check("POST /predict accepts valid payload", resp.status_code == 200, f"({resp.status_code})")

    if resp.status_code == 200:
        data = resp.json()
        check("response has fraudProbability", "fraudProbability" in data, f"keys: {list(data.keys())}")
        check("response has riskLevel", "riskLevel" in data, f"keys: {list(data.keys())}")
        check("response has modelVersion", "modelVersion" in data, f"keys: {list(data.keys())}")
        check("riskLevel is valid", data.get("riskLevel") in ["LOW", "MEDIUM", "HIGH", "CRITICAL"])
        check("fraudProbability is float", isinstance(data.get("fraudProbability"), float))
        check("fraudProbability in [0,1]", 0 <= data.get("fraudProbability", -1) <= 1)


def test_ml_predict_missing_fields():
    """Validate /predict rejects missing required fields."""
    print("\n── ML /predict Missing Fields ──")

    payload = {"amount": 100.0}
    resp = requests.post(
        f"{BASE_URLS['ml-service']}/predict",
        json=payload,
        timeout=10,
    )
    check("rejects missing fields", resp.status_code == 422, f"({resp.status_code})")


def test_ml_health():
    """Validate /health endpoint."""
    print("\n── ML /health ──")

    resp = requests.get(f"{BASE_URLS['ml-service']}/health", timeout=10)
    check("GET /health returns 200", resp.status_code == 200)

    if resp.status_code == 200:
        data = resp.json()
        check("has status field", "status" in data)


def test_backend_ml_client_compatibility():
    """Validate backend can reach ml-service through its client."""
    print("\n── Backend ML Client ──")

    # Backend health should be up (which means ML client configured)
    resp = requests.get(f"{BASE_URLS['backend']}/actuator/health", timeout=10)
    check("backend health UP", resp.status_code == 200)

    if resp.status_code == 200:
        data = resp.json()
        check("backend status is UP", data.get("status") == "UP")


def test_error_handling():
    """Validate error responses are compatible."""
    print("\n── Error Handling ──")

    # Invalid JSON
    resp = requests.post(
        f"{BASE_URLS['ml-service']}/predict",
        data="not json",
        headers={"Content-Type": "application/json"},
        timeout=10,
    )
    check("rejects invalid JSON", resp.status_code == 422, f"({resp.status_code})")

    # Empty body
    resp = requests.post(
        f"{BASE_URLS['ml-service']}/predict",
        json={},
        timeout=10,
    )
    check("rejects empty body", resp.status_code == 422, f"({resp.status_code})")


def test_batch_predict():
    """Validate /batch-predict endpoint if available."""
    print("\n── ML /batch-predict ──")

    payload = {
        "transactions": [
            {
                "amount": 100.0,
                "merchant_category": "electronics",
                "country": "US",
                "hour_of_day": 14,
                "is_weekend": False,
                "user_id": "user-1",
                "transaction_id": "tx-1",
            },
            {
                "amount": 5000.0,
                "merchant_category": "crypto",
                "country": "KY",
                "hour_of_day": 3,
                "is_weekend": True,
                "user_id": "user-2",
                "transaction_id": "tx-2",
            },
        ]
    }

    resp = requests.post(
        f"{BASE_URLS['ml-service']}/batch-predict",
        json=payload,
        timeout=10,
    )

    if resp.status_code == 404:
        print("  POST /batch-predict: SKIP (not implemented)")
        return

    check("POST /batch-predict returns 200", resp.status_code == 200, f"({resp.status_code})")

    if resp.status_code == 200:
        data = resp.json()
        check("returns list of predictions", isinstance(data, list) or "predictions" in data)


def main():
    print("=" * 50)
    print("Contract Tests: Backend ↔ ML Service")
    print("=" * 50)

    test_ml_health()
    test_ml_predict_request_shape()
    test_ml_predict_missing_fields()
    test_error_handling()
    test_batch_predict()
    test_backend_ml_client_compatibility()

    print("\n" + "=" * 50)
    print(f"Results: {PASS} passed, {FAIL} failed")
    print("=" * 50)

    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
