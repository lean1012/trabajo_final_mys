library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity floatpoint_adder is
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
end;

architecture floatpoint_adder_arq of floatpoint_adder is

--Funciones auxiliares para parametrizar los parametros EXPONENT_BIT,MANTISSA_BITS, ....

	function f_max_exponent(constant PRECISION : natural)
		return natural is
	begin
		case PRECISION is
			when 32     => return 254; --maximo desplazamiento 254 ( cuando el exponente es 254 y el otro es 0)
			when 64     => return 2046;
			when others => return 254;
		end case;
	end function;

	function f_expon_bits(constant PRECISION : natural)
		return natural is
	begin
		case PRECISION is
			when 32     => return 8;
			when 64     => return 11;
			when others => return 8;
		end case;
	end function;

	function f_mantissa_bits(constant PRECISION : natural)
		return natural is
	begin
		case PRECISION is
			when 32     => return 23;
			when 64     => return 52;
			when others => return 23;
		end case;
	end function;

	function f_sign_bits(constant PRECISION : natural)
		return natural is
	begin
		case PRECISION is
			when 32     => return 1;
			when 64     => return 1;
			when others => return 1;
		end case;
	end function;

	function f_exp_all_one(constant PRECISION : natural)
		return natural is
	begin
		case PRECISION is
			when 32     => return 255;
			when 64     => return 2047;
			when others => return 255;
		end case;
	end function;

	constant EXPONENT_BITS : natural := f_expon_bits(PRECISION_BITS);
	constant MANTISSA_BITS : natural := f_mantissa_bits(PRECISION_BITS);
	constant SIGN_BITS     : natural := f_sign_bits(PRECISION_BITS);
	constant MAX_EXP       : natural := f_max_exponent(PRECISION_BITS);

	constant EXP_ALL_ONE   : natural := f_exp_all_one(PRECISION_BITS);
	type STATES is (
		WAITING_STATE,
		COMPARING_EXP_STATE,
		ADD_STATE,
		NORMALIZATION_STATE,
		ROUNDING_STATE,
		NORMALIZATION_STATE_2,
		INF_STATE,
		DONE_STATE
	);

	signal current_state, next_state : STATES;
	signal sg_a                      : std_logic                                              := '0';
	signal exponent_a                : std_logic_vector(EXPONENT_BITS - 1 downto 0)           := (others => '0');
	signal mantissa_a                : std_logic_vector(MANTISSA_BITS + 1 downto 0)           := (others => '0');
	signal sg_b                      : std_logic                                              := '0';
	signal exponent_b                : std_logic_vector(EXPONENT_BITS - 1 downto 0)           := (others => '0');
	signal mantissa_b                : std_logic_vector(MANTISSA_BITS + 1 downto 0)           := (others => '0');
	signal mantissa_a_aux            : std_logic_vector(MANTISSA_BITS + 1 + MAX_EXP downto 0) := (others => '0');
	signal mantissa_b_aux            : std_logic_vector(MANTISSA_BITS + 1 + MAX_EXP downto 0) := (others => '0');
	signal mantissa_add              : std_logic_vector(MANTISSA_BITS + 1 + MAX_EXP downto 0) := (others => '0');
	signal sig_o               		 : std_logic                                              := '0';
	signal mantissa_o                : std_logic_vector(MANTISSA_BITS + 1 downto 0)           := (others => '0');
	signal exponent_o                : std_logic_vector(EXPONENT_BITS - 1 downto 0)           := (others => '0');

