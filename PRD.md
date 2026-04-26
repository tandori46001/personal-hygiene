# PRD — personal-hygiene

> **Versión:** v0.2 (2026-04-25) — primera versión + fixes C1-C6 de auditoría lógica.
> **Estado:** ✅ Análisis · ⬜ Plan · ⬜ Bootstrap · ⬜ MVP · ⬜ Beta · ⬜ Release.
> **Stack:** Swift / SwiftUI nativo · iPhone + Apple Watch · CloudKit · Apple Intelligence on-device.
> **Lenguajes UI:** ES · EN · FR (i18n desde el inicio).

> **Política de valores reales (placeholder policy).** Este repositorio puede ser publicado.
> Por tanto: ningún identificador personal (nombre, email, fecha de nacimiento, dirección, IBAN, número de seguridad social, datos médicos reales, fotos de pasaporte, números de póliza) aparece en este PRD ni en ningún archivo trackeado. Los ejemplos usan placeholders reconocibles (`<usuario>`, `usuario@example.com`, `0000-0000`, `País destino`). Los datos reales viven sólo en CloudKit cifrado del usuario y en Keychain del dispositivo.

---

## 1. Visión

Una app personal de horarios de **precisión militar** que cubre el 100% del día del usuario — desde la primera ducha de la mañana hasta la hora de acostarse — y le libera de tener que **decidir** y **recordar** cada bloque. La app planifica, avisa y registra; el usuario sólo ejecuta.

Diferenciador: no es un calendario más. Es un **planificador de rutina total** con tres características que las apps existentes (Structured, Routinery, Fantastical) no combinan:

1. **Cobertura completa del día** — incluye comidas, aseo, hidratación, medicación y sueño, no sólo "tareas".
2. **Modo Vacaciones** holístico — recordatorios escalonados desde 6 meses antes, itinerario IA, meteo marítima para buceo, divisas, advisories oficiales, checklist de documentos.
3. **Apple Watch first** — interacciones glanceables de 1-2 segundos en la muñeca, no en el bolsillo.

---

## 2. Project identity

**Qué es:** App nativa iOS+watchOS de planificación de rutina diaria personal con bloques de tiempo precisos, recordatorios fiables (incluyendo medicación crítica), y un módulo separado de planificación de vacaciones.

**Qué NO es:**
- No es una app de productividad / GTD / kanban.
- No es un calendario compartido / familiar / profesional.
- No es una red social ni tiene componente social.
- No es un tracker de hábitos con gamificación.
- No es multi-usuario (aplicación estrictamente personal).

**Modelo de despliegue:** App Store iOS + watchOS app companion. Distribución personal inicialmente (TestFlight); posible publicación pública en fase posterior.

**Postura de privacidad:** datos sólo en el dispositivo del usuario y en su iCloud privado. Ningún backend propio. Ningún tercero recibe datos personales. Documentos sensibles (escaneos de pasaporte) cifrados on-device en Keychain con Data Protection class `complete`.

**Usuario objetivo:** una sola persona — el desarrollador. Adulto, multilingüe (ES/EN/FR), con rutina diaria estable, medicación regular, hijos a los que ve regularmente, viajes internacionales frecuentes, hobbies que incluyen buceo.

---

## 3. Goals & success criteria

### Goals

| # | Goal | Métrica de éxito |
|---|---|---|
| G1 | Usuario abre la app < 5 veces al día (todo lo importante llega vía notificación) | < 5 aperturas/día tras 2 semanas de uso |
| G2 | 0 dosis de medicación olvidadas | Cumplimiento HealthKit Medications ≥ 99% en 30 días |
| G3 | Sueño ≥ 7h/noche en ≥ 6 noches/semana | Métrica HealthKit Sleep |
| G4 | Tiempo de planificación diaria ≤ 1 minuto | El usuario no edita la plantilla a diario; sólo en cambios |
| G5 | Vacaciones sin olvidos críticos (pasaporte, visa, vacunas) | 0 incidencias en los próximos 3 viajes |
| G6 | App fluida y glanceable en Apple Watch | Tap-to-feedback < 100ms · sin scroll horizontal · sin spinners visibles en interacciones de < 1 paso |

