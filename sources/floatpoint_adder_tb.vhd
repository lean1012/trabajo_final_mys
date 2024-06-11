library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity floatpoint_adder_tb is
end;

architecture floatpoint_adder_tb_arq of floatpoint_adder_tb is

	component floatpoint_adder is
		generic (
			PRECISION_BITS : natural := 32
		);

		port (
			a_i     : in  std_logic_vector(PRECISION_BITS - 1 downto 0);
			b_i     : in  std_logic_vector(PRECISION_BITS - 1 downto 0);
			start_i : in  std_logic;
			s_o     : out std_logic_vector(PRECISION_BITS - 1 downto 0);
			done_o  : out std_logic;
			rst     : in  std_logic;
			clk     : in  std_logic
		);
	end component;

	constant PRECISION_BITS_TB : natural                                          := 32;
	signal a_tb                : std_logic_vector(PRECISION_BITS_TB - 1 downto 0) := "01000001001001101110000101001000";--"11001011000110001001011010000000"; --"10111101100000010100011100000001";
	signal b_tb                : std_logic_vector(PRECISION_BITS_TB - 1 downto 0) := "11000100111101111110000001010010";--"00111000011110111010100010000010"; --"00100110100011001100110011001101";
	signal start_tb            : std_logic                                        := '0';
	signal s_tb                : std_logic_vector(PRECISION_BITS_TB - 1 downto 0);
	signal done_tb             : std_logic;
	signal rst_tb              : std_logic := '0';
	signal clk_tb              : std_logic := '0';

begin

	clk_tb   <= not clk_tb after 100 ns;
	rst_tb   <= '1' after 10 ns, '0' after 120 ns;
	start_tb <= '1' after 230 ns, '0' after 1000 ns, '1' after 2100 ns;
	DUT : floatpoint_adder
	generic map(
		PRECISION_BITS => PRECISION_BITS_TB
	)
	port map(
		a_i     => a_tb,
		b_i     => b_tb,
		start_i => start_tb,
		s_o     => s_tb,
		done_o  => done_tb,
		rst     => rst_tb,
		clk     => clk_tb
	);

end;