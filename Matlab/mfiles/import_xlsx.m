%% Import Data
clear all;clc;close all

baseroot = 'E:\Dropbox\Research\Projects\Topic 2 LATET (3YP)\Replication Package\Empirical Illustration\Stata\xlsx\';

ZD_xlsx = importdata([baseroot,'data_ZD.xlsx']);
Y1_xlsx = importdata([baseroot,'data_Y1.xlsx']);
Y2_xlsx = importdata([baseroot,'data_Y2.xlsx']);
W1_xlsx = importdata([baseroot,'data_W1.xlsx']);
W2_xlsx = importdata([baseroot,'data_W2.xlsx']);
T1_xlsx = importdata([baseroot,'data_T1.xlsx']);
T2_xlsx = importdata([baseroot,'data_T2.xlsx']);
Tg_xlsx = importdata([baseroot,'data_Tg.xlsx']);
Wg_xlsx = importdata([baseroot,'data_Wg.xlsx']);

ZD      = ZD_xlsx.data;
Z       = cat(3, ZD(:,5), ZD(:,6));
D_obs   = cat(3, ZD(:,7), ZD(:,8));

Y1_all  = Y1_xlsx.data;
Y2_all  = Y2_xlsx.data;

Y_obs   = cat(3,Y1_all(:,5),Y2_all(:,5));
Y_pre   = cat(3,Y1_all(:,6),Y2_all(:,6));
%Y_pre_m = cat(3,Y1_all(:,7),Y2_all(:,7));

W1  = W1_xlsx.data;
W2  = W2_xlsx.data;
W   = cat(3,W1(:,5:end),W2(:,5:end));

T1  = T1_xlsx.data;
T2  = T2_xlsx.data;
T   = cat(3,T1(:,5:end),T2(:,5:end));

Tg  = Tg_xlsx.data;
Tg  = Tg(:,5:end);
Wg  = Wg_xlsx.data;
Wg  = Wg(:,5:end);
Xg  = [Tg Wg];

G = size(Y_obs,1)