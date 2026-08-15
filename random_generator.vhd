library ieee;
use ieee.std_logic_1164.all;

entity random_generator is
  generic
  (
    input_width  : integer := 8;
    output_width : integer := 4
  );
  port
  (
    clk      : in std_logic;
    rst      : in std_logic := '0';
    seed     : in std_logic_vector(input_width - 1 downto 0);
    rand_out : out std_logic_vector(output_width - 1 downto 0)
  );
end entity random_generator;

architecture rtl of random_generator is
  signal curr : std_logic_vector(input_width - 1 downto 0) := (0 => '1', others => '0');
  signal fb   : std_logic;
begin
  -- x^8 + x^6 + x^5 + x^4 + 1 (width 8); XOR ends otherwise.
  g_fb8 : if input_width = 8 generate
    fb <= curr(7) xor curr(5) xor curr(4) xor curr(3);
  end generate;
  g_fb_other : if input_width /= 8 generate
    fb <= curr(0) xor curr(input_width - 1);
  end generate;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        if seed = (seed'range => '0') then
          curr <= (0 => '1', others => '0');
        else
          curr <= seed;
        end if;
      else
        curr <= curr(input_width - 2 downto 0) & fb;
      end if;
    end if;
  end process;

  -- Two LFSR bits → one-hot color so each button is equally likely.
  rand_out <= "0001" when curr(1 downto 0) = "00" else
    "0010" when curr(1 downto 0) = "01" else
    "0100" when curr(1 downto 0) = "10" else
    "1000";
end architecture;