begin

	
	process (clk, rst, start_i)
		variable diff     : unsigned(EXPONENT_BITS - 1 downto 0);
		variable sticky_b : std_logic := '0';
		variable round_b  : std_logic := '0';
		variable guard_b  : std_logic := '0';
		constant zeros    : std_logic_vector(MAX_EXP - 2 downto 0) := (others => '0');

	begin
		if rst = '1' then
			next_state <= WAITING_STATE;
			done_o     <= '0';
			s_o        <= (others => '0');
		elsif rising_edge(clk) then
			current_state <= next_state;
			case next_state is
				-- WATING_STATE *************************************************************************************************
				when WAITING_STATE =>
					-- Elimino las salidas					
					if start_i = '1' then	
						done_o <= '0';
						s_o    <= (others => '0');	
						-- Pregunto si alguno es NaN				
						if (((to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) /= 0)) or ((to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) /= 0))) then
							sig_o    <= '1';
							exponent_o     <= (others => '1');
							mantissa_o <= (others => '1');
							next_state     <= DONE_STATE;
						-- Pregunto si alguno es infinito
						elsif (((to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) = 0)) or ((to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) = 0))) then
							if ((to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) = 0)) then
								-- a es infinito
								mantissa_a <= (others => '0');
								exponent_a <= (others => '1');
								sg_a       <= a_i(PRECISION_BITS - 1);
							else
								-- a no es infinito
								sg_a <= a_i(PRECISION_BITS - 1);
								mantissa_a <= (others => '0');
								exponent_a <= (others => '0');
							end if;
							if ((to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = EXP_ALL_ONE) and (to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0))) = 0)) then
								-- b es infinito
								mantissa_b <= (others => '0');
								exponent_b <= (others => '1');
								sg_b       <= b_i(PRECISION_BITS - 1);
							else
								-- b no es infinito
								sg_b <= b_i(PRECISION_BITS - 1);
								mantissa_b <= (others => '0');
								exponent_b <= (others => '0');
							end if;
							next_state <= INF_STATE;
						else
							-- a y b no son NaN ni infnitos
							--Copio los signos
							sg_a <= a_i(PRECISION_BITS - 1);
							sg_b <= b_i(PRECISION_BITS - 1);
							-- Veo si A es normalizados o denormalizados mirando el exponente
							if (to_integer(unsigned(a_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = 0) then
								-- es denormalizado agrego 00 y exp 1
								mantissa_a <= "00" & a_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0);
								exponent_a <= std_logic_vector(to_unsigned(1, EXPONENT_BITS));
							else
								-- numero normalizado, agrego 01 y copio el exponente
								mantissa_a <= "01" & a_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0);
								exponent_a <= a_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS);
							end if;
							-- Veo si B es normalizados o denormalizados mirando el exponente
							if (to_integer(unsigned(b_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS))) = 0) then
								-- es denormalizado agrego 00 y exp 1
								mantissa_b <= "00" & b_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0);
								exponent_b <= std_logic_vector(to_unsigned(1, EXPONENT_BITS));
							else
								-- numero normalizado, agrego 01 y copio el exponente
								mantissa_b <= "01" & b_i(PRECISION_BITS - 1 - SIGN_BITS - EXPONENT_BITS downto 0);
								exponent_b <= b_i(PRECISION_BITS - 1 - SIGN_BITS downto PRECISION_BITS - SIGN_BITS - EXPONENT_BITS);
							end if;
							-- preparo las mantissas axuliares para hacer el corrimiento
							mantissa_a_aux <= (others => '0');
							mantissa_b_aux <= (others => '0');
							next_state <= COMPARING_EXP_STATE;
						end if;
					else
						next_state <= WAITING_STATE;						
					end if;
					
				-- END WATING_STATE *************************************************************************************************

				-- COMPARING_STATE *************************************************************************************************
				when COMPARING_EXP_STATE =>
					-- Busco quien tiene el exponente mas grande
					if (exponent_a > exponent_b) then
						-- A tiene el exponente mas grande por lo tanto desplazo a b, diff = exp a - exp b
						exponent_o <= exponent_a;
						diff := unsigned(exponent_a) - unsigned(exponent_b);
						mantissa_b_aux(MANTISSA_BITS + 1 + MAX_EXP - to_integer(diff) downto MAX_EXP - to_integer(diff)) <= mantissa_b(MANTISSA_BITS + 1 downto 0);
						mantissa_a_aux(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP)                                       <= mantissa_a(MANTISSA_BITS + 1 downto 0);
					elsif (exponent_b > exponent_a) then
						-- B tiene el exponente mas grande por lo tanto desplazo a a, diff = exp b - exp a
						exponent_o <= exponent_b;
						diff := unsigned(exponent_b) - unsigned(exponent_a);
						mantissa_a_aux(MANTISSA_BITS + 1 + MAX_EXP - to_integer(diff) downto MAX_EXP - to_integer(diff)) <= mantissa_a(MANTISSA_BITS + 1 downto 0);
						mantissa_b_aux(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP)                                       <= mantissa_b(MANTISSA_BITS + 1 downto 0);
					else
						-- Ambos tienen el mismo exponente, no desplazo
						exponent_o                                                 <= exponent_a;
						mantissa_a_aux(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP) <= mantissa_a(MANTISSA_BITS + 1 downto 0);
						mantissa_b_aux(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP) <= mantissa_b(MANTISSA_BITS + 1 downto 0);
					end if;
					next_state <= ADD_STATE;
				-- END COMPARING_STATE *************************************************************************************************

				-- ADD_STATE *************************************************************************************************
				when ADD_STATE =>
				    -- Si tienen igual signo solo sumo
					if sg_a = sg_b then
						mantissa_add <= std_logic_vector(unsigned(mantissa_a_aux) + unsigned(mantissa_b_aux));
						sig_o  <= sg_a;
						next_state   <= NORMALIZATION_STATE;
					else
						-- Veo quien tiene la mantissa mas grande, el resultado del signo será la mantissa mas grande y la resta = mantissa_grande - mantissa_chica
						if (mantissa_a_aux = mantissa_b_aux) then
							-- mantissas iguales por lo tanto es 0 el resultado
							mantissa_o <= (others => '0');
							exponent_o     <= (others => '0');
							sig_o    <= '0';
							next_state <= DONE_STATE;
						elsif (mantissa_a_aux > mantissa_b_aux) then
							-- A tiene mayor mantiza por lo tanto la resta será del mismo signo que A, mantissa a - mantissa b
							mantissa_add <= std_logic_vector(unsigned(mantissa_a_aux) - unsigned(mantissa_b_aux));
							sig_o  <= sg_a;
							-- Next state
							next_state <= NORMALIZATION_STATE;
						else
							-- B tiene mayor mantiza por lo tanto la resta será del mismo signo que B, mantissa b - mantissa a
							mantissa_add <= std_logic_vector(unsigned(mantissa_b_aux) - unsigned(mantissa_a_aux));
							sig_o  <= sg_b;
							next_state <= NORMALIZATION_STATE;
						end if;

					end if;
				-- END ADD_STATE *************************************************************************************************

				-- NORMALIZATION_STATE *************************************************************************************************
				when NORMALIZATION_STATE =>
					-- ver si hay overflow
					if mantissa_add(MANTISSA_BITS + 1 + MAX_EXP) = '1' then
						if (unsigned(exponent_o) = 254) then
							sig_o    <= sg_a;
							exponent_o     <= (others => '1');
							mantissa_o <= (others => '0');
							next_state     <= DONE_STATE;
						else
							-- desplazo a la derecha, aumento exponente
							mantissa_add <= '0' & mantissa_add(MANTISSA_BITS + 1 + MAX_EXP downto 1);
							exponent_o   <= std_logic_vector(unsigned(exponent_o) + 1); --ver de que lado es el exponente
							next_state   <= ROUNDING_STATE;
						end if;
					-- desplazo a la izquierda hasta tener un 1, disminuyo exponente
					elsif mantissa_add(MANTISSA_BITS + MAX_EXP) = '0' then
						if (to_integer(unsigned(exponent_o)) > 1) then
							mantissa_add <= mantissa_add(MANTISSA_BITS + MAX_EXP downto 0) & '0';
							exponent_o   <= std_logic_vector(unsigned(exponent_o) - 1); --ver de que lado es el exponente
							next_state   <= NORMALIZATION_STATE;
						else
							exponent_o <= (others => '0');
							next_state <= ROUNDING_STATE;
						end if;
					else
						next_state <= ROUNDING_STATE;
					end if;
				-- END NORMALIZATION_STATE *************************************************************************************************

				-- ROUNDING_STATE **********************************************************************************************************
				when ROUNDING_STATE =>
				--Condición de redondeo Round = 1, Sticky = 1 o Guard = 1, Round = 1								
					if mantissa_add(MAX_EXP - 2 downto 0) = zeros(MAX_EXP - 2 downto 0) then
						sticky_b := '0';
					else
						sticky_b := '1';
					end if;
					round_b := (mantissa_add(MAX_EXP - 1));
					guard_b := (mantissa_add(MAX_EXP));
					if (((round_b and sticky_b) = '1') or ((guard_b and round_b) = '1')) then
						mantissa_o <= std_logic_vector(1 + unsigned(mantissa_add(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP)));

					else
						mantissa_o <= std_logic_vector(0 + unsigned(mantissa_add(MANTISSA_BITS + 1 + MAX_EXP downto MAX_EXP)));
					end if;

					next_state <= NORMALIZATION_STATE_2;
				-- END ROUNDING_STATE ***************************************************************************************************

				-- NORMALIZATION_STATE_2 *************************************************************************************************
				-- verifico que la mantiza empiece con 01, en caso de ser 10 aumento exponente y desplazo
				when NORMALIZATION_STATE_2 =>
					-- ver si hay overflow
					if mantissa_o(MANTISSA_BITS + 1) = '1' then
						mantissa_o <= '0' & mantissa_o(MANTISSA_BITS + 1 downto 1);
						exponent_o     <= std_logic_vector(unsigned(exponent_o) + 1); --ver de que lado es el exponente
					else
						mantissa_o <= mantissa_o;
						exponent_o     <= exponent_o;
					end if;
					next_state <= DONE_STATE;
				-- END NORMALIZATION_STATE_2 *************************************************************************************************

				-- INF_STATE ****************************************************************************************************************
				when INF_STATE =>
					if (exponent_a = exponent_b) then
						-- los dos son inf, tengo que ver los signos
						if (sg_a = sg_b) then
							-- infinitos de mismo signo
							sig_o    <= sg_a;
							exponent_o     <= (others => '1');
							mantissa_o <= (others => '0');
						else
							-- es +inf -inf es NaN
							sig_o    <= '1';
							exponent_o     <= (others => '1');
							mantissa_o <= (others => '1');
						end if;
					elsif (to_integer(unsigned(exponent_a)) = EXP_ALL_ONE) then
						-- a es inf
						sig_o    <= sg_a;
						exponent_o     <= (others => '1');
						mantissa_o <= (others => '0');
					else
						-- b es inf
						sig_o    <= sg_b;
						exponent_o     <= (others => '1');
						mantissa_o <= (others => '0');
					end if;			
					next_state <= DONE_STATE;
				-- END INF_STATE *****************************************************************************************************************

				-- DONE_STATE ********************************************************************************************************************
				when DONE_STATE =>
					-- muestro salidas
					s_o        <= sig_o & exponent_o & mantissa_o(MANTISSA_BITS + 1 - 2 downto 0);
					done_o     <= '1';
					next_state <= WAITING_STATE;


				-- END DONE_STATE *****************************************************************************************************************
				when others =>
					next_state <= WAITING_STATE;
			end case;
		else
			current_state <= current_state; -- sin esto me agrega un latch
		end if;

	end process;
end;