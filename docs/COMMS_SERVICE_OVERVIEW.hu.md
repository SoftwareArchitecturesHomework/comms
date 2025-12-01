# Comms Szolgáltatás – Pontos és Tömör Áttekintés

Ez a dokumentum a Comms szolgáltatás valós, jelenlegi működését írja le. Csak két fő funkcionális területet kezel: (1) e‑mail értesítések küldése sablonokból és (2) Discord interakciók / parancsok feldolgozása. Minden korábbi utalás gRPC-re, általános üzenetbuszra, összetett streamelt dashboardokra vagy többcsatornás szabálymotorra eltávolításra került, mert nem részei a tényleges implementációnak.

## 1. Cél és Hatókör

- E‑mailek küldése üzleti események (feladat kiosztás, projekt státusz, szabadság kérés stb.) alapján.
- Discord slash command / interaction kérések fogadása, validálása, aláírás ellenőrzése és válasz generálása.
- Minimális integráció: nincs általános üzenetközvetítő réteg, nincs gRPC szolgáltatás, nincs bonyolult belső queue rendszer.

## 2. Fő Összetevők

### E‑mail

- Swoosh (`Comms.Mailer`) a küldéshez; konfiguráció `:comms` OTP alkalmazás alatt (pl. `smtp_from_email`).
- Sablonok: `lib/comms_web/templates/email/*.html.eex` – klasszikus `.eex`, NEM LiveView. Minden sablon a várt assign kommenttel indul (pl. `# assigner: %{name: String, email: String}`).
- Építés: `Comms.Notifications` modul állítja össze a `Swoosh.Email` struktúrát (from, to, subject, body). A body renderelést Phoenix sablonmotor végzi a megfelelő path alapján.

### Discord

- Router pipeline `:discord` és `CommsWeb.Plugs.VerifyDiscordSignature` plug a Discord aláírás ellenőrzéséhez (fejlécek: `X-Signature-Ed25519`, `X-Signature-Timestamp`).
- Végpontok:
  - `POST /discord/interactions` – slash command / component interactions.

## 3. Adat és Sablonkezelés

- Nincs komplex perzisztált "message" entitás az e‑mailekhez – az e‑mail összeállítás futáskor történik a kapott paraméterekből.
- Sablonváltozók: közvetlenül a `render` híváskor kerülnek átadásra assign mapként; a sablonok végeznek interpolációt. Nincs dinamikus sablon verziózás.
- Discord válaszok: általában JSON payload a Discord API elvárásai szerint (type, data). A validáció a signature ellenőrzés és a parancs típus alapján történik.

## 4. Folyamatok

### E‑mail Küldés

1. HTTP POST érkezik egy dedikált értesítési végpontra (pl. `/notifications/vacation-request`).
2. Controller / action validálja a minimális mezőket (címzett, JWT, kontextus adatok).
3. `Comms.Notifications` összeállítja a `Swoosh.Email` struktúrát: `from_email()` + dinamikus `to`.
4. Sablon render: `Phoenix.View.render("email/vacation_request.html", assigns)` – generált HTML a levél törzséhez.
5. `Comms.Mailer.deliver(email)` → küldés. Hibánál visszatér `{:error, reason}`.

### Discord Interaction

1. Discord küld egy HTTP POST-ot az `interactions` végpontra, fejlécekben időbélyeg + aláírás.
2. `VerifyDiscordSignature` plug hitelesíti (Ed25519).
3. Controller dekódolja a JSON-t; slash command név alapján routing / dispatch.
4. Válasz JSON: ack / ephemeral üzenet / follow‑up trigger.

### Discord Command Telepítés

`mix discord.install_commands` futtatás:

- Ellenőrzi szükséges env változókat.
- Küldi az upsert kérést a Discord API-hoz Req segítségével.
- Siker / hiba logolás, hibánál `Mix.raise/1`.

## 5. Hibakezelés

- E‑mail: Swoosh visszatérési érték alapján döntés. Nincs automatikus retry vagy backoff – hiba esetén a hívó fél (felsőbb szolgáltatás) kezeli az újrapróbálkozást.
- Discord: Signature hiba → 401 / 403; ismeretlen parancs → 400 egyszerű üzenettel; parse hiba → 422 JSON.
- Mix task: env hiány esetén `Mix.raise`; API hiba esetén status + body megjelenítés.

## 6. Biztonság

- Discord aláírás ellenőrzés kötelező; nincs további token validáció a Discord interactions endpointnál.
- E‑mail végpontok: belső (feltételezett) használat – javasolt IP / auth réteg (ha még nincs) a router pipeline-ban.
- `String.to_atom/1` nem használatos felhasználói bemenetre.
- Sablonokban nincs futtatható kód injektálás: csak interpoláció a kapott assign értékekkel.

## 7. Konfiguráció

- SMTP from cím: `Application.get_env(:comms, :smtp_from_email, "noreply@example.com")`.
- Discord env: `DISCORD_APP_ID`, `DISCORD_BOT_TOKEN`.
- Telepítés konténerrel: `Dockerfile`, `docker-compose.yaml` (standard Phoenix release). Nincs külön build pipeline a dokumentum szerint.

## 8. Egyszerű Metrikák / Logok (Aktuális Állapot)

- Strukturált log: siker / hiba e‑mail küldés, Discord parancs neve, státusz.
- Nincs dedikált Telemetry esemény-gyűjtés vagy histogram leírás jelen dokumentumban; igény esetén bővíthető.

## 9. Javasolt Közeli Fejlesztések

- Alap retry réteg e‑mail küldési hálózati hibákra (pl. 2 próbálkozás, rövid késleltetés).
- Alap rate limit a Discord notify végponton túlterhelés ellen.
- Telemetry hook: `:comms, :email, :sent|:error` és `:comms, :discord, :interaction`.
- Egyszerű audit log (append‑only) táblázat az érzékeny e‑mail eseményekhez.

## 10. Tesztelési Fókusz

- Unit: `Comms.Notifications` – helyes `from`, `subject`, sablon változó kitöltés.
- Plug teszt: hamis Discord signature → 403.
- Mix task: mockolt HTTP válasz (Req adapter konfigurációval) siker / hiba.

## 11. Korlátok

- Nincs többcsatornás szabálymotor.
- Nincs gRPC interfész.
- Nincs általános üzenetsor / queue perzisztencia.
- Nincs automatikus sablon verziózás.

## 12. Összegzés

A Comms jelenlegi formájában célzott, kétfunkciós szolgáltatás: e‑mail értesítések és Discord interakciók. Egyszerű moduláris felépítést használ, minimalista hibakezeléssel és könnyen bővíthető metrikákkal. A javasolt fejlesztések azonnal növelnék a megbízhatóságot (retry), láthatóságot (Telemetry), valamint operatív kontrollt (rate limit, audit log) anélkül, hogy felesleges komplexitást adnának hozzá.
