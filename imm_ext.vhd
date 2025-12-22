library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity imm_ext_risb is
    generic ( dataWidth : integer:=32 );
    port (
        instr   : in  std_logic_vector(dataWidth - 1 downto 0);
        insType : in  std_logic_vector(2 downto 0); 
        immExt  : out std_logic_vector(dataWidth - 1 downto 0)
    );
end entity imm_ext_risb;

architecture behav of imm_ext_risb is
    signal immValue : unsigned(31 downto 0);
begin
    process (insType, instr)
    begin
        immValue <= (others => '0');
        case insType is
            when I_TYPE | L_TYPE => 
                -- I-Type: imm[11:0] = instr[31:20]
                immValue(11 downto 0) <= unsigned(instr(31 downto 20));
                -- Extension de signe
                if instr(31) = '1' then immValue(31 downto 12) <= (others => '1'); end if;

            when S_TYPE => 
                -- S-Type: imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
                immValue(4 downto 0)   <= unsigned(instr(11 downto 7));
                immValue(11 downto 5)  <= unsigned(instr(31 downto 25));
                -- Extension de signe
                if instr(31) = '1' then immValue(31 downto 12) <= (others => '1'); end if;
                
            when B_TYPE =>
                 -- B-Type (pour info)
                immValue(0) <= '0';
                immValue(4 downto 1)   <= unsigned(instr(11 downto 8));
                immValue(10 downto 5)  <= unsigned(instr(30 downto 25));
                immValue(11)           <= instr(7);
                if instr(31) = '1' then immValue(31 downto 12) <= (others => '1'); end if;

            when others => 
                immValue <= (others => '0');
        end case;
    end process;
    immExt <= std_logic_vector(immValue);
end behav;