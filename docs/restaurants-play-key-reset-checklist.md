# Restaurants Play Upload Key Reset Checklist

Use this checklist for the Restaurants Android package upload-key reset and CI rotation.

## Generated Artifacts
- Keystore: `android/restaurants-upload-2026.jks`
- Public cert for Play reset: `restaurants-upload-2026.pem` (copy also available as `android/restaurants-upload-2026.pem`)
- Alias: `restaurantsupload2026`

## Fingerprints (New Upload Key)
- SHA1: `0E:9A:1C:9E:FA:6E:A4:4F:EF:BA:53:79:16:B9:DF:14:16:FB:67:B2`
- SHA256: `5F:52:C9:3E:36:8E:AB:FB:0E:EB:21:E3:09:FF:E5:E5:C3:E5:9E:A1:C7:CE:F8:CE:ED:42:14:53:EA:9A:61:47`

## Local Signing Config
`android/key.properties`

Required keys:
- storePassword
- keyPassword
- keyAlias=restaurantsupload2026
- storeFile=../restaurants-upload-2026.jks
- expectedSha1=0E:9A:1C:9E:FA:6E:A4:4F:EF:BA:53:79:16:B9:DF:14:16:FB:67:B2

## Play Console Steps
1. Open Restaurants app in Play Console.
2. Go to Setup -> App integrity.
3. Request upload key reset.
4. Upload `restaurants-upload-2026.pem`.
5. Wait for Google approval email.
6. Upload new `build/app/outputs/bundle/release/app-release.aab`.

## CI/CD Secrets (Restaurants)
Set/update these secrets:
- KEYSTORE_BASE64
- KEYSTORE_PASSWORD
- KEY_PASSWORD
- KEY_ALIAS=restaurantsupload2026
- EXPECTED_UPLOAD_SHA1=0E:9A:1C:9E:FA:6E:A4:4F:EF:BA:53:79:16:B9:DF:14:16:FB:67:B2

### Generate KEYSTORE_BASE64 (Windows PowerShell)
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android/restaurants-upload-2026.jks'))
```

## Validation
1. Trigger CI Android release build.
2. Ensure `Verify AAB upload key SHA1` step passes.
3. Confirm Play accepts the AAB (no wrong key error).
