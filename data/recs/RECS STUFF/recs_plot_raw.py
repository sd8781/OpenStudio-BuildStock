# -*- coding: utf-8 -*-
"""
Created on Mon Sep 26 15:26:57 2016

@author: jalley
"""
#import plotly.plotly as py
#import plotly.graph_objs as go
#import os, sys
#import pandas as pd
#import csv
#from medoids_tstat import do_plot
#import itertools
#import numpy as np
#from matplotlib.lines import Line2D
#from scipy import stats
#from matplotlib.pyplot import show
#from colour import Color

import seaborn as sns
import matplotlib.pyplot as plt

import query_recs_raw as recs

vintages = {'pre-1950' : 0,
            '1950s' : 1,
            '1960s' : 2,
            '1970s' : 3,
            '1980s' : 4,
            '1990s' : 5,
            '2000s' : 6}

num_vintages = {0 : 'pre-1950',
            1:'1950s' ,
            2:'1960s' ,
            3:'1970s' ,
            4:'1980s' ,
            5:'1990s' ,
            6:'2000s' }

sizes = {'0-1499' : 0,
         '1500-2499' : 1,
         '2500-3499' : 2,
         '3500+' : 3}

num_sizes = {0:'0-1499' ,
         1:'1500-2499' ,
         2:'2500-3499' ,
         3:'3500+'}

income_range = {    1:'Less than $2,500',
                    2:'$2,500 to $4,999',
                    3:'$5,000 to $7,499',
                    4:'$7,500 to $9,999',
                    5:'$10,000 to $14,999',
                    6:'$15,000 to $19,999',
                    7:'$20,000 to $24,999',
                    8:'$25,000 to $29,999',
                    9:'$30,000 to $34,999',
                    10:'$35,000 to $39,999',
                    11:'$40,000 to $44,999',
                    12:'$45,000 to $49,999',
                    13:'$50,000 to $54,999',
                    14:'$55,000 to $59,999',
                    15:'$60,000 to $64,999',
                    16:'$65,000 to $69,999',
                    17:'$70,000 to $74,999',
                    18:'$75,000 to $79,999',
                    19:'$80,000 to $84,999',
                    20:'$85,000 to $89,999',
                    21:'$90,000 to $94,999',
                    22:'$95,000 to $99,999',
                    23:'$100,000 to $119,999',
                    24:'$120,000 or More'}

med_income = {1:1250,
                2:3250,
                3:6250,
                4:8750,
                5:12250,
                6:17250,
                7:22250,
                8:27250,
                9:32250,
                10:37250,
                11:42250,
                12:47250,
                13:52250,
                14:57250,
                15:62250,
                16:67250,
                17:72250,
                18:77250,
                19:82250,
                20:87250,
                21:92250,
                22:97250,
                23:110000,
                24:120000 }

fpl16 = {    1:11880,
            2:16020,
            3:20160,
            4:24300,
            5:28440,
            6:32580,
            7:36730,
            8:40890}

fpl09 = {    1:10830,
            2:14570,
            3:18310,
            4:22050,
            5:25790,
            6:29530,
            7:33270,
            8:37010}

fpl = fpl09

def stackedbar(df, VAR, TITLE):
##Change only these two parameters
#    VAR = 'Size'
#    TITLE = "House Size" + " vs. " + "Federal Poverty Levels 250, 200, 150, 100, 50"

    #Set up cut by different FPL levels

    CUT = ['FPLALL','FPL250','FPL200','FPL150','FPL100','FPL50']
    i = len(CUT)

    #Colors for plot gradient

    colors = sns.color_palette("GnBu", i)

    #Loop to plot different poverty levels
    plt.figure()
    for j in range(len(CUT)):
        POV = CUT[j]
        df1 = recs.calc_general(df, cut_by=[VAR],columns=[POV])
        ax = sns.barplot(x = df1[VAR], y = df1[1.0], color = colors[j])

    #Save and label

	ax.set_xlabel(VAR + " of Home", fontsize = 13.5)
	ax.set_ylabel("Distribution of Homes According to Income", fontsize = 12)
	ax.set_title(TITLE, fontsize = 15)
	fig = ax.get_figure()
	fig.savefig(VAR+'_pov_lvls.png', bbox_inches = 'tight')
	print fig

