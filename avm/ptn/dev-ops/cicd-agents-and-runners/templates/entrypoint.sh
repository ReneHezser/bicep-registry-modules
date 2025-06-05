#!/bin/bash
set -e

REPO_URL="https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
echo "Repository URL: $REPO_URL"
REGISTRATION_TOKEN_API_URL="https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/actions/runners/registration-token"
echo "Registration token API url: $REGISTRATION_TOKEN_API_URL"

if [ $GITHUB_PAT != '' ]; then
  echo "Configuring using PAT"
  REGISTRATION_TOKEN="$(curl -X POST -fsSL \
    -H 'Accept: application/vnd.github+json' \
    -H "Authorization: Bearer $GITHUB_PAT" \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "$REGISTRATION_TOKEN_API_URL" \
    | jq -r '.token')"
else
  echo "Configuring using APPKEY"

  now=$(date +%s)
  iat=$((${now} - 60)) # Issues 60 seconds in the past
  exp=$((${now} + 300)) # Expires 10 minutes in the future

  b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

  header_json='{
      "typ":"JWT",
      "alg":"RS256"
  }'
  header=$( echo -n "${header_json}" | b64enc )

  payload_json='{
      "iat":'"${iat}"',
      "exp":'"${exp}"',
      "iss":'"${GITHUB_CLIENTID}"'
  }'
  # Payload encode
  payload=$( echo -n "${payload_json}" | b64enc )
  # Signature
  header_payload="${header}"."${payload}"
  signature=$(
      openssl dgst -sha256 -sign <(echo -n "${GITHUB_APPKEY}") \
      <(echo -n "${header_payload}") | b64enc
  )
  # Create JWT
  JWT="${header_payload}"."${signature}"

  ACCESS_TOKEN="$(curl --request POST \
  --url "https://api.github.com/app/installations/${GITHUB_INSTALLATIONID}/access_tokens" \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer ${JWT}" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  | jq -r '.token')"

  REGISTRATION_TOKEN="$(curl -X POST -fsSL \
    -H 'Accept: application/vnd.github+json' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "$REGISTRATION_TOKEN_API_URL" \
    | jq -r '.token')"
fi
if [ $RUNNER_LABEL != '' ]; then
  ./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --labels $RUNNER_LABEL --unattended --ephemeral --disableupdate
else
  ./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --unattended --ephemeral --disableupdate
fi

 ./run.sh