### Success criteria por fase

**MVP (Fase 1):** el usuario es capaz de seguir su rutina diaria completa durante 14 días consecutivos sólo con las notificaciones de la app, sin recurrir a Recordatorios o Calendario nativos.

**Beta (Fase 2):** el módulo de medicación supera el test de 30 días con ≥ 99% de adherencia.

**Release (Fase 3):** el módulo de vacaciones cubre un viaje internacional real de inicio a fin sin olvidos críticos.

---

## 4. Non-goals

- ❌ Multi-usuario / familia / equipos — un solo usuario.
- ❌ Sincronización con Google Calendar / Outlook / otros — sólo Apple Calendar nativo.
- ❌ Backend propio — sólo CloudKit.
- ❌ Gamificación, rachas, badges, leaderboards.
- ❌ Coaching de hábitos / contenido motivacional / IA conversacional sobre rutina.
- ❌ Apple Watch standalone (LTE) en MVP — sólo como app companion del iPhone en fase 1.
- ❌ Android / Mac / Web en MVP — fase final, opcional.
- ❌ Compartición en tiempo real del itinerario de viaje — sólo exportación a PDF.
- ❌ Estadísticas detalladas a largo plazo — minimalismo total. Excepción: cumplimiento de medicación.
- ❌ APIs de pago en cualquier fase — todas las APIs externas deben tener free tier indefinido suficiente para uso personal.

---

## 5. User scenarios (un día y un viaje en la vida)

### 5.1 Día laborable típico

1. **07:00** — el Watch hace haptic suave: bloque "aseo + ducha" empieza. El usuario no toca el iPhone.
2. **07:30** — bloque "desayuno" empieza. El usuario marca "hecho" tocando la complication.
3. **08:00** — bloque "medicación matutina" — Critical Alert (sobrepasa modo silencio). El usuario marca como tomada en HealthKit Medications, lo que cierra el bloque.
4. **08:30 → 17:00** — jornada laboral. Modo Deep Focus activo: silenciado todo excepto medicación crítica y citas médicas.
5. **17:00** — bloque "deporte". Watch sugiere abrir Workouts.
6. **18:30** — bloque "compras supermercado". Notificación con `travel_time + 15min` antes (Apple Maps API estima el tiempo).
7. **20:00** — bloque "cena con hijos" (recurrente, marcado como referencia, no compartido).
8. **22:30** — wind-down inicia (HealthKit Sleep Focus). Pantalla pasa a modo nocturno.
9. **23:00** — bedtime objetivo (para 7h de sueño con despertar 06:00).

### 5.2 Vacaciones internacionales (preparación a 6 meses vista)

1. **6 meses antes** — usuario crea viaje en módulo Vacaciones. Indica fechas, destino, tipo (buceo). App verifica:
   - ¿Pasaporte válido + 6 meses tras fecha de regreso? → notificación si renovación necesaria.
   - ¿Visa requerida? → enlace a embajada del destino.
   - ¿Vacunas recomendadas? → checklist según OMS/CDC para el destino.
2. **3 meses antes** — recordatorios: reservar vuelos, alojamiento, seguro de viaje.
3. **1 mes antes** — recordatorios: comprar adaptadores, ropa específica, equipo de buceo.
4. **2 semanas antes** — recordatorios: renovar recetas, notificar al banco, eSIM/roaming.
5. **1 semana antes** — generar itinerario IA (regenerable). Imprimir documentos. Conseguir cash en moneda local.
6. **Día D** — checklist final: pasaporte, billetes, póliza, contactos de emergencia.
7. **En destino** — meteo + mareas + olas diarias. Advisories actualizados. Conversor de divisa.
8. **Al volver** — plan de re-entrada (revisión médica si destino exótico, restock medicación).

---

## 6. Funcional — Módulos

### M1 — Plantilla de rutina diaria