def kdeplot(df, VAR1, VAR2, TITLE):

	#removes values of 0 from the dataset
	temp_set = ['athome','temphome','tempgone','tempnite','temphomeac','tempgoneac','tempniteac']
	if VAR2 in temp_set:
		df1 = df[df[VAR2] !=0]
	else:
		df1 = df
	ax = sns.jointplot(x=VAR1, y = VAR2, data = df1, kind = "kde", joint_kws={'weights':'nweight'})
	ax.savefig(VAR1 +" vs. "+ VAR2 +'_kde .png', bbox_inches = 'tight')

if __name__ == '__main__':
	df = recs.process_csv_data()
	df = recs.assign_sizes(df)
	poverty(df)
#	stackedbar(df,'equipm', 'Heating Equipment' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
#	stackedbar(df,'fuelheat', 'Heating Fuel' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
#	stackedbar(df,'division', 'Census Division' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
#	stackedbar(df,'Size', 'House Size' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Square Footage',True)	#Percentage
#	stackedbar(df,'Size', 'House Size' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Square Footage',False)	#Distribution
#	stackedbar(df,'YEARMADERANGE', 'Vintage' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Year Made',True)		#Percentage
#	stackedbar(df,'YEARMADERANGE', 'Vintage' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Year Made',False)		#Distribution
#	stackedbar(df,'equipm', 'Heating Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Heating Equipment',True)	#Percentage
#	stackedbar(df,'equipm', 'Heating Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Heating Equipment',False)	#Distribution
#	stackedbar(df,'equipage', 'Heating System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age (years)',True)
#	stackedbar(df,'equipage', 'Heating System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age (years)',False)
#	stackedbar(df,'cooltype', 'A/C Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Type of A/C Equipment',True)
#	stackedbar(df,'cooltype', 'A/C Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Type of A/C Equipment',False)
#	stackedbar(df,'agecenac', 'Central A/C System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age of System',True)
#	stackedbar(df,'agecenac', 'Central A/C System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age of System',False)
#	stackedbar(df,'wwacage', 'Window A/C Unit Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age of Oldest Unit',True)
#	stackedbar(df,'wwacage', 'Window A/C Unit Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50', 'Age of Oldest Unit',False)
#	stackedbar(df,'equipm', 'Heating Equipment' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
#	stackedbar(df,'fuelheat', 'Heating Fuel' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
#	stackedbar(df,'division', 'Census Division' + ' vs. Federal Poverty Levels: 250,200,150,100,50')
	kdeplot(df,'income', 'temphome', 'Day Thermostat Temp When Home (Winter)')
	kdeplot(df,'income', 'tempgone', 'Day Thermostat Temp When Gone(Winter)')
	kdeplot(df,'income', 'tempnite', 'Night Thermostat Temp (Winter)')
	kdeplot(df,'income', 'temphomeac', 'Day Thermostat Temp When Home (Summer)')
	kdeplot(df,'income', 'tempgoneac', 'Day Thermostat Temp When Gone(Summer)')
	kdeplot(df,'income', 'tempniteac', 'Night Thermostat Temp (Winter)')
#JOINTPLOT

#    df1 = df1[PROB]=df1[1].where(df1[1]>0,other=0)
#    df = df[(df[PROB] >0)]


#	sns.jointplot(x=VAR1, y = VAR2, data = df, kind = "reg")
#	plt.title(TITLE)
#BARCHART
#    ax = plt.axes()
#    sns.barplot(x=VAR,y= 1, palette = 'Reds_d', data = df1)
#    ax.set_title(TITLE)
#    plt.show()

#STACKED BAR




















#Other calls


