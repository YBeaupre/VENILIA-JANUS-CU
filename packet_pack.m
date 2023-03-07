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
% PACKET_PACK Pack JANUS packet.
%
% Packs one JANUS packet, created using PACKET_NEW, into a sequence of
% 64 bits and computes it's CRC.
%
% Inputs:
%   pkt        Packet structure created with PACKET_NEW.
%
% Outputs:
%   bits       Packet bits.
%   crg_bits   Optional cargo bits.
%   pkt        Packet structure with computed CRC.
%
% See also PACKET_NEW, PACKET_UNPACK.
%

function [bits, crg_bits, pkt] = packet_pack(pkt)
    global verbose;

    defaults;

    % Initialize bitset.
    bin = zeros(1, 'uint64');

    % 4 bits: Version Number.
    pkt.version = uint64(pkt.version);
    bin = bitshift(pkt.version, 60);

    % 1 bit: Mobility Flag.
    pkt.mobility = uint64(pkt.mobility ~= 0);
    bin = bitor(bin, bitshift(pkt.mobility, 59));

    % 1 bit: Schedule Flag.
    pkt.schedule = uint64(0);

    % 1 bit: Tx/Rx Flag.
    pkt.tx_rx = uint64(pkt.tx_rx ~= 0);
    bin = bitor(bin, bitshift(pkt.tx_rx, 57));

    % 1 bit: Forwarding Capability.
    pkt.forward = uint64(pkt.forward ~= 0);
    bin = bitor(bin, bitshift(pkt.forward, 56));

    % 8 bits: Class User Identifier.
    pkt.class_id = uint64(bitand(pkt.class_id, 2^8 - 1));
    bin = bitor(bin, bitshift(pkt.class_id, 48));
    pkt.class_id_name = user_class_lookup_index(pkt.class_id);

    % 6 bits: Application Type.
    pkt.app_type = uint64(bitand(pkt.app_type, 2^6 - 1));
    bin = bitor(bin, bitshift(pkt.app_type, 42));

    tx_interval = 0;
    if (isfield(pkt, 'reserv_time') && pkt.reserv_time > 0)
        pkt.reserv_repeat = uint64(0);
        tx_interval = pkt.reserv_time;
    elseif (isfield(pkt, 'repeat_int') && pkt.repeat_int > 0)
        pkt.reserv_repeat = uint64(1);
        tx_interval = pkt.repeat_int;
    end

    if (tx_interval ~= 0)
        [result, evalue1, evalue2, index] = packet_tx_interval_lookup_value(tx_interval, pkt.reserv_repeat);
        index = uint64(index);
        if (result == 0 || result == 1)
            pkt.schedule = uint64(1);
            tx_interval = evalue1;
        elseif (result == 2)
            pkt.schedule = uint64(1);
            if (pkt.reserv_repeat == 0)
                index = uint64(uint32(index) + 1);
                tx_interval = evalue2;
            else
                tx_interval = evalue1;
            end
        else
            error('janus:packet_pack:inv_interval', 'Invalid reservation time or repeat interval.')
        end

        if (pkt.reserv_repeat == 0)
            pkt.reserv_time = tx_interval;
        else
            pkt.repeat_int = tx_interval;
        end

        % 1 bit: Schedule Flag.
        bin = bitor(bin, bitshift(pkt.schedule, 58));
        % 1 bit: Reservation/Repeat Flag.
        bin = bitor(bin, bitshift(pkt.reserv_repeat, 41));
        % 7 bits: Reservation Time or Repeat Interval Table Index.
        bin = bitor(bin, bitshift(index, 34));
    end

    if (pkt.schedule == 0)
        app_data_len = 34;
    else
        app_data_len = 26;
    end
    
    plugin = sprintf('plugin_%03d_%02d', pkt.class_id, pkt.app_type);
    
    cargo_size = 0;
    if (pkt.cargo_size > 0)
        % cargo already provided
        cargo_size = pkt.cargo_size;
        if (cargo_size > JANUS_MAX_PKT_CRG_SIZE)
            error('janus:packet_pack:inv_cargo_size', ...
                [ 'cargo size ' cargo_size ':  exceeding maximum value.' ]);
        end
    else
        if (isfield(pkt, 'packet_app_fields'))
            try
                eval(['[pkt.cargo, cargo_size, pkt.packet_app_fields] = ' plugin '(''cargo_encode'',' ...
                    ' pkt.packet_app_fields, cargo_size);']);
                if (cargo_size < 0)
                    error('janus:packet_pack:inv_cargo_size', 'Invalid cargo size.')
                end
                
            catch ME_cargo
                if (verbose)
                    disp([plugin ': ' ME_cargo.message '.' ]);
                end
            end
        end
    end

    %  Set application data.
    if (pkt.app_data == intmax('uint64'))
        % app_data not provided
        pkt.app_data = uint64(0);
        
        if (isfield(pkt, 'packet_app_fields') || (cargo_size > 0))
            try 
                if (~isfield(pkt, 'packet_app_fields'))
                    pkt.packet_app_fields = [];
                end
                eval(['[pkt.cargo_size, pkt.app_data, pkt.packet_app_fields] = ' plugin '(''app_data_encode'',' ...
                    '  cargo_size, pkt.packet_app_fields, app_data_len);']);
                if (pkt.cargo_size < 0)
                    error('janus:packet_pack:inv_cargo_size', 'Invalid cargo size.')
                end
                % pad cargo if needed
                pad = zeros(1, pkt.cargo_size - cargo_size);
                pkt.cargo = [pkt.cargo pad];
            catch ME_app_data
                if (verbose)
                    disp([plugin ': ' ME_app_data.message '.' ]);
                end
            end
        end
        
    end

    if (pkt.app_data > 2^app_data_len)
        error('janus:packet_pack:inv_app_data', 'Invalid application data.')
    end

    % 26/34 bits: Application Data.
    bin = bitor(bin, bitshift(pkt.app_data, 8));

    % 8 bits: CRC.
    u8 = fliplr(typecast(bin, 'uint8'));
    u8(8) = crc(u8(1 : 7), CRC_POLY);
    pkt.crc = u8(8);

    pkt.crc_validity = 1;

    % Convert to bits.
    bits = bytes2bits(u8);
    crg_bits = bytes2bits(pkt.cargo);

    % Packet bytes.
    pkt.bytes = u8;
end
