library IEEE;
use IEEE.std_logic_1164.ALL;

entity registre_instr is
    generic ( DATA_WIDTH : integer := 32 );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        ri_enable : in  std_logic; -- Signal d'activation venant du contrôleur
        din       : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Sortie de IMEM
        dout      : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- Vers le Décodeur
    );
end entity registre_instr;

architecture behavior of registre_instr is
begin
    process (clk, reset)
    begin
        if reset = '1' then
            dout <= (others => '0');
        elsif rising_edge(clk) then
            if ri_enable = '1' then
                dout <= din;
            end if;
        end if;
    end process;
end behavior;