**Descripción:** sistema de plantillas reutilizables. El usuario define una vez su rutina típica por tipo de día (`weekday`, `weekend`, `vacation`) y la app genera el calendario diario automáticamente.

**Requisitos:**
- M1.1 Crear/editar bloques con: título, hora inicio, duración, categoría, ubicación opcional, notas.
- M1.2 Categorías predefinidas: aseo, comida, deporte, trabajo, médico, compras, medicación, social, hijos, sueño, hidratación, hogar.
- M1.3 Plantillas por día: lunes-viernes idénticas por defecto, sábado y domingo personalizables.
- M1.4 Modo vacaciones (M9) sustituye plantillas normales mientras está activo.
- M1.5 El usuario gestiona imprevistos manualmente — la app NO reordena bloques automáticamente.
- M1.6 Edición rápida de un día concreto sin afectar la plantilla maestra.

### M2 — Notificaciones y alertas

**Requisitos:**
- M2.1 Por cada bloque: notificación 15 minutos antes.
- M2.2 Si el bloque tiene ubicación distinta: notificación `travel_time + 15min` antes (Apple Maps `MKDirections`).
- M2.3 Notificación llega a iPhone (banner + sonido) Y Apple Watch (haptic), salvo en modo Deep Focus.
- M2.4 Modo silencio opcional por bloque (sólo haptic, sin sonido).
- M2.5 Medicación crítica: `UNNotificationContentProviding` con `interruptionLevel = .critical` (sobrepasa modo silencio y Focus).
- M2.6 Vacaciones: alertas escalonadas según timing definido en M9.

### M3 — Medicación

**Requisitos:**
- M3.1 Integración con **HealthKit Medications API** (WWDC25) — no reinventar.
- M3.2 Soporte de Dose Reminders y Follow-up Reminders (30 min después si no marcada). Critical Alerts (sobrepasa silencio/Focus) **sólo si Apple aprueba el entitlement** `com.apple.developer.usernotifications.critical-alerts`. Plan de fallback: si el entitlement es denegado, usar notificación normal con sonido propio + repetición a 5 y 10 min hasta que el usuario actúe.
- M3.3 Tracking de cumplimiento — única estadística persistente en la app.
- M3.4 Dashboard semanal: días con 100% adherencia / días con alguna dosis omitida.
- M3.5 **Sincronización Health → bloque M1.** La app observa cambios en HealthKit Medications mediante `HKObserverQuery` con background delivery habilitado. Cuando una dosis se marca como tomada/omitida en Health, el bloque correspondiente en M1 se actualiza automáticamente sin requerir abrir la app. La asociación bloque ↔ dosis se establece por `HKMedicationConcept` + ventana horaria (±30 min del horario del bloque). **Estado:** infraestructura compilada (`HealthKitMedicationService` placeholder + `MedicationCompliance` + `MedicationDoseLog`); validación con dispositivo real + entitlement HealthKit pendiente. Sin entitlement, todo el módulo funciona en modo `InMemoryMedicationService` (sin sincronización con Health).
- **M3.2 follow-up reminders (shipped session 9, round 7):** mientras no exista el entitlement HealthKit, `MedicationFollowUpFactory` programa una notificación adicional a `triggerDate + 30 min` para cada bloque de medicación, con prefijo `personal-hygiene.medication.followup.` y nivel critical. Si Apple aprueba el entitlement Critical Alerts y se conecta `HKObserverQuery`, esta lógica se reemplaza por re-notificación basada en evento real (la dosis no se marcó tomada en Health).

### M4 — Sueño

> **Nota técnica.** HealthKit Sleep es **read-mostly**: la app puede leer datos de sueño (`HKCategoryValueSleepAnalysis`) pero NO existe API pública para fijar el sleep schedule de la app Health programáticamente. Por tanto, la app **mantiene su propio bloque de sueño** dentro de M1 y sólo *lee* HealthKit para validar la duración real.

