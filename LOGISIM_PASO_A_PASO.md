# Circuito en Logisim (parte por parte)

> Objetivo: construir en Logisim un reproductor de nota de voz que cuente de `00:00` al tiempo configurado (máx `05:00`) con velocidades `1x`, `1.5x`, `2x`, y LED de fin.

---

## 0) Convención de señales

- `CLK`: reloj base (el de Logisim).
- `RST`: reset general.
- `START`: inicia reproducción.
- `SPEED[1:0]`: `00=1x`, `01=1.5x`, `10=2x`.
- Entradas tiempo objetivo:
  - `T_MIN[2:0]` (0..5)
  - `T_SEC_T[2:0]` (0..5)
  - `T_SEC_U[3:0]` (0..9)
- Salidas:
  - `CUR_MIN[2:0]`, `CUR_SEC_T[2:0]`, `CUR_SEC_U[3:0]`
  - `DONE_LED`

---

## 1) Subcircuito A: `TARGET_MMSS` (armado del tiempo objetivo)

### Qué hace
Convierte `T_MIN:T_SEC_T:T_SEC_U` en segundos totales (0..300):

`TARGET_TOTAL = T_MIN*60 + T_SEC_T*10 + T_SEC_U`

### Cómo armarlo en Logisim
1. Crea subcircuito `TARGET_MMSS`.
2. Coloca:
   - 2 multiplicadores (`Arithmetic -> Multiplier`):
     - `T_MIN * 60`
     - `T_SEC_T * 10`
   - 2 sumadores (`Arithmetic -> Adder`) en cascada.
3. Ajusta anchos:
   - Salida final de **9 bits**.
4. Salida del bloque: `TARGET_TOTAL[8:0]`.

---

## 2) Subcircuito B: `SPEED_DIV` (divisor por velocidad)

### Qué hace
Genera un pulso `TICK_EN` según velocidad:
- 1x -> 1 pulso/segundo
- 1.5x -> 1 pulso cada 2/3 s
- 2x -> 1 pulso cada 1/2 s

### Cómo armarlo en Logisim
1. Crea `SPEED_DIV`.
2. Componentes:
   - 1 contador grande `CNT_DIV` (N bits, según reloj).
   - 1 comparador igualdad `CNT_DIV == DIV_LIMIT`.
   - 1 multiplexor 4:1 para escoger `DIV_LIMIT` por `SPEED`.
   - 3 constantes:
     - `LIMIT_1X`
     - `LIMIT_1_5X`
     - `LIMIT_2X`
3. Lógica:
   - Si `CNT_DIV == DIV_LIMIT`, entonces:
     - `TICK_EN = 1` durante 1 ciclo
     - `CNT_DIV = 0`
   - En otro caso `CNT_DIV++` y `TICK_EN=0`.
4. Fórmulas de límites (si `Fclk` Hz):
   - `LIMIT_1X = Fclk - 1`
   - `LIMIT_1_5X = (2*Fclk)/3 - 1`
   - `LIMIT_2X = Fclk/2 - 1`

> En Logisim de clase, puedes bajar `Fclk` para no usar contadores enormes (por ejemplo con otro divisor previo).

---

## 3) Subcircuito C: `CTRL_START_DONE` (control de ejecución)

### Qué hace
Controla cuándo corre el conteo y cuándo termina.

### Señales internas
- `RUN` (latch/FF D): habilita conteo.
- `DONE` (latch/FF D): enciende LED al final.
- `START_EDGE`: detector de flanco de `START`.

### Cómo armarlo
1. Detector de flanco:
   - 1 FF D para `START_D`.
   - `START_EDGE = START AND (NOT START_D)`.
2. Lógica de arranque:
   - Si `START_EDGE=1` y `TARGET_TOTAL>0` y `TARGET_TOTAL<=300`:
     - `RUN=1`, `DONE=0`.
3. Lógica de fin:
   - Si `ELAPSED_TOTAL == TARGET_TOTAL` y `RUN=1`:
     - `RUN=0`, `DONE=1`.
4. `DONE` -> `DONE_LED`.

---

## 4) Subcircuito D: `ELAPSED_COUNTER` (contador principal)

### Qué hace
Cuenta segundos reproducidos (`0..TARGET_TOTAL`) usando `TICK_EN`.

### Cómo armarlo
1. Crea contador de 9 bits `ELAPSED_TOTAL`.
2. Habilitación de suma:
   - `INC_EN = RUN AND TICK_EN`.
3. Siguiente estado:
   - Si `RST=1` o `START_EDGE=1` => `ELAPSED_TOTAL=0`.
   - Si `INC_EN=1` y `ELAPSED_TOTAL < TARGET_TOTAL` => `ELAPSED_TOTAL++`.
   - Si no, mantiene valor.

---

## 5) Subcircuito E: `BIN_TO_MMSS` (decodificación a minutos y segundos)

### Qué hace
Convierte `ELAPSED_TOTAL` a:
- `CUR_MIN = ELAPSED_TOTAL / 60`
- `REM = ELAPSED_TOTAL mod 60`
- `CUR_SEC_T = REM / 10`
- `CUR_SEC_U = REM mod 10`

### En Logisim
- Opción A (directa): usar divisores/módulo si tu versión lo permite.
- Opción B (más didáctica): manejar 3 contadores BCD encadenados (Useg, Dseg, Min), incrementados por `TICK_EN`.

---

## 6) Subcircuito F: `DISPLAY`

### Qué hace
Muestra `M:SS` y velocidad.

### Armado
1. Usa 3 decodificadores BCD->7 segmentos:
   - `CUR_MIN`
   - `CUR_SEC_T`
   - `CUR_SEC_U`
2. Velocidad actual:
   - 2 LEDs para `SPEED[1:0]`, o
   - 1 display extra con lógica combinacional para “1”, “1.5”, “2”.

---

## 7) Integración final (Top)

Conecta en este orden:
1. `TARGET_MMSS` -> `TARGET_TOTAL`
2. `SPEED_DIV` -> `TICK_EN`
3. `CTRL_START_DONE` recibe `START`, `TARGET_TOTAL`, `ELAPSED_TOTAL`
4. `ELAPSED_COUNTER` recibe `RUN`, `TICK_EN`, `TARGET_TOTAL`, `RST`, `START_EDGE`
5. `BIN_TO_MMSS` recibe `ELAPSED_TOTAL`
6. `DISPLAY` recibe `CUR_MIN`, `CUR_SEC_T`, `CUR_SEC_U`, `SPEED`
7. `DONE` a LED

---

## 8) Prueba paso a paso en Logisim

1. Configura `T_MIN=0`, `T_SEC_T=2`, `T_SEC_U=0` (00:20).
2. `SPEED=00` (1x), pulsa `START`.
3. Verifica que sube 00:00, 00:01, ... hasta 00:20.
4. Comprueba que `DONE_LED` enciende al llegar.
5. Repite con `SPEED=01` y `SPEED=10`, debe terminar antes en tiempo real.

---

## 9) Mapa rápido de bloques que ya tienes en VHDL

- `TARGET_MMSS` + control top -> `voice_note_player.vhd`
- `SPEED_DIV` -> `tick_gen_speed.vhd`
- `ELAPSED_COUNTER` -> `elapsed_counter.vhd`
- `BIN_TO_MMSS` -> `time_decode.vhd`
- `DISPLAY` -> `seven_seg_decoder.vhd`

