 
 
    --------------------------------------------------------------------------------
--
-- BLK MEM GEN v7_3 Core - Stimulus Generator For Single Port ROM
--
--------------------------------------------------------------------------------
--
-- (c) Copyright 2006_3010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

--------------------------------------------------------------------------------
--
-- Filename: bmg_stim_gen.vhd
--
-- Description:
--  Stimulus Generation For SROM
--
--------------------------------------------------------------------------------
-- Author: IP Solutions Division
--
-- History: Sep 12, 2011 - First Release
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;

 LIBRARY work;
USE work.ALL;
USE work.BMG_TB_PKG.ALL;


ENTITY REGISTER_LOGIC_SROM IS
  PORT(
    Q   : OUT STD_LOGIC;
    CLK   : IN STD_LOGIC;
    RST : IN STD_LOGIC;
    D   : IN STD_LOGIC
    );
END REGISTER_LOGIC_SROM;

ARCHITECTURE REGISTER_ARCH OF REGISTER_LOGIC_SROM IS
   SIGNAL Q_O : STD_LOGIC :='0';
BEGIN
  Q <= Q_O;
FF_BEH: PROCESS(CLK)
BEGIN
   IF(RISING_EDGE(CLK)) THEN
      IF(RST /= '0' ) THEN
	Q_O <= '0';
     ELSE
        Q_O <= D;
      END IF;
    END IF;
  END PROCESS;
END REGISTER_ARCH;

LIBRARY STD;
USE STD.TEXTIO.ALL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
--USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;

 LIBRARY work;
USE work.ALL;
USE work.BMG_TB_PKG.ALL;


ENTITY BMG_STIM_GEN IS
      GENERIC ( C_ROM_SYNTH : INTEGER := 0
      );
      PORT (
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC;
            ADDRA: OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0'); 
            DATA_IN : IN STD_LOGIC_VECTOR (7 DOWNTO 0);   --OUTPUT VECTOR         
            STATUS : OUT STD_LOGIC:= '0'
    	  );
END BMG_STIM_GEN;