**Requisitos:**
- M4.1 Lectura de datos de sueño desde **HealthKit Sleep** (`HKCategoryValueSleepAnalysis`) cuando el Apple Watch los proporciona.
- M4.2 La app calcula y muestra un bedtime objetivo propio: `wake_up_time - 7h45min` (target medio 7-8h). Este valor crea un bloque en M1 (categoría `sueño`) — NO escribe en el sleep schedule de Apple Health.
- M4.3 Activación de Sleep Focus durante el wind-down: la app **sugiere** activar el Focus "Sueño" del usuario (deep link a Ajustes o Shortcut). NO se activa programáticamente — el usuario lo confirma una vez y queda automatizado vía Shortcuts si desea.
- M4.4 Lectura de duración real de sueño desde Watch (si disponible) para mostrar al usuario "objetivo vs. real" en el bloque del día siguiente.

### M5 — Hidratación

**Requisitos:**
- M5.1 Recordatorios espaciados durante el día (cada 2h por defecto, configurable).
- M5.2 No notificar durante bloques de sueño ni durante Deep Focus salvo si el usuario lo activa.
- M5.3 Tracking opcional (sin presión) — vasos consumidos / objetivo. Sin gráficos.

### M6 — Tareas domésticas recurrentes

**Requisitos:**
- M6.1 Bloques recurrentes con cadencia semanal/mensual: cambiar sábanas, regar plantas, limpieza, etc.
- M6.2 Marcar "hecho" y la app calcula la próxima ocurrencia.
- M6.3 Si una tarea se omite > 1 cadencia, escalado visual (no notificación adicional, sólo destacada en la lista del día).

### M7 — Cumpleaños y aniversarios

**Requisitos:**
- M7.1 Integración con **Contacts framework** (`CNContactStore` + `CNContact.birthday` + `CNContact.dates`).
- M7.2 Permiso (`NSContactsUsageDescription`) solicitado al activar el módulo.
- M7.3 Generación automática de bloques recordatorio:
   - 1 semana antes: "comprar regalo / preparar mensaje".
   - Día D: "felicitar a `<nombre>`".
- M7.4 Sin escritura en Contactos — sólo lectura.

### M8 — Modo Deep Focus

**Requisitos:**
- M8.1 Bloques pueden marcarse como "deep focus".
- M8.2 Durante esos bloques, silenciar todas las notificaciones de la app excepto: medicación crítica, citas médicas con < 30 min de antelación.
- M8.3 Integración con **iOS Focus API** — la app sugiere activar el Focus "Trabajo" del usuario si está configurado.

### M9 — Módulo Vacaciones (fase final)

**Modo aparte, activable desde tab/sheet.** No interfiere con la rutina diaria.

#### M9.1 — Trip Setup
- Crear viaje: nombre, destino (país + ciudad), fechas inicio/fin, tipo (`internacional`, `doméstico`, `weekend`), actividades (`buceo`, `senderismo`, `cultural`, otras).
- Calcular automáticamente el timeline de preparación según fechas.

#### M9.2 — Reminders escalonados

Generación automática de bloques en el calendario principal con la siguiente cadencia:

| Antelación | Categoría | Tareas |
|---|---|---|
| 6 meses | Documentos | Validez pasaporte (≥ 6 meses tras regreso), visa requerida, seguro de viaje |
| 3 meses | Reserva | Vuelos, alojamiento, vacunas si exótico |
| 1 mes | Compras | Adaptadores eléctricos, ropa, equipo específico (buceo, etc.) |
| 2 semanas | Salud + finanzas | Renovar recetas, notificar al banco, eSIM/roaming |
| 1 semana | Logística | Imprimir documentos, copias digitales, conseguir cash, check-in online (24-48h antes) |
| 3-5 días | Equipaje | Empezar maleta (10 días si destino complejo) |
| 1-2 días | Final | Lavandería, compartir itinerario con familia (export PDF), cargar dispositivos |
| Día D | Salida | Outfit, pasaporte, billetes, contactos de emergencia |

