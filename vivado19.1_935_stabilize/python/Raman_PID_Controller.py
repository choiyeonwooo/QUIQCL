# -*- coding: utf-8 -*-
"""
Created on Fri Sep  4 16:32:25 2020

@author: hp
updates:
1) XADC used: adc output bit changed to 16bit
2) current used as control variable
"""

from email import message
from Arty_S7_v1_01 import ArtyS7
from DDS_Controller import AD9912 as dds
# from ADS8698_v1_00 import ADS8698 as adc
from XADC_v1 import XADC as adc
import time
import numpy as np
import math
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
from pandas import DataFrame
from scipy.optimize import curve_fit


class Raman_PID_Controller():
    def __init__(self, fpga):
        # FPGA connect and dds initialization
        self.fpga = fpga
        self.pid_mode = 0 #default: frequency control
        self.min_freq = 0
        self.max_freq = 500
        self.com = 'COM4'
        self.dds = dds(self.fpga, self.min_freq, self.max_freq)
        # self.adc = adc(self.fpga)
    def write_to_fpga(self, msg):
        self.fpga.send_command(msg)
    
    def read_from_fpga(self):
        print(self.fpga.read_next_message())
    
    ##########################################
    # DDS
    ##########################################
    
    # Start dds state in FPGA (different from power_on, power_on just makes final output on)
    def dds_start(self):
        cmd = 'DDS START'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)
    
    # Stop dds state in FPGA (different from power_down, power_down just makes final output off)    
    def dds_stop(self):
        cmd = 'DDS STOP'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)

    # def dds_read(self, select): #select 0: freq. 1: current 2: phase
    #     cmd = 'READ DDS'
    #     self.fpga.send_command(cmd)
        
    #     self.fpga.send_mod_BTF_int_list() #1_00_addr
    #     bit_pattern_string = ''
    #     adcv = self.fpga.read_next_message()
        
    #     for eachByte in adcv[1]:                                ##vivado에 따로 읽을수 있게 만들어놓은 부분을 구현해서 사용해야함
    #         bit_pattern_string += (format(ord(eachByte), '08b') + ' ')
    #     print("Bit Pattern : " + bit_pattern_string)
 
    #     if adcv[0] != '!':
    #         print('read_adc: Reply is not CMD type:', adcv)
    #         return False

    #     # For Analog output(16bit)
    #     adc_voltage=self.adc_voltage_transform(ord(adcv[1][0]), ord(adcv[1][1]))
    #     # adcv[1][2]: zero padding

    #     # PD Tracking control variable(48bit)    
    #     CVAR_Tracking_raw = (ord(adcv[1][3]) << 40) + (ord(adcv[1][4]) << 32) + (ord(adcv[1][5]) << 24) + (ord(adcv[1][6]) << 16) + (ord(adcv[1][7]) << 8) + (ord(adcv[1][8]))
        
    #     # AOM control variable      
    #     CVAR_AOM_raw = (ord(adcv[1][9]) << 40) + (ord(adcv[1][10]) << 32) + (ord(adcv[1][11]) << 24) + (ord(adcv[1][12]) << 16) + (ord(adcv[1][13]) << 8) + (ord(adcv[1][14]))
    #     # print("ADC_RESULT: ",adc_voltage,"\n") 
    #     data= [adc_voltage, CVAR_Tracking_raw, CVAR_AOM_raw]
    #     # data = self.adc.adc_load_data()

    #     if(self.pid_mode == 0): # output frequency of DDS
    #         CVAR_Tracking = (data[1] * Fs) / ((2 ** CVAR_bit) * (10 ** 6)) #MHz
    #         CVAR_AOM = (data[2] * Fs) / ((2 ** CVAR_bit) * (10 ** 6))
    #     elif(self.pid_mode == 1): # output current of DDS
    #         CVAR_Tracking = 0
    #         # CVAR_Tracking = Iref * ( 72 + 192 * data[1] / 1024)
    #         CVAR_AOM = Iref * ( 72 + 192 * data[2] / 1024)
    #         # CVAR_AOM = data[2]
    #     # elif(self.pid_mode == 2): # output phase of DDS
    #         # CVAR_Tracking
        
    #     return [data[0], CVAR_Tracking, CVAR_AOM]

    def set_frequency(self, freq_in_MHz, ch1, ch2): #48bit
        if (freq_in_MHz < self.min_freq) or (freq_in_MHz > self.max_freq):
            print('Error in set_frequency: frequency should be between' +  str(self.min_freq) + 'and' + str(self.max_freq) + 'MHz')
            raise ValueError(freq_in_MHz)
        
        # self.dds_start()
        cmd = 'WRITE DDS REG'
        cmd_up = 'UPDATE'
         
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list(self.dds.FTW_Hz(freq_in_MHz*1e6), ch1, ch2))
        self.fpga.send_command(cmd)
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', ch1, ch2)) # Update the buffered (mirrored) registers
        self.fpga.send_command(cmd)
        
    def set_current(self, current, ch1, ch2): #10bit
        if (current < 0) or (current > 0x3ff):
            print('Error in set_current: current should be between 0 and 0x3ff')
            raise ValueError(current)
        # real current value is... (1.2 / Rref ) * ( 72 + 192 * current / 1024)
        # self.dds_start()
        cmd = 'WRITE DDS REG'
        cmd_up = 'UPDATE'
        
        # self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list(self.dds.make_header_string(0x040C, 2)+('%04x' % current), ch1, ch2)) 
        #make_9int_list uses 9byte -> first 1byte for data info. last 8byte for data
        #current doesn't require 8byte, so only 2byte + 2byte used and last 4byte filled with zeros.
        self.fpga.send_command(cmd)
    
    def set_phase(self, phase, ch1, ch2): 
        # Convert phase into radian
        phase = (np.pi / 180) * phase
        # Convert phase for DDS
        phase = int(phase * (2**14) / (2 * np.pi))
        
        # self.dds_start()
        cmd = 'WRITE DDS REG'
        cmd_up = 'UPDATE'
        
        #  Phase value: 0000 ~ 3FFF
        if (phase < 0) or (phase > 2**14):
            print('Error in set_phase: phase should be between 0 and 360 (degree).')
            raise ValueError(phase)
            
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_int_list(self.dds.make_header_string(0x01AD, 2)+('%04x' % phase), ch1, ch2)) 
        self.fpga.send_command(cmd)
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', ch1, ch2)) # Update the buffered (mirrored) registers
        self.fpga.send_command(cmd)
        # self.dds_stop()
    
    def power_down(self, ch1, ch2):
        # Digital powerdown
        # self.dds_start()
        cmd = 'WRITE DDS REG'
        cmd_up = 'UPDATE'
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list(self.dds.make_header_string(0x0010, 1)+'91', ch1, ch2))
        self.fpga.send_command(cmd)
        # self.dds_stop()
        print('Power down(%d, %d)' %(ch1, ch2))
     
    def power_up(self, ch1, ch2):
        # Digital powerup
        # self.dds_start()
        cmd = 'WRITE DDS REG'
        cmd_up = 'UPDATE'
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list(self.dds.make_header_string(0x0010, 1)+'90', ch1, ch2))
        self.fpga.send_command(cmd)
        # self.dds_stop()
        print('Power up(%d, %d)' %(ch1, ch2))
    
    ##########################################
    # COMP control
    ##########################################
    
    def comp_start(self):
        cmd = 'COMP START'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)
        
        
    def comp_stop(self):
        cmd = 'COMP STOP'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)    
    
    def set_pid_mode(self, mode):
        # 0: frequency control(patched)
        # 1: current control(patched)
        # 2: phase control(not yet)
        self.pid_mode = mode
        cmd = 'COMP PID MODE'
        cmd_up = 'UPDATE'
        # self.dds_stop()

        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list([mode])
        self.fpga.send_command(cmd)

        # self.dds_start()

        print(cmd)

    def comp_set_K0(self,K0):
        cmd = 'COMPENSATOR K0'
        cmd_up = 'UPDATE'
        code = int(K0)
        message = [code // 65536, (code % 65536) // 256, code % 256] 
        #3byte message(0: 2**15 upper, 1: 2**8~2**15, 2: 0~2**8)
        
        # stop DDS 
        # self.dds_stop()
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(message)
        self.fpga.send_command(cmd)
        
        # DDS update needed since DDS1_update and DDS2_update captures BTF_buffer directly
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', 1, 1)) # Update the buffered (mirrored) registers
        self.fpga.send_command('WRITE DDS REG')
        
        # start DDS
        # self.dds_start()
        
        print(cmd)

    def comp_set_K1(self,K1):
        cmd = 'COMPENSATOR K1'
        cmd_up = 'UPDATE'
        code = int(K1)
        message = [code // 65536, (code % 65536) // 256, code % 256]

        # stop DDS 
        # self.dds_stop()
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(message)
        self.fpga.send_command(cmd)
        
        # DDS update needed since DDS1_update and DDS2_update captures BTF_buffer directly
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', 1, 1)) # Update the buffered (mirrored) registers
        self.fpga.send_command('WRITE DDS REG')
        
        # start DDS
        # self.dds_start()
        
        print(cmd)   
        
    def comp_set_K2(self,K2):
        cmd = 'COMPENSATOR K2'
        cmd_up = 'UPDATE'
        code = int(K2)
        message = [code // 65536, (code % 65536) // 256, code % 256]
        
        # stop DDS
        # self.dds_stop()
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(message)
        self.fpga.send_command(cmd)
        
        # DDS update needed since DDS1_update and DDS2_update captures BTF_buffer directly
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', 1, 1)) # Update the buffered (mirrored) registers
        self.fpga.send_command('WRITE DDS REG')
        
        # start DDS
        # self.dds_start()
     
        print(cmd)
    
    def comp_set(self, P, I, D):
        #discrete PID control
        K0 = P + I + D
        K1 = P - I + 2 * D
        K2 = D
        
        self.comp_set_K0(K0)
        self.comp_set_K1(K1)
        self.comp_set_K2(K2)

    # Setting the setpoint of the comp Controller
    def comp_set_setpoint(self,code):
        cmd = 'COMP SETPOINT'
        cmd_up = 'UPDATE'
        message = [code//65536,(code%65536) // 256, code % 256]
        
        # stop dds
        # self.dds_stop()
        
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(message)
        self.fpga.send_command(cmd)
        
        # DDS update needed since DDS1_update and DDS2_update captures BTF_buffer directly
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(self.dds.make_9int_list('000501', 1, 1)) # Update the buffered (mirrored) registers
        # [W_bar][W1,W0][addr:0x0005][data]='b0_00_0000000000005_00000001
        self.fpga.send_command('WRITE DDS REG')
        
        # start dds
        # self.dds_start()
        print(message)
        print(cmd)    
        
    def const_shoot(self):
        cmd='CONST SHOOT'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)    
    
    ##########################################
    # ADC
    ##########################################
    def adc_start(self):       
        cmd='ADC START'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)

    def adc_stop(self):
        cmd='ADC STOP'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)

    def set_setpoint(self, setpoint):
        #setpoint input: 0~1V
        setpoint_adc = int(setpoint*0xfff)   #12bit: 0x000~0xfff
        if(setpoint < 0 or setpoint > 1): 
            print('Error in setpoint: PD setpoint should be between ' +  str(0) + 'V ' + 'and ' + str(1) + 'V')
            raise ValueError(setpoint)
        else: 
            cmd='ADC SETPOINT'
            cmd_up='UPDATE'
            self.fpga.send_command(cmd_up)
            self.fpga.send_mod_BTF_int_list([setpoint_adc>>4, (setpoint_adc%16)<<4])
            self.fpga.send_command(cmd)
            print(cmd)

    def adc_range_select(self, adc_ch = 0, option = 1):
        ch_cmd=((0x05+adc_ch)<<1)+1
        cmd='ADC RANGE'
        cmd_up = 'UPDATE'
        
        if option==1:
            option_cmd=0
        elif option==2:
            option_cmd=1
        elif option==3:
            option_cmd=2
        elif option==4:
            option_cmd=5
        elif option==5:
            option_cmd=6
                
        message=[ch_cmd, option_cmd]
        self.fpga.send_command(cmd_up)
        self.fpga.send_mod_BTF_int_list(message)
        self.fpga.send_command(cmd)
        print(cmd)
        self.adc_start()    

    def adc_voltage_transform(self,v1,v2): 
        #16bit input, lsb 4bit ignored
        V_max = 0xFFF #{v1[8:0],v2[8:4]}
        voltage = ( (v1 << 4) + (v2 >> 4) ) / V_max 
        return voltage

    # convert raw data from ADC & DDS to usable data
    def adc_load_data(self):
        Fs = 10 ** 9 # Sampling frequency of DDS
        Rref = 10 ** 4 
        Iref = 1.2 / Rref 
        CVAR_bit = 48 # Frequency tuning word uses 48 bit
        cmd_load='LOAD'
        self.fpga.send_command(cmd_load)
        print(cmd_load)
        
        bit_pattern_string = ''
        adcv = self.fpga.read_next_message()
        
        for eachByte in adcv[1]:                                ##vivado에 따로 읽을수 있게 만들어놓은 부분을 구현해서 사용해야함
            bit_pattern_string += (format(ord(eachByte), '08b') + ' ')
        print("Bit Pattern : " + bit_pattern_string)
 
        if adcv[0] != '!':
            print('read_adc: Reply is not CMD type:', adcv)
            return False

        # For Analog output(16bit)
        adc_voltage=self.adc_voltage_transform(ord(adcv[1][0]), ord(adcv[1][1]))
        # adcv[1][2]: zero padding

        # PD Tracking control variable(48bit)    
        CVAR_Tracking_raw = (ord(adcv[1][3]) << 40) + (ord(adcv[1][4]) << 32) + (ord(adcv[1][5]) << 24) + (ord(adcv[1][6]) << 16) + (ord(adcv[1][7]) << 8) + (ord(adcv[1][8]))
        
        # AOM control variable      
        CVAR_AOM_raw = (ord(adcv[1][9]) << 40) + (ord(adcv[1][10]) << 32) + (ord(adcv[1][11]) << 24) + (ord(adcv[1][12]) << 16) + (ord(adcv[1][13]) << 8) + (ord(adcv[1][14]))
        # print("ADC_RESULT: ",adc_voltage,"\n") 
        data= [adc_voltage, CVAR_Tracking_raw, CVAR_AOM_raw]
        # data = self.adc.adc_load_data()

        if(self.pid_mode == 0): # output frequency of DDS
            CVAR_Tracking = (data[1] * Fs) / ((2 ** CVAR_bit) * (10 ** 6)) #MHz
            CVAR_AOM = (data[2] * Fs) / ((2 ** CVAR_bit) * (10 ** 6))
        elif(self.pid_mode == 1): # output current of DDS
            CVAR_Tracking = 0
            # CVAR_Tracking = Iref * ( 72 + 192 * data[1] / 1024)
            CVAR_AOM = Iref * ( 72 + 192 * data[2] / 1024)
            # CVAR_AOM = data[2]
        # elif(self.pid_mode == 2): # output phase of DDS
            # CVAR_Tracking
        
        return [data[0], CVAR_Tracking, CVAR_AOM]
    
    def fit_func(self, x, p1, p2, p3, p4):
        return p1 * np.sin(2 * np.pi * p2 * x + p3) + p4

    def adc_load_large_data_Freq(self):
        N = 100 # large data is array with length 100
        cmd_load='LOAD LARGE'
        self.send_command(cmd_load)
        print(cmd_load)

        adcv = self.read_next_message()

        if adcv[0] != '#':   ##tx_buffer2
            print('read_adc: Reply is not CMD type:', adcv)
            return False
        ex_da=[]
        mo_adcv=[]
        for i in range(len(adcv[1])):
            mo_adcv.append(ord(adcv[1][i]))
        
        mo_adcv=np.array(mo_adcv)      
        large_adcv=mo_adcv.reshape(N,2) # N adc_out is transmitted, each 2byte
        voltage_array = []
        
        for i in range(len(large_adcv)):     
            voltage=self.adc_voltage_transform(large_adcv[i][0], large_adcv[i][1])            
            ex_da.append([i,voltage])
            voltage_array.append(voltage)
        
        data = [ex_da, voltage_array]
        # data = self.adc.adc_load_large_data(N)

        # python plot 
        sampling_freq = 20 * (10 ** 3) # Sampling frequency is 20kHz - alterable in Verilog
        Ts = 1 / sampling_freq # Sampling rate
        xdata = np.linspace(1, N, N) * Ts 
        # voltage_array = 0.05 * np.sin(2 * np.pi * 4000 * xdata) # For test purpose
        
        plt.figure(figsize = (7, 7))
        plt.plot(xdata * (10**3), data[1],'yo', color = 'b', label = 'Read Data from FPGA')
        plt.axis([0, (N * Ts) * (10**3), 2* np.min(data[1]), 2 * np.max(data[1])])
        
        # Fit function
        # Initial guess with fft
        Y = np.fft.fft(data[1])/N
        Y = Y[range(int(N/2))]
        mY = np.abs(Y)
        locY = np.argmax(mY)
        freq_guess = (sampling_freq / N) * locY

        # Fit with initial guess
        popt, pcov = curve_fit(self.fit_func, xdata, data[1], [np.max(data[1]), freq_guess, 0, 0])     
        freq_difference = math.ceil(np.abs(popt[1])) # fitted frequency
        plt.plot(xdata * (10**3), self.fit_func(xdata, popt[0], popt[1], popt[2], popt[3]), color = 'r', label = 'Fitted result, freq = ' + str(freq_difference) + 'Hz')
        plt.title('ADC Data Read')
        plt.xlabel('Time (ms)')
        plt.ylabel('ADC Voltage (V)')
        plt.legend(fontsize = 20)
        plt.legend(loc = 'upper right')
        plt.show()

        #making excel file
        df = DataFrame(data[0],columns=['time', 'voltage'])
        writer=pd.ExcelWriter('pandastest.xlsx',engine='xlsxwriter')#writer instance
        df.to_excel(writer, sheet_name='Sheet1')#write to excel
        
        workbook=writer.book
        worksheet= writer.sheets['Sheet1']
        
        chart=workbook.add_chart({'type':'line'})#choose data
        
        chart.add_series({'values':'=Sheet1!$C$2:$C$101'})
        worksheet.insert_chart('D2',chart)
        chart.set_y_axis({'min': 2 * np.min(data[1]), 'max': 2 * np.max(data[1])})
        writer.close()

        return freq_difference # return fitted frequency

    def adc_load_large_data_Current(self):
        N = 100 # large data is array with length 100
        cmd_load='LOAD LARGE'
        self.send_command(cmd_load)
        print(cmd_load)

        adcv = self.read_next_message()

        if adcv[0] != '#':   ##tx_buffer2
            print('read_adc: Reply is not CMD type:', adcv)
            return False
        ex_da=[]
        mo_adcv=[]
        for i in range(len(adcv[1])):
            mo_adcv.append(ord(adcv[1][i]))
        
        mo_adcv=np.array(mo_adcv)      
        large_adcv=mo_adcv.reshape(N,2) # N adc_out is transmitted, each 2byte
        voltage_array = []
        
        for i in range(len(large_adcv)):     
            voltage=self.adc_voltage_transform(large_adcv[i][0], large_adcv[i][1])            
            ex_da.append([i,voltage])
            voltage_array.append(voltage)
        
        data=[ex_da, voltage_array]
        # data = self.adc.adc_load_large_data(N)

        # python plot 
        sampling_freq = 20 * (10 ** 3) # Sampling frequency is 20kHz - alterable in Verilog
        Ts = 1 / sampling_freq # Sampling rate
        xdata = np.linspace(1, N, N) * Ts 
        # voltage_array = 0.05 * np.sin(2 * np.pi * 4000 * xdata) # For test purpose
        
        plt.figure(figsize = (7, 7))
        plt.plot(xdata * (10**3), data[1],'yo', color = 'b', label = 'Read Data from FPGA')
        plt.axis([0, (N * Ts) * (10**3), 2* np.min(data[1]), 2 * np.max(data[1])])
        
        freq = self.load_large_data_Freq()
        T = 1/freq
        M = int(T/Ts) # number of samples in one cycle
        while(N%M!=0):
            M+=1
        print("number of data in one cycle: %d", M)
        group = data[1].reshape(int(100/M),M)
        peaks=[]
        for i in range(int(100/M)):
            peaks.append(abs(max(group[i],key=abs)))
        amplitude = np.mean(peaks)
        
        return amplitude
        
    ##########################################
    # ETC
    ##########################################
    def const_shoot(self):
        cmd = 'CONST SHOOT'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)
        
    def user_sampling(self): # user defined sampling
        cmd = 'USER SAMPLING' 
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)
        
    def terminate_condition(self): # termnitate const_shoot and user_sampling
        cmd = 'TERM COND'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        print(cmd)
    
    def normal_feedback(self):
        # turn off DDS 
        # self.dds_stop()
        
        cmd = 'NORMAL'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        
        # turn on DDS 
        # self.dds_start()
        print(cmd)
        
    def reverse_feedback(self):
        # turn off DDS 
        # self.dds_stop()
        
        cmd = 'REVERSE'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        
        # turn on DDS 
        # self.dds_start()
        print(cmd)
        
    def single_pass(self):
        # turn off DDS
        # self.dds_stop()
        
        cmd = 'SINGLE PASS'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        
        # turn on DDS
        # self.dds_start()
        print(cmd)
        
    def double_pass(self):
        # turn off DDS
        # self.dds_stop()
        
        cmd = 'DOUBLE PASS'
        cmd_up = 'UPDATE'
        self.fpga.send_command(cmd_up)
        self.fpga.send_command(cmd)
        
        # turn on DDS
        # self.dds_start()
        print(cmd)
        
    def read_freuquency(self):
        cmd_load='LOAD LARGE'
        self.fpga.send_command(cmd_load)
        print(cmd_load)
        
        print(self.fpga.read_next_message())
        
    
if __name__ == '__main__':
    if 'fpga' in vars(): # To close the previously opened device when re-running the script with "F5"
        fpga.close()
    fpga = ArtyS7('COM4') 
    fpga.print_idn()
    
    dna_string = fpga.read_DNA() 
    print('FPGA DNA string:', dna_string)

    pid = Raman_PID_Controller(fpga)    
    
"""
pid.adc_range_select()
pid.set_current(1023, 1, 1)
pid.set_frequency(360.0000, 1, 0) 
pid.set_frequency(143.0000, 0, 1)
pid.reverse_feedback()
pid.user_sampling()

pid.comp_set(50000, 1000, 0)
pid.comp_start()
pid.comp_stop()

pid.comp_set_setpoint(code = 0b100000000000000000)

pid.load_data()
pid.adc_load_large_data()

for i in range(1, 5):
    pid.load_data()
    time.sleep(0.5)

pid.terminate_condition()

pid.power_down(1, 1)
pid.power_up(1, 1)
pid.normal_feedback()

"""    
    
    
    