ARCHITECTURE BEHAVIORAL OF BMG_STIM_GEN IS

    FUNCTION hex_to_std_logic_vector(
    hex_str       : STRING;
    return_width  : INTEGER)
  RETURN STD_LOGIC_VECTOR IS
    VARIABLE tmp        : STD_LOGIC_VECTOR((hex_str'LENGTH*4)+return_width-1
                                           DOWNTO 0);

  BEGIN
    tmp := (OTHERS => '0');
    FOR i IN 1 TO hex_str'LENGTH LOOP
      CASE hex_str((hex_str'LENGTH+1)-i) IS
        WHEN '0' => tmp(i*4-1 DOWNTO (i-1)*4) := "0000";
        WHEN '1' => tmp(i*4-1 DOWNTO (i-1)*4) := "0001";
        WHEN '2' => tmp(i*4-1 DOWNTO (i-1)*4) := "0010";
        WHEN '3' => tmp(i*4-1 DOWNTO (i-1)*4) := "0011";
        WHEN '4' => tmp(i*4-1 DOWNTO (i-1)*4) := "0100";
        WHEN '5' => tmp(i*4-1 DOWNTO (i-1)*4) := "0101";
        WHEN '6' => tmp(i*4-1 DOWNTO (i-1)*4) := "0110";
        WHEN '7' => tmp(i*4-1 DOWNTO (i-1)*4) := "0111";
        WHEN '8' => tmp(i*4-1 DOWNTO (i-1)*4) := "1000";
        WHEN '9' => tmp(i*4-1 DOWNTO (i-1)*4) := "1001";
        WHEN 'a' | 'A' => tmp(i*4-1 DOWNTO (i-1)*4) := "1010";
        WHEN 'b' | 'B' => tmp(i*4-1 DOWNTO (i-1)*4) := "1011";
        WHEN 'c' | 'C' => tmp(i*4-1 DOWNTO (i-1)*4) := "1100";
        WHEN 'd' | 'D' => tmp(i*4-1 DOWNTO (i-1)*4) := "1101";
        WHEN 'e' | 'E' => tmp(i*4-1 DOWNTO (i-1)*4) := "1110";
        WHEN 'f' | 'F' => tmp(i*4-1 DOWNTO (i-1)*4) := "1111";
        WHEN OTHERS  =>  tmp(i*4-1 DOWNTO (i-1)*4) := "1111";
      END CASE;
    END LOOP;
    RETURN tmp(return_width-1 DOWNTO 0);
  END hex_to_std_logic_vector;

CONSTANT ZERO : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL READ_ADDR_INT : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL READ_ADDR : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL CHECK_READ_ADDR : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL EXPECTED_DATA : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL DO_READ : STD_LOGIC := '0';
SIGNAL CHECK_DATA : STD_LOGIC := '0';
SIGNAL CHECK_DATA_R : STD_LOGIC := '0';
SIGNAL CHECK_DATA_2R : STD_LOGIC := '0';
SIGNAL DO_READ_REG: STD_LOGIC_VECTOR(4 DOWNTO 0) :=(OTHERS => '0');
CONSTANT DEFAULT_DATA  : STD_LOGIC_VECTOR(7 DOWNTO 0):= hex_to_std_logic_vector("0",8);

BEGIN


SYNTH_COE:  IF(C_ROM_SYNTH =0 ) GENERATE

type mem_type is array (255 downto 0) of std_logic_vector(7 downto 0);

  FUNCTION bit_to_sl(input: BIT) RETURN STD_LOGIC IS
    VARIABLE temp_return : STD_LOGIC;
  BEGIN
    IF (input = '0') THEN
      temp_return := '0';
    ELSE
      temp_return := '1';
    END IF;
    RETURN temp_return;
  END bit_to_sl;

     function char_to_std_logic (
      char : in character)
      return std_logic is

      variable data : std_logic;

   begin
      if char = '0' then
         data := '0';

      elsif char = '1' then
         data := '1';

      elsif char = 'X' then
         data := 'X';

      else
         assert false
            report "character which is not '0', '1' or 'X'."
            severity warning;

         data := 'U';
      end if;

      return data;

   end char_to_std_logic;

impure FUNCTION init_memory( C_USE_DEFAULT_DATA : INTEGER;
                       C_LOAD_INIT_FILE : INTEGER ;
					   C_INIT_FILE_NAME : STRING ;
                       DEFAULT_DATA   :  STD_LOGIC_VECTOR(7 DOWNTO 0);
                       width : INTEGER;
                       depth         : INTEGER)
  RETURN mem_type IS
  VARIABLE init_return   : mem_type := (OTHERS => (OTHERS => '0'));
  FILE     init_file     : TEXT;
  VARIABLE mem_vector    : BIT_VECTOR(width-1 DOWNTO 0);
  VARIABLE bitline     : LINE;
  variable bitsgood    : boolean := true;
  variable bitchar     : character;
  VARIABLE i             : INTEGER;
  VARIABLE j             : INTEGER;
  BEGIN

    --Display output message indicating that the behavioral model is being
    --initialized
    ASSERT (NOT (C_USE_DEFAULT_DATA=1 OR C_LOAD_INIT_FILE=1)) REPORT " Block Memory Generator CORE Generator module loading initial data..." SEVERITY NOTE;

    -- Setup the default data
    -- Default data is with respect to write_port_A and may be wider
    -- or narrower than init_return width.  The following loops map
    -- default data into the memory
    IF (C_USE_DEFAULT_DATA=1) THEN
      FOR i IN 0 TO depth-1 LOOP
          init_return(i) := DEFAULT_DATA;
        END LOOP;
    END IF;

    -- Read in the .mif file
    -- The init data is formatted with respect to write port A dimensions.
    -- The init_return vector is formatted with respect to minimum width and
    -- maximum depth; the following loops map the .mif file into the memory
    IF (C_LOAD_INIT_FILE=1) THEN
      file_open(init_file, C_INIT_FILE_NAME, read_mode);
      i := 0;
      WHILE (i < depth AND NOT endfile(init_file)) LOOP
        mem_vector := (OTHERS => '0');
        readline(init_file, bitline);
--        read(file_buffer, mem_vector(file_buffer'LENGTH-1 DOWNTO 0));

        FOR j IN 0 TO width-1 LOOP
		  read(bitline,bitchar,bitsgood);
          init_return(i)(width-1-j) := char_to_std_logic(bitchar);
        END LOOP;
        i := i + 1;
    END LOOP;
      file_close(init_file);
    END IF;
    RETURN init_return;

  END FUNCTION;


  --***************************************************************
  -- convert bit to STD_LOGIC
  --***************************************************************

constant c_init : mem_type := init_memory(0,
                                          0,
										  "no_coe_file_loaded",
                                           DEFAULT_DATA,
                                          8,
                                          256);


constant rom : mem_type := c_init;
BEGIN

 EXPECTED_DATA <= rom(conv_integer(unsigned(check_read_addr)));

  CHECKER_RD_ADDR_GEN_INST:ENTITY work.ADDR_GEN
    GENERIC MAP( C_MAX_DEPTH =>256 )

     PORT MAP(
        CLK => CLK,
     	RST => RST,
   	    EN  => CHECK_DATA_2R,
        LOAD => '0',
     	LOAD_VALUE => ZERO,
    	ADDR_OUT => CHECK_READ_ADDR
       );
 

  PROCESS(CLK)
   BEGIN
     IF(RISING_EDGE(CLK)) THEN
       IF(CHECK_DATA_2R ='1') THEN
    	 IF(EXPECTED_DATA = DATA_IN) THEN
	        STATUS<='0';
    	 ELSE
	        STATUS <= '1';
     	 END IF;
       END IF;
	 END IF;
  END PROCESS;
END GENERATE; 
-- Simulatable ROM 

--Synthesizable ROM
SYNTH_CHECKER: IF(C_ROM_SYNTH = 1) GENERATE
  PROCESS(CLK)
  BEGIN
     IF(RISING_EDGE(CLK)) THEN
	   IF(CHECK_DATA_2R='1') THEN
		 IF(DATA_IN=DEFAULT_DATA) THEN
		   STATUS <= '0';
	     ELSE
		   STATUS <= '1';
		 END IF;
	   END IF;
	 END IF;
  END PROCESS;

END GENERATE;


    READ_ADDR_INT(7 DOWNTO 0) <= READ_ADDR(7 DOWNTO 0);
    ADDRA <= READ_ADDR_INT ;

   CHECK_DATA <= DO_READ;




  RD_ADDR_GEN_INST:ENTITY work.ADDR_GEN
    GENERIC MAP( C_MAX_DEPTH => 256 )

     PORT MAP(
        CLK => CLK,
     	RST => RST,
   	    EN  => DO_READ,
        LOAD => '0',
     	LOAD_VALUE => ZERO,
    	ADDR_OUT => READ_ADDR
       );

RD_PROCESS: PROCESS (CLK)
       BEGIN
     IF (RISING_EDGE(CLK)) THEN
          IF(RST='1') THEN
    	     DO_READ <= '0';
		  ELSE
             DO_READ <= '1';
	    END IF;
	 END IF;
END PROCESS;

  BEGIN_SHIFT_REG: FOR I IN 0 TO 4 GENERATE
  BEGIN
    DFF_RIGHT: IF I=0 GENERATE
     BEGIN
     SHIFT_INST_0: ENTITY work.REGISTER_LOGIC_SROM
        PORT MAP(
                 Q  => DO_READ_REG(0),
                 CLK =>CLK,
                 RST=>RST,
                 D  =>DO_READ
                );
     END GENERATE DFF_RIGHT;
    DFF_OTHERS: IF ((I>0) AND (I<=4)) GENERATE
     BEGIN
       SHIFT_INST: ENTITY work.REGISTER_LOGIC_SROM
         PORT MAP(
                 Q  => DO_READ_REG(I),
                 CLK =>CLK,
                 RST=>RST,
                 D  =>DO_READ_REG(I-1)
                );
      END GENERATE DFF_OTHERS;
   END GENERATE BEGIN_SHIFT_REG;


CHECK_DATA_REG_1: ENTITY work.REGISTER_LOGIC_SROM
        PORT MAP(
                 Q  => CHECK_DATA_2R,
                 CLK =>CLK,
                 RST=>RST,
                 D  =>CHECK_DATA_R
                );

CHECK_DATA_REG: ENTITY work.REGISTER_LOGIC_SROM
        PORT MAP(
                 Q  => CHECK_DATA_R,
                 CLK =>CLK,
                 RST=>RST,
                 D  =>CHECK_DATA
                );






END ARCHITECTURE;


