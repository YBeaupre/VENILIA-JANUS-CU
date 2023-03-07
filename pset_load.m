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
% PSET_LOAD Load a parameter set structure from a CSV file.
%
% Inputs:
%    file       Path to a CSV file containing a table of parameter sets.
%    id         Parameter set Id.
%    params     Optional parameters structure, created by PARAMETERS.
%
% Outputs:
%    p          Parameter set structure.
%
% See also PSET_NEW, PARAMETERS.

function p = pset_load(file, id, params)
    if (nargin < 3)
        params = parameters();
    end

    p = {};
    fd = fopen(file, 'r');
    if (fd == -1)
        error('Parameter set file not found');
    end

    while ~feof(fd),
        l = fgetl(fd);
        [val, count, err, nidx] = sscanf(l, '%d , %d , %d , %[^\n]');

        if (count == 4)
            if (val(1) == id)
                p = pset_new(val(1), char(val(4:end))', val(2), val(3), params);
                fclose(fd);
                return
            end
        end
    end

    if isempty(p)
        error('Parameter set id not present in parameter set file.');
    end

    fclose(fd);
end
