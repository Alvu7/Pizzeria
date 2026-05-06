library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generic 7-segment decoder (active-low outputs: abcdefg)
entity seven_seg_decoder is
  port (
    bin : in  unsigned(3 downto 0);
    seg : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of seven_seg_decoder is
begin
  process(bin)
  begin
    case to_integer(bin) is
      when 0 => seg <= "0000001";
      when 1 => seg <= "1001111";
      when 2 => seg <= "0010010";
      when 3 => seg <= "0000110";
      when 4 => seg <= "1001100";
      when 5 => seg <= "0100100";
      when 6 => seg <= "0100000";
      when 7 => seg <= "0001111";
      when 8 => seg <= "0000000";
      when 9 => seg <= "0000100";
      when others => seg <= "1111110"; -- '-'
    end case;
  end process;
end architecture;
