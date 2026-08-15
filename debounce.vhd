library ieee;
use ieee.std_logic_1164.all;

entity debounce is
  generic
  (
    stable_ticks : integer := 2500000 -- 20 ms at 125 MHz
  );
  port
  (
    clk  : in std_logic;
    btn  : in std_logic;
    dbnc : out std_logic
  );
end debounce;

architecture behavioral of debounce is
  constant ticks : integer := stable_ticks;

  signal sync0  : std_logic := '0';
  signal sync1  : std_logic := '0';
  signal count  : integer range 0 to ticks := 0;
  signal dbnc_r : std_logic := '0';
begin
  dbnc <= dbnc_r;

  process (clk)
  begin
    if rising_edge(clk) then
      sync0 <= btn;
      sync1 <= sync0;

      if sync1 = '1' then
        if count < ticks then
          count <= count + 1;
        else
          dbnc_r <= '1';
        end if;
      else
        count  <= 0;
        dbnc_r <= '0';
      end if;
    end if;
  end process;
end behavioral;
