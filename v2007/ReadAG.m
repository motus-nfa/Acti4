function [Acc,SF,StartActi,SN] = ReadAG(File,varargin)

% Reads acceleromater data from gt3x/act4-files.
%
% If input is a gt3x file it must be of ActiLife ver. 5.
% Se ReadACT4 for input/output.

  [~,~,Ext] = fileparts(File);
  if strcmpi(Ext,'.gt3x'), [Acc,SF,StartActi,SN] = ReadActigraphGT3X(File,varargin{:}); end %only ActiLiFe ver. 5
  if strcmpi(Ext,'.act4'), [Acc,SF,StartActi,SN] = ReadACT4(File,varargin{:}); end