#### M9.3 — Documentos digitales
- Escaneo con **VisionKit** (`VNDocumentCameraViewController`) + OCR (`VNRecognizeTextRequest`).
- Almacenamiento cifrado en Keychain con Data Protection class `complete`.
- Acceso offline (vital si el dispositivo no tiene conexión en destino).
- Lista canónica generada: vuelos, alojamiento, póliza seguro, copia pasaporte, itinerario, contactos de emergencia, recetas en inglés.

#### M9.4 — Itinerario IA
- **MVP:** Apple Intelligence on-device (gratis, privado, limitado en capacidad).
- **Fase posterior:** opción de elegir entre Google AI Studio Flash, Claude API, GPT API, Ollama local.
- Prompt incluye: fechas, destino, presupuesto, actividades elegidas, intereses.
- El usuario puede editar manualmente el itinerario generado.
- **Compartir como texto plano**: el itinerario generado puede exportarse vía Share Sheet (`UIActivityViewController`) como texto simple — útil para enviar por WhatsApp/SMS/Mail a familiares sin abrir el PDF completo.
- Disclaimer obligatorio: "Verificar precios y horarios antes de reservar — la IA puede tener datos desactualizados".

#### M9.5 — Meteo + mareas + olas
- **WeatherKit** (Apple, gratis hasta 500k llamadas/mes) — meteo terrestre.
- **Open-Meteo Marine API** (gratis, sin auth, uso no comercial) — olas, swell, mareas — sólo si el viaje incluye actividad marítima.
- Vista por día durante el viaje.

#### M9.6 — Divisa y cash
- **Frankfurter API** (gratis, sin auth, sin límites) — tipo de cambio en tiempo real.
- Estimación de cash recomendado: cálculo simple `días × estimación coste medio diario` (estimación basada en IA con prompt sobre el destino).

#### M9.7 — Advisories y zonas peligrosas
- **MVP:** feed RSS oficial del Ministerio de Asuntos Exteriores español — `exteriores.gob.es/recomendaciones-de-viaje` (gratis).
- **Fase posterior:** opcionalmente añadir feeds gobierno UK (FCDO) y US State Dept para cross-check.
- Mostrar nivel de riesgo + recomendaciones específicas del destino.

#### M9.8 — Ajuste de rutina por jet-lag
- Al confirmar llegada al destino, la app reajusta los bloques de rutina a la zona horaria local manteniendo la duración del sueño objetivo.
- Wind-down y bedtime se desplazan automáticamente.

#### M9.9 — Plan de re-entrada
- Al confirmar regreso, generar bloques recordatorio:
  - Restock de medicación si gastada.
  - Revisión médica si destino exótico (configurable según destino).
  - Lavandería + descarga/respaldo de fotos.

#### M9.10 — Exportación PDF
- Botón "Exportar viaje" → genera PDF con: itinerario, vuelos, alojamiento, contactos de emergencia, copia documentos.
- Compartir vía sheet nativo iOS (Mail, Messages, WhatsApp, AirDrop, …).

---

## 7. Non-functional requirements

### 7.1 Privacidad
- Datos NUNCA salen del ecosistema Apple del usuario.
- Documentos sensibles cifrados con Data Protection class `complete` (sólo accesibles con dispositivo desbloqueado).
- iCloud E2E encryption activado (CloudKit Private Database).
- Solicitar permisos de forma incremental — no pedir todos al inicio.

### 7.2 i18n
- Cadenas localizadas en ES, EN, FR desde la primera pantalla.
- Formatos de fecha/hora/divisa según locale del usuario.
- Cada string nueva DEBE aterrizar en los 3 locales en el mismo commit (regla heredada del template; ver §6 del PRD-START-NEW-PROJECT.md).

### 7.3 Accesibilidad
- VoiceOver soportado en todas las pantallas iOS.
- Dynamic Type — la app debe ser usable con texto extra grande.
- Apple Watch: tap targets ≥ 44pt.
- Contraste ≥ AAA donde sea posible.

### 7.4 Performance
- App fría → primera pantalla útil en < 2s en iPhone reciente.
- Apple Watch: complications actualizadas en < 500ms.
- Sincronización CloudKit transparente, sin spinners visibles para el usuario.

