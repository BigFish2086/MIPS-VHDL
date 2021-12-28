#!/usr/bin/env python3

import sys

TMPL = '''
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY {0} IS
  PORT (
    clk : IN STD_LOGIC;
    fsh : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
{1}
  );
END ENTITY;

ARCHITECTURE {0}_arc OF {0} IS
BEGIN
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF fsh = "1" THEN
{2}
      ELSE
{3}
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;
'''

PORT_ARG_TMPL = '{0}_in : IN STD_LOGIC_VECTOR( {1}  DOWNTO 0);\n' + \
                '{0}_out : OUT STD_LOGIC_VECTOR( {1}  DOWNTO 0)'

input_file_name = sys.argv[1]
output_file_name_no_ext = input_file_name.split('.')[0]

port_args = []
flush_body = []
proc_body = []
with open(input_file_name) as file:
  lines = [line.strip().replace(' ', '').split(';')[0].split('#')[0].split(':')
           for line in file.readlines()]
  lines = [line for line in lines if line[0].strip()]
  for line in lines:
    port_name, bit_count = line if len(line) > 1 else (line[0], '1')
    port_args.append(PORT_ARG_TMPL.format(port_name, int(bit_count)-1))
    flush_body.append('{0}_out <= "{1}";'.format(port_name, int(bit_count) * '0'))
    proc_body.append('{0}_out <= {0}_in;'.format(port_name))

with open(output_file_name_no_ext + '.vhd', 'w') as file:
  file.write(TMPL.format(output_file_name_no_ext,
                         ';\n'.join(port_args),
                         '\n'.join(flush_body),
                         '\n'.join(proc_body)))
    