----------------------------------------------------------------------------------
-- Author: Velat Kilic
-- Falling edge detector
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fall_edge is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        di  : in std_logic;
        do  : out std_logic
    );
end fall_edge;

architecture Behavioral of fall_edge is
    signal prev : std_logic;
begin

    process(clk,rst)
    begin
        if rst='1' then
            prev <= di;
        elsif rising_edge(clk) then
            prev <= di;
        end if;
    end process;
    
    do <= '1' when prev='1' and di='0' else '0';
end Behavioral;
