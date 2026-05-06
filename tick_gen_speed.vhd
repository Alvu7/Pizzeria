library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Tick generator with selectable playback speed.
entity tick_gen_speed is
  generic (
    CLK_HZ : positive := 50_000_000
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    en        : in  std_logic;
    speed_sel : in  std_logic_vector(1 downto 0); -- 00=1x, 01=1.5x, 10=2x
    tick      : out std_logic
  );
end entity;

architecture rtl of tick_gen_speed is
  signal div_limit : unsigned(31 downto 0);
  signal cnt       : unsigned(31 downto 0);
begin
  -- Combinational divisor selection.
  process(speed_sel)
  begin
    case speed_sel is
      when "00" => div_limit <= to_unsigned(CLK_HZ - 1, 32);           -- 1.0 s
      when "01" => div_limit <= to_unsigned((2 * CLK_HZ) / 3 - 1, 32); -- 0.666.. s
      when "10" => div_limit <= to_unsigned(CLK_HZ / 2 - 1, 32);       -- 0.5 s
      when others => div_limit <= to_unsigned(CLK_HZ - 1, 32);
    end case;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt  <= (others => '0');
        tick <= '0';
      else
        tick <= '0';
        if en = '1' then
          if cnt = div_limit then
            cnt  <= (others => '0');
            tick <= '1';
          else
            cnt <= cnt + 1;
          end if;
        else
          cnt <= (others => '0');
        end if;
      end if;
    end if;
  end process;
end architecture;
