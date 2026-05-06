# CIRCUITO FINAL (LOGISIM) — VERSIÓN LIMPIA PARA ENTREGA

> Esta versión está hecha para que puedas **borrar lo anterior** y quedarte con una guía clara, ordenada y directa del circuito.

---

## 1) Qué debes dejar al final

Solo estos bloques en Logisim:

1. `TARGET_MMSS`
2. `SPEED_DIV`
3. `CTRL_START_DONE`
4. `ELAPSED_COUNTER`
5. `BIN_TO_MMSS`
6. `DISPLAY_7SEG`

Y una salida final: `DONE_LED`.

---

## 2) Conexión general (TOP)

```text
Entradas:
  CLK, RST, START, SPEED[1:0], T_MIN[2:0], T_SEC_T[2:0], T_SEC_U[3:0]

                         +-------------------+
T_MIN,T_SEC_T,T_SEC_U -->|    TARGET_MMSS    |--> TARGET_TOTAL[8:0]
                         +-------------------+
                                      |
                                      v
CLK,RST,SPEED ----------------> +-------------------+
                                |     SPEED_DIV     |--> TICK_EN
                                +-------------------+
                                      |
                                      v
START,TARGET_TOTAL,ELAPSED,RST -> +-------------------+
                                   | CTRL_START_DONE   |--> RUN
                                   | (genera START_EDGE|--> DONE_LED
                                   +-------------------+
                                             |
                                             v
RUN,TICK_EN,TARGET_TOTAL,RST,START_EDGE --> +-------------------+
                                             |  ELAPSED_COUNTER  |--> ELAPSED_TOTAL[8:0]
                                             +-------------------+
                                                        |
                                                        v
                                            +-------------------+
                                            |    BIN_TO_MMSS    |
                                            +-------------------+
                                              |      |      |
                                              v      v      v
                                            CUR_MIN SEC_T  SEC_U
                                               \      |      /
                                                \     |     /
                                                 +-----------+
                                                 | DISPLAY   |
                                                 |  7-SEG    |
                                                 +-----------+
```

---

## 3) Bloque por bloque (exacto para construir)

## A) `TARGET_MMSS`

**Función:**

`TARGET_TOTAL = T_MIN*60 + T_SEC_T*10 + T_SEC_U`

**Componentes Logisim:**
- 2 multiplicadores
- 2 sumadores
- salida de 9 bits

**Rango válido:** `0..300`.

---

## B) `SPEED_DIV`

**Función:** generar `TICK_EN` según velocidad.

- `SPEED=00` -> 1x
- `SPEED=01` -> 1.5x
- `SPEED=10` -> 2x

**Estructura:**
- contador `CNT_DIV`
- MUX para elegir `DIV_LIMIT`
- comparador `CNT_DIV == DIV_LIMIT`
- reset de `CNT_DIV` cuando hay match

**Fórmulas:**
- `LIMIT_1X = Fclk - 1`
- `LIMIT_1_5X = (2*Fclk)/3 - 1`
- `LIMIT_2X = Fclk/2 - 1`

---

## C) `CTRL_START_DONE`

**Función:** arrancar, mantener ejecución y detectar fin.

1. `START_EDGE = START AND NOT(START_D)` usando 1 FF D.
2. Si `START_EDGE=1` y `TARGET_TOTAL>0` y `<=300`:
   - `RUN=1`
   - `DONE=0`
3. Si `RUN=1` y `ELAPSED_TOTAL == TARGET_TOTAL`:
   - `RUN=0`
   - `DONE=1`
4. `DONE -> DONE_LED`

---

## D) `ELAPSED_COUNTER`

**Función:** cuenta de 0 hasta `TARGET_TOTAL`.

- `INC_EN = RUN AND TICK_EN`
- si `RST=1` o `START_EDGE=1` -> `ELAPSED_TOTAL=0`
- si `INC_EN=1` y `ELAPSED_TOTAL < TARGET_TOTAL` -> `ELAPSED_TOTAL++`
- caso contrario mantiene valor

**Componentes:**
- registro/contador 9 bits
- sumador +1
- comparador `<`
- MUX de próximo estado

---

## E) `BIN_TO_MMSS`

- `CUR_MIN = ELAPSED_TOTAL / 60`
- `REM = ELAPSED_TOTAL mod 60`
- `CUR_SEC_T = REM / 10`
- `CUR_SEC_U = REM mod 10`

Si no tienes división/mod directo: usa 3 contadores BCD encadenados.

---

## F) `DISPLAY_7SEG`

- 3 decodificadores BCD->7 segmentos:
  - minutos
  - decenas de segundo
  - unidades de segundo

Velocidad visible opcional:
- 2 LEDs conectados a `SPEED[1:0]`.

---

## 4) Checklist final (para que "se vea mejor")

- [ ] El circuito solo tiene esos 6 bloques + LED final.
- [ ] No hay bloques extra que no uses.
- [ ] Señales con nombre claro (`TARGET_TOTAL`, `ELAPSED_TOTAL`, `RUN`, `TICK_EN`).
- [ ] Displays muestran `M:SS`.
- [ ] `DONE_LED` enciende justo al llegar al objetivo.
- [ ] Cambiar `SPEED` altera la rapidez real del conteo.

---

## 5) Prueba rápida para demo

1. Pon objetivo `00:20`.
2. Ejecuta en `1x` y verifica llegada a `00:20`.
3. Repite en `1.5x` y `2x` (debe terminar antes en tiempo real).
4. Verifica que `DONE_LED=1` al final.

