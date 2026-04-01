import time

import jwt
import requests


def _get_google_access_token(client_email: str, private_key: str, scope: str) -> str:
    """
    Exchange a service account JWT for a Google OAuth2 access token.
    A successful exchange proves the private key, client email, and requested scope are all valid.
    """
    now = int(time.time())
    assertion = jwt.encode(
        {
            "iss": client_email,
            "sub": client_email,
            "aud": "https://oauth2.googleapis.com/token",
            "iat": now,
            "exp": now + 3600,
            "scope": scope,
        },
        private_key,
        algorithm="RS256",
    )
    response = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": assertion,
        },
        timeout=10,
    )
    assert response.status_code == 200, (
        f"Failed to obtain Google access token: {response.status_code} {response.text}"
    )
    return response.json()["access_token"]


def test_firebase_push_credentials(firebase_credentials: dict) -> None:
    """
    Credential health check: validate that the Firebase service account can send push notifications.

    Sends a validate_only FCM message — no notification is delivered. A 200 response confirms the
    private key, client email, project ID, and FCM send permissions are all intact.
    """
    access_token = _get_google_access_token(
        firebase_credentials["client_email"],
        firebase_credentials["private_key"],
        "https://www.googleapis.com/auth/firebase.messaging",
    )
    response = requests.post(
        f'https://fcm.googleapis.com/v1/projects/{firebase_credentials["project_id"]}/messages:send',
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        },
        json={
            "validate_only": True,
            "message": {
                "topic": "credential-health-check",
                "notification": {"title": "ping", "body": "pong"},
            },
        },
        timeout=10,
    )
    assert response.status_code == 200, (
        f"FCM push credential check failed: {response.status_code} {response.text}"
    )


def test_firebase_auth_credentials(firebase_credentials: dict) -> None:
    """
    Credential health check: validate that the Firebase service account can verify OAuth tokens.

    Obtains an Identity Toolkit access token — proves the same credentials used by the platform's
    firebase_auth.verify_id_token() (for both Google and Apple Sign In) are intact.
    """
    _get_google_access_token(
        firebase_credentials["client_email"],
        firebase_credentials["private_key"],
        "https://www.googleapis.com/auth/identitytoolkit",
    )


def test_apple_sign_in_credentials(apple_sign_in_credentials: dict) -> None:
    """
    Credential health check: validate the Apple Sign In private key by pinging Apple's token endpoint.

    A dummy authorization code is submitted with a real client secret JWT. Apple responds with
    'invalid_grant' when credentials are valid (the code is bad but the key checked out). Any other
    error — particularly 'invalid_client' — indicates the key, Key ID, Team ID, or Client ID is broken.
    """
    now = int(time.time())
    client_secret = jwt.encode(
        {
            "iss": apple_sign_in_credentials["team_id"],
            "iat": now,
            "exp": now + 180,
            "aud": "https://appleid.apple.com",
            "sub": apple_sign_in_credentials["client_id"],
        },
        apple_sign_in_credentials["key_p8"],
        algorithm="ES256",
        headers={"kid": apple_sign_in_credentials["key_id"]},
    )
    response = requests.post(
        "https://appleid.apple.com/auth/token",
        data={
            "client_id": apple_sign_in_credentials["client_id"],
            "client_secret": client_secret,
            "code": "dummy_authorization_code",
            "grant_type": "authorization_code",
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=10,
    )
    error = response.json().get("error")
    assert error == "invalid_grant", (
        f"Apple Sign In credential check failed: expected 'invalid_grant' but got "
        f"'{error}' ({response.status_code}). This likely indicates an invalid key, Key ID, Team ID, or Client ID."
    )
