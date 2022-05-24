# -*- coding: utf-8 -*-
"""
Created 2020-08-27

@author: Modified by Jiyong Yu (Original Work by Taehyun Kim)

"""
from __future__ import unicode_literals
import os, sys
filename = os.path.abspath(__file__)
dirname = os.path.dirname(filename)

new_path_list = []
new_path_list.append(dirname + '\\ui_resources') # For resources_rc.py
# More paths can be added here...
for each_path in new_path_list:
    if not (each_path in sys.path):
        sys.path.append(each_path)

import ImportForSpyderAndQt5
from TripleBoard_AD9912 import AD9912
from Arty_S7_v1_01 import ArtyS7

from PyQt5 import uic
qt_designer_file = dirname + '\\TripleBoard_AD9912.ui'
Ui_QDialog, QtBaseClass = uic.loadUiType(qt_designer_file)
ICON_ON = ":/icons/Toggle_Switch_ON_64x34.png"
ICON_OFF = ":/icons/Toggle_Switch_OFF_64x34.png"

from PyQt5 import QtWidgets, QtGui, QtCore
from PyQt5.QtWidgets import QMessageBox

import socket
from shutil import copyfile
import configparser
from code_editor.code_editor_v2_00 import TextEditor

class TripleBoard_AD9912(QtWidgets.QDialog, Ui_QDialog):
    
    def __init__(self, parent=None, connection_callback=None, fpga=None):
        
        # FPGA connect and dds initialization
        if fpga is None:
            self.fpga = ArtyS7('COM10') # Main Experiment Server 
            self.fpga.print_idn()
            dna_string = self.fpga.read_DNA()
            print('FPGA DNA string:', dna_string)
        else:
            self.fpga = fpga
        
        min_freq = 0;
        max_freq = 400;
        self.dds = AD9912(self.fpga, min_freq, max_freq)
        
        # initial power off
