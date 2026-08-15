library ieee;
use ieee.std_logic_1164.all;

entity debounce_tb is
end debounce_tb;

architecture testbench of debounce_tb is
  constant clk_period : time := 8 ns;
  constant ticks      : integer := 4;

  signal tb_clk  : std_logic := '0';
  signal tb_btn  : std_logic := '0';
  signal tb_dbnc : std_logic;
  signal done    : boolean := false;
begin
  tb_clk <= not tb_clk after clk_period / 2 when not done else '0';

  uut : entity work.debounce
    generic map (stable_ticks => ticks)
    port map (clk => tb_clk, btn => tb_btn, dbnc => tb_dbnc);

  stim : process
  begin
    wait until rising_edge(tb_clk);
    tb_btn <= '1';
    for i in 1 to 3 loop
      wait until rising_edge(tb_clk);
    end loop;
    tb_btn <= '0';
    wait until rising_edge(tb_clk);
    wait until rising_edge(tb_clk);
    assert tb_dbnc = '0'
      report "short bounce must not set dbnc" severity failure;

    tb_btn <= '1';
    for i in 1 to ticks + 6 loop
      wait until rising_edge(tb_clk);
    end loop;
    assert tb_dbnc = '1'
      report "stable high must set dbnc" severity failure;

    tb_btn <= '0';
    for i in 1 to 4 loop
      wait until rising_edge(tb_clk);
    end loop;
    assert tb_dbnc = '0'
      report "release must clear dbnc" severity failure;

    report "debounce_tb passed" severity note;
    done <= true;
    wait;
  end process;
end testbench;
