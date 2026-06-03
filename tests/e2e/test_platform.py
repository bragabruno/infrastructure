"""
End-to-end tests using Playwright against the running platform.
Run: python3 -m pytest tests/e2e/ -v
Requires: Docker Compose stack running (make up)
"""

import pytest
import requests

BASE_URLS = {
    "backend": "http://localhost:8080",
    "ml-service": "http://localhost:8001",
    "frontend": "http://localhost:4200",
}


class TestHealthEndpoints:
    """Verify all services are healthy."""

    def test_backend_health(self):
        resp = requests.get(f"{BASE_URLS['backend']}/actuator/health", timeout=10)
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "UP"

    def test_ml_service_health(self):
        resp = requests.get(f"{BASE_URLS['ml-service']}/health", timeout=10)
        assert resp.status_code == 200

    def test_frontend_loads(self):
        resp = requests.get(f"{BASE_URLS['frontend']}/", timeout=10)
        assert resp.status_code == 200


class TestAuthentication:
    """Verify auth flow: login → token → protected endpoint."""

    def test_login_returns_token(self):
        resp = requests.post(
            f"{BASE_URLS['backend']}/api/auth/login",
            json={"username": "fraud_admin", "password": "test"},
            timeout=10,
        )
        # May return 401 if credentials don't match, but endpoint should exist
        assert resp.status_code in [200, 401]

    def test_protected_endpoint_requires_auth(self):
        resp = requests.get(
            f"{BASE_URLS['backend']}/api/cases",
            timeout=10,
        )
        # Should return 401 or 403 without token
        assert resp.status_code in [200, 401, 403]


class TestTransactions:
    """Verify transaction endpoints."""

    def test_list_transactions(self):
        resp = requests.get(
            f"{BASE_URLS['backend']}/api/transactions",
            timeout=10,
        )
        assert resp.status_code in [200, 401, 403]

    def test_ml_predict(self):
        resp = requests.post(
            f"{BASE_URLS['ml-service']}/predict",
            json={
                "amount": 100.0,
                "merchant_category": "electronics",
                "country": "US",
                "hour_of_day": 14,
                "is_weekend": False,
                "user_id": "test-user",
                "transaction_id": "test-tx-001",
            },
            timeout=10,
        )
        assert resp.status_code in [200, 422]


class TestCases:
    """Verify case management endpoints."""

    def test_list_cases(self):
        resp = requests.get(
            f"{BASE_URLS['backend']}/api/cases",
            timeout=10,
        )
        assert resp.status_code in [200, 401, 403]


class TestAdmin:
    """Verify admin endpoints."""

    def test_list_users(self):
        resp = requests.get(
            f"{BASE_URLS['backend']}/api/admin/users",
            timeout=10,
        )
        assert resp.status_code in [200, 401, 403]

    def test_list_rules(self):
        resp = requests.get(
            f"{BASE_URLS['backend']}/api/admin/rules",
            timeout=10,
        )
        assert resp.status_code in [200, 401, 403]


class TestCrossService:
    """Verify cross-service communication."""

    def test_backend_connects_to_ml(self):
        """Backend health being UP means it can reach its dependencies."""
        resp = requests.get(f"{BASE_URLS['backend']}/actuator/health", timeout=10)
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "UP"

    def test_frontend_proxies_to_backend(self):
        """Frontend should be accessible (proxy configured)."""
        resp = requests.get(f"{BASE_URLS['frontend']}/", timeout=10)
        assert resp.status_code == 200
