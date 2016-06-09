# this program takes in a text file .sas program, and outputs another sas program with only the macro language from the original

import sys

with open(sys.argv[1],'rb') as infil, open(sys.argv[2],'wb') as outfil:
    num_macros = 0
    for line in infil:
        if line[:6].upper() == '%MACRO':
            num_macros += 1
        if num_macros > 0 or line[:7].upper() == 'LIBNAME' or line[:8].upper() == '%INCLUDE':
            outfil.write(line)
        if line [:5].upper() == '%MEND':
            num_macros -= 1

