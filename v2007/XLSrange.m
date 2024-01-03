% XLSRANGE returns the address of a range as used by Excel.
%
% Usage: rng = XLSrange(sizeofarray)
%        rng = XLSrange(sizeofarray, topleft)
%
% Inputs:
%   sizeofarray     [nbrows,nbcols], the size of the array that needs to
%                   be written to Excel.
%   topleft         [row,col], coordinates of the top left corner cell.
%                   Default is [1 1] (i.e. cell 'A1').
% Output:
%   rng             A string containing the range in Excel notation.
%
% Example:
%   M = rand(25,5);
%   % We start in cell 'B4' (= coordinates [4,2]).
%   rng = XLSrange(size(M),[4,2]);
%   % This produces rng = 'B4:F28'.
%   xlswrite('M.xls',M,'',rng)
%
% Author: Yvan Lengwiler
% Date  : 2010/05/21
%
% see also XLSWRITE

function rng = XLSrange(sizeofarray, topleft)

    % default for topleft is [1 1]
    if nargin == 1
        topleft = [1 1];
    end

    % some error checking
    if ~(numel(topleft) == 2 && numel(sizeofarray) == 2  && ...
            all(fix(topleft) == topleft) && ...
            all(fix(sizeofarray) == sizeofarray) && ...
            all(topleft > 0) && ...
            all(sizeofarray > 0) )
        error(['XLSrange: invalid args. ''topleft'' and ''sizeofarray''', ...
            ' must be vectors of two integers each.']);
    end
    
    % top left cell
    toprow = int2str(topleft(1));
    topcol = to26(topleft(2));
    
    if max(sizeofarray(1),sizeofarray(2)) == 1;

        % output only a single cell address is sizeofarray is 1x1
        rng = [topcol,toprow];

    else
    
        % bottom right cell
        botrow = int2str(topleft(1) + sizeofarray(1) - 1);
        botcol = to26(topleft(2) + sizeofarray(2) - 1);

        % result
        rng = [topcol,toprow,':',botcol,botrow];

    end

    % convert to 26imal code
    function code = to26(number)
        code = '';
        while number>0
            m = mod(number-1,26);
            code = [char(65+m),code];
            number = (number - m - 1) / 26;
        end
    end

end
