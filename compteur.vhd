library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity compteur is
    generic (
        TAILLE : integer := 32
    );
    port (
        din         : in  std_logic_vector(TAILLE-1 downto 0);
        clk         : in  std_logic;
        reset       : in  std_logic;
        load        : in  std_logic;
        pc_enable   : in  std_logic; -- NOUVEAU SIGNAL
        dout        : out std_logic_vector(TAILLE-1 downto 0);
        pc_plus_4   : out std_logic_vector(TAILLE-1 downto 0)
    );
end entity compteur;

architecture behavior of compteur is
    signal cpt : unsigned(TAILLE-1 downto 0);
begin
    process (clk, reset)
    begin
        if reset = '1' then
            cpt <= (others => '0');
        elsif rising_edge(clk) then
            if load = '1' then
                -- Priorité au saut (Branch/Jump)
                cpt <= unsigned(din);
            elsif pc_enable = '1' then
                -- Incrémentation seulement si autorisé (Pendant l'état FETCH)
                cpt <= cpt + 4;
            end if;
            -- Sinon, cpt conserve sa valeur (Decode, Execute, Mem, WB)
        end if;
    end process;

    dout <= std_logic_vector(cpt);
    pc_plus_4 <= std_logic_vector(cpt + 4); 

end behavior;