# Plan de la Beta 1

Alcance **congelado** el 2026-09-30. Lo que no esté aquí, no entra en la beta 1: se
apunta en "Fuera de alcance" y se decide después. Sin esta lista, el juego no se termina
nunca, que es exactamente lo que le pasó a los ~45 documentos que sustituyó el GDD.

**Qué es la beta 1:** una **prueba abierta en Google Play**, sin monetizar, con una vía
de feedback dentro del juego. Cualquiera con el enlace puede instalarla y opinar.

---

## 1. Juego

- [ ] **Menú a escala**: Forja, Perfil, Tienda, Lab y Misiones siguen con pestañas a 11 px
      y cabeceras a 10/26 px sin escalar. Es el último resto del rediseño.
- [ ] **Lab y Misiones**: solo tienen el escalado global, sin repasar pantalla a pantalla.
- [ ] **Modal de información del panel de mejoras**: verificado en PC, falta en el móvil.
- [ ] **Fondos**: mejorar los de partida y menú. Es el único trabajo de arte de la beta;
      el resto de placeholders se quedan.
- [ ] **Cero de Orbitron**: decidir si se cambia por Rajdhani. Con estadísticas a 0 la
      pantalla parece rota sin estarlo.

## 2. Pruebas y balance

- [ ] **Cubrir lo que no tiene pruebas**: Dron, Commander, tutorial y disparos especiales.
- [ ] **Simulador de balance headless**: que juegue cientos de partidas y saque curvas de
      tiempo por ascensión, causas de muerte y economía. Hoy "partida larga / balance real"
      es el único ❓ grande del estado del proyecto y se puede medir sin jugar.
- [ ] **Pase de balance** con esos datos. Criterio, dicho por el usuario: el juego es
      *entretenido, de estrategia*, no de adrenalina. Lo que se busca es que **las
      decisiones importen** — que elegir entre bonus, defensa y ataque no tenga una ruta
      óptima obvia que haga irrelevante el resto.
- [ ] **Rendimiento en el móvil** con el profiler, con muchos espectros en pantalla.

## 3. Técnico

- [ ] **Audio**: convertir los 8 WAV (6,1 MB) a OGG.
- [ ] **Leak de 1 recurso al cierre**: preexistente, no afecta al juego. Mirarlo o
      documentarlo como aceptado.
- [ ] **Export de release**: preset AAB, versionado (`versionCode`/`versionName`) y build
      firmada de verdad, no la de depuración.

## 4. Feedback dentro del juego

- [ ] Botón en el menú que abra un **formulario de Google** con la versión y la ascensión
      alcanzada como contexto. Sin backend, sin cuentas, sin datos personales.
- [ ] El formulario lo crea el usuario; aquí solo se conecta la URL.

## 5. Publicación (prueba abierta)

Requisitos de Play para una prueba abierta — son los mismos que para publicar:

- [ ] **Clave de firma** (`.jks`) creada por el usuario con `keytool`, guardada en
      `D:\_credenciales\`, **nunca en el repo**. Activar *Play App Signing*: si la clave de
      subida se pierde, Google puede reemplazarla; sin eso, perderla deja la app sin
      actualizaciones para siempre.
- [ ] **Política de privacidad** con URL pública. Se redacta aquí; el usuario la publica.
- [ ] **Ficha**: icono 512×512, gráfico de portada 1024×500, capturas de teléfono,
      descripción corta y larga.
- [ ] **Cuestionario de clasificación por edades** y **formulario de seguridad de datos**:
      los responde el usuario; aquí se prepara el borrador con lo que hace la app.

---

## Fuera de alcance de la beta 1

- **Monetización**: ni anuncios de AdMob ni compras (IAP). Se añaden cuando el balance
  esté asentado y sepamos si engancha. La Tienda mantiene su hueco sin lógica.
- **iOS**: necesita un Mac y cuenta de desarrollador de Apple.
- **Torneos y Alianzas**: ya aparecen como "próximamente" en el menú.
- **Arte completo**: solo se tocan los fondos.

---

## Reparto

**Lo hace el usuario** (no puede hacerlo el agente):

- Crear la clave de firma y custodiar sus contraseñas.
- Publicar la política de privacidad y rellenar los formularios de Play.
- Crear el formulario de Google del feedback.
- Decir si el juego entretiene: eso no se mide con pruebas.
- Desbloquear el móvil cuando toque verificar.

**Lo hace el agente:** código, pruebas, simulador y datos de balance, conversión de audio,
capturas de la ficha, borradores de política de privacidad y de los formularios, y el
pipeline de export.

---

## Orden de trabajo

1. Menú a escala, Lab y Misiones (cierra el rediseño de UI).
2. Pruebas de Dron, Commander, tutorial y especiales.
3. Simulador de balance y pase de ajuste. **Aquí es donde más se necesita al usuario.**
4. Fondos, audio y rendimiento.
5. Firma, ficha y prueba abierta.

El feedback (punto 4 del alcance) puede entrar en cualquier momento: es pequeño e
independiente.
