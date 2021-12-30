LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY MemoryStage IS
  PORT (
    clk                  : IN STD_LOGIC;
    rst                  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    wrt_data, addr       : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    mr, mw, ps_pp, pc_op : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    func                 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    pc   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    flgs : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    wb_data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

    set_pc, set_flgs : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    new_pc           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    new_flgs         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    ex2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE MemoryStageArch OF MemoryStage IS
  SIGNAL stack_reg                          : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00010000";
  SIGNAL adr                                : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mw_adr0, mw_adr1, mr_adr0, mr_adr1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
  ram : ENTITY work.ram PORT MAP (clk, adr, mw, pc_op, mw_adr0, mw_adr1, mr_adr0, mr_adr1);

  -- the data out of the memory, this might be just the result of the alu op.
  WITH mr SELECT
    wb_data <=
    mr_adr0 WHEN "1",
    wrt_data WHEN OTHERS;

  -- the address to work with in the ram.
  WITH ps_pp & mr & mw SELECT
  adr <=
    -- when writing to the memory using the stack,
    -- you should write at address that is one block higher.
    STD_LOGIC_VECTOR(UNSIGNED(stack_reg) - 1) WHEN "101",
    -- reading is normal, we read from the same block.
    stack_reg WHEN "110",
    -- that's for immediate addressing.
    "0000000000000000" & addr WHEN OTHERS;

  -- lower 16-bit of memory write data.
  WITH pc_op SELECT
    mw_adr0 <=
    pc(15 DOWNTO 0) WHEN "1",
    wrt_data WHEN OTHERS;

  -- the upper 16-bit of memory write data.
  mw_adr1 <= flgs & pc(28 DOWNTO 16);

  -- when to set the set_pc flag, the new_pc should be returned to the fetch stage.
  WITH pc_op & mr SELECT
  set_pc <=
    "1" WHEN "11",
    "0" WHEN OTHERS;

  -- when to set the set_flgs flag, the new_flgs should be returned to the alu.
  WITH pc_op & mr & func SELECT
  -- func code of rti is 000.
  set_flgs <=
    "1" WHEN "11000",
    "0" WHEN OTHERS;

  -- the new_pc in case of ret/rti.
  new_pc <= "000" & mr_adr0(12 DOWNTO 0) & mr_adr1;

  -- the new_flgs in case or rti.
  new_flgs <= mr_adr0(15 DOWNTO 13);

  -- stack pointer things.
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- fire ex2 if we need.
      IF stack_reg > x"00010000" THEN
        ex2 <= "1";
      END IF;
      -- reset the stack.
      IF rst = "1" THEN
        stack_reg <= x"00010000";
        ex2       <= "0";
      END IF;

      IF ps_pp = "1" THEN
        IF mr = "1" THEN
          IF pc_op = "1" THEN
            stack_reg <= STD_LOGIC_VECTOR(UNSIGNED(stack_reg) + 2);
          ELSE
            stack_reg <= STD_LOGIC_VECTOR(UNSIGNED(stack_reg) + 1);
          END IF;
        ELSIF mw = "1" THEN
          IF pc_op = "1" THEN
            stack_reg <= STD_LOGIC_VECTOR(UNSIGNED(stack_reg) - 2);
          ELSE
            stack_reg <= STD_LOGIC_VECTOR(UNSIGNED(stack_reg) - 1);
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;