### 7.5 Fiabilidad
- Las notificaciones de medicación NUNCA pueden fallar — mismo nivel de criticidad que un calendario médico.
- Backup automático diario a iCloud + opción de backup manual antes de viajes.
- Restore desde iCloud probado y documentado en el QA manual.

### 7.6 Offline
- App 100% funcional sin conexión salvo: Itinerario IA, meteo/mareas, divisa, advisories.
- Si no hay conexión, mostrar última versión cacheada con timestamp.

---

## 8. Tech stack (referencia abreviada — detalle en ARCHITECTURE.md)

| Capa | Tecnología | Versión | Motivo |
|---|---|---|---|
| Lenguaje | Swift | 6.x | Nativo Apple |
| UI | SwiftUI | iOS 18+ / watchOS 11+ | Declarativo, Watch + iPhone con un solo paradigma |
| Sync | CloudKit | — | Gratis, integrado en iCloud, E2E |
| Calendar | EventKit | — | Citas médicas, eventos sociales |
| Salud | HealthKit (Medications + Sleep) | iOS 18+ | API oficial WWDC25 para medicación |
| Contactos | Contacts framework | — | Cumpleaños/aniversarios |
| Notificaciones | UserNotifications | — | Critical Alerts para medicación |
| Watch | WidgetKit (complications) | watchOS 11+ | ClockKit deprecado |
| OCR | Vision + VisionKit | — | Escaneo de documentos |
| IA local | Apple Intelligence (Foundation Models) | iOS 18.1+ | Gratis, privado |
| IA externa (futuro) | Google AI Studio Flash / Claude / GPT / Ollama | — | Opt-in fase posterior |
| Meteo | WeatherKit | — | Apple, free tier 500k/mes |
| Marítima | Open-Meteo Marine | — | Gratis, sin auth |
| Divisa | Frankfurter | — | Gratis, sin auth |
| Advisories | exteriores.gob.es RSS | — | Oficial, gratis |

---

## 9. Phased delivery plan

> **Principio rector:** entregar una **fase pequeña y completa** antes de empezar la siguiente. Calidad sobre velocidad.

### Fase 0 — Bootstrap (semana 1)
Setup repositorio + meta-system del template (CLAUDE.md, memory, LESSONS, QA_MANUAL, ROADMAP, PRD, ARCHITECTURE). Xcode project con esquemas iOS + watchOS. CI/CD básico (GitHub Actions con Xcode Cloud o `xcodebuild`).

### Fase 1 — MVP rutina diaria (semanas 2-6)
- M1 plantillas + M2 notificaciones básicas + M3 medicación (con HealthKit Medications) + M4 sueño.
- iPhone sólo (sin Watch todavía).
- i18n ES/EN/FR.
- 14 días de uso real personal antes de cerrar la fase.

### Fase 2 — Apple Watch companion (semanas 7-9)
- App watchOS con plantillas del día.
- Complications para "qué viene ahora".
- Haptic notifications.
- Marcar bloques como hechos desde el Watch.

### Fase 3 — Módulos secundarios (semanas 10-12)
- M5 hidratación + M6 tareas domésticas + M7 contactos + M8 deep focus.

### Fase 4 — Beta TestFlight (semana 13)
- TestFlight cerrado (sólo el desarrollador como tester).
- Iteración de bugs durante 2 semanas.

### Fase 5 — Módulo Vacaciones (semanas 14-20)
- M9 completo. Es el módulo más complejo — se aborda al final cuando el resto está estable.
- Integraciones externas: WeatherKit, Open-Meteo Marine, Frankfurter, RSS gobierno.
- VisionKit + OCR.
- Itinerario IA on-device.

### Fase 6 — App Store release (semanas 21-22)
- App Store submission.
- Localización del listing en 3 idiomas.
- Política de privacidad pública.

### Fase 7 — Plataformas adicionales (futuro, sin fecha)
- Apple Watch standalone.
- macOS via Mac Catalyst o app nativa SwiftUI.
- Android (Kotlin Multiplatform o reescritura nativa).

