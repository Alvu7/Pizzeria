library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Counts elapsed seconds from 0 to target.
entity elapsed_counter is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en_tick : in  std_logic;
    run     : in  std_logic;
    target  : in  unsigned(8 downto 0);
    clr     : in  std_logic;
    elapsed : out unsigned(8 downto 0)
  );
end entity;

architecture rtl of elapsed_counter is
  signal elapsed_r : unsigned(8 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        elapsed_r <= (others => '0');
      else
        if clr = '1' then
          elapsed_r <= (others => '0');
        elsif run = '1' and en_tick = '1' then
          if elapsed_r < target then
            elapsed_r <= elapsed_r + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  elapsed <= elapsed_r;
end architecture;
