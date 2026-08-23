library ieee;
use ieee.std_logic_1164.all;

-- Direct tests of the simon_game FSM (no top_level wrapper):
--   1. reset path: holding reset rotates the LFSR seed (regression for a
--      dead-branch bug where the zero-seed guard could never fire)
--   2. a full max-length run wins every round and returns to idle
-- Playing buttons straight into p_btn skips the debouncers entirely,
-- so this bench also proves the FSM core independent of input timing.
entity simon_game_tb is
end entity simon_game_tb;

architecture tb_arch of simon_game_tb is
  constant clk_period : time := 8 ns;
  constant hold_clks  : integer := 12;
  constant step_ticks : integer := 20;
  constant max_len    : integer := 2; -- must match the generic below

  constant SEG_1     : std_logic_vector(7 downto 0) := "00000110";
  constant SEG_2     : std_logic_vector(7 downto 0) := "01011011";
  constant SEG_3     : std_logic_vector(7 downto 0) := "01001111";
  constant SEG_4     : std_logic_vector(7 downto 0) := "01100110";
  constant SEG_WIN   : std_logic_vector(7 downto 0) := "01010100";
  constant SEG_IN    : std_logic_vector(7 downto 0) := "11111111";
  constant SEG_BLANK : std_logic_vector(7 downto 0) := "00000000";

  signal clk       : std_logic := '0';
  signal p_btn     : std_logic_vector(3 downto 0) := (others => '0');
  signal start_btn : std_logic := '0';
  signal rst_btn   : std_logic := '0';
  signal dispSeg   : std_logic_vector(7 downto 0);
  signal done      : boolean := false;

  type seq_t is array (0 to 15) of integer;
begin
  clk <= not clk after clk_period / 2 when not done else '0';

  dut : entity work.simon_game
    generic map
    (
      clk_freq       => step_ticks,
      debounce_ticks => 2,
      max_pattern    => max_len
    )
    port map
    (
      clk       => clk,
      p_btn     => p_btn,
      start_btn => start_btn,
      rst_btn   => rst_btn,
      dispSeg   => dispSeg
    );

  stimulus : process
    variable seq : seq_t;

    procedure wait_clks(count : natural) is
    begin
      for i in 1 to count loop
        wait until rising_edge(clk);
      end loop;
    end procedure;

    procedure press(idx : integer) is
    begin
      p_btn      <= (others => '0');
      p_btn(idx) <= '1';
      wait_clks(hold_clks);
      p_btn <= (others => '0');
      wait_clks(4);
    end procedure;

    -- Like press, but keeps the button held until the DUT shows `expected`.
    -- The event-driven wait catches short-lived segments (the win flash is
    -- only clk_freq/4 ticks here) that an edge-polling loop could miss.
    procedure press_until(idx : integer; expected : std_logic_vector(7 downto 0); msg : string) is
    begin
      p_btn      <= (others => '0');
      p_btn(idx) <= '1';
      wait until dispSeg = expected for 2 us;
      assert dispSeg = expected report msg severity failure;
      p_btn <= (others => '0');
      wait_clks(4);
    end procedure;

    function is_digit(seg : std_logic_vector(7 downto 0)) return boolean is
    begin
      return seg = SEG_1 or seg = SEG_2 or seg = SEG_3 or seg = SEG_4;
    end function;

    function digit_idx(seg : std_logic_vector(7 downto 0)) return integer is
    begin
      if seg = SEG_1 then
        return 0;
      elsif seg = SEG_2 then
        return 1;
      elsif seg = SEG_3 then
        return 2;
      else
        return 3;
      end if;
    end function;

    procedure wait_for(seg : std_logic_vector(7 downto 0); msg : string) is
      variable guard : integer := 0;
    begin
      while dispSeg /= seg loop
        wait until rising_edge(clk);
        guard := guard + 1;
        assert guard < 600 report msg severity failure;
      end loop;
    end procedure;

    -- Record the next `count` digits as the DUT plays its hint sequence.
    procedure collect_digits(variable captured : out seq_t; count : integer) is
      variable guard : integer;
    begin
      captured := (others => 0);
      for r in 0 to count - 1 loop
        guard := 0;
        while not is_digit(dispSeg) loop
          wait until rising_edge(clk);
          guard := guard + 1;
          assert guard < 600 report "timeout waiting for hint digit" severity failure;
        end loop;
        captured(r) := digit_idx(dispSeg);
        guard       := 0;
        while is_digit(dispSeg) loop
          wait until rising_edge(clk);
          guard := guard + 1;
          assert guard < 300 report "hint digit stuck on display" severity failure;
        end loop;
      end loop;
      -- Wait for the input prompt: the FSM is still in its display state
      -- for a few clocks after the last hint digit clears, and a press
      -- during that window would be dropped.
      wait_for(SEG_IN, "did not reach input prompt");
    end procedure;
  begin
    -- 1. Reset path: stay in reset longer than one full LFSR period
    --    (period 51 here) so the seed must rotate under our feet.
    rst_btn <= '1';
    wait_clks(60);
    assert dispSeg = SEG_BLANK report "reset must blank the display" severity failure;
    rst_btn <= '0';
    wait_clks(8);

    -- 2. Full max-length game: echo every hint correctly, round by round.
    start_btn <= '1';
    wait_clks(hold_clks);
    start_btn <= '0';

    for round in 1 to max_len loop
      collect_digits(seq, round);
      for i in 0 to round - 2 loop
        press(seq(i));
      end loop;
      -- Last echo of the round: hold until the win flash appears.
      press_until(seq(round - 1), SEG_WIN, "correct echo must win the round");
    end loop;

    -- 3. Beating the longest game returns to idle (display goes dark).
    wait_for(SEG_BLANK, "finished game must return to idle");

    report "simon_game_tb passed" severity note;
    done <= true;
    wait;
  end process;
end architecture;
