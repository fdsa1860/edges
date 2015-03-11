% test_edgesTrain
clc;close all;clear;
addpath(genpath('./'))
opts = edgesTrain();
opts.bsdsDir = '~/research/data/BSR/BSDS500/data/';
opts.sharpen=0;
opts.imWidth = 64;
opts.gtWidth = 32;
% opts.shrink = 4;
model = edgesTrain( opts );