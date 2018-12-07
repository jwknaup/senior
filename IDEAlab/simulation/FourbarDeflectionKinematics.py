# -*- coding: utf-8 -*-
"""
Created on Fri Oct 12 01:06:13 2018

@author: Jacob
"""

import sympy as sp
import numpy as np
import matplotlib.pyplot as plt

# =============================================================================
# F = 0
# x = sp.symbols('x')
# l1x, l1y = sp.symbols('l1x l1y', real=True)
# l2x, l2y = sp.symbols('l2x l2y', real=True)
# 
# l1 = 2
# l2 = 1
# 
# E = 1
# I = 1
# 
# P0 = [0, 0]
# P1 = [-F*l1**3/(3*E*I), l1]
# P2 = P0 + [l2, 0]
# 
# system = [P1[0]+l1x+l2x-P2[0], P1[1]+l1y-l2y-P2[1], l1-sp.sqrt(l1x**2+l1y**2), l2-sp.sqrt(l2x**2+l2y**2)]
# ans = sp.nonlinsolve(system, [l1x, l1y, l2x, l2y])
# print(ans.args)
# l1x, l1y, l2x, l2y = ans.args[1]
# P3 = []
# =============================================================================

theta1 = np.linspace(0.1, np.pi-0.1, 100)
theta2 = np.linspace(0.1, np.pi-0.1, 100)
thetad = np.linspace(0, np.pi/2.0-0.1, 100)
#F = (2*np.tan(theta2-theta1)/1**2 - np.tan(theta1-np.pi/2))
F = (2*np.tan(thetad)/1**2)
# =============================================================================
# print(F)
# plt.plot(theta1, F)
# plt.figure()
# plt.plot(theta2, F)
# =============================================================================

#####################################################
def fourbar_kinematics():
    F_measured = [0, 0, 0.005, 0.0085, 0.01, 0.013, 0.017, 0.018, 0.026, 0.03, 0.037, 0.0435, 0.0465]
    theta_measured = [0, 0, 0.0764823741, 0.130020036, 0.1529647483, 0.1988541728, 0.2600400721, 0.2753365469, 0.3977083455, 0.4588942448, 0.5659695686, 0.665396655, 0.7112860795]
    EI = 3000000 * 1/12*(0.21)*(0.022)**3
    print(EI)
    F_predicted = EI*(2*np.tan(theta_measured)/4**2)
    F_applied = [0, 0.00375, 0.0075, 0.01125, 0.015, 0.01875, 0.0225, 0.02625, 0.03375, 0.0375, 0.045, 0.0525, 0.06]
    plt.plot(theta_measured, F_applied, 'k.')
    plt.plot(theta_measured, F_predicted, 'kx')
    plt.legend(['Force Applied', 'Force Predicted'])
    plt.title('Theoretical vs Experimental Force-Deflection Relationship')
    plt.xlabel('angle (rad)')
    plt.ylabel('force (N)')
    
def measured_v_actual_angle():
    directory = 'C:/Users/Jacob/Documents/Senior/IDEAlab/datas/'
    file = 'measured v actual angle.csv'
    path = directory + file
    angles = np.genfromtxt(path, delimiter=',')
    measured = angles[:,1]
    measured[measured<0] = 0
    actual = angles[:,3]
    plt.plot(actual, measured, 'k.')
    plt.xlabel('Actual Angle (deg)')
    plt.ylabel('Measured Angle (deg)')
    plt.title('Measured vs Actual Angle')
    
    
fourbar_kinematics()
    
    