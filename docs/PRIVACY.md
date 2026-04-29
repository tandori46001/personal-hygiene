# Privacy policy — PersonalHygiene

**Effective date:** 2026-04-29
**Version:** 1.0 (draft, awaiting Apple Developer Program activation + App Store submission)
**Contact:** wingelo0@gmail.com

This document defines what data the PersonalHygiene iOS + watchOS app collects, where it goes, and what rights you have. The same policy is provided in English (§ EN), Spanish (§ ES), and French (§ FR). The English version is canonical.

---

## EN — English

### 1. Summary

PersonalHygiene is a single-user personal scheduling app. **Your data never leaves your Apple ecosystem.** There are no analytics, no third-party SDKs, no telemetry, and no advertising identifiers. The developer (the author of this app) cannot read, recover, or sell your data — there is no backend.

### 2. What we store, and where

| Data type | Where it lives | Encryption |
|---|---|---|
| Daily routine templates, blocks, completion history | Your iPhone's local database (SwiftData), synced via your iCloud Private Database | iCloud E2E |
| Medication adherence + dose log | Your iPhone's HealthKit store | Apple-managed (Keychain-class) |
| Sleep log | Your iPhone's HealthKit store | Apple-managed |
| Hydration log, mood log, housekeeping streaks | SwiftData + CloudKit Private DB | iCloud E2E |
| Birthdays + relationships | Imported from your Contacts on first run; cached locally; never re-shared | Local |
| Trip data, itineraries, packing lists, expenses | SwiftData + CloudKit Private DB | iCloud E2E |
| Trip documents (passport scans, etc.) | iOS Keychain | Keychain hardware-backed |
| Cover photos for trips | SwiftData external storage | Local file system |

### 3. What we send to external services, and why

These are the only network calls the app makes. None of them include your name, identifier, or any PII.

| Service | What we send | Why |
|---|---|---|
| **Apple WeatherKit** | Latitude + longitude of your trip destination | Weather forecast for itinerary days |
| **Open-Meteo Marine API** | Latitude + longitude of marine destinations | Marine forecast (waves, tides) for diving / sailing days |
| **Frankfurter API** | A pair of currency codes (e.g. `EUR → USD`) | Currency conversion for your trip budget |
| **Apple MapKit / `MKLocalSearchCompleter`** | Search query as you type a destination | Auto-complete trip destinations |
| **CoreLocation reverse-geocode** (only if you opt in to "auto-detect home") | Your current latitude + longitude, once | Default home location for travel-time notifications |
| **Apple Intelligence Foundation Models** | The itinerary prompt you generate | On-device generation only — does not leave your device |
| **Travel advisory websites** (5 government sources) | The destination country code | Opens the official advisory page in Safari |

### 4. What we do NOT do

- We do **not** maintain any server.
- We do **not** collect analytics, crash reports, or usage telemetry.
- We do **not** integrate with any advertising network.
- We do **not** sell, share, or transmit your routine, medication, sleep, mood, or trip data to any third party.
- We do **not** include any third-party SDK in the app binary.
- We do **not** request any tracking permission (no IDFA usage).

### 5. Permissions the app may request

| Permission | Why | Required? |
|---|---|---|
| Notifications | Routine + medication + trip reminders | Required for the app's core function |
| HealthKit (Medications + Sleep) | Read your medication and sleep records | Optional per metric |
| Critical Alerts | Bypass Silent mode for medication reminders | Optional, defaults off |
| Contacts | Import birthdays of people you choose | Optional |
| Calendar (EventKit) | Read your calendar to detect conflicts with blocks | Optional |
| Camera (VisionKit) | Scan trip documents | Optional |
| Photo library (PhotosPicker) | Pick a cover photo for a trip | Optional |
| Location (when in use) | Auto-detect home location for travel-time blocks; map preview of trip destinations | Optional, defaults off |
| Focus | Read scheduled Focus windows to mute non-critical alerts | Optional |

You can revoke any permission in iOS Settings → PersonalHygiene at any time.

### 6. Data export and deletion

- **Export:** Settings → Backup & Data → Export backup writes a JSON file to your Files app or share sheet. The file contains everything except HealthKit records (those remain in HealthKit).
- **Delete all data:** Settings → Backup & Data → Reset all data wipes the local SwiftData store and triggers an iCloud delete on your next sync.
- **Per-trip delete:** swipe-to-delete on any trip. Cascades to milestones + documents.
- **Uninstall:** removes the local store. Your iCloud copy persists until you sign out of iCloud or delete the app's iCloud data via iOS Settings → Apple ID → iCloud → PersonalHygiene → Delete data from iCloud.

