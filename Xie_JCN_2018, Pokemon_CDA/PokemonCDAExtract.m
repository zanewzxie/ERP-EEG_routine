% scripts for Pokemon CDA Exp, 
% modified from CW CDA scripts based on older version of ERPLAB toolbox.
% significant change: function naming convention is consistent with EEGLAB now. Chan * Bin operation changed from : to @ 

clear all;close all;

cd('/Volumes/Zane/Exp2_CDA_PK_Short/ERP')
addpath(genpath('/Users/Zane/Documents/MATLAB/eeglab13_5_4b'))

DirWorking=pwd;
SaveDir = [DirWorking '/saved_analysis'];
 
%% 
subanly =1; % SUBJECT TO ANALYZE
BDFfilename = sprintf('/CD_PK_CDA_%d.bdf',subanly);

[ALLEEG EEG CURRENTSET ALLCOM]= eeglab;% Load eeglab 

EEG = pop_biosig([DirWorking BDFfilename],'ref',[37 38]);
EEG = eeg_checkset( EEG );
% [ALLEEG EEG CURRENTSET ] = eeg_store(ALLEEG, EEG);% Store the dataset into EEGLAB 
Setname = sprintf('PokemonS%d',subanly);

EEG=pop_chanedit(EEG,'lookup', '/MATLAB/eeglab13_5_4b/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp');
% figure; pop_spectopo(EEG, 1, [0  2139038], 'EEG' , 'percent', 15, 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
% Setname='PokemonE1S1';

EEG.setname=Setname;
EEG=pop_saveset(EEG, 'filename', [EEG.setname '_Chan.set'], 'filepath', SaveDir);
eeglab redraw                    % updates the GUI window to show the current dataset 


%% sort events into necesary bins
    EEG = pop_creabasiceventlist( EEG , 'Eventlist', 'elist.txt', 'BoundaryNumeric', { -99 } ...
                             , 'BoundaryString', { 'boundary' }, 'Warning', 'on' );

    EEG  = pop_binlister( EEG , 'BDF'                                                  ... 
                    , [DirWorking '/Pokemon_CDA.txt']  ...
                    , 'ExportEL' , [DirWorking '/EvtList.txt'] ...
                    , 'ImportEL', 'no'                                             ... 
                    , 'Saveas', 'on'                                               ...
                    , 'SendEL2', 'EEG&Text'                                    ...
                    , 'Warning', 'on' );
    
    eeglab redraw                    % updates the GUI window to show the current dataset 
%% Remove based line
%     EEG = pop_rmbase(EEG, [-500 0]);% Remove baseline % no onger needed

EEG = pop_epochbin( EEG , [-200.0 2000.0],  'pre');
EEG.setname= [EEG.setname '_EEG_elist_be'];
EEG=pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', SaveDir);

% pop_plotdata(EEG, 1, [1:38] , 'all', 'ERPs epochs ERP', 0, 1, [0 0]);
pop_plotdata(EEG, 1, [1:38] , [1:400], 'ERPs epochs ERP', 0, 1, [0 0]);

%% Artifact detection 
% EEG = pop_basicfilter( EEG,  1:40, 0, 30, 2, 'butter', 0, 'boundary' );

% Artifact Detection with Moving window peak to peak threshold
% Test period [-200 2000]. Voltage threshold 100uV
% Moving window width: 200 ms. Window step: 50. Channels 1:32
% this one for big eye blinks
EEG = pop_artmwppth( EEG, 'Channel' , [35 36], 'Flag' , [1 2], 'Threshold', 100 ...
                   , 'Twindow', [-200 2000], 'Windowsize' ,200, 'Windowstep' , 50);
% The script-based routine does not show you the data. To see the data, do
% this: 
pop_eegplot(EEG);

%     EEG =  pop_artmwppth( EEG, [EEG.xmin EEG.xmax]*1000, 100, (EEG.xmax-EEG.xmin)*1000, 50,  1:40, 2);
%% Artifact Detection, Step-like artifacts

% Test period [-200 2000], Voltage Threshold 20
% Moving Window Width 400, Window step 10
% Channel 16 only, Mark flags 1 and 3 (you must always mark flag 1
% this one for eye movement
EEG = pop_artstep( EEG,'Channel' , [33 34], 'Flag', [1 3], 'Threshold',  15 ...
                 , 'Twindow' , [-200 2000], 'Windowsize' , 400, 'Windowstep' , 100);
pop_eegplot(EEG);
            
%% CHECK

[EEG, tprej, acce, rej, histoflags ] = pop_summary_AR_eeg_detection(EEG,'none') % GUI: 09-Nov-2015 20:29:47


%% Compute Averaged ERP
ERPSetname = [Setname '_ERP'];
ERP = pop_averager( EEG , 'Criterion', 1, 'DSindex',  1, 'SEM', 'on'); 
ERP = pop_erpchanoperator( ERP, {  'ch39 = ch34-ch33 label HEOG'   'ch40 = ch36-ch35 label VEOG'   });
% ERPEyeSetname = [ERPSetname '_EyeResidual'];
% ERP = pop_savemyerp( ERP, 'erpname', [ERPEyeSetname '.erp'] , 'filepath', SaveDir);  
% ERP = pop_loaderp( 'filename',[ERPEyeSetname '.erp'], 'filepath', SaveDir);

% Plotting Averaged ERP Waveform
pop_ploterps( ERP, [1:4],[39] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
            , 'Blc', 'pre', 'Box', [ 1 2], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
            , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
            , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
            , 'xscale', [ -200.0  2000 -200:500:2000], 'YDir', 'normal', 'yscale', [ -10.0 10.0 -10:5:10]  );               
        

%% Export EEG Eventlist to Text file

EEG = pop_exporteegeventlist(EEG, [DirWorking ['/Sub_' num2str(subanly) '_Export_EEG_EL.txt']]);   
% Note that you will need to replace the path with the actual location in your file system
EEG.setname=[EEG.setname '_ar'];
EEG=pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', SaveDir);    



%% Compute Averaged ERP
 ERP = pop_averager( EEG , 'Criterion', 1, 'DSindex',  1, 'SEM', 'on'); 
 ERPSetname = [Setname '_ERP'];

ERP = pop_savemyerp( ERP, 'erpname', [ERPSetname '.set'],'filename', [ERPSetname '.erp'] ...
                   , 'filepath', SaveDir);     
      
% Plotting Averaged ERP Waveform
pop_ploterps( ERP, [1:4],1:36 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
            , 'Blc', 'pre', 'Box', [ 9 4], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
            , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
            , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
            , 'xscale', [ -200.0  2000 -200:500:2000], 'YDir', 'normal', 'yscale', [ -10.0 10.0 -10:5:10]  );               
        
        

%% Filtering  For ploting only. 
forplot = 0;
if forplot == 1
    %Channels [1:16], High pass 0, Low pass 30, Order 2, IIR Butterworth
    ERP = pop_filterp( ERP,1:32, 'Cutoff',30, 'Design', 'butter', 'Filter', 'lowpass', 'Order',2 );
    % EEG = pop_basicfilter( EEG,  1:40, 0, 30, 2, 'butter', 0, 'boundary' );
    ERPSetname = [ERPSetname '_30Hz'];
    ERP = pop_savemyerp( ERP, 'erpname', [ERPSetname '.set'],'filename', [ERPSetname '.erp'] ...
                       , 'filepath', SaveDir);     

    pop_ploterps( ERP, [1:4],1:32 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
                , 'Blc', 'pre', 'Box', [ 8 4], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
                , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
                , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
                , 'xscale', [ -200.0 798.0 -100:170:750], 'YDir', 'normal', 'yscale', [ -10.0 10.0 -10:5:10]  );  
end

%% Load raw EPR data and get the CDA measures. 
if forplot == 0 
    LoadERPSetname = [Setname '_ERP'];
else
    LoadERPSetname = [Setname '_30Hz'];
end    
    
ERP = pop_loaderp( 'filename',[LoadERPSetname '.erp'], 'filepath', SaveDir);

% EEG = pop_eegchanoperator( EEG, {  'ch39 = ch34-ch33 label HEOG'   'ch40 = ch36-ch35 label VEOG'   });
MatChan = splitbrain(ERP);
L =MatChan{1}(:,1)';
R =MatChan{1}(:,2)';
% L = [1 3 4 5 6 8 9 10 11 12 13 14 15 37];  %specifies LEFT channels 
% R = [17 18 19 20 21 23 24 25 26 27 28 29 32 38];  %specifies RIGHT channels
% bin 1 LVF target, 1st
% bin 2 RVF target, 1st
% bin 3 LVF target, 5th
% bin 4 RVF target, 5th

% ERP = pop_eegchanoperator( ERP, {  'ch39 = ch34-ch33 label HEOG'   'ch40 = ch36-ch35 label VEOG'   });
    
ERP = pop_binoperator(ERP, { 'nb1 = (b1@R + b2@L)/2 label 1st.Contra'...
        'nb2 = (b1@L + b2@R)/2 label 1st.Ipsi'...
        'nb3 = (b3@R + b4@L)/2 label 5th.Contra'...
        'nb4 = (b3@L + b4@R)/2 label 5th.Ipsi'}); 
%  
ERPSetname = [LoadERPSetname '_CI'];
   
ERP = pop_savemyerp( ERP, 'erpname', [ERPSetname '.set'],'filename', [ERPSetname '.erp'] ...
                   , 'filepath', SaveDir);     
               

pop_ploterps( ERP, [1:4],1:16 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
            , 'Blc', 'pre', 'Box', [4 4], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
            , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
            , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
            , 'xscale', [ -200.0  2000 -200:500:2000], 'YDir', 'normal', 'yscale', [ -10.0 10.0 -10:5:10]  );  
        
%% CDA

ERP = pop_binoperator(ERP, { 'bin5 = bin1 - bin2 label 1st  Contra-Ipsi'...
        'bin6 = bin3 - bin4 label 5th  Contra-Ips'}); 
     
ERP = pop_erpchanoperator( ERP, {  'ch17 = (ch7+ch8+ch9+ch10+ch11+ch12)/6 label Pa-Oci'} , 'ErrorMsg', 'popup', 'Warning', 'on' );
ERP = pop_erpchanoperator( ERP, {  'ch18 = (ch11+ch12)/2 label PO7/8-PO3/4, Brady'} , 'ErrorMsg', 'popup', 'Warning', 'on' );
ERP = pop_erpchanoperator( ERP, {  'ch19 = (ch6+ch7+ch8+ch9+ch10+ch11+ch12+ch13)/8 label ALL-OP'} , 'ErrorMsg', 'popup', 'Warning', 'on' );
ERP = pop_erpchanoperator( ERP, {  'ch20 = (ch7+ch8+ch9+ch11+ch12)/5 label Pa-Oci-5pairs, Qi'} , 'ErrorMsg', 'popup', 'Warning', 'on' );
ERP = pop_erpchanoperator( ERP, {  'ch21 = (ch7+ch9+ch11+ch12)/4 label Pa-Oci-4pairs, Stormer'} , 'ErrorMsg', 'popup', 'Warning', 'on' );
ERP = pop_erpchanoperator( ERP, {  'ch22 = (ch7+ch8+ch9+ch10+ch11+ch12)/6 label Pa-Oci-6pairs'} , 'ErrorMsg', 'popup', 'Warning', 'on' );

ERPSetname = [ERPSetname '_CDA'];    
ERP = pop_savemyerp( ERP, 'erpname', [ERPSetname '.set'],'filename', [ERPSetname '.erp'] ...
                   , 'filepath', SaveDir);     

        
pop_ploterps(ERP, [5:6],[6:14] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
            , 'Blc', 'pre', 'Box', [5 3], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
            , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
            , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
            , 'xscale',[ -200.0 1500 -100:500:1500], 'YDir', 'normal', 'yscale', [ -5.0 5.0 -10:5:10]  );  
      
        
eeglab redraw                    % updates the GUI window to show the current dataset 
%% plot avarager posterior and occipital extrodes. 

pop_ploterps(ERP, [5 6],[14:22] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on'                ...
            , 'Blc', 'pre', 'Box', [5 3], 'ChLabel', 'on', 'FontSizeChan',10, 'FontSizeLeg',10           ...
            , 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-','g-' , 'b-' }, 'LineWidth',1, 'Maximize', 'on'             ...
            , 'Position', [ 102.833 9.375 108.667 35.125], 'Style', 'Matlab'                              ...
            , 'xscale', [ -200.0  2000 -200:500:2000], 'YDir', 'normal', 'yscale', [-2 2 -2:2:2]  );  
      

%% get the measures and ploting ERP measurement toolbox
LoadERPSetname = [ERPSetname];

% LoadERPSetname = 'PokemonS31_ERP_CI_CDA';

ERP = pop_loaderp( 'filename',[LoadERPSetname '.erp'], 'filepath', SaveDir);
 
ALLERP = pop_geterpvalues( ERP, [1500 2000], [ 5 6], 20 , 'Append', 'on', 'Baseline', 'pre', 'FileFormat', 'wide', 'Filename', 'CDA_MeanAmplitude.txt',...
 'Fracreplace', 'NaN', 'InterpFactor',  1, 'Measure', 'meanbl', 'Resolution',  3 );

ALLERP = pop_geterpvalues( ERP, [500 1750], [ 5 6],  20, 'Afraction',  0.5, 'Append', 'on', 'Baseline', 'pre', 'FileFormat',...
 'wide', 'Filename', 'CDA_50_FractionAreaLatency.txt', 'Fracreplace', 'errormsg', 'InterpFactor',  1, 'Measure', 'fareanlat', 'Resolution',...
  3 );

