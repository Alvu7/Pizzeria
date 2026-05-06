library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ================================================================
-- Top-level: voice note player simulator
-- Counts from 00:00 up to configured target time (max 05:00)
-- Playback speed selectable: 1x, 1.5x, 2x
-- ================================================================
entity voice_note_player is
  generic (
    CLK_HZ : positive := 50_000_000
  );
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;                         -- active-low reset
    start       : in  std_logic;                         -- pulse or level to start
    speed_sel   : in  std_logic_vector(1 downto 0);      -- 00=1x, 01=1.5x, 10=2x
    set_min     : in  unsigned(2 downto 0);              -- 0..5
    set_sec_t   : in  unsigned(2 downto 0);              -- tens of seconds 0..5
    set_sec_u   : in  unsigned(3 downto 0);              -- units of seconds 0..9

    -- Visual outputs (for 7-seg decoders)
    cur_min     : out unsigned(2 downto 0);
    cur_sec_t   : out unsigned(2 downto 0);
    cur_sec_u   : out unsigned(3 downto 0);
    speed_code  : out std_logic_vector(1 downto 0);

    -- Optional raw total-seconds output (debug/monitor)
    cur_total_s : out unsigned(8 downto 0);
    tgt_total_s : out unsigned(8 downto 0);

    done_led    : out std_logic
  );
end entity;

architecture rtl of voice_note_player is
  signal rst                : std_logic;
  signal tick_en            : std_logic;
  signal run                : std_logic;
  signal done               : std_logic;

  signal target_total       : unsigned(8 downto 0);
  signal elapsed_total      : unsigned(8 downto 0);

  signal s_min              : unsigned(2 downto 0);
  signal s_sec_t            : unsigned(2 downto 0);
  signal s_sec_u            : unsigned(3 downto 0);

  signal start_d            : std_logic;
  signal start_rise         : std_logic;
  signal clr_counter        : std_logic;

begin
  rst <= not rst_n;

  ------------------------------------------------------------------
  -- Edge detector for START (simple synchronizer-style register)
  ------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        start_d <= '0';
      else
        start_d <= start;
      end if;
    end if;
  end process;

  start_rise <= start and (not start_d);

  ------------------------------------------------------------------
  -- Convert configured BCD-like inputs to total seconds
  -- target_total = minutes*60 + tens*10 + units
  ------------------------------------------------------------------
  target_total <= (set_min * 60) + (set_sec_t * 10) + resize(set_sec_u, 9);

  ------------------------------------------------------------------
  -- Playback control FSM (implicit 2-state via run/done flags)
  ------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        run <= '0';
        done <= '0';
      else
        if start_rise = '1' then
          -- Start only when target is valid and > 0
          if (target_total > 0) and (target_total <= 300) then
            run  <= '1';
            done <= '0';
          end if;
        elsif done = '1' then
          -- Hold done until new start
          run <= '0';
        end if;

        -- Stop when counter reaches target
        if elapsed_total = target_total and run = '1' then
          run  <= '0';
          done <= '1';
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- Speed-controlled tick generator
  -- 1x  : 1 tick every 1 s
  -- 1.5x: 1 tick every 2/3 s  (counter advances 1 sec faster)
  -- 2x  : 1 tick every 1/2 s
  ------------------------------------------------------------------
  u_tick_gen : entity work.tick_gen_speed
    generic map (
      CLK_HZ => CLK_HZ
    )
    port map (
      clk       => clk,
      rst       => rst,
      en        => run,
      speed_sel => speed_sel,
      tick      => tick_en
    );

  ------------------------------------------------------------------
  -- Elapsed-time counter in seconds
  ------------------------------------------------------------------
  clr_counter <= start_rise;

  u_elapsed_counter : entity work.elapsed_counter
    port map (
      clk         => clk,
      rst         => rst,
      en_tick     => tick_en,
      run         => run,
      target      => target_total,
      clr         => clr_counter,
      elapsed     => elapsed_total
    );

  ------------------------------------------------------------------
  -- Binary seconds -> MM:SS digits
  ------------------------------------------------------------------
  u_time_decode : entity work.time_decode
    port map (
      total_s => elapsed_total,
      min_d   => s_min,
      sec_t   => s_sec_t,
      sec_u   => s_sec_u
    );

  -- Outputs
  cur_min     <= s_min;
  cur_sec_t   <= s_sec_t;
  cur_sec_u   <= s_sec_u;
  speed_code  <= speed_sel;
  cur_total_s <= elapsed_total;
  tgt_total_s <= target_total;
  done_led    <= done;

end architecture;
