LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;

ENTITY IRam IS
  PORT (
    pc          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    instruction : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    immediate   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE IRamArch OF IRam IS
  TYPE ram_type IS ARRAY(0 TO 2 ** 20 - 1) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL ram : ram_type;
BEGIN
  instruction <= ram(to_integer(unsigned(pc)));
  immediate   <= ram(to_integer(unsigned(pc) + 1));
END ARCHITECTURE;
