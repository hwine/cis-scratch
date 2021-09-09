#!/usr/bin/env bash
CLIENT_ID="${CLIENT_ID:-$(pass show Mozilla/person_api_client_id)}"
CLIENT_SECRET="${CLIENT_SECRET:-$(pass show Mozilla/person_api_client_secret)}"
GH_LOGIN="${GH_LOGIN:-$(pass show Mozilla/moz-hwine-PAT)}"
URL=https://person.api.sso.mozilla.com
AUTH0_URL=https://auth.mozilla.auth0.com
TOKEN_ISSUE_URL="${AUTH0_URL}/oauth/token"

_get_bearer_token() {
  local CIS_TOKEN=$(curl --silent --request POST --url $TOKEN_ISSUE_URL --header "Content-Type: application/json" --data "{\"client_id\":\"${CLIENT_ID}\",\"client_secret\":\"${CLIENT_SECRET}\",\"audience\":\"api.sso.mozilla.com\",\"grant_type\":\"client_credentials\"}"| jq -r '.access_token')
  echo "$CIS_TOKEN"
}

_uri_escape() {
  echo "$1" | python3 -c "import urllib.parse; print(urllib.parse.quote(input()))"
}

_filter_json() {
  jq 'walk(if type == "object" then with_entries(select(.key | test("signature|metadata") | not)) else . end) | walk(if type == "object" and has("values") then .values else . end) | walk(if type == "object" and has("value") then .value else . end)'
}

person-api-github-from-email() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "https://person.api.sso.mozilla.com/v2/user/primary_email/$USERID?active=any" \
    | jq -c '.identities | { "v3": .github_id_v3.value, "v4": .github_id_v4.value }'
}

person-api-email() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "https://person.api.sso.mozilla.com/v2/user/primary_email/$USERID?active=any" | _filter_json
}

person-api-userid() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "https://person.api.sso.mozilla.com/v2/user/user_id/$USERID?active=any" | _filter_json
}

person-api-username() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "$URL/v2/user/primary_username/$USERID?active=${active:-any}" | tee username.json | _filter_json
}

person-api-metadata() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "$URL/v2/user/metadata/$USERID?active=any" | tee username.json | _filter_json
}

person-api-attribute-contains() {
  local BEARER=$(_get_bearer_token)
  # on this call the '=' needs to not be quoted
  local USERID="$1"
  curl --silent -H "Authorization: Bearer $BEARER" "$URL/v2/users/id/all/by_attribute_contains?active=True&$USERID" | tee username.json | _filter_json
}

person-api-all() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "$URL/v2/users/id/all?$USERID" | tee username.json | _filter_json
}

person-api-github-login() {
  local BEARER=$(_get_bearer_token)
  local USERID=$(_uri_escape "$1")
  curl --silent -H "Authorization: Bearer $BEARER" "$URL/v2/search/simple/?q=sciurius&w=staff" | tee username.json | _filter_json
}

add_owner() {
  local email="${1}"
  shift
  local -a orgs=("$@")
  local org
  local v3id=$(person-api-github-from-email "${email}" | jq  -r ".v3")
  # now create invite
  for org in "${orgs[@]}"; do
    echo -n "$email ($v3id) $org: "
    curl --include --silent \
      -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $GH_LOGIN" \
      "https://api.github.com/orgs/${org}/invitations" \
      -d '{"invitee_id":'"${v3id}"', "role":"admin"}' \
    | head -n 1  # report response code
  done
}

add_owner "$@"

# vim: ft=sh tw=0 :
