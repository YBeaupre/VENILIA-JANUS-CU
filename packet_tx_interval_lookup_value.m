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
%| Author: Luigi Elia D'Amaro                                             |
%+------------------------------------------------------------------------+
%
% PACKET_TX_INTERVAL_LOOKUP_VALUE(dvalue, res_rep)
%
% Lookup the index associated with a given transmit reservation time or
% repeat interval (in seconds) in the reservation time table or in the
% repeat interval table, according to reservation or repeat flag.
% If the desired value or an approximation (within a tollerance) is
% available in the lookup table, then the found value and its table
% index are returned.
% If the desired value is not available in the lookup table, the two
% nearest values (one lower and one higher than the desired value)
% and the index of the lower one are returned.
% If desired value is too low, lowest table value and an invalid index
% are returned.
% If desired value is too high, highest table value and an invalid
% index are returned.
%
% Inputs:
%   dvalue  Desired value.
%   res_rep Reservation or repeat flag.
%
% Outputs:
%   result  Result of lookup. It can be:
%           0, if dvalue is found;
%           1, if an approximation of dvalue is found;
%           2, if dvalue is between two values (both are returned);
%           3, if dvalue is too low (invalid index is returned);
%           4, if dvalue is too high (invalid index is returned).
%   evalue1 Found table value, if result is 0 or 1.
%           Highest table value lower than dvalue, if result is 2.
%           Lowest table value, if result is 3.
%           Highest table value, if result is 4.
%   evalue2 Lowest table value higher than dvalue, if result is 2,
%           0.0 otherwise.
%   index   Index of found table value, if result is 0 or 1.
%           Index of the evalue1, if result is 2 (index+1 for evalue2).
%           Invalid index (-1), if result is 3 or 4.
%
% See also PACKET_TX_INTERVAL_LOOKUP_VALUE,
% PACKET_TX_RESERVATION_TIME_TABLE, PACKET_TX_REPEAT_INTERVAL_TABLE.
%

function [result, evalue1, evalue2, index] = packet_tx_interval_lookup_value(dvalue, res_rep)
    % Exact time.
    JANUS_PACKET_EXACT_TIME = 0;
    % Approximated value, within 5% tollerance of the interval step.
    JANUS_PACKET_APPROXIMATED_TIME = 1;
    % Between two values.
    JANUS_PACKET_BETWEEN_TWO_VALUES = 2;
    % Below the minimum value.
    JANUS_PACKET_ERROR_MIN = 3;
    % Beyond the maximum value.
    JANUS_PACKET_ERROR_MAX = 4;

    if (res_rep == 0)
        table = packet_tx_reservation_time_table;
    else
        table = packet_tx_repeat_interval_table;
    end

    evalue2 = 0.0;
    index = -1;
    
    if (dvalue < table(1))
        evalue1 = table(1);
        result = JANUS_PACKET_ERROR_MIN;
        return
    end

    if (dvalue > table(end))
        evalue1 = table(end);
        result = JANUS_PACKET_ERROR_MAX;
        return
    end

    index = find(dvalue <= table, 1, 'first');

    if (dvalue == table(index))
        evalue1 = table(index);
        index = index - 1;
        result = JANUS_PACKET_EXACT_TIME;
        return
    end

    % Accepting if in 5% tollerance of the interval step.
    interval_tollerance = ((table(index) - table(index - 1)) * 0.05);

    if ((table(index) - dvalue) < interval_tollerance)
        evalue1 = table(index);
        index = index - 1;
        result = JANUS_PACKET_APPROXIMATED_TIME;
        return
    end

    if ((dvalue - table(index - 1)) < interval_tollerance)
        evalue1 = table(index - 1);
        index = index - 2;
        result = JANUS_PACKET_APPROXIMATED_TIME;
        return
    end

    evalue1 = table(index - 1);
    evalue2 = table(index);
    index = index - 2;
    result = JANUS_PACKET_BETWEEN_TWO_VALUES;
end
