------------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice - Anno Accademico 2021/2022

-- Alessandro Folini (Codice Persona: 10674753 Matricola: 933707)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
	port (
		i_clk : in std_logic;
		i_rst : in std_logic;
		i_start : in  std_logic;
		i_data : in  std_logic_vector(7 downto 0);
		o_address : out std_logic_vector(15 downto 0);
		o_done : out std_logic;
		o_en : out std_logic;
		o_we : out std_logic;
		o_data : out std_logic_vector(7 downto 0)
	);
end entity project_reti_logiche;

architecture Behavioral of project_reti_logiche is
	type STATE is (START, READ_LEN, WAIT_READ_LEN, SET_LEN, READ_WORD, WAIT_READ_WORD, CONV, WRITE_FIRST_WORD, WAIT_WRITE_FIRST_WORD, WRITE_SECOND_WORD, WAIT_WRITE_SECOND_WORD, DONE);
	signal curr_state, next_state : STATE := START;
	signal last_word_address, last_word_address_next, last_read_address, last_read_address_next, y, y_next, o_address_next : std_logic_vector(15 downto 0) := (others => '0');
	signal last_written_address, last_written_address_next : std_logic_vector(15 downto 0) := ("0000001111101000");
	signal pos, pos_next : integer range 0 to 7 := 7;
	signal old_i_data, old_i_data_next, o_data_next : std_logic_vector(7 downto 0) := (others => '0');
	signal o_en_next, o_we_next, o_done_next : std_logic := '0';

	begin
		process(i_clk, i_rst) is
		begin
			if i_rst = '1' then		
                curr_state <= START;
                o_address <= "0000000000000000";
                o_en <= '0';
                o_we <= '0';
                o_done <= '0';
                o_data <= "00000000";
                last_read_address <= "0000000000000000";
                last_written_address <= "0000001111101000";
                last_word_address <= "0000000000000000";
                old_i_data <= "00000000";
                y <= "0000000000000000";
                pos <= 7;
            elsif i_clk'event and i_clk = '1' then
				curr_state <= next_state;
				o_address <= o_address_next;
				o_en <= o_en_next;
				o_we <= o_we_next;
				o_done <= o_done_next;
				o_data <= o_data_next;
				last_read_address <= last_read_address_next;
                last_written_address <= last_written_address_next;
                last_word_address <= last_word_address_next;
                old_i_data <= old_i_data_next;
                y <= y_next;
                pos <= pos_next;
			end if;
		end process;

		process(curr_state, i_start, i_data, pos, last_read_address, last_written_address, last_word_address, old_i_data, y) is
		begin
		  next_state <= curr_state;
		  o_address_next <= "0000000000000000";
		  o_data_next <= "00000000";
		  o_en_next <= '0';
		  o_we_next <= '0';
		  o_done_next <= '0';
		  last_read_address_next <= last_read_address;
		  last_written_address_next <= last_written_address;
		  last_word_address_next <= last_word_address;
		  old_i_data_next <= old_i_data;
		  y_next <= y;
		  pos_next <= pos;
		  
			case curr_state is
			
				when START =>
				    old_i_data_next <= "00000000";
                    last_read_address_next <= "0000000000000000";
                    last_written_address_next <= "0000001111101000";
                    pos_next <= 7;
                    if i_start = '1' then
						next_state <= READ_LEN;
					else
						next_state <= START;
					end if;

				when READ_LEN =>
				    o_en_next <= '1';
                    next_state <= WAIT_READ_LEN;
					
				when WAIT_READ_LEN =>
				    next_state <= SET_LEN;
				
				when SET_LEN =>
				    if not(unsigned(i_data) = 0) then
                        last_word_address_next <= std_logic_vector(unsigned("00000000" & i_data) + 1);
                        next_state <= READ_WORD;
                    else
                        o_done_next <= '1';
                        next_state <= DONE;
                    end if;
				    

				when READ_WORD => 
					last_read_address_next <= std_logic_vector(unsigned(last_read_address) + 1);
					o_address_next <= last_read_address + 1;
					if not(last_read_address = last_word_address-1) then
						o_en_next <= '1';
						next_state <= WAIT_READ_WORD;
					else
						o_done_next <= '1';
						next_state <= DONE;
					end if;

				when WAIT_READ_WORD =>
					next_state <= CONV;

				when CONV =>
					if pos = 7 then
						y_next(15) <= i_data(pos) xor old_i_data(1);
						y_next(14) <= i_data(pos) xor old_i_data(1) xor old_i_data(0);
					elsif pos = 6 then
						y_next(13) <= i_data(pos) xor old_i_data(0);
						y_next(12) <= i_data(pos) xor i_data(pos+1) xor old_i_data(0);
					else
						y_next(pos + pos + 1) <= i_data(pos) xor i_data(pos+2);
						y_next(pos + pos) <= i_data(pos) xor i_data(pos+1) xor i_data(pos+2); 
					end if;
                   
                    if pos = 0 then
						next_state <= WRITE_FIRST_WORD;
					else
					    pos_next <= pos - 1; 
						next_state <= CONV;
						
					end if;

				when WRITE_FIRST_WORD =>
				    old_i_data_next <= i_data;
				    o_address_next <= last_written_address;
					o_en_next <= '1';
					o_we_next <= '1';
					last_written_address_next <= std_logic_vector(unsigned(last_written_address) + 1);
					o_data_next <= y(15 downto 8);
					next_state <= WAIT_WRITE_FIRST_WORD;

				when WAIT_WRITE_FIRST_WORD =>
					next_state <= WRITE_SECOND_WORD;
					
				when WRITE_SECOND_WORD =>
                    o_address_next <= last_written_address;
                    o_en_next <= '1';
                    o_we_next <= '1';
                    last_written_address_next <= std_logic_vector(unsigned(last_written_address) + 1);
                    o_data_next <= y(7 downto 0);
                    next_state <= WAIT_WRITE_SECOND_WORD;
                    
				when WAIT_WRITE_SECOND_WORD => 
				    y_next <= "0000000000000000";
				    pos_next <= 7;
				    next_state <= READ_WORD;
				    
				when DONE =>
					if i_start = '0' then
						next_state <= START;
					else
						o_done_next <= '1';
						next_state <= DONE;
					end if;
			end case;
		end process;
	
end architecture;