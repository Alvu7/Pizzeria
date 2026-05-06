library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Converts total seconds (0..300) to MM:SS digits.
entity time_decode is
  port (
    total_s : in  unsigned(8 downto 0);
    min_d   : out unsigned(2 downto 0);
    sec_t   : out unsigned(2 downto 0);
    sec_u   : out unsigned(3 downto 0)
  );
end entity;

architecture rtl of time_decode is
  signal mins  : unsigned(2 downto 0);
  signal rem_s : unsigned(5 downto 0);
begin
  mins  <= resize(total_s / 60, 3);
  rem_s <= resize(total_s mod 60, 6);

  min_d <= mins;
  sec_t <= resize(rem_s / 10, 3);
  sec_u <= resize(rem_s mod 10, 4);
end architecture;
