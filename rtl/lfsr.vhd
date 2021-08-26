----------------------------------------------------------------------------------
-- Author : Velat Kilic
-- Linear feedback shift register for random projection pattern calculation
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.all;

entity lfsr is
    Port (
        clk  : in std_logic; -- clock
        rst  : in std_logic; -- asynch reset
        enl  : in std_logic; -- enable prbs generation
        we   : in std_logic; -- write enable for seed
        seed : in std_logic_vector(63 downto 0); -- seed
        prbs : out std_logic_vector(63 downto 0) -- output prbs
    );
end lfsr;

architecture Behavioral of lfsr is
    signal prbs_temp : std_logic_vector(63 downto 0);
begin

    prbs <= prbs_temp;
    process(clk,rst)
    begin
        if rst='1' then
            prbs_temp <= x"3A923A92BA923A92"; -- reset to seed value
        elsif rising_edge(clk) then
            if we='1' then
                prbs_temp <= seed;
            elsif enl='1' then
                -- Polynomial tap from xapp052 Xilinx
                prbs_temp <= prbs_temp(62 downto 0) & (prbs_temp(63) xnor prbs_temp(62) xnor prbs_temp(60) xnor prbs_temp(59));
            end if;
        end if;
    end process;
end Behavioral;