#        self.dds.board_select(1)
#        self.dds.power_down(1, 1)
#        self.dds.board_select(2)
#        self.dds.power_down(1, 1)
#        self.dds.board_select(3)
#        self.dds.power_down(1, 1)
        
        # GUI initialization
        QtWidgets.QDialog.__init__(self, parent)
        self.setupUi(self)
        self.initUi()

        self.on_pixmap = QtGui.QPixmap(ICON_ON)
        self.on_icon = QtGui.QIcon(self.on_pixmap)

        self.off_pixmap = QtGui.QPixmap(ICON_OFF)
        self.off_icon = QtGui.QIcon(self.off_pixmap)
        
        # configuration setting
        self.config_editor = TextEditor(window_title = 'Config editor')
        config_dir = dirname + '\\config'
        self.config_filename = '%s\\%s.ini' % (config_dir, socket.gethostname())
        self.config_file_label.setText(self.config_filename)
        if not os.path.exists(self.config_filename):
            copyfile('%s\\default.ini' % config_dir, self.config_filename)
        self.reload_config()
        
    
    def initUi(self):
        # configuration
        self.reload_config_button.clicked.connect(self.reload_config)
        self.edit_config_button.clicked.connect(self.edit_config)
        self.save_config_button.clicked.connect(self.save_config)
        
        # Board1
        # DDS1
        self.Board1_DDS1_output_on = False
        
        self.Board1_DDS1_freq_spinbox.valueChanged.connect(self.Board1_DDS1_freq_apply)
        self.Board1_DDS1_power_spinbox.valueChanged.connect(self.Board1_DDS1_power_apply)
        self.Board1_DDS1_phase_spinbox.valueChanged.connect(self.Board1_DDS1_phase_apply)
        
        self.Board1_DDS1_freq_step_size.textChanged.connect(self.Board1_DDS1_freq_step_size_update)
        self.Board1_DDS1_power_step_size.textChanged.connect(self.Board1_DDS1_power_step_size_update)
        self.Board1_DDS1_phase_step_size.textChanged.connect(self.Board1_DDS1_phase_step_size_update)
        
        self.Board1_DDS1_output_button.clicked.connect(self.Board1_DDS1_output_on_off)
        
        # DDS2
        self.Board1_DDS2_output_on = False
        
        self.Board1_DDS2_freq_spinbox.valueChanged.connect(self.Board1_DDS2_freq_apply)
        self.Board1_DDS2_power_spinbox.valueChanged.connect(self.Board1_DDS2_power_apply)
        self.Board1_DDS2_phase_spinbox.valueChanged.connect(self.Board1_DDS2_phase_apply)
        
        self.Board1_DDS2_freq_step_size.textChanged.connect(self.Board1_DDS2_freq_step_size_update)
        self.Board1_DDS2_power_step_size.textChanged.connect(self.Board1_DDS2_power_step_size_update)
        self.Board1_DDS2_phase_step_size.textChanged.connect(self.Board1_DDS2_phase_step_size_update)
        
        self.Board1_DDS2_output_button.clicked.connect(self.Board1_DDS2_output_on_off)
        
        # Board2
        # DDS1
        self.Board2_DDS1_output_on = False
        
        self.Board2_DDS1_freq_spinbox.valueChanged.connect(self.Board2_DDS1_freq_apply)
        self.Board2_DDS1_power_spinbox.valueChanged.connect(self.Board2_DDS1_power_apply)
        self.Board2_DDS1_phase_spinbox.valueChanged.connect(self.Board2_DDS1_phase_apply)
        
        self.Board2_DDS1_freq_step_size.textChanged.connect(self.Board2_DDS1_freq_step_size_update)
        self.Board2_DDS1_power_step_size.textChanged.connect(self.Board2_DDS1_power_step_size_update)
        self.Board2_DDS1_phase_step_size.textChanged.connect(self.Board2_DDS1_phase_step_size_update)
        
        self.Board2_DDS1_output_button.clicked.connect(self.Board2_DDS1_output_on_off)
        
        # DDS2
        self.Board2_DDS2_output_on = False
        
        self.Board2_DDS2_freq_spinbox.valueChanged.connect(self.Board2_DDS2_freq_apply)
        self.Board2_DDS2_power_spinbox.valueChanged.connect(self.Board2_DDS2_power_apply)
        self.Board2_DDS2_phase_spinbox.valueChanged.connect(self.Board2_DDS2_phase_apply)
        
        self.Board2_DDS2_freq_step_size.textChanged.connect(self.Board2_DDS2_freq_step_size_update)
        self.Board2_DDS2_power_step_size.textChanged.connect(self.Board2_DDS2_power_step_size_update)
        self.Board2_DDS2_phase_step_size.textChanged.connect(self.Board2_DDS2_phase_step_size_update)
        
        self.Board2_DDS2_output_button.clicked.connect(self.Board2_DDS2_output_on_off)
        
        # Board3
        # DDS1
        self.Board3_DDS1_output_on = False
        
        self.Board3_DDS1_freq_spinbox.valueChanged.connect(self.Board3_DDS1_freq_apply)
        self.Board3_DDS1_power_spinbox.valueChanged.connect(self.Board3_DDS1_power_apply)
        self.Board3_DDS1_phase_spinbox.valueChanged.connect(self.Board3_DDS1_phase_apply)
        
        self.Board3_DDS1_freq_step_size.textChanged.connect(self.Board3_DDS1_freq_step_size_update)
        self.Board3_DDS1_power_step_size.textChanged.connect(self.Board3_DDS1_power_step_size_update)
        self.Board3_DDS1_phase_step_size.textChanged.connect(self.Board3_DDS1_phase_step_size_update)
        
        self.Board3_DDS1_output_button.clicked.connect(self.Board3_DDS1_output_on_off)
        
        # DDS2
        self.Board3_DDS2_output_on = False
        
        self.Board3_DDS2_freq_spinbox.valueChanged.connect(self.Board3_DDS2_freq_apply)
        self.Board3_DDS2_power_spinbox.valueChanged.connect(self.Board3_DDS2_power_apply)
        self.Board3_DDS2_phase_spinbox.valueChanged.connect(self.Board3_DDS2_phase_apply)
        
        self.Board3_DDS2_freq_step_size.textChanged.connect(self.Board3_DDS2_freq_step_size_update)
        self.Board3_DDS2_power_step_size.textChanged.connect(self.Board3_DDS2_power_step_size_update)
        self.Board3_DDS2_phase_step_size.textChanged.connect(self.Board3_DDS2_phase_step_size_update)
        
        self.Board3_DDS2_output_button.clicked.connect(self.Board3_DDS2_output_on_off)
        
        # Manual apply
        self.Board1_DDS1_manual_apply_button.clicked.connect(self.Board1_DDS1_manual_apply)
        self.Board1_DDS2_manual_apply_button.clicked.connect(self.Board1_DDS2_manual_apply)
        self.Board2_DDS1_manual_apply_button.clicked.connect(self.Board2_DDS1_manual_apply)
        self.Board2_DDS2_manual_apply_button.clicked.connect(self.Board2_DDS2_manual_apply)
        self.Board3_DDS1_manual_apply_button.clicked.connect(self.Board3_DDS1_manual_apply)
        self.Board3_DDS2_manual_apply_button.clicked.connect(self.Board3_DDS2_manual_apply)

    def reload_config(self):
        self.config = configparser.ConfigParser()
        self.config.read(self.config_filename)
        
        # Auto apply configuration
        self.Board1_DDS1_auto_apply_checkbox.setChecked(self.config['Board1_DDS1']['auto_apply'] == 'True')
        self.Board1_DDS2_auto_apply_checkbox.setChecked(self.config['Board1_DDS2']['auto_apply'] == 'True')
        self.Board2_DDS1_auto_apply_checkbox.setChecked(self.config['Board2_DDS1']['auto_apply'] == 'True')
        self.Board2_DDS2_auto_apply_checkbox.setChecked(self.config['Board2_DDS2']['auto_apply'] == 'True')
        self.Board3_DDS1_auto_apply_checkbox.setChecked(self.config['Board3_DDS1']['auto_apply'] == 'True')
        self.Board3_DDS2_auto_apply_checkbox.setChecked(self.config['Board3_DDS2']['auto_apply'] == 'True')
        
        # Frequency configuration
        self.Board1_DDS1_freq_spinbox.setValue(float(self.config['Board1_DDS1']['freq_last_used']))
        self.Board1_DDS2_freq_spinbox.setValue(float(self.config['Board1_DDS2']['freq_last_used']))
        self.Board2_DDS1_freq_spinbox.setValue(float(self.config['Board2_DDS1']['freq_last_used']))
        self.Board2_DDS2_freq_spinbox.setValue(float(self.config['Board2_DDS2']['freq_last_used']))
        self.Board3_DDS1_freq_spinbox.setValue(float(self.config['Board3_DDS1']['freq_last_used']))
        self.Board3_DDS2_freq_spinbox.setValue(float(self.config['Board3_DDS2']['freq_last_used']))
        
        self.Board1_DDS1_freq_step_size.setText(self.config['Board1_DDS1']['freq_step_last_used'])
        self.Board1_DDS2_freq_step_size.setText(self.config['Board1_DDS2']['freq_step_last_used'])
        self.Board2_DDS1_freq_step_size.setText(self.config['Board2_DDS1']['freq_step_last_used'])
        self.Board2_DDS2_freq_step_size.setText(self.config['Board2_DDS2']['freq_step_last_used'])
        self.Board3_DDS1_freq_step_size.setText(self.config['Board3_DDS1']['freq_step_last_used'])
        self.Board3_DDS2_freq_step_size.setText(self.config['Board3_DDS2']['freq_step_last_used'])

        # Power configuration
        self.Board1_DDS1_power_spinbox.setValue(int(self.config['Board1_DDS1']['power_last_used']))
        self.Board1_DDS2_power_spinbox.setValue(int(self.config['Board1_DDS2']['power_last_used']))
        self.Board2_DDS1_power_spinbox.setValue(int(self.config['Board2_DDS1']['power_last_used']))
        self.Board2_DDS2_power_spinbox.setValue(int(self.config['Board2_DDS2']['power_last_used']))
        self.Board3_DDS1_power_spinbox.setValue(int(self.config['Board3_DDS1']['power_last_used']))
        self.Board3_DDS2_power_spinbox.setValue(int(self.config['Board3_DDS2']['power_last_used']))
        
        self.Board1_DDS1_power_step_size.setText(self.config['Board1_DDS1']['power_step_last_used'])
        self.Board1_DDS2_power_step_size.setText(self.config['Board1_DDS2']['power_step_last_used'])
        self.Board2_DDS1_power_step_size.setText(self.config['Board2_DDS1']['power_step_last_used'])
        self.Board2_DDS2_power_step_size.setText(self.config['Board2_DDS2']['power_step_last_used'])
        self.Board3_DDS1_power_step_size.setText(self.config['Board3_DDS1']['power_step_last_used'])
        self.Board3_DDS2_power_step_size.setText(self.config['Board3_DDS2']['power_step_last_used'])
        
        # Phase configuration
        self.Board1_DDS1_phase_spinbox.setValue(float(self.config['Board1_DDS1']['phase_last_used']))
        self.Board1_DDS2_phase_spinbox.setValue(float(self.config['Board1_DDS2']['phase_last_used']))
        self.Board2_DDS1_phase_spinbox.setValue(float(self.config['Board2_DDS1']['phase_last_used']))
        self.Board2_DDS2_phase_spinbox.setValue(float(self.config['Board2_DDS2']['phase_last_used']))
        self.Board3_DDS1_phase_spinbox.setValue(float(self.config['Board3_DDS1']['phase_last_used']))
        self.Board3_DDS2_phase_spinbox.setValue(float(self.config['Board3_DDS2']['phase_last_used']))
        
        self.Board1_DDS1_phase_step_size.setText(self.config['Board1_DDS1']['phase_step_last_used'])
        self.Board1_DDS2_phase_step_size.setText(self.config['Board1_DDS2']['phase_step_last_used'])
        self.Board2_DDS1_phase_step_size.setText(self.config['Board2_DDS1']['phase_step_last_used'])
        self.Board2_DDS2_phase_step_size.setText(self.config['Board2_DDS2']['phase_step_last_used'])
        self.Board3_DDS1_phase_step_size.setText(self.config['Board3_DDS1']['phase_step_last_used'])
        self.Board3_DDS2_phase_step_size.setText(self.config['Board3_DDS2']['phase_step_last_used'])
        
        # Purpose configuration
        self.Board1_DDS1_purpose.setText(self.config['Board1_DDS1']['purpose'])
        self.Board1_DDS2_purpose.setText(self.config['Board1_DDS2']['purpose'])
        self.Board2_DDS1_purpose.setText(self.config['Board2_DDS1']['purpose'])
        self.Board2_DDS2_purpose.setText(self.config['Board2_DDS2']['purpose'])
        self.Board3_DDS1_purpose.setText(self.config['Board3_DDS1']['purpose'])
        self.Board3_DDS2_purpose.setText(self.config['Board3_DDS2']['purpose'])
                
    def edit_config(self):
        self.config_editor.show()
        self.config_editor.open_document_by_external(self.config_filename)

    def config_changed(self):
        self.config = configparser.ConfigParser()
        self.config.read(self.config_filename)
        
        # Auto apply configuration
        if self.Board1_DDS1_auto_apply_checkbox.isChecked() != (self.config['Board1_DDS1']['auto_apply'] == 'True'):
            return True
        if self.Board1_DDS2_auto_apply_checkbox.isChecked() != (self.config['Board1_DDS2']['auto_apply'] == 'True'):
            return True
        if self.Board2_DDS1_auto_apply_checkbox.isChecked() != (self.config['Board2_DDS1']['auto_apply'] == 'True'):
            return True
        if self.Board2_DDS2_auto_apply_checkbox.isChecked() != (self.config['Board2_DDS2']['auto_apply'] == 'True'):
            return True
        if self.Board3_DDS1_auto_apply_checkbox.isChecked() != (self.config['Board3_DDS1']['auto_apply'] == 'True'):
            return True
        if self.Board3_DDS2_auto_apply_checkbox.isChecked() != (self.config['Board3_DDS2']['auto_apply'] == 'True'):
            return True
        
        # Frequency configuration
        if self.Board1_DDS1_freq_spinbox.value() != float(self.config['Board1_DDS1']['freq_last_used']):
            return True
        if self.Board1_DDS2_freq_spinbox.value() != float(self.config['Board1_DDS2']['freq_last_used']):
            return True
        if self.Board2_DDS1_freq_spinbox.value() != float(self.config['Board2_DDS1']['freq_last_used']):
            return True
        if self.Board2_DDS2_freq_spinbox.value() != float(self.config['Board2_DDS2']['freq_last_used']):
            return True
        if self.Board3_DDS1_freq_spinbox.value() != float(self.config['Board3_DDS1']['freq_last_used']):
            return True
        if self.Board3_DDS2_freq_spinbox.value() != float(self.config['Board3_DDS2']['freq_last_used']):
            return True
        
        if self.Board1_DDS1_freq_step_size.text() != self.config['Board1_DDS1']['freq_step_last_used']:
            return True
        if self.Board1_DDS2_freq_step_size.text() != self.config['Board1_DDS2']['freq_step_last_used']:
            return True
        if self.Board2_DDS1_freq_step_size.text() != self.config['Board2_DDS1']['freq_step_last_used']:
            return True
        if self.Board2_DDS2_freq_step_size.text() != self.config['Board2_DDS2']['freq_step_last_used']:
            return True
        if self.Board3_DDS1_freq_step_size.text() != self.config['Board3_DDS1']['freq_step_last_used']:
            return True
        if self.Board3_DDS2_freq_step_size.text() != self.config['Board3_DDS2']['freq_step_last_used']:
            return True
        
        # Power configuration
        if self.Board1_DDS1_power_spinbox.value() != int(self.config['Board1_DDS1']['power_last_used']):
            return True
        if self.Board1_DDS2_power_spinbox.value() != int(self.config['Board1_DDS2']['power_last_used']):
            return True
        if self.Board2_DDS1_power_spinbox.value() != int(self.config['Board2_DDS1']['power_last_used']):
            return True
        if self.Board2_DDS2_power_spinbox.value() != int(self.config['Board2_DDS2']['power_last_used']):
            return True
        if self.Board3_DDS1_power_spinbox.value() != int(self.config['Board3_DDS1']['power_last_used']):
            return True
        if self.Board3_DDS2_power_spinbox.value() != int(self.config['Board3_DDS2']['power_last_used']):
            return True
        
        if self.Board1_DDS1_power_step_size.text() != self.config['Board1_DDS1']['power_step_last_used']:
            return True
        if self.Board1_DDS2_power_step_size.text() != self.config['Board1_DDS2']['power_step_last_used']:
            return True
        if self.Board2_DDS1_power_step_size.text() != self.config['Board2_DDS1']['power_step_last_used']:
            return True
        if self.Board2_DDS2_power_step_size.text() != self.config['Board2_DDS2']['power_step_last_used']:
            return True
        if self.Board3_DDS1_power_step_size.text() != self.config['Board3_DDS1']['power_step_last_used']:
            return True
        if self.Board3_DDS2_power_step_size.text() != self.config['Board3_DDS2']['power_step_last_used']:
            return True
        
        # Phase configuration
        if self.Board1_DDS1_phase_spinbox.value() != float(self.config['Board1_DDS1']['phase_last_used']):
            return True
        if self.Board1_DDS2_phase_spinbox.value() != float(self.config['Board1_DDS2']['phase_last_used']):
            return True
        if self.Board2_DDS1_phase_spinbox.value() != float(self.config['Board2_DDS1']['phase_last_used']):
            return True
        if self.Board2_DDS2_phase_spinbox.value() != float(self.config['Board2_DDS2']['phase_last_used']):
            return True
        if self.Board3_DDS1_phase_spinbox.value() != float(self.config['Board3_DDS1']['phase_last_used']):
            return True
        if self.Board3_DDS2_phase_spinbox.value() != float(self.config['Board3_DDS2']['phase_last_used']):
            return True
        
        if self.Board1_DDS1_phase_step_size.text() != self.config['Board1_DDS1']['phase_step_last_used']:
            return True
        if self.Board1_DDS2_phase_step_size.text() != self.config['Board1_DDS2']['phase_step_last_used']:
            return True
        if self.Board2_DDS1_phase_step_size.text() != self.config['Board2_DDS1']['phase_step_last_used']:
            return True
        if self.Board2_DDS2_phase_step_size.text() != self.config['Board2_DDS2']['phase_step_last_used']:
            return True
        if self.Board3_DDS1_phase_step_size.text() != self.config['Board3_DDS1']['phase_step_last_used']:
            return True
        if self.Board3_DDS2_phase_step_size.text() != self.config['Board3_DDS2']['phase_step_last_used']:
            return True
        
        # Purpose configuration
        if self.Board1_DDS1_purpose.text() != self.config['Board1_DDS1']['purpose']:
            return True
        if self.Board1_DDS2_purpose.text() != self.config['Board1_DDS2']['purpose']:
            return True
        if self.Board2_DDS1_purpose.text() != self.config['Board2_DDS1']['purpose']:
            return True
        if self.Board2_DDS2_purpose.text() != self.config['Board2_DDS2']['purpose']:
            return True
        if self.Board3_DDS1_purpose.text() != self.config['Board3_DDS1']['purpose']:
            return True
        if self.Board3_DDS2_purpose.text() != self.config['Board3_DDS2']['purpose']:
            return True
        
        return False

    
    def save_config(self):
        self.config = configparser.ConfigParser()
        self.config.read(self.config_filename)
        
        # Auto aply configuraiton
        self.config['Board1_DDS1']['auto_apply'] = str(self.Board1_DDS1_auto_apply_checkbox.isChecked())
        self.config['Board1_DDS2']['auto_apply'] = str(self.Board1_DDS2_auto_apply_checkbox.isChecked())
        self.config['Board2_DDS1']['auto_apply'] = str(self.Board2_DDS1_auto_apply_checkbox.isChecked())
        self.config['Board2_DDS2']['auto_apply'] = str(self.Board2_DDS2_auto_apply_checkbox.isChecked())
        self.config['Board3_DDS1']['auto_apply'] = str(self.Board3_DDS1_auto_apply_checkbox.isChecked())
        self.config['Board3_DDS2']['auto_apply'] = str(self.Board3_DDS2_auto_apply_checkbox.isChecked())
        
        # Frequency configuration
        self.config['Board1_DDS1']['freq_last_used'] = str(self.Board1_DDS1_freq_spinbox.value())
        self.config['Board1_DDS2']['freq_last_used'] = str(self.Board1_DDS2_freq_spinbox.value())
        self.config['Board2_DDS1']['freq_last_used'] = str(self.Board2_DDS1_freq_spinbox.value())
        self.config['Board2_DDS2']['freq_last_used'] = str(self.Board2_DDS2_freq_spinbox.value())
        self.config['Board3_DDS1']['freq_last_used'] = str(self.Board3_DDS1_freq_spinbox.value())
        self.config['Board3_DDS2']['freq_last_used'] = str(self.Board3_DDS2_freq_spinbox.value())
        
        self.config['Board1_DDS1']['freq_step_last_used'] = self.Board1_DDS1_freq_step_size.text()
        self.config['Board1_DDS2']['freq_step_last_used'] = self.Board1_DDS2_freq_step_size.text()
        self.config['Board2_DDS1']['freq_step_last_used'] = self.Board2_DDS1_freq_step_size.text()
        self.config['Board2_DDS2']['freq_step_last_used'] = self.Board2_DDS2_freq_step_size.text()
        self.config['Board3_DDS1']['freq_step_last_used'] = self.Board3_DDS1_freq_step_size.text()
        self.config['Board3_DDS2']['freq_step_last_used'] = self.Board3_DDS2_freq_step_size.text()

        # Power configuration
        self.config['Board1_DDS1']['power_last_used'] = str(int(self.Board1_DDS1_power_spinbox.value()))
        self.config['Board1_DDS2']['power_last_used'] = str(int(self.Board1_DDS2_power_spinbox.value()))
        self.config['Board2_DDS1']['power_last_used'] = str(int(self.Board2_DDS1_power_spinbox.value()))
        self.config['Board2_DDS2']['power_last_used'] = str(int(self.Board2_DDS2_power_spinbox.value()))
        self.config['Board3_DDS1']['power_last_used'] = str(int(self.Board3_DDS1_power_spinbox.value()))
        self.config['Board3_DDS2']['power_last_used'] = str(int(self.Board3_DDS2_power_spinbox.value()))
        
        self.config['Board1_DDS1']['power_step_last_used'] = self.Board1_DDS1_power_step_size.text()
        self.config['Board1_DDS2']['power_step_last_used'] = self.Board1_DDS2_power_step_size.text()
        self.config['Board2_DDS1']['power_step_last_used'] = self.Board2_DDS1_power_step_size.text()
        self.config['Board2_DDS2']['power_step_last_used'] = self.Board2_DDS2_power_step_size.text()
        self.config['Board3_DDS1']['power_step_last_used'] = self.Board3_DDS1_power_step_size.text()
        self.config['Board3_DDS2']['power_step_last_used'] = self.Board3_DDS2_power_step_size.text()
        
        # Phase configuration
        self.config['Board1_DDS1']['phase_last_used'] = str(self.Board1_DDS1_phase_spinbox.value())
        self.config['Board1_DDS2']['phase_last_used'] = str(self.Board1_DDS2_phase_spinbox.value())
        self.config['Board2_DDS1']['phase_last_used'] = str(self.Board2_DDS1_phase_spinbox.value())
        self.config['Board2_DDS2']['phase_last_used'] = str(self.Board2_DDS2_phase_spinbox.value())
        self.config['Board3_DDS1']['phase_last_used'] = str(self.Board3_DDS1_phase_spinbox.value())
        self.config['Board3_DDS2']['phase_last_used'] = str(self.Board3_DDS2_phase_spinbox.value())
        
        self.config['Board1_DDS1']['phase_step_last_used'] = self.Board1_DDS1_phase_step_size.text()
        self.config['Board1_DDS2']['phase_step_last_used'] = self.Board1_DDS2_phase_step_size.text()
        self.config['Board2_DDS1']['phase_step_last_used'] = self.Board2_DDS1_phase_step_size.text()
        self.config['Board2_DDS2']['phase_step_last_used'] = self.Board2_DDS2_phase_step_size.text()
        self.config['Board3_DDS1']['phase_step_last_used'] = self.Board3_DDS1_phase_step_size.text()
        self.config['Board3_DDS2']['phase_step_last_used'] = self.Board3_DDS2_phase_step_size.text()
        
        # Purpose configuration
        self.config['Board1_DDS1']['purpose'] = self.Board1_DDS1_purpose.text()
        self.config['Board1_DDS2']['purpose'] = self.Board1_DDS2_purpose.text()
        self.config['Board2_DDS1']['purpose'] = self.Board2_DDS1_purpose.text()
        self.config['Board2_DDS2']['purpose'] = self.Board2_DDS2_purpose.text()
        self.config['Board3_DDS1']['purpose'] = self.Board3_DDS1_purpose.text()
        self.config['Board3_DDS2']['purpose'] = self.Board3_DDS2_purpose.text()

        with open(self.config_filename, 'w') as new_config_file:
            self.config.write(new_config_file)

        
    def closeEvent(self, event):

        if self.config_changed():
            self.save_config()
            print('Configuration change saved!')

        self.fpga.close() 
    
    #########################################################################################################################
    ## GUI manipulation
    #########################################################################################################################

    #########################################################################
    # Board1
    #########################################################################
    # DDS1
    def Board1_DDS1_freq_apply(self):
        freq_unit_index = self.Board1_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board1_DDS1_freq_spinbox.value() * scale /1e6
        
        if(self.Board1_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_frequency(freq_in_MHz, 1, 0)
                        
    def Board1_DDS1_power_apply(self):
        FSC = int(self.Board1_DDS1_power_spinbox.value()); # current scaling factor
        
        if(self.Board1_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_current(FSC, 1, 0)        
    
    def Board1_DDS1_phase_apply(self):
        phase = self.Board1_DDS1_phase_spinbox.value();
        
        if(self.Board1_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_phase(phase, 1, 0)
            
    def Board1_DDS1_manual_apply(self):
        freq_unit_index = self.Board1_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board1_DDS1_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board1_DDS1_power_spinbox.value()); # current scaling factor
        phase = self.Board1_DDS1_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(1)
        self.dds.set_frequency(freq_in_MHz, 1, 0)
        self.dds.set_current(FSC, 1, 0)        
        self.dds.set_phase(phase, 1, 0)

                            
    def Board1_DDS1_freq_step_size_update(self):
        try:
            step_value = float(self.Board1_DDS1_freq_step_size.text())
        except:
            return
        self.Board1_DDS1_freq_spinbox.setSingleStep(step_value)
        
    def Board1_DDS1_power_step_size_update(self):
        try:
            step_value = int(float(self.Board1_DDS1_power_step_size.text()))
        except:
            return
        self.Board1_DDS1_power_spinbox.setSingleStep(step_value)
        
    def Board1_DDS1_phase_step_size_update(self):
        try:
            step_value = float(self.Board1_DDS1_phase_step_size.text())
        except:
            return
        self.Board1_DDS1_phase_spinbox.setSingleStep(step_value)

    def Board1_DDS1_output_on_off(self):
        self.dds.board_select(1)

        if (self.Board1_DDS1_output_on == True):
            self.Board1_DDS1_output_on = False
            self.Board1_DDS1_output_button.setIcon(self.off_icon)
            self.dds.power_down(1, 0)
        else:
            self.Board1_DDS1_output_on = True
            self.Board1_DDS1_output_button.setIcon(self.on_icon)
            self.dds.power_up(1, 0)
    
    # DDS2
    def Board1_DDS2_freq_apply(self):
        freq_unit_index = self.Board1_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board1_DDS2_freq_spinbox.value() * scale /1e6
        
        if(self.Board1_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_frequency(freq_in_MHz, 0, 1)
        
    def Board1_DDS2_power_apply(self):
        FSC = int(self.Board1_DDS2_power_spinbox.value()); # current scaling factor
        
        if(self.Board1_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_current(FSC, 0, 1)        
    
    def Board1_DDS2_phase_apply(self):
        phase = self.Board1_DDS2_phase_spinbox.value();
        
        if(self.Board1_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(1)
            self.dds.set_phase(phase, 0, 1)
    
    def Board1_DDS2_manual_apply(self):
        freq_unit_index = self.Board1_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board1_DDS2_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board1_DDS2_power_spinbox.value()); # current scaling factor
        phase = self.Board1_DDS2_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(1)
        self.dds.set_frequency(freq_in_MHz, 0, 1)
        self.dds.set_current(FSC, 0, 1)        
        self.dds.set_phase(phase, 0, 1)
    
    def Board1_DDS2_freq_step_size_update(self):
        try:
            step_value = float(self.Board1_DDS2_freq_step_size.text())
        except:
            return
        self.Board1_DDS2_freq_spinbox.setSingleStep(step_value)
        
    def Board1_DDS2_power_step_size_update(self):
        try:
            step_value = int(self.Board1_DDS2_power_step_size.text())
        except:
            return
        self.Board1_DDS2_power_spinbox.setSingleStep(step_value)
        
    def Board1_DDS2_phase_step_size_update(self):
        try:
            step_value = float(self.Board1_DDS2_phase_step_size.text())
        except:
            return
        self.Board1_DDS2_phase_spinbox.setSingleStep(step_value)

    def Board1_DDS2_output_on_off(self):
        self.dds.board_select(1)

        if (self.Board1_DDS2_output_on == True):
            self.Board1_DDS2_output_on = False
            self.Board1_DDS2_output_button.setIcon(self.off_icon)
            self.dds.power_down(0, 1)
        else:
            self.Board1_DDS2_output_on = True
            self.Board1_DDS2_output_button.setIcon(self.on_icon)
            self.dds.power_up(0, 1)
            
    #########################################################################
    # Board2
    #########################################################################
    # DDS1
    def Board2_DDS1_freq_apply(self):
        freq_unit_index = self.Board2_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board2_DDS1_freq_spinbox.value() * scale /1e6
        
        if(self.Board2_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_frequency(freq_in_MHz, 1, 0)
        
    def Board2_DDS1_power_apply(self):
        FSC = int(self.Board2_DDS1_power_spinbox.value()); # current scaling factor
        
        if(self.Board2_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_current(FSC, 1, 0)        
    
    def Board2_DDS1_phase_apply(self):
        phase = self.Board2_DDS1_phase_spinbox.value();
        
        if(self.Board2_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_phase(phase, 1, 0)
        
    def Board2_DDS1_manual_apply(self):
        freq_unit_index = self.Board2_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board2_DDS1_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board2_DDS1_power_spinbox.value()); # current scaling factor
        phase = self.Board2_DDS1_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(2)
        self.dds.set_frequency(freq_in_MHz, 1, 0)
        self.dds.set_current(FSC, 1, 0)        
        self.dds.set_phase(phase, 1, 0)    
    
    def Board2_DDS1_freq_step_size_update(self):
        try:
            step_value = float(self.Board2_DDS1_freq_step_size.text())
        except:
            return
        self.Board2_DDS1_freq_spinbox.setSingleStep(step_value)
        
    def Board2_DDS1_power_step_size_update(self):
        try:
            step_value = int(self.Board2_DDS1_power_step_size.text())
        except:
            return
        self.Board2_DDS1_power_spinbox.setSingleStep(step_value)
        
    def Board2_DDS1_phase_step_size_update(self):
        try:
            step_value = float(self.Board2_DDS1_phase_step_size.text())
        except:
            return
        self.Board2_DDS1_phase_spinbox.setSingleStep(step_value)

    def Board2_DDS1_output_on_off(self):
        self.dds.board_select(2)

        if (self.Board2_DDS1_output_on == True):
            self.Board2_DDS1_output_on = False
            self.Board2_DDS1_output_button.setIcon(self.off_icon)
            self.dds.power_down(1, 0)
        else:
            self.Board2_DDS1_output_on = True
            self.Board2_DDS1_output_button.setIcon(self.on_icon)
            self.dds.power_up(1, 0)
    
    # DDS2
    def Board2_DDS2_freq_apply(self):
        freq_unit_index = self.Board2_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board2_DDS2_freq_spinbox.value() * scale /1e6
        
        if(self.Board2_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_frequency(freq_in_MHz, 0, 1)
        
        
    def Board2_DDS2_power_apply(self):
        FSC = int(self.Board2_DDS2_power_spinbox.value()); # current scaling factor
        
        if(self.Board2_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_current(FSC, 0, 1)        
    
    def Board2_DDS2_phase_apply(self):
        phase = self.Board2_DDS2_phase_spinbox.value();
        
        if(self.Board2_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(2)
            self.dds.set_phase(phase, 0, 1)
    
    def Board2_DDS2_manual_apply(self):
        freq_unit_index = self.Board2_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board2_DDS2_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board2_DDS2_power_spinbox.value()); # current scaling factor
        phase = self.Board2_DDS2_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(2)
        self.dds.set_frequency(freq_in_MHz, 0, 1)
        self.dds.set_current(FSC, 0, 1)        
        self.dds.set_phase(phase, 0, 1)    
    
    def Board2_DDS2_freq_step_size_update(self):
        try:
            step_value = float(self.Board2_DDS2_freq_step_size.text())
        except:
            return
        self.Board2_DDS2_freq_spinbox.setSingleStep(step_value)
        
    def Board2_DDS2_power_step_size_update(self):
        try:
            step_value = int(self.Board2_DDS2_power_step_size.text())
        except:
            return
        self.Board2_DDS2_power_spinbox.setSingleStep(step_value)
        
    def Board2_DDS2_phase_step_size_update(self):
        try:
            step_value = float(self.Board2_DDS2_phase_step_size.text())
        except:
            return
        self.Board2_DDS2_phase_spinbox.setSingleStep(step_value)

    def Board2_DDS2_output_on_off(self):
        self.dds.board_select(2)

        if (self.Board2_DDS2_output_on == True):
            self.Board2_DDS2_output_on = False
            self.Board2_DDS2_output_button.setIcon(self.off_icon)
            self.dds.power_down(0, 1)
        else:
            self.Board2_DDS2_output_on = True
            self.Board2_DDS2_output_button.setIcon(self.on_icon)
            self.dds.power_up(0, 1)
            
    #########################################################################
    # Board3
    #########################################################################
    # DDS1
    def Board3_DDS1_freq_apply(self):
        freq_unit_index = self.Board3_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board3_DDS1_freq_spinbox.value() * scale /1e6
        
        if(self.Board3_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_frequency(freq_in_MHz, 1, 0)
        
        
    def Board3_DDS1_power_apply(self):
        FSC = int(self.Board3_DDS1_power_spinbox.value()); # current scaling factor
        
        if(self.Board3_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_current(FSC, 1, 0)        
    
    def Board3_DDS1_phase_apply(self):
        phase = self.Board3_DDS1_phase_spinbox.value();
        
        if(self.Board3_DDS1_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_phase(phase, 1, 0)
            
    def Board3_DDS1_manual_apply(self):
        freq_unit_index = self.Board3_DDS1_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board3_DDS1_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board3_DDS1_power_spinbox.value()); # current scaling factor
        phase = self.Board3_DDS1_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(3)
        self.dds.set_frequency(freq_in_MHz, 1, 0)
        self.dds.set_current(FSC, 1, 0)        
        self.dds.set_phase(phase, 1, 0)    
        
    def Board3_DDS1_freq_step_size_update(self):
        try:
            step_value = float(self.Board3_DDS1_freq_step_size.text())
        except:
            return
        self.Board3_DDS1_freq_spinbox.setSingleStep(step_value)
        
    def Board3_DDS1_power_step_size_update(self):
        try:
            step_value = int(self.Board3_DDS1_power_step_size.text())
        except:
            return
        self.Board3_DDS1_power_spinbox.setSingleStep(step_value)
        
    def Board3_DDS1_phase_step_size_update(self):
        try:
            step_value = float(self.Board3_DDS1_phase_step_size.text())
        except:
            return
        self.Board3_DDS1_phase_spinbox.setSingleStep(step_value)

    def Board3_DDS1_output_on_off(self):
        self.dds.board_select(3)

        if (self.Board3_DDS1_output_on == True):
            self.Board3_DDS1_output_on = False
            self.Board3_DDS1_output_button.setIcon(self.off_icon)
            self.dds.power_down(1, 0)
        else:
            self.Board3_DDS1_output_on = True
            self.Board3_DDS1_output_button.setIcon(self.on_icon)
            self.dds.power_up(1, 0)
    
    # DDS2
    def Board3_DDS2_freq_apply(self):
        freq_unit_index = self.Board3_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board3_DDS2_freq_spinbox.value() * scale /1e6
        
        if(self.Board3_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_frequency(freq_in_MHz, 0, 1)
        
        
    def Board3_DDS2_power_apply(self):
        FSC = int(self.Board3_DDS2_power_spinbox.value()); # current scaling factor
        
        if(self.Board3_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_current(FSC, 0, 1)        
    
    def Board3_DDS2_phase_apply(self):
        phase = self.Board3_DDS2_phase_spinbox.value();
        
        if(self.Board3_DDS2_auto_apply_checkbox.isChecked() == True):
            self.dds.board_select(3)
            self.dds.set_phase(phase, 0, 1)
            
    def Board3_DDS2_manual_apply(self):
        freq_unit_index = self.Board3_DDS2_freq_unit.currentIndex()
        scale = 10**(3 * freq_unit_index)
        freq_in_MHz = self.Board3_DDS2_freq_spinbox.value() * scale /1e6
        FSC = int(self.Board3_DDS2_power_spinbox.value()); # current scaling factor
        phase = self.Board3_DDS2_phase_spinbox.value();
        
        # Manual setting
        self.dds.board_select(3)
        self.dds.set_frequency(freq_in_MHz, 0, 1)
        self.dds.set_current(FSC, 0, 1)        
        self.dds.set_phase(phase, 0, 1)    
        
    def Board3_DDS2_freq_step_size_update(self):
        try:
            step_value = float(self.Board3_DDS2_freq_step_size.text())
        except:
            return
        self.Board3_DDS2_freq_spinbox.setSingleStep(step_value)
        
    def Board3_DDS2_power_step_size_update(self):
        try:
            step_value = int(self.Board3_DDS2_power_step_size.text())
        except:
            return
        self.Board3_DDS2_power_spinbox.setSingleStep(step_value)
        
    def Board3_DDS2_phase_step_size_update(self):
        try:
            step_value = float(self.Board3_DDS2_phase_step_size.text())
        except:
            return
        self.Board3_DDS2_phase_spinbox.setSingleStep(step_value)

    def Board3_DDS2_output_on_off(self):
        self.dds.board_select(3)

        if (self.Board3_DDS2_output_on == True):
            self.Board3_DDS2_output_on = False
            self.Board3_DDS2_output_button.setIcon(self.off_icon)
            self.dds.power_down(0, 1)
        else:
            self.Board3_DDS2_output_on = True
            self.Board3_DDS2_output_button.setIcon(self.on_icon)
            self.dds.power_up(0, 1)
    
if __name__ == "__main__":
    app = QtWidgets.QApplication.instance()
    if app is None:
        app = QtWidgets.QApplication([])
    
    triple_dds = TripleBoard_AD9912()
    triple_dds.show()
    app.exec_()
    sys.exit(app.exec_())

