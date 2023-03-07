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
%| Authors: Ricardo Martins, Luigi Elia D'Amaro                           |
%+------------------------------------------------------------------------+
%
% PACKET_TX_INTERVAL_LOOKUP_INDEX(index, res_rep)
%
% Return the transmit reservation time or repeat interval (in seconds)
% associated with the supplied 'index' and reservation/repeat flag.
%
% Inputs:
%   index    Index.
%   res_rep  Reservation or repeat flag.
%
% Outputs:
%   value    Transmit reservation time or repeat interval (in seconds).
%
% See also PACKET_TX_INTERVAL_LOOKUP_VALUE, PACKET_TX_RESERVATION_TIME_TABLE,
% PACKET_TX_REPEAT_INTERVAL_TABLE.
%

function value = packet_tx_interval_lookup_index(index, res_rep)
    if (res_rep == 0)
        table = packet_tx_reservation_time_table;
    else
        table = packet_tx_repeat_interval_table;
    end
    value = table(index + 1);
end
