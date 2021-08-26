-- author: Velat Kilic
-- DMD calibration pattern generator using an lfsr

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity pattern_generator is
    generic (
        OBJECT_SIZE  : natural := 16
    );
    port(
        clk          : in  std_logic;
        rst          : in std_logic;
        start        : in std_logic;
        vsync        : in  std_logic;
        pixel_x      : in  std_logic_vector(OBJECT_SIZE-1 downto 0);
        pixel_y      : in  std_logic_vector(OBJECT_SIZE-1 downto 0);
        px           : in unsigned(3 downto 0);
        py           : in unsigned(3 downto 0);
        x1           : in  unsigned(OBJECT_SIZE-1 downto 0);
        x2           : in  unsigned(OBJECT_SIZE-1 downto 0);
        y1           : in  unsigned(OBJECT_SIZE-1 downto 0);
        y2           : in  unsigned(OBJECT_SIZE-1 downto 0);
        yt           : in  unsigned(OBJECT_SIZE-1 downto 0);
        rgb          : out std_logic_vector(23 downto 0);
        trig         : out std_logic
    );
end pattern_generator;

architecture rtl of pattern_generator is
    type state_type is (idle, fonwait, fetch);
    signal fsm : state_type := idle;
    
    signal x,y : unsigned(OBJECT_SIZE-1 downto 0);
    signal cntx,cnty : unsigned(3 downto 0);
    signal fon,eof : std_logic; -- frame on signal and end of frame signal
    signal we,enl : std_logic;
    signal prbs,seed: std_logic_vector(63 downto 0); -- seed
    
begin
    
    -- FSM
    process(clk,rst)
    begin
        if (rst='1') then
            fsm <= idle;
        elsif (rising_edge(clk)) then
            case fsm is
            when idle =>
                if start='1' then
                    fsm <= fonwait;
                else
                    fsm <= idle;
                end if;
            when fonwait =>
                if fon='1' then
                    fsm <= fetch;
                else
                    fsm <= fonwait;
                end if;
            when fetch => 
                if eof='1' then
                    fsm <= fonwait;
                else
                    fsm <= fetch;
                end if;
            end case;
        end if;
    end process;

    -- Output
    rgb <= (others => '1') when (fon='1' and prbs(0)='1') else (others => '0');
    
    -- Linear feedback shift register
    lu: entity lfsr
    port map(
        clk  => clk,
        rst  => rst, -- asynch reset
        enl  => enl, -- enable prbs generation
        we   => we, -- write enable for seed
        seed => seed, -- seed
        prbs => prbs-- output prbs
        );
    -- Enable prbs generation in fetch
    process(clk,rst)
    begin
        if rst='1' then
            seed <= x"3A923A92BA923A92";
        elsif rising_edge(clk) then
            if x=x1 then
                seed <= prbs;
            end if;
        end if;
    end process;
    
    we <= '1' when x=x1-1 and cnty/=py-1 else '0';
    
    enl <= '1' when cntx=px-1 and fon='1' else '0';
    
    -- Frame on signal
    fon <= '1' when (x>x1 and x<x2) and (y>y1 and y<y2) else '0';
    x <= unsigned(pixel_x);
    y <= unsigned(pixel_y);
    
    -- End of frame signal
    fe: entity fall_edge port map(clk=>clk, rst=>rst, di=>vsync, do=>eof);
    
    -- Counters
    process(clk,rst)
    begin
        if rst='1' then
            cntx <= (others=>'0');
        elsif rising_edge(clk) then
            if fon='1' then
                if cntx=px-1 then
                    cntx <= (others=>'0');
                else 
                    cntx <= cntx + 1;
                end if;
            else
                cntx <= (others=>'0');
            end if;
        end if;
    end process;
    
    process(clk,rst)
    begin
        if rst='1' then
            cnty <= (others=>'0');
        elsif rising_edge(clk) then
            if x=x1 and y>y1 then
                if cnty=py-1 then
                    cnty <= (others=>'0');
                else 
                    cnty <= cnty + 1;
                end if;
            elsif y>y2 then
                cnty <= (others=>'0');
            end if;
        end if;
    end process;
    
    -- camera trigger signal
    -- active low
    trig <= '0' when y=yt else '1';

end rtl;
