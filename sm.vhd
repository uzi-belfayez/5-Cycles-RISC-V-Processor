library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

-- 1. DÉCLARATION DE L'ENTITÉ (C'est la partie qu'il vous manquait)
entity sm is
    generic (
        dataWidth      : integer:=32
    );
    port (
        data       : in std_logic_vector (dataWidth - 1 downto 0); -- Donnée à écrire (depuis rs2)
        q          : in std_logic_vector (dataWidth - 1 downto 0); -- Donnée lue en mémoire (Valeur actuelle)
        res        : in std_logic_vector (1 downto 0);             -- Adresse LSB (Alignement)
        funct3     : in std_logic_vector (2 downto 0);             -- Type (SB, SH, SW)
        dataOut    : out std_logic_vector (dataWidth - 1 downto 0) -- Donnée modifiée vers dmem
    );
end entity sm;

-- 2. ARCHITECTURE (Logique corrigée pour l'alignement)
architecture behav of sm is

    alias q_0 : std_logic_vector(7 downto 0) is q(7 downto 0);
    alias q_1 : std_logic_vector(7 downto 0) is q(15 downto 8);
    alias q_2 : std_logic_vector(7 downto 0) is q(23 downto 16);
    alias q_3 : std_logic_vector(7 downto 0) is q(31 downto 24);

    -- Variable intermédiaire pour préparer la donnée alignée
    signal data_to_write : std_logic_vector(31 downto 0);
    
    -- Masque (1=Garder mémoire, 0=Ecrire data)
    signal m : std_logic_vector(3 downto 0);

begin

    -------------------------------------------------------------------------
    -- 1. DATA ALIGNMENT
    -- Déplace l'octet ou le demi-mot de poids faible vers la bonne position
    -------------------------------------------------------------------------
    process (data, res, funct3)
    begin
        -- Par défaut, on prend la donnée brute (cas SW)
        data_to_write <= data;

        if funct3(1 downto 0) = "00" then -- SB (Store Byte)
            case res is
                when "00"   => 
                    data_to_write(7 downto 0)   <= data(7 downto 0);
                when "01"   => 
                    data_to_write(15 downto 8)  <= data(7 downto 0);
                when "10"   => 
                    data_to_write(23 downto 16) <= data(7 downto 0);
                when "11"   => 
                    data_to_write(31 downto 24) <= data(7 downto 0);
                when others => null;
            end case;

        elsif funct3(1 downto 0) = "01" then -- SH (Store Half)
            if res(1) = '1' then -- Upper Half (Adresse terminant par 10)
                data_to_write(31 downto 16) <= data(15 downto 0);
            else                 -- Lower Half (Adresse terminant par 00)
                data_to_write(15 downto 0)  <= data(15 downto 0);
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- 2. MASK GENERATION
    -- Définit quels octets doivent être écrasés
    -------------------------------------------------------------------------
    process (res, funct3)
    begin
        m <= "1111"; -- Par défaut : on ne touche à rien (tout à 1)
        
        case funct3(1 downto 0) is
            when "00" => -- SB
                case res is
                    when "00" => m <= "1110"; -- Ecrit octet 0
                    when "01" => m <= "1101"; -- Ecrit octet 1
                    when "10" => m <= "1011"; -- Ecrit octet 2
                    when "11" => m <= "0111"; -- Ecrit octet 3
                    when others => null;
                end case;
            when "01" => -- SH
                if res(1) = '0' then m <= "1100"; -- Ecrit partie basse
                else                 m <= "0011"; -- Ecrit partie haute
                end if;
            when "10" => -- SW
                m <= "0000"; -- Ecrit tout
            when others => null;
        end case;
    end process;

    -------------------------------------------------------------------------
    -- 3. FINAL MERGE
    -- Si m(i)='1', on garde l'ancienne valeur (q). Sinon on prend la nouvelle (data_to_write).
    -------------------------------------------------------------------------
    dataOut(7 downto 0)   <= q_0 when m(0) = '1' else data_to_write(7 downto 0);
    dataOut(15 downto 8)  <= q_1 when m(1) = '1' else data_to_write(15 downto 8);
    dataOut(23 downto 16) <= q_2 when m(2) = '1' else data_to_write(23 downto 16);
    dataOut(31 downto 24) <= q_3 when m(3) = '1' else data_to_write(31 downto 24);

end behav;