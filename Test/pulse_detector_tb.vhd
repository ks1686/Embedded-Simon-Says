library ieee;
use ieee.std_logic_1164.all;

entity pulse_detector_tb is
end pulse_detector_tb;

architecture tb_arch of pulse_detector_tb is
  constant clk_period : time := 8 ns;

  signal clk, rst, in_pulse, out_pulse : std_logic := '0';
  signal detect_type                   : std_logic_vector(1 downto 0) := "00";
  signal done                          : boolean := false;
begin
  clk <= not clk after clk_period / 2 when not done else '0';

  uut : entity work.pulse_detector
    port map
    (
      clk         => clk,
      rst         => rst,
      in_pulse    => in_pulse,
      detect_type => detect_type,
      out_pulse   => out_pulse
    );

  stim : process
    variable seen : integer;
    procedure wait_clks(n : natural) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    rst <= '1';
    wait_clks(3);
    rst <= '0';
    wait_clks(3);
    assert out_pulse = '0' report "idle must be 0" severity failure;

    detect_type <= "00";
    in_pulse    <= '1';
    seen        := 0;
    for i in 1 to 8 loop
      wait until rising_edge(clk);
      if out_pulse = '1' then
        seen := seen + 1;
      end if;
    end loop;
    assert seen = 1 report "rising edge must pulse once" severity failure;

    detect_type <= "01";
    in_pulse    <= '0';
    seen        := 0;
    for i in 1 to 8 loop
      wait until rising_edge(clk);
      if out_pulse = '1' then
        seen := seen + 1;
      end if;
    end loop;
    assert seen = 1 report "falling edge must pulse once" severity failure;

    detect_type <= "10";
    in_pulse    <= '1';
    seen        := 0;
    for i in 1 to 6 loop
      wait until rising_edge(clk);
      if out_pulse = '1' then
        seen := seen + 1;
      end if;
    end loop;
    in_pulse <= '0';
    for i in 1 to 6 loop
      wait until rising_edge(clk);
      if out_pulse = '1' then
        seen := seen + 1;
      end if;
    end loop;
    assert seen = 2 report "either-edge must pulse on rise and fall" severity failure;

    report "pulse_detector_tb passed" severity note;
    done <= true;
    wait;
  end process;
end architecture;
