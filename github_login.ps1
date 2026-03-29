$clientId = "178c6fc778ccc68e1d6a"
$body = @{ client_id = $clientId; scope = "repo gist read:org" }
$headers = @{ "Accept" = "application/json" }

Write-Host "Requesting code..."
$resp = Invoke-RestMethod -Uri "https://github.com/login/device/code" -Method Post -Body $body -Headers $headers
$deviceCode = $resp.device_code
$userCode = $resp.user_code
$interval = $resp.interval

Write-Host "USER_CODE=$userCode"
Write-Host "Wait for user to enter code on website..."

$bodyAuth = @{
    client_id = $clientId
    device_code = $deviceCode
    grant_type = "urn:ietf:params:oauth:grant-type:device_code"
}

$token = $null
while ($true) {
    Start-Sleep -Seconds $interval
    try {
        $authResp = Invoke-RestMethod -Uri "https://github.com/login/oauth/access_token" -Method Post -Body $bodyAuth -Headers $headers
        if ($authResp.access_token) {
            $token = $authResp.access_token
            Write-Host "Successfully authenticated!"
            break
        } elseif ($authResp.error -eq "authorization_pending") {
            continue
        } else {
            Write-Host "Error: $($authResp.error)"
            break
        }
    } catch {
        Write-Host "Exception $_"
        break
    }
}

if ($token) {
    $token | gh auth login --with-token
    Write-Host "Token saved to GitHub CLI!"
}
