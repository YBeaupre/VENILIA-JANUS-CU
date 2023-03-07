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
%| Authors: Giovanni Zappa, Luigi Elia D'Amaro                            |
%+------------------------------------------------------------------------+
%
% DETECTOR_PARAMETERS Computes parameters of preamble for detector.
%
% Inputs:
%    params      Parameters structure.
%    pset        Parameters set structure.
%    f32slots    First 32 hopping sequence values.
%
% Outputs:
%    freq_vec    Vector of used baseband frequencies in the preamble.
%    chip_order  Indexes order of preamble's frequencies.
%
% See also PSET_NEW, PARAMETERS.

function [freq_vec, chip_order] = detector_parameters(params, pset, f32slots)

    ofslots = (-pset.nblock - 1 : pset.nblock) * pset.chip_frq;
    freq_sec = ofslots(f32slots(:) * 2 + 1 + params.c32_sequence(:));

    freq_vec = unique(sort(freq_sec));
    chip_order = arrayfun(@(f) find(freq_vec == f), freq_sec);
end
