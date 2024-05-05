clc
clear all
format compact
format short g

addpath('mfiles')

% Import dataset (xlsx file format) generated from Stata
% import_xlsx 
% save('data_analysis')
load('data_analysis')


r1_lin = estim(Y_obs,D_obs,Z,W,T,Tg,Xg,2,4,"true","lin",1,"on")
r2_lin = estim(Y_obs,D_obs,Z,W,T,Tg,Xg,3,4,"true","lin",1,"on")

r1_nl = estim(Y_obs,D_obs,Z,W,T,Tg,Xg,2,4,"true","nl",1,"on")
r2_nl = estim(Y_obs,D_obs,Z,W,T,Tg,Xg,3,4,"true","nl",1,"on")

r1_vb = estim_VB(Y_obs,D_obs,Z,W,T,Xg, "true",2,4)
r2_vb = estim_VB(Y_obs,D_obs,Z,W,T,Xg, "true",3,4)

[r1_lin;r2_lin;r1_vb;r2_vb]
[r1_nl;r2_nl;r1_vb;r2_vb]