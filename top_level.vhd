library ieee;
use ieee.std_logic_1164.all;

entity top_level is
  generic
  (
    clk_freq       : integer := 125000000;
    debounce_ticks : integer := 2500000;
    max_pattern    : integer := 15
  );
  port
  (
    clk                : in std_logic;
    p_btn              : in std_logic_vector(3 downto 0);
    start_btn, rst_btn : in std_logic;
    dispSeg            : out std_logic_vector(7 downto 0)
  );
end entity top_level;

architecture rtl of top_level is
  component simon_game is
    generic
    (
      clk_freq       : integer := 125000000;
      debounce_ticks : integer := 2500000;
      max_pattern    : integer := 15
    );
    port
    (
      clk                : in std_logic;
      p_btn              : in std_logic_vector(3 downto 0);
      start_btn, rst_btn : in std_logic;
      dispSeg            : out std_logic_vector(7 downto 0)
    );
  end component simon_game;
begin
  simon_game_inst : simon_game
  generic map
  (
    clk_freq       => clk_freq,
    debounce_ticks => debounce_ticks,
    max_pattern    => max_pattern
  )
  port map
  (
    clk       => clk,
    p_btn     => p_btn,
    start_btn => start_btn,
    rst_btn   => rst_btn,
    dispSeg   => dispSeg
  );
end architecture;