---

## 10. Privacy & data model (resumen)

- Toda persistencia local en SwiftData (iOS 17+) o Core Data.
- Sync vía CloudKit Private Database (E2E con iCloud).
- Documentos sensibles fuera de SwiftData — guardados como `Data` cifrado en Keychain.
- Ningún identificador del usuario se envía a APIs externas — las llamadas a WeatherKit/Open-Meteo/Frankfurter sólo envían coordenadas o códigos de divisa.
- Apple Intelligence on-device garantiza que el contenido del itinerario IA nunca sale del dispositivo.

---

## 11. Acceptance criteria por fase

### Fase 1 (MVP)
- [ ] Plantilla de rutina creada y editable
- [ ] Notificaciones llegan 15 min antes (configurable)
- [ ] Medicación integrada con HealthKit Medications (Critical Alerts si entitlement aprobado, fallback notificación repetida si no)
- [ ] Bloque de sueño/bedtime presente en la rutina diaria con cálculo automático desde wake-up; lectura HealthKit Sleep para validar duración real
- [ ] i18n ES + EN + FR — cero claves sin traducir
- [ ] 14 días consecutivos de uso real sin recurrir a apps nativas

### Fase 5 (Vacaciones)
- [ ] Trip setup completo en < 2 minutos
- [ ] Recordatorios escalonados generados automáticamente
- [ ] Documentos escaneados y cifrados, accesibles offline
- [ ] Itinerario IA generado sin conexión
- [ ] Meteo + mareas mostradas correctamente
- [ ] Advisory de exteriores.gob.es funciona para país destino
- [ ] PDF exportable y compartible vía Mail/SMS/WhatsApp
- [ ] Probado con un viaje internacional real de inicio a fin

---

## 12. Out of scope / future work

- Apple Watch standalone (LTE) — fase posterior.
- Sincronización con Google Calendar / Outlook.
- Compartición en tiempo real de itinerarios.
- Estadísticas a largo plazo más allá de medicación.
- Coaching IA conversacional.
- Android, macOS, Web.
- Modo familiar / multi-usuario.
- Integración con apps de terceros (Notion, Todoist, etc.).

---

## 13. Open questions

| # | Pregunta | Resolución |
|---|---|---|
| Q1 | ¿Modelo de datos en SwiftData o Core Data? | A definir en ARCHITECTURE.md |
| Q2 | ¿Apple Intelligence Foundation Models bastan para itinerarios reales o requieren Claude/GPT? | Validar en Fase 5 con prueba real |
| Q3 | ¿Cómo manejar bloques recurrentes que cruzan la medianoche local cuando se cambia de zona horaria mid-viaje? (M9.8 ya define rebase a hora local; queda definir el caso límite) | Decidir antes de Fase 5 — propuesta: split del bloque en dos partes con la nueva medianoche local |
| Q4 | ¿Política de actualización de plantilla cuando cambia la rutina del usuario? | Versioning ligero — guardar última versión + opción "restaurar plantilla anterior" |
| Q5 | ¿Cómo autenticar acceso a documentos sensibles en la app? | Face ID / Touch ID antes de mostrar pasaporte y similares |

---

## 14. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Critical Alerts entitlement** denegado por Apple (`com.apple.developer.usernotifications.critical-alerts`) | Media | Alta | Plan de fallback ya definido en M3.2: notificación normal con sonido propio + repetición a 5 y 10 min. Solicitar entitlement con justificación clara (medicación crítica) durante el desarrollo, no en submission. |
| HealthKit Medications API tiene limitaciones que no cubren caso del usuario | Media | Alta | Validar early en Fase 1; si limita, complementar con UserNotifications custom |
| Apple Intelligence on-device demasiado limitada para itinerarios útiles | Media | Media | Diseñar arquitectura para swap de provider en Fase 5; offer fallback a Claude API |
| Open-Meteo Marine cambia política gratuita | Baja | Baja | Cache agresivo; alternativa StormGlass de pago si pasa |
| RSS exteriores.gob.es cambia formato | Media | Baja | Parser robusto con fallback a "no datos disponibles, ver web oficial" |
| CloudKit limita storage personal | Muy baja | Baja | Documentos pesados (PDFs grandes) almacenados localmente, no en sync |
| User burnout por demasiadas notificaciones | Media | Alta | Configurabilidad agresiva; default sensato; modo silencio por bloque |

