function [SN,SF,Start,End,Stop,Down,IbyteStart,Nsamples] = AGinfo(File)

% Reads the header informations of AG data file.
% Eeither gt3x-file (original ActiLife ver. 5) or act4-file (converted ActiLife ver. 6 (or 5))

[~,~,Ext] = fileparts(File);
if strcmpi(Ext,'.gt3x'), [SN,SF,Start,End,Stop,Down,IbyteStart,Nsamples] = GT3Xinfo(File); end
if strcmpi(Ext,'.act4'), [SN,SF,Start,End,Stop,Down,IbyteStart,Nsamples] = ACT4info(File); end
if isnan(Stop), Stop = End; end %8/1/2013