library ieee;
use ieee.std_logic_1164.all;

-- Two-flop synchronizer, then edge-detect the settled sample.
entity pulse_detector is
  port
  (
    clk         : in std_logic;
    rst         : in std_logic;
    in_pulse    : in std_logic;
    detect_type : in std_logic_vector(1 downto 0); -- 00 rise, 01 fall, 10 either
    out_pulse   : out std_logic
  );
end entity pulse_detector;

architecture rtl of pulse_detector is
  signal sync0 : std_logic := '0';
  signal sync1 : std_logic := '0';
  signal prev  : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sync0 <= '0';
        sync1 <= '0';
        prev  <= '0';
      else
        sync0 <= in_pulse;
        sync1 <= sync0;
        prev  <= sync1;
      end if;
    end if;
  end process;

  with detect_type select
    out_pulse <=
      (not prev and sync1) when "00",
      (prev and not sync1) when "01",
      (prev xor sync1) when "10",
      '0' when others;
end architecture;
