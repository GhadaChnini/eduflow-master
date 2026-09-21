// @ts-nocheck
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const PROJECT_ID = 'eduflow-88537'
const CLIENT_EMAIL = 'firebase-adminsdk-fbsvc@eduflow-88537.iam.gserviceaccount.com'

// Private key - cleaned up
const PRIVATE_KEY_PEM = `MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDKDKnpyG7mZ0rKtMtvQu0qs5I6oXxWSveHEXMl9yOyPbSC/MTEMqQ85NuvNcYw+obUQpkMN4kWx3RuOuF1iLdXKM13kVFFXE0yWkum0sDp8/OYcdtegZj9xaiR/dB4ni6m4YAvfOKsDXM2OSxB7l/EkO5syZYilYBS9H6h2sfT50MnSXmFy15NPHlKPfbe53h+d621fuI65yIgA4h86jYvkIbo0iPiEO7q2oteE2TOxDsFLmAVSEsHm/kySDJe3cSWp3HHgHNvxUnJuN0Hr6+F3bZBTwRK8W3oN39qQODkQvE6hZP5A+e3BC4KXc3G3L3Bp8Ycr4AfrQNEhh4jiQ/1AgMBAAECggEAEsdIh3TccceJ2PsiqS2UM1LLNW3Ky45eIQyLIi0tASThAQeTFhUK1KoEjO03hVfTbijeZpdGw3o4JQKN78mMGKqvJfy4i/S/K/3eaBvQWC4XJsT2OXtcB8H2H9NyK7Ov7EyrCD7YJlt9qL15kosgFXnO3weBT6eLbKpSlqJpzhTXBN+jkWs4tNlBoezFKVZ91uwirFM3aZuJLhG/FgULb6fuHztF86XvrAp9NZsVr6G3o32A0VKRGMzX56BdeGLhSXFlNbpThlooW9u1MovOnmyamMKnDHc0Y0SW3Z4e+uV+c/2IZK8LPkNuURTdsPwRVWe3rLiheIayXY4HueMLoQKBgQDttO8dGlRcwOVOl/91mjUZBky9c76BOZJ51nq+DB2l7Aw6dMH8KZY7PjAr/EKzp6CsnaQEjRl06sjKeH5Z2HjWa0/rX0XmR9dPMHb5ibDkAypp8hMLMhKgSC8/uAXhsopi16Tz9cg0M3vg88Yg7f5cc2IhFANbic9F51cehry2bQKBgQDZmT6PpqaesUkmnJ/MicPvBhn5xzLrajIeR6Vn+dnTWt6g96PWkMQyj8jgElNZPVr7QFz+vR+lbWXANg66Rj4xccvVoIZ80fN/Mz/pMo16LJ176c6pvbLDRB2CjlaK+5E+gqbx4F9jGVaZI71tTiPs0ql18VVYMNIk6da5renqqQKBgQDdA9k7vwpnf3b133/H0czC6seZcy/TKTuXCyPu5ob+if5Ir9zZ37TueoEBtLg0IIzVUnF5RdRAkDiHgQdB9HNOMlMJrvjoBy4bVB2bIToWlxbtkQXB6BnHa7Z60ViupHnlM0oNBx7R4nixDRfP8FkLjsDTrq78gqL1BQdMu8xk9QKBgQCA2hYJyo1v+1tt2eFmpU25BMvs9OBaNxBmjdaMs48hcPXUK9CBBkioCCzTQwbIGWT+0yY+Uo+izh0qrNgbxeyeKtyhK+V3lHu0Hw0BckYEytaWweT27rYkmvk+jjsBIeboNUXWhR7299In7NoHF/Z+DmD6zmXTS1WlNjNI0ItrwQKBgGs0ZXyTtVgzoSKM0EfPE9mLLCi1Sg6GA6DK8eUFEaPlZqUdIIGFRiKulaAqav2cnx6Xb9lgslVeXXwuUJG5105izJ7Nkj0RaMeu8hJtcEqxj0QD7Eg/awtQJLNrIKPvEhthnT+VMidLpT0ekUizlvM6V3YMBU7lex834t/GD85E`

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const headerStr = JSON.stringify({ alg: 'RS256', typ: 'JWT' })
  const payloadStr = JSON.stringify({
    iss: CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })

  const header = base64url(new TextEncoder().encode(headerStr))
  const payload = base64url(new TextEncoder().encode(payloadStr))
  const signingInput = `${header}.${payload}`

  const binaryKey = Uint8Array.from(atob(PRIVATE_KEY_PEM), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: { name: 'SHA-256' } },
    false,
    ['sign']
  )

  const signatureBuffer = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  )

  const signature = base64url(new Uint8Array(signatureBuffer))
  const jwt = `${signingInput}.${signature}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const tokenData = await tokenRes.json()
  if (!tokenData.access_token) {
    throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
  }
  return tokenData.access_token
}

serve(async (req) => {
  try {
    const { token, title, body, data } = await req.json()
    if (!token) return new Response(JSON.stringify({ error: 'No token' }), { status: 400 })

    const accessToken = await getAccessToken()

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: data || {},
            android: {
              priority: 'high',
              notification: { channel_id: 'eduflow_channel', sound: 'default' },
            },
          },
        }),
      }
    )

    const result = await res.json()
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    return new Response(JSON.stringify({ error: msg }), { status: 500 })
  }
})