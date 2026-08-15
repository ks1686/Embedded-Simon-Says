library ieee;
use ieee.std_logic_1164.all;

entity random_generator_tb is
end random_generator_tb;

architecture rtl of random_generator_tb is
  constant clk_period : time := 8 ns;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal seed     : std_logic_vector(7 downto 0) := "10101010";
  signal rand_out : std_logic_vector(3 downto 0);
  signal done     : boolean := false;
begin
  clk <= not clk after clk_period / 2 when not done else '0';

  uut : entity work.random_generator
    generic map (input_width => 8, output_width => 4)
    port map (clk => clk, rst => rst, seed => seed, rand_out => rand_out);

  stim : process
    variable seen : std_logic_vector(3 downto 0) := (others => '0');
  begin
    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';

    for i in 1 to 64 loop
      wait until rising_edge(clk);
      assert rand_out = "0001" or rand_out = "0010" or rand_out = "0100" or rand_out = "1000"
        report "rand_out must be one-hot" severity failure;
      if rand_out = "0001" then
        seen(0) := '1';
      elsif rand_out = "0010" then
        seen(1) := '1';
      elsif rand_out = "0100" then
        seen(2) := '1';
      else
        seen(3) := '1';
      end if;
    end loop;

    assert seen = "1111" report "all four colors must appear" severity failure;

    report "random_generator_tb passed" severity note;
    done <= true;
    wait;
  end process;
end architecture;
