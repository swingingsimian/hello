#!/usr/bin/env nextflow

/*
 * Service Account Token Exchange POC
 *
 * Proves the end-to-end flow:
 *   1. Receive an SA ID token (service-account:init scope) via pipeline params
 *   2. Exchange it at GET /exchange/token for a Bearer access token
 *   3. Use the access token to call /api/user-info on the platform
 *
 * Usage:
 *   nextflow run swingingsimian/hello -r sa-token-exchange \
 *     --sa_token '<JWT from POST /orgs/{orgId}/service-accounts/{saId}/token>' \
 *     --platform_url 'http://localhost:8000'
 */

params.sa_token = null
params.platform_url = 'http://localhost:8000'

process exchangeToken {
    output:
    env ACCESS_TOKEN, emit: accessToken

    script:
    """
    echo "Exchanging SA init token at ${params.platform_url}/exchange/token ..."

    RESPONSE=\$(curl -sf "${params.platform_url}/exchange/token" \
      -H "Authorization: Bearer ${params.sa_token}")

    ACCESS_TOKEN=\$(echo "\$RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

    if [ -z "\$ACCESS_TOKEN" ]; then
        echo "ERROR: Token exchange failed. Response: \$RESPONSE"
        exit 1
    fi

    echo "Token exchange succeeded"
    """
}

process callUserInfo {
    input:
    val token

    output:
    stdout

    script:
    """
    echo "Calling ${params.platform_url}/api/user-info with exchanged access token..."

    HTTP_CODE=\$(curl -s -o /tmp/response.json -w "%{http_code}" \
      "${params.platform_url}/api/user-info" \
      -H "Authorization: Bearer \${token}")

    BODY=\$(cat /tmp/response.json)
    echo "HTTP \$HTTP_CODE"
    echo "\$BODY" | head -5

    if [ "\$HTTP_CODE" != "200" ]; then
        echo "FAIL: expected 200, got \$HTTP_CODE"
        exit 1
    fi

    echo ""
    echo "SUCCESS: Service account authenticated via token exchange"
    """
}

workflow {
    if (!params.sa_token) {
        error "Missing --sa_token. Mint one via: POST /orgs/{orgId}/service-accounts/{saId}/token"
    }

    exchangeToken()
    callUserInfo(exchangeToken.out.accessToken)
    callUserInfo.out.view { it }
}
