library ieee;
use ieee.std_logic_1164.all;

entity top_level_tb is
end entity top_level_tb;

architecture tb_arch of top_level_tb is
  constant clk_period : time := 8 ns;
  constant hold_clks  : integer := 12;
  constant step_ticks : integer := 20;

  constant SEG_1     : std_logic_vector(7 downto 0) := "00000110";
  constant SEG_2     : std_logic_vector(7 downto 0) := "01011011";
  constant SEG_3     : std_logic_vector(7 downto 0) := "01001111";
  constant SEG_4     : std_logic_vector(7 downto 0) := "01100110";
  constant SEG_IN    : std_logic_vector(7 downto 0) := "11111111";
  constant SEG_WIN   : std_logic_vector(7 downto 0) := "01010100";
  constant SEG_LOSE  : std_logic_vector(7 downto 0) := "00111000";
  constant SEG_BLANK : std_logic_vector(7 downto 0) := "00000000";

  signal clk        : std_logic := '0';
  signal tb_btn     : std_logic_vector(3 downto 0) := "0000";
  signal start_sig  : std_logic := '0';
  signal rst_sig    : std_logic := '0';
  signal dispSeg_tb : std_logic_vector(7 downto 0) := (others => '0');
  signal done       : boolean := false;

  type seq_t is array (0 to 15) of integer;
begin
  clk <= not clk after clk_period / 2 when not done else '0';

  dut : entity work.top_level
    generic map
    (
      clk_freq       => step_ticks,
      debounce_ticks => 2,
      max_pattern    => 2
    )
    port map
    (
      clk       => clk,
      p_btn     => tb_btn,
      start_btn => start_sig,
      rst_btn   => rst_sig,
      dispSeg   => dispSeg_tb
    );

  stimulus : process
    variable seq : seq_t := (others => 0);
    variable n   : integer;
    variable btn : integer;

    procedure wait_clks(count : natural) is
    begin
      for i in 1 to count loop
        wait until rising_edge(clk);
      end loop;
    end procedure;

    procedure press(idx : integer) is
    begin
      tb_btn      <= (others => '0');
      tb_btn(idx) <= '1';
      wait_clks(hold_clks);
      tb_btn <= (others => '0');
      wait_clks(4);
    end procedure;

    procedure press_until(idx : integer; expected : std_logic_vector(7 downto 0); msg : string) is
    begin
      tb_btn      <= (others => '0');
      tb_btn(idx) <= '1';
      wait until dispSeg_tb = expected for 2 us;
      assert dispSeg_tb = expected report msg severity failure;
      tb_btn <= (others => '0');
      wait_clks(4);
    end procedure;

    procedure pulse_start is
    begin
      start_sig <= '1';
      wait_clks(hold_clks);
      start_sig <= '0';
    end procedure;

    function is_digit(seg : std_logic_vector(7 downto 0)) return boolean is
    begin
      return seg = SEG_1 or seg = SEG_2 or seg = SEG_3 or seg = SEG_4;
    end function;

    function digit_btn(seg : std_logic_vector(7 downto 0)) return integer is
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

    procedure collect_sequence(variable captured : out seq_t; variable length : out integer) is
      variable local : seq_t := (others => 0);
      variable len   : integer := 0;
      variable guard : integer := 0;
    begin
      while dispSeg_tb /= SEG_IN and guard < 800 loop
        if is_digit(dispSeg_tb) then
          local(len) := digit_btn(dispSeg_tb);
          len        := len + 1;
          while is_digit(dispSeg_tb) loop
            wait until rising_edge(clk);
            guard := guard + 1;
          end loop;
        else
          wait until rising_edge(clk);
          guard := guard + 1;
        end if;
      end loop;
      assert dispSeg_tb = SEG_IN report "did not reach input prompt" severity failure;
      captured := local;
      length   := len;
    end procedure;
  begin
    wait_clks(4);
    pulse_start;
    collect_sequence(seq, n);
    assert n = 1 report "first round must show one step" severity failure;
    press_until(seq(0), SEG_WIN, "correct reply must win");

    collect_sequence(seq, n);
    assert n = 2 report "second round must replay two steps" severity failure;
    press(seq(0));
    press_until(seq(1), SEG_WIN, "max-length prefix compare must still win");

    wait until dispSeg_tb = SEG_BLANK for 2 us;
    wait_clks(step_ticks + 4);
    pulse_start;
    collect_sequence(seq, n);
    btn := (seq(0) + 1) mod 4;
    press_until(btn, SEG_LOSE, "wrong button must lose");

    report "top_level_tb passed" severity note;
    done <= true;
    wait;
  end process;
end architecture;
