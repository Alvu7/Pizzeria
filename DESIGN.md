# Simulador digital de reproducción de nota de voz (VHDL)

## 1) Diseño modular

El sistema se divide en bloques secuenciales y combinacionales básicos, sin RAM/ROM:

1. **`voice_note_player` (top-level)**
   - Integra todos los módulos.
   - Recibe duración configurada (`set_min`, `set_sec_t`, `set_sec_u`) con rango hasta **5:00**.
   - Gestiona señal `start`, estado de ejecución (`run`) y fin (`done_led`).

2. **`tick_gen_speed` (divisor/frecuencia variable)**
   - Genera un pulso `tick` periódicamente según velocidad:
     - 1x -> 1 tick cada 1.0 s
     - 1.5x -> 1 tick cada 2/3 s
     - 2x -> 1 tick cada 0.5 s
   - Implementado con contador + comparador (lógica secuencial/combinacional).

3. **`elapsed_counter` (contador de tiempo transcurrido)**
   - Cuenta segundos transcurridos desde 0 hasta `target`.
   - Incrementa sólo cuando `run='1'` y llega `en_tick='1'`.

4. **`time_decode` (conversión a MM:SS)**
   - Convierte segundos totales en dígitos:
     - minutos
     - decenas de segundo
     - unidades de segundo

5. **`seven_seg_decoder` (visualización)**
   - Decodifica BCD/binario a 7 segmentos para cada dígito.
   - Permite mostrar cronómetro y también la velocidad mediante indicadores externos.

---

## 2) Diagrama de bloques

```text
             +-------------------------------+
start ------>|                               |
set_min ---->|                               |
set_sec_t -->|       voice_note_player       |---- done_led
set_sec_u -->|           (Control)           |
speed_sel -->|                               |---- cur_min
clk -------->|                               |---- cur_sec_t
rst_n ------>|                               |---- cur_sec_u
             +---------------+---------------+
                             |
                             | run, speed_sel
                             v
                    +------------------+
                    |  tick_gen_speed  |---- tick_en
                    +------------------+
                             |
                             v
                    +------------------+
                    | elapsed_counter  |---- elapsed_total_s
                    +------------------+
                             |
                             v
                    +------------------+
                    |   time_decode    |
                    +------------------+
                      |      |      |
                      v      v      v
                    min    sec_t   sec_u
                      \      |      /
                       \     |     /
                        +-----------+
                        |7seg decods|
                        +-----------+
```

---

## 3) Implementación de velocidades

En `tick_gen_speed` se usa un único reloj base `clk` y un divisor seleccionable:

- **1x (`speed_sel="00"`)**  
  `div_limit = CLK_HZ - 1`  
  -> un pulso por segundo.

- **1.5x (`speed_sel="01"`)**  
  `div_limit = (2*CLK_HZ)/3 - 1`  
  -> un pulso cada 0.666... s.  
  El contador “consume” 1 segundo de audio cada 2/3 de segundo real.

- **2x (`speed_sel="10"`)**  
  `div_limit = CLK_HZ/2 - 1`  
  -> un pulso cada 0.5 s.

Con eso, **no se altera el contenido del contador**, sólo la frecuencia de actualización.

---

## 4) Uso básico del sistema

1. Configurar tiempo objetivo (MM:SS) por entradas binarias.
2. Seleccionar velocidad (`speed_sel`).
3. Pulsar `start`.
4. El contador parte en 00:00 y avanza hasta el objetivo.
5. Al llegar al objetivo, `done_led = '1'`.

---

## 5) Sugerencias para Logisim

1. **Entradas**
   - Pulsadores/switches para `start`, `rst_n`, `speed_sel`, y tiempo configurado.

2. **Divisor de frecuencia**
   - Implementar un contador N bits + comparador (`== limit`) + reset del contador.
   - Usar multiplexor para elegir el `limit` según velocidad.

3. **Contador principal**
   - Contador de segundos de 9 bits (0..300).
   - Habilitación por `tick_en` AND `run`.

4. **Conversión MM:SS**
   - Si no se dispone de división directa en Logisim, usar contadores BCD encadenados:
     - unidades de segundo (0..9)
     - decenas de segundo (0..5)
     - minutos (0..5)

5. **Comparación fin**
   - Comparar contador actual con tiempo objetivo (en segundos o en BCD equivalente).
   - Cuando igualdad=1 -> apagar `run` y encender LED de fin.

6. **Visualización**
   - 3 displays de 7 segmentos para `M:SS`.
   - Para velocidad, usar:
     - 2 LEDs codificados (`00`,`01`,`10`) o
     - un display adicional con letras/símbolos simplificados.

