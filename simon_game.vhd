library ieee;
use ieee.std_logic_1164.all;

entity simon_game is
  generic
  (
    clk_freq       : integer := 125000000; -- ticks per display/win/lose second
    debounce_ticks : integer := 2500000; -- 20 ms at 125 MHz
    max_pattern    : integer := 15 -- sequence length cap
  );
  port
  (
    clk                : in std_logic;
    p_btn              : in std_logic_vector(3 downto 0);
    start_btn, rst_btn : in std_logic;
    dispSeg            : out std_logic_vector(7 downto 0)
  );
end entity simon_game;

architecture rtl of simon_game is
  constant data_bus : integer := 4;

  signal level       : integer range 0 to max_pattern := 0;
  signal gen_pattern : std_logic_vector(data_bus - 1 downto 0);
  signal seed        : std_logic_vector(7 downto 0) := "00000001";
  signal seed_shift  : std_logic := '0';

  signal rst         : std_logic := '0';
  signal p_dbnc      : std_logic_vector(3 downto 0);
  signal pulse       : std_logic_vector(3 downto 0);
  signal start_level : std_logic;
  signal start_pulse : std_logic;
  signal index       : integer range 0 to max_pattern := 0;
  signal disp_cntr   : integer range 0 to clk_freq := 0;
  signal disp_data   : std_logic_vector(3 downto 0) := (others => '0');

  type mem_type is array (0 to max_pattern - 1) of std_logic_vector(data_bus - 1 downto 0);
  signal game_reg : mem_type := (others => (others => '0'));
  signal user_reg : mem_type := (others => (others => '0'));

  type state_type is (idle, gen, display, input, check, win, lose);
  signal state : state_type := idle;

  function onehot_from_pulse(p : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    if p(0) = '1' then
      return "0001";
    elsif p(1) = '1' then
      return "0010";
    elsif p(2) = '1' then
      return "0100";
    else
      return "1000";
    end if;
  end function;

  component debounce is
    generic
    (
      stable_ticks : integer := 2500000
    );
    port
    (
      clk  : in std_logic;
      btn  : in std_logic;
      dbnc : out std_logic
    );
  end component debounce;

  component pulse_detector is
    port
    (
      clk         : in std_logic;
      rst         : in std_logic;
      in_pulse    : in std_logic;
      detect_type : in std_logic_vector(1 downto 0);
      out_pulse   : out std_logic
    );
  end component pulse_detector;

  component random_generator is
    generic
    (
      input_width  : integer := 8;
      output_width : integer := 4
    );
    port
    (
      clk, rst : in std_logic;
      seed     : in std_logic_vector(input_width - 1 downto 0);
      rand_out : out std_logic_vector(output_width - 1 downto 0)
    );
  end component random_generator;
begin
  dbnc_start_btn : debounce
  generic map (stable_ticks => debounce_ticks)
  port map (clk => clk, btn => start_btn, dbnc => start_level);

  dbnc_rst_btn : debounce
  generic map (stable_ticks => debounce_ticks)
  port map (clk => clk, btn => rst_btn, dbnc => rst);

  start_edge : pulse_detector
  port map (clk => clk, rst => rst, in_pulse => start_level, detect_type => "00", out_pulse => start_pulse);

  btn_path : for i in 0 to 3 generate
    dbnc_btn : debounce
    generic map (stable_ticks => debounce_ticks)
    port map (clk => clk, btn => p_btn(i), dbnc => p_dbnc(i));

    pulse_btn : pulse_detector
    port map (clk => clk, rst => rst, in_pulse => p_dbnc(i), detect_type => "00", out_pulse => pulse(i));
  end generate;

  random_gen : random_generator
  generic map (input_width => 8, output_width => data_bus)
  port map (clk => clk, rst => rst, seed => seed, rand_out => gen_pattern);

  -- Common-anode-style digits: 1/2/3/4, all-on for input, 'n' for win, 'L' for lose.
  process (disp_data)
  begin
    case disp_data is
      when "0001" => dispSeg <= "00000110"; -- 1
      when "0010" => dispSeg <= "01011011"; -- 2
      when "0100" => dispSeg <= "01001111"; -- 3
      when "1000" => dispSeg <= "01100110"; -- 4
      when "1111" => dispSeg <= "11111111"; -- input prompt
      when "1110" => dispSeg <= "01010100"; -- n (next / win)
      when "1101" => dispSeg <= "00111000"; -- L
      when others => dispSeg <= "00000000";
    end case;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        if seed_shift = '0' then
          seed <= seed(6 downto 0) & seed(7);
          if seed(6 downto 0) & seed(7) = "00000000" then
            seed <= "00000001";
          end if;
        end if;
        seed_shift    <= '1';
        state         <= idle;
        level         <= 0;
        index         <= 0;
        disp_cntr     <= 0;
        game_reg      <= (others => (others => '0'));
        user_reg      <= (others => (others => '0'));
        disp_data     <= (others => '0');
      else
        seed_shift <= '0';

        case state is
          when idle =>
            disp_cntr <= 0;
            level     <= 0;
            index     <= 0;
            game_reg  <= (others => (others => '0'));
            user_reg  <= (others => (others => '0'));
            disp_data <= (others => '0');
            if start_pulse = '1' then
              state <= gen;
            end if;

          when gen =>
            if level < max_pattern then
              game_reg(level) <= gen_pattern;
              level           <= level + 1;
            end if;
            index     <= 0;
            disp_cntr <= 0;
            state     <= display;

          when display =>
            if disp_cntr = 0 then
              disp_data <= game_reg(index);
            elsif disp_cntr = (clk_freq / 2) - 1 then
              disp_data <= (others => '0');
            end if;

            if disp_cntr < clk_freq - 1 then
              disp_cntr <= disp_cntr + 1;
            else
              disp_cntr <= 0;
              if index + 1 = level then
                user_reg  <= (others => (others => '0'));
                disp_data <= (others => '0');
                index     <= 0;
                state     <= input;
              else
                index <= index + 1;
              end if;
            end if;

          when input =>
            disp_data <= "1111";
            if pulse /= "0000" and index < level then
              user_reg(index) <= onehot_from_pulse(pulse);
              if index + 1 = level then
                index <= 0;
                state <= check;
              else
                index <= index + 1;
              end if;
            end if;

          when check =>
            if user_reg(index) = game_reg(index) then
              if index + 1 = level then
                index     <= 0;
                disp_cntr <= 0;
                state     <= win;
              else
                index <= index + 1;
              end if;
            else
              index     <= 0;
              disp_cntr <= 0;
              state     <= lose;
            end if;

          when win =>
            if disp_cntr < clk_freq / 4 then
              disp_data <= "1110";
            else
              disp_data <= (others => '0');
            end if;
            if disp_cntr < clk_freq - 1 then
              disp_cntr <= disp_cntr + 1;
            else
              disp_cntr <= 0;
              if level = max_pattern then
                state <= idle;
              else
                state <= gen;
              end if;
            end if;

          when lose =>
            if disp_cntr < clk_freq / 4 then
              disp_data <= "1101";
            else
              disp_data <= (others => '0');
            end if;
            if disp_cntr < clk_freq - 1 then
              disp_cntr <= disp_cntr + 1;
            else
              disp_cntr <= 0;
              state     <= idle;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
