# Circuitos (Logisim) — vista por bloques y conexiones

## 1) Circuito TOP (interconexión general)

```text
                 +---------------------+
T_MIN ---------->|                     |
T_SEC_T -------->|     TARGET_MMSS     |---- TARGET_TOTAL[8:0]
T_SEC_U -------->|   (M*60 + T*10+U)   |
                 +---------------------+
                            |
                            v
CLK,RST,SPEED ----+  +------------------+
                  +->|    SPEED_DIV     |---- TICK_EN
START ------------+  | (1x/1.5x/2x)     |
                     +------------------+
                            |
                            v
                 +-----------------------+
START ---------->|                       |
TARGET_TOTAL --->|    CTRL_START_DONE    |---- RUN
ELAPSED_TOTAL -->| (START_EDGE, DONE)    |---- DONE_LED
RST ------------>|                       |
                 +-----------------------+
                            |
                            v
                 +-----------------------+
RUN ------------>|                       |
TICK_EN -------->|    ELAPSED_COUNTER    |---- ELAPSED_TOTAL[8:0]
TARGET_TOTAL --->|       (0..TARGET)     |
RST ------------>|                       |
START_EDGE ----->|                       |
                 +-----------------------+
                            |
                            v
                 +-----------------------+
ELAPSED_TOTAL -->|      BIN_TO_MMSS      |---- CUR_MIN[2:0]
                 |   (/60, mod60,/10)    |---- CUR_SEC_T[2:0]
                 +-----------------------+---- CUR_SEC_U[3:0]
                            |
                            v
                 +-----------------------+
CUR_MIN -------->|                       |---- SEG_MIN[6:0]
CUR_SEC_T ------>|      DISPLAY_7SEG     |---- SEG_SEC_T[6:0]
CUR_SEC_U ------>|                       |---- SEG_SEC_U[6:0]
                 +-----------------------+
```

---

## 2) Circuito `TARGET_MMSS`

```text
T_MIN[2:0] ----[* 60]----+
                          +----[ + ]----+
T_SEC_T[2:0] --[* 10]----+              +----[ + ]---- TARGET_TOTAL[8:0]
                                         |
T_SEC_U[3:0] ----------------------------+
```

- Componentes: 2 multiplicadores, 2 sumadores.
- Salida de 9 bits (0..300).

---

## 3) Circuito `SPEED_DIV`

```text
SPEED[1:0] ---> [MUX 4:1] ---> DIV_LIMIT -------------------+
                /    |    \                                 |
         LIMIT_1X LIMIT_1_5X LIMIT_2X                      |
                                                            v
CLK ---> [COUNTER CNT_DIV] ---> [CMP == DIV_LIMIT] ---> TICK_EN (pulso 1 ciclo)
                  ^                         |
                  |                         +---- reset CNT_DIV a 0
                  +---- incremento normal (CNT_DIV + 1)
```

- `LIMIT_1X = Fclk - 1`
- `LIMIT_1_5X = (2*Fclk)/3 - 1`
- `LIMIT_2X = Fclk/2 - 1`

---

## 4) Circuito `CTRL_START_DONE`

```text
START ----+------------------------------+
          |                              v
          |                         +-----------+
          +---->[FF D: START_D]----| NOT       |
                                    +-----------+
START -----------------------------------AND----------> START_EDGE

START_EDGE + (TARGET_TOTAL>0) + (TARGET_TOTAL<=300) ----> SET RUN

(ELAPSED_TOTAL == TARGET_TOTAL) AND RUN -----------------> CLR RUN / SET DONE

DONE -----------------------------------------------> DONE_LED
```

- Usa compuertas AND/NOT, comparadores y FF D.

---

## 5) Circuito `ELAPSED_COUNTER`

```text
INC_EN = RUN AND TICK_EN

if RST=1 or START_EDGE=1  => ELAPSED_TOTAL = 0
else if INC_EN=1 and ELAPSED_TOTAL < TARGET_TOTAL => ELAPSED_TOTAL + 1
else hold
```

Implementación en Logisim:
- 1 contador/registro de 9 bits para `ELAPSED_TOTAL`.
- 1 sumador `+1`.
- 1 comparador `< TARGET_TOTAL`.
- 1 MUX para seleccionar `0`, `ELAPSED+1` o `ELAPSED`.

---

## 6) Circuito `BIN_TO_MMSS`

```text
ELAPSED_TOTAL ----[/60]----> CUR_MIN
ELAPSED_TOTAL ----[mod60]--> REM
REM --------------[/10]----> CUR_SEC_T
REM --------------[mod10]--> CUR_SEC_U
```

Si no tienes división/mod directo en Logisim:
- alternativa con contadores BCD encadenados (Useg, Dseg, Min).

---

## 7) Circuito `DISPLAY_7SEG`

```text
CUR_MIN   ---> [BCD->7SEG] ---> SEG_MIN
CUR_SEC_T ---> [BCD->7SEG] ---> SEG_SEC_T
CUR_SEC_U ---> [BCD->7SEG] ---> SEG_SEC_U
```

Velocidad (opcional visual):
- 2 LEDs conectados a `SPEED[1:0]`.

