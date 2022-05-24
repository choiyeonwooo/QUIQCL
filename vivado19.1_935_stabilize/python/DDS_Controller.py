# -*- coding: utf-8 -*-
"""
Created on Fri Aug 21 16:15:41 2020

@author: Modified by Jiyong Yu (Original work by Taehyun Kim)
"""

# Created for controlling triple DDS Board simultaneously

from Arty_S7_v1_01 import ArtyS7
import numpy as np

class AD9912():
    def __init__(self, fpga, min_freq = 10, max_freq = 400): # change default range if needed
        self.min_freq = min_freq
        self.max_freq = max_freq
        self.fpga = fpga
        
    def make_header_string(self, register_address, bytes_length, direction='W'):
        # this function makes 16bit DDS instruction word in string!

        # DDS instruction word format: 
        # from MSB..
        # [15] W_bar/R
        # [14:13] data_length (00: 1byte, 01: 2byte, 10: 3byte, 11: streaming mode)
        # [12:0] address to write on DDS register
        if direction == 'W':
            MSB = 0
        elif direction == 'R':
            MSB = 1
        else:
            print('Error in make_header: unknown direction (%s). ' % direction, \
                  'direction should be either \'W\' or \'R\'.' )
            raise ValueError()
            
        if type(register_address) == str:
            address = int(register_address, 16)
        elif type(register_address) == int:
            address = register_address
        else:
            print('Error in make_header: unknown register address type (%s). ' % type(register_address), \
                  'register_address should be either hexadecimal string or integer' )
            raise ValueError()
            
        if (bytes_length < 1) or (bytes_length > 8):
            print('Error in make_header: length should be between 1 and 8.' )
            raise ValueError()
        elif bytes_length < 4:
            W1W0 = bytes_length - 1
        else:
            W1W0 = 3
        
        # print(MSB, W1W0, address)
        header_value = (MSB << 15) + (W1W0 << 13) + address
        return ('%04X' % header_value)
            
    
    def FTW_Hz(self, freq):
        # make_header_string('0x01AB', 8)
        FTW_header = "61AB"
        #freq in Hz
        y = int((2**48)*(freq/(10**9))) #FTW: 48bit data in DDS
        z = hex(y)[2:] # hex(): change integer y to hex string
                        # 2^48 ~ 10^14 and freq < 1000nHz -> 2 MSB not used. To match 12 hex bits(=48bit), choose [2:]
        FTW_body = (12-len(z))*"0"+z # 6byte FTW raw_value
        return FTW_header + FTW_body
    
    def make_int_list(self, hex_string, ch1, ch2):
        hex_string_length = len(hex_string)
        byte_length = (hex_string_length // 2)
        if hex_string_length % 2 != 0:
            print('Error in make_int_list: hex_string cannot be odd length')
            raise ValueError()
        
        int_list = [(ch1 << 5) + (ch2 << 4) + byte_length]
        for n in range(byte_length):
            int_list.append(int(hex_string[2*n:2*n+2], 16))
        return int_list

    def make_9int_list(self, hex_string, ch1, ch2):
        #MSB 1byte for 2bit()+2bit(tracking/AOM update select)+4bit(data length)
        #8byte for DDS
        hex_string_length = len(hex_string)
        byte_length = (hex_string_length // 2)
        if hex_string_length % 2 != 0:
            print('Error in make_int_list: hex_string cannot be odd length')
            raise ValueError()
        
        int_list = [(ch1 << 5) + (ch2 << 4) + byte_length]
        for n in range(byte_length):
            int_list.append(int(hex_string[2*n:2*n+2], 16))
        for n in range(8-byte_length):
            int_list.append(0)
        # [{ch1, ch2, byte_length},hex_string[0:2], hex_string[2:4], ...(,0,0,..)] -> 9byte is enough
        #print(int_list)
        return int_list
    
    def board_select(self, board_select):
        # Board selection among triple DDS board
        self.fpga.send_command('Board' + str(board_select) + ' Select')

    def set_frequency(self, freq_in_MHz, ch1, ch2):
        if (freq_in_MHz < self.min_freq) or (freq_in_MHz > self.max_freq):
            print('Error in set_frequency: frequency should be between' +  str(self.min_freq) + 'and' + str(self.max_freq) + 'MHz')
            raise ValueError(freq_in_MHz)
        
            
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.FTW_Hz(freq_in_MHz*1e6), ch1, ch2))
        self.fpga.send_command('WRITE DDS REG')
        self.fpga.send_mod_BTF_int_list(self.make_9int_list('000501', ch1, ch2)) # Update the buffered (mirrored) registers
        self.fpga.send_command('WRITE DDS REG')


    def set_current(self, current, ch1, ch2):
        # DAC full-scale current
        # 1020 mVp-p (264*I_DAC_REF) => 670 mVp-p w/ FDB_IN
        #  270 mVp-p  (72*I_DAC_REF) => 180 mVp-p w/ FDB_IN
        if (current < 0) or (current > 0x3ff):
            print('Error in set_current: current should be between 0 and 0x3ff')
            raise ValueError(current)
    
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0x040C, 2)+('%04x' % current), ch1, ch2)) 
        self.fpga.send_command('WRITE DDS REG')
    
    
    def soft_reset(self, ch1, ch2):
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0, 1)+'3C', ch1, ch2))
        self.fpga.send_command('WRITE DDS REG')
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0, 1)+'18', ch1, ch2))
        self.fpga.send_command('WRITE DDS REG')
        
    def set_phase(self, phase, ch1, ch2):
        # Convert phase into radian
        phase = (np.pi / 180) * phase
        # Convert phase for DDS
        phase = int(phase * (2**14) / (2 * np.pi))
        
        #  Phase value: 0000 ~ 3FFF
        if (phase < 0) or (phase > 2**14):
            print('Error in set_phase: phase should be between 0 and 360 (degree).')
            raise ValueError(phase)
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0x01AD, 2)+('%04x' % phase), ch1, ch2)) 
        self.fpga.send_command('WRITE DDS REG')
        self.fpga.send_mod_BTF_int_list(self.make_9int_list('000501', ch1, ch2)) # Update the buffered (mirrored) registers
        self.fpga.send_command('WRITE DDS REG')

    def power_down(self, ch1, ch2):
        # Digital powerdown
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0x0010, 1)+'91', ch1, ch2))
        self.fpga.send_command('WRITE DDS REG')

    def power_up(self, ch1, ch2):
        # Digital power-up. We don't turn on the ch2 HSTL trigger automatically
        self.fpga.send_mod_BTF_int_list(self.make_9int_list(self.make_header_string(0x0010, 1)+'90', ch1, ch2))
        self.fpga.send_command('WRITE DDS REG')
        
    
if __name__ == '__main__':
    if 'fpga' in vars(): # To close the previously opened device when re-running the script with "F5"
        fpga.close()
    fpga = ArtyS7('COM10') 
    fpga.print_idn()
    
    dna_string = fpga.read_DNA()
    print('FPGA DNA string:', dna_string)

    dds = AD9912(fpga, 10, 400)

"""
    dac.set_ch123(0, 5)
    dds.set_frequency(10, 1, 1)
    fpga.close()
"""