%+------------------------------------------------------------------------+
%| JANUS is a simple, robust, open standard signalling method for         |
%| underwater communications. See <http://www.januswiki.org> for details. |
%+------------------------------------------------------------------------+
%| Example software implementations provided by STO CMRE are subject to   |
%| Copyright (C) 2008-2018 STO Centre for Maritime Research and           |
%| Experimentation (CMRE)                                                 |
%|                                                                        |
%| This is free software: you can redistribute it and/or modify it        |
%| under the terms of the GNU General Public License version 3 as         |
%| published by the Free Software Foundation.                             |
%|                                                                        |
%| This program is distributed in the hope that it will be useful, but    |
%| WITHOUT ANY WARRANTY; without even the implied warranty of FITNESS     |
%| FOR A PARTICULAR PURPOSE. See the GNU General Public License for       |
%| more details.                                                          |
%|                                                                        |
%| You should have received a copy of the GNU General Public License      |
%| along with this program. If not, see <http://www.gnu.org/licenses/>.   |
%+------------------------------------------------------------------------+
%| Author: Ricardo Martins                                                |
%+------------------------------------------------------------------------+
%
% PSET_NEW Create a parameter set structure.
%
% Inputs:
%    id         Parameter set Id.
%    name       Parameter set name.
%    cfreq      Parameter set center frequency (Hz).
%    dbwidth    Parameter set desired frequency bandwidth (Hz).
%    params     Optional parameters structure, created by PARAMETERS.
%
% Outputs:
%    p          Parameter set structure.
%
% See also PSET_LOAD, PARAMETERS.

function p = pset_new(id, name, cfreq, dbwidth, params)
    defaults;

    % If no desired bandwidth is given the standard dictates that it
    % shall be 1/3 of the center frequency.
    if (nargin < 4)
        dbwidth = cfreq / 3;
    end

    if (nargin < 5)
        params = parameters();
    end

    % Parameter set: identifier.
    p.id = id;
    % Parameter set: center frequency.
    p.cfreq = cfreq;
    % Parameter set: name (free-form).
    p.name = name;
    % Chip: frequency (Hz).  
    p.chip_frq = round(dbwidth / (CHIP_NFRQ * ALPHABET_SIZE));
    % Chip: duration (s).
    p.chip_dur = params.pset_chip_len_mul / p.chip_frq;

    % Interim values.
    nblock = dbwidth / (p.chip_frq * ALPHABET_SIZE);
    [p.prim_q, p.prim_a] = primitive(fix(nblock));

    % Number of frequency blocks.
    p.nblock = p.prim_q - 1;
    % Available bandwidth.
    p.bwidth = p.nblock * p.chip_frq * ALPHABET_SIZE;

end
