library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity ir_dec_risb is
    generic (
        dataWidth   :   integer:=32;
        aluOpWidth  :   integer:=5 
    );
    port ( 
        instr           :   in    std_logic_vector (dataWidth - 1 downto 0);
        aluOp           :   out   std_logic_vector (aluOpWidth - 1 downto 0);
        insType         :   out   std_logic_vector(2 downto 0);
        loadType        :   out   std_logic_vector(2 downto 0);
        RI_sel          :   out   std_logic;
        rdWrite         :   out   std_logic;
        wrMem           :   out   std_logic;
        loadAcc         :   out   std_logic;
        pc_load         :   out   std_logic;
        bsel            :   out   std_logic;
        memType         :   out   std_logic_vector(2 downto 0); -- Ajout du port manquant pour SM
        
        -- Ports non utilisés mais présents dans votre top-level
        bres            :   in    std_logic;
        btype           :   out   std_logic_vector (2 downto 0);
        immSig          :   out   std_logic; -- Redondant avec RI_sel mais gardé pour compatibilité
        writeDataMem    :   out   std_logic; -- Redondant avec wrMem
        memDataOutSig   :   out   std_logic;
        clk, reset      :   in    std_logic
    );
end entity ir_dec_risb;

architecture behav of ir_dec_risb is
    alias opcode    : std_logic_vector(6 downto 0) is instr(6 downto 0);
    alias funct3    : std_logic_vector(2 downto 0) is instr(14 downto 12);
    alias funct7_b5 : std_logic is instr(30);
    
    signal instType_local : std_logic_vector(2 downto 0);
begin

    -- Décodage du Type
    process (opcode)
    begin
        case opcode is
            when R_TYPE_OPCODE => instType_local <= R_TYPE;
            when I_TYPE_OPCODE => instType_local <= I_TYPE;
            when L_TYPE_OPCODE => instType_local <= L_TYPE;
            when S_TYPE_OPCODE => instType_local <= S_TYPE;
            when B_TYPE_OPCODE => instType_local <= B_TYPE;
            when others        => instType_local <= UNKTYP;
        end case;
    end process;
    insType <= instType_local;

    -- Génération aluOp (5 bits)
    process (instType_local, funct3, funct7_b5)
    begin
        aluOp <= (others => '0'); -- Reset à 00000
        case instType_local is
            when R_TYPE => 
                aluOp <= '0' & funct7_b5 & funct3; -- Concatenation explicite sur 5 bits
            when I_TYPE =>
                if funct3 = "101" then -- SRAI
                    aluOp <= '0' & funct7_b5 & funct3;
                else
                    aluOp <= "00" & funct3;
                end if;
            when others => 
                aluOp <= "00000"; -- ADD par défaut (pour L, S)
        end case;
    end process;

    -- Signaux de Contrôle
    process (instType_local, funct3, bres)
    begin
        -- Valeurs par défaut
        rdWrite <= '0'; RI_sel <= '0'; wrMem <= '0'; loadAcc <= '0';
        pc_load <= '0'; bsel <= '0';
        loadType <= "010"; memType <= "010";
        
        -- Signaux de compatibilité
        immSig <= '0'; writeDataMem <= '0'; memDataOutSig <= '0';

        case instType_local is
            when R_TYPE => 
                rdWrite <= '1'; RI_sel <= '0'; 
                
            when I_TYPE => 
                rdWrite <= '1'; RI_sel <= '1'; immSig <= '1';
                
            when L_TYPE => 
                rdWrite <= '1'; RI_sel <= '1'; immSig <= '1';
                loadAcc <= '1';      -- Mux WB = Mem
                loadType <= funct3;  -- Pour LM
                memDataOutSig <= '1';

            when S_TYPE => 
                rdWrite <= '0'; RI_sel <= '1'; immSig <= '1';
                wrMem <= '1';        -- Ecriture Mem
                writeDataMem <= '1';
                memType <= funct3;   -- Pour SM
                
            when B_TYPE =>
                bsel <= bres;
                pc_load <= bres;
                
            when others => null;
        end case;
    end process;
    
    btype <= funct3; -- Pour Branch Controller

end behav;