---

## 15. Referencias y best practices

### Apple frameworks
- [HealthKit Medications API — WWDC25](https://developer.apple.com/videos/play/wwdc2025/321/)
- [EventKit — Apple Developer](https://developer.apple.com/documentation/eventkit)
- [VisionKit — Apple Developer](https://developer.apple.com/documentation/visionkit)
- [Capture machine-readable codes and text — WWDC22](https://developer.apple.com/videos/play/wwdc2022/10025/)
- [CNContactStore — Apple Developer](https://developer.apple.com/documentation/contacts/cncontactstore)
- [Creating accessory widgets and watch complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [Set up sleep schedule in Health — Apple Support](https://support.apple.com/guide/iphone/set-up-a-sleep-schedule-iphaf56dceb4/ios)
- [Set up medication reminders iOS — MacRumors](https://www.macrumors.com/how-to/set-up-critical-medication-reminders-ios/)

### Apps de referencia (no copiar)
- [Structured — Daily Planner](https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946)
- [Routinery — Routine Planner](https://apps.apple.com/us/app/routine-planner-habit-tracker/id1450486923)
- [Best Daily Routine Apps 2026 — Habi](https://habi.app/insights/best-daily-routine-apps/)

### UX best practices
- [Best Practices for Designing Apple Watch Apps with SwiftUI](https://moldstud.com/articles/p-best-practices-for-designing-apple-watch-apps-with-swiftui-a-comprehensive-guide)
- [12 Best Time Blocking Apps 2026](https://www.calendar0.app/blog/time-blocking-apps)
- [Mobile App MVP Development — Netguru](https://www.netguru.com/blog/mobile-app-development-mvp)

### APIs externas
- [Open-Meteo Marine Weather API](https://open-meteo.com/en/docs/marine-weather-api)
- [Frankfurter — Free exchange rates API](https://frankfurter.dev/)

### Travel best practices
- [International Travel Checklist — US State Dept](https://travel.state.gov/en/international-travel/planning/checklist.html)
- [Pre-Trip Checklist 37 things — Allianz Partners](https://www.allianztravelinsurance.com/travel/planning/pretrip-checklist.htm)
- [Best AI Prompts for Travel Itineraries 2026](https://www.stayvista.com/blog/best-ai-prompts-for-travel-2025-guide/)
- [Best Passport Organizer App 2026](https://traveldocumentvault.com/blog/best-passport-organizer-app/)

---

**Version history:**

- **v0.1 (2026-04-25)** — primera versión. Análisis cerrado tras 4 rondas de clarificación con el usuario. Stack confirmado: Swift/SwiftUI nativo, CloudKit, Apple Intelligence on-device, APIs gratuitas. 9 módulos definidos, 7 fases de delivery propuestas.
- **v0.2 (2026-04-25)** — auditoría lógica + fixes de 6 invariantes rotos:
  - C1: Critical Alerts entitlement no es garantía → plan de fallback en M3.2 + riesgo en §14.
  - C2: HealthKit Sleep no permite escribir schedule → M4 reformulado para sólo *leer*; bedtime mantenido en bloque M1 propio.
  - C3: §11 acceptance Fase 1 reformulado para reflejar M4 corregido.
  - C4: M3.5 nuevo — sincronización HealthKit → bloque M1 vía `HKObserverQuery`.
  - C5: G6 "60fps" sustituido por "tap-to-feedback < 100ms" (métrica honesta).
  - C6: Q3 reformulado — el caso decidido (rebase a hora local) ya está en M9.8; pregunta abierta es ahora el caso límite de bloques que cruzan medianoche local.
  - Pendiente: 12 significant + 8 minor de la auditoría — esperando decisión del usuario.