### 7. Children

The app is not designed for users under 13. If you add a child's birthday or a child traveller in your trip, that information is stored only on your device and your iCloud private database — it is never shared.

### 8. Changes to this policy

We will publish any material change to this policy at least 30 days before it takes effect, both in this document and in an in-app banner.

### 9. Your rights (GDPR + CCPA)

Because all your data is in your own Apple ecosystem and we have no copy:
- You have the right to access — your data is always accessible to you on-device.
- You have the right to deletion — Settings → Backup & Data → Reset all data.
- You have the right to portability — Settings → Backup & Data → Export backup.
- You have the right to lodge a complaint with your data-protection authority. Contact us at the address above.

---

## ES — Español

### 1. Resumen

PersonalHygiene es una aplicación personal monousuario. **Tus datos nunca salen de tu ecosistema Apple.** No hay analítica, SDKs de terceros, telemetría ni identificadores publicitarios. El desarrollador no puede leer, recuperar ni vender tus datos — no hay backend.

### 2. Qué se almacena y dónde

Tu información permanece en SwiftData local + CloudKit privado (cifrado E2E con iCloud). Documentos sensibles (escaneos de pasaporte, etc.) se guardan en el Keychain del dispositivo.

### 3. Llamadas externas

| Servicio | Qué se envía | Para qué |
|---|---|---|
| Apple WeatherKit | Coordenadas del destino | Pronóstico del tiempo |
| Open-Meteo Marine | Coordenadas marinas | Pronóstico marino |
| Frankfurter | Códigos de divisa | Conversión de moneda |
| MapKit | Texto de búsqueda | Autocompletado de destinos |
| CoreLocation (opt-in) | Tu ubicación, una vez | Detección de "casa" para tiempo de viaje |
| Apple Intelligence | El prompt del itinerario | Generación on-device — no sale del dispositivo |

Ninguna de estas llamadas incluye tu nombre ni ningún identificador personal.

### 4. Qué NO hacemos

No mantenemos servidor. No recolectamos analítica ni telemetría. No integramos redes de publicidad. No vendemos, compartimos ni transmitimos tus datos a terceros. No incluimos SDKs de terceros en el binario.

### 5. Tus derechos

Acceso, exportación, eliminación: todos disponibles desde **Ajustes → Copia de seguridad y datos** dentro de la app.

### 6. Contacto

wingelo0@gmail.com

---

## FR — Français

### 1. Résumé

PersonalHygiene est une application personnelle monoutilisateur. **Vos données ne quittent jamais votre écosystème Apple.** Aucun service d'analyse, aucun SDK tiers, aucune télémétrie, aucun identifiant publicitaire. Le développeur ne peut ni lire, ni récupérer, ni vendre vos données — il n'y a pas de serveur.

### 2. Stockage des données

Vos données restent en local (SwiftData) + iCloud privé (chiffrement E2E). Les documents sensibles (scans de passeport, etc.) sont conservés dans le Keychain de l'appareil.

### 3. Appels réseau externes

| Service | Données envoyées | Finalité |
|---|---|---|
| Apple WeatherKit | Coordonnées de destination | Prévisions météo |
| Open-Meteo Marine | Coordonnées maritimes | Prévisions marines |
| Frankfurter | Codes de devises | Conversion de monnaie |
| MapKit | Texte de recherche | Autocomplétion |
| CoreLocation (opt-in) | Votre position, une fois | Détection du domicile pour les temps de trajet |
| Apple Intelligence | Le prompt d'itinéraire | Génération on-device — ne quitte pas l'appareil |

Aucun appel ne contient votre nom ni d'identifiant personnel.

### 4. Ce que nous ne faisons PAS

Pas de serveur. Pas de collecte d'analyse ni de télémétrie. Aucune intégration publicitaire. Aucune vente ni partage de vos données. Aucun SDK tiers dans le binaire.

### 5. Vos droits

Accès, exportation, suppression : tous disponibles depuis **Réglages → Sauvegarde et données** dans l'application.

### 6. Contact

wingelo0@gmail.com

---

## Hosting plan

This document is intended to be hosted at a stable HTTPS URL, required by App Store Connect during submission. Recommended path:

1. Create a `gh-pages` branch on this repository.
2. Add `docs/PRIVACY.md` rendered to `index.html` via Jekyll (GitHub Pages built-in).
3. Submit `https://wingelo.github.io/personal-hygiene/` (or equivalent) to App Store Connect → App Information → Privacy Policy URL.

Alternative: host on a personal domain with a static-page generator, or as a Notion/Substack public page.
