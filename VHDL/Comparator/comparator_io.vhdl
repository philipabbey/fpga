-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Input-Output logic required in order to instantiate a generic comparator component
-- in a device and verify synthesis and timing results are as expected. Due to the
-- need for precise bus widths and placed pins in Quartus Prime, the bus width can
-- not be easily varied for synthesis, which limits evaluation of the VHDL code. Try
-- Synplify Pro instead for a rough estimate without full placement.
--
-- Instance:
--   Data Bus Width: 101
--   Pipeline Depth:   3
--   LUT Size:         6
--
-- Creates a tree with maximum logic depth of 1, and division stages 6, 6, 3.
--
-- Tested using: Quartus Prime Ver 18.1.1 Build 646 04/11/2019.
--
-- Timing Results:
--   Model: Slow 1100mV 85C
--   F Max: 426.44 Mhz
--
-- P A Abbey, 23 August 2019
--
-------------------------------------------------------------------------------------

-- # *************************** ModelSim construction report ***************************
-- #  Pipeline depth:         3
-- #  Compare Width:        101
-- #  LUT Size:               6
-- #  Max LUT Depth:          1
-- #  Expected LUT depth:     1 (calculated externally from the DUT's toplevel generics)
-- #
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- #
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:   6, Max Width:   18, LUT Depth: 1
-- # Depth: 2, Divide:   6, Max Width:    3, LUT Depth: 1
-- # Depth: 1, Divide:   1, Max Width:    6, LUT Depth: 1
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- #
-- # ************************************************************************************
--
-- The ModelSim report provides only sufficient details to calculate the expected
-- worst case logic usage, for a fully populated tree. In this case that would be a
-- 108 bit data width rather than only 101 bits. Based on the ModelSim report one
-- might expect:
--
-- LUT Size = 6
-- Depth	Divide	Width		Flops	LUTs (Maximum LUT Depth = 1)
--   3      6      18        1    1
--   2      6       3        6    6
--   1      -       6       36   36
--                        ----------
--            No more than  43   43
--
-- The non-fully populated (101 bit data width) tree uses 41 of each. No further
-- logic optimisations have been offered by synthesis.
--
-- +---------------------------- Quartus Prime Construction Report ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- ; Analysis & Synthesis Resource Utilization by Entity                                                                                                                                                                                                                                                        ;
-- +-------------------------------------------------+---------------------+---------------------------+-------------------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- ; Compilation Hierarchy Node                      ; Combinational ALUTs ; Dedicated Logic Registers ; Block Memory Bits ; DSP Blocks ; Pins ; Virtual Pins ; Full Hierarchy Name                                                                                              ; Entity Name   ; Library Name ;
-- +-------------------------------------------------+---------------------+---------------------------+-------------------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- ; |comparator_io                                  ; 41 (0)              ; 448 (407)                 ; 0                 ; 0          ; 205  ; 0            ; |comparator_io                                                                                                   ; comparator_io ; work         ;
-- ;    |comparator:comparator_c|                    ; 41 (1)              ; 41 (1)                    ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c                                                                           ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:0:comparator_c|    ; 7 (1)               ; 7 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:1:comparator_c|    ; 7 (1)               ; 7 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:2:comparator_c|    ; 7 (1)               ; 7 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:3:comparator_c|    ; 7 (1)               ; 7 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:4:comparator_c|    ; 7 (1)               ; 7 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:5:comparator_c|    ; 5 (1)               ; 5 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 1 (1)               ; 1 (1)                     ; 0                 ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- +-------------------------------------------------+---------------------+---------------------------+-------------------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- Note: For table entries with two numbers listed, the numbers in parentheses indicate the number of resources of the given type used by the specific entity alone. The numbers listed outside of parentheses indicate the total resources of the given type used by the specific entity and all of its sub-entities in the hierarchy.
--
-- +------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- ; Fitter Resource Utilization by Entity                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ;
-- +-------------------------------------------------+----------------------+----------------------------------+---------------------------------------------------+----------------------------------+----------------------+---------------------+---------------------------+---------------+-------------------+-------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- ; Compilation Hierarchy Node                      ; ALMs needed [=A-B+C] ; [A] ALMs used in final placement ; [B] Estimate of ALMs recoverable by dense packing ; [C] Estimate of ALMs unavailable ; ALMs used for memory ; Combinational ALUTs ; Dedicated Logic Registers ; I/O Registers ; Block Memory Bits ; M10Ks ; DSP Blocks ; Pins ; Virtual Pins ; Full Hierarchy Name                                                                                              ; Entity Name   ; Library Name ;
-- +-------------------------------------------------+----------------------+----------------------------------+---------------------------------------------------+----------------------------------+----------------------+---------------------+---------------------------+---------------+-------------------+-------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- ; |comparator_io                                  ; 132.5 (101.9)        ; 220.0 (188.1)                    ; 87.5 (86.2)                                       ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 43 (2)              ; 448 (407)                 ; 0 (0)         ; 0                 ; 0     ; 0          ; 205  ; 0            ; |comparator_io                                                                                                   ; comparator_io ; work         ;
-- ;    |comparator:comparator_c|                    ; 30.6 (0.8)           ; 31.9 (0.8)                       ; 1.4 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 41 (1)              ; 41 (1)                    ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c                                                                           ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:0:comparator_c|    ; 5.3 (0.8)            ; 5.3 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 7 (1)               ; 7 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:0:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:1:comparator_c|    ; 5.3 (0.8)            ; 5.6 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 7 (1)               ; 7 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 1.0 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.6 (0.6)            ; 0.6 (0.6)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:1:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:2:comparator_c|    ; 5.3 (0.8)            ; 5.8 (0.8)                        ; 0.5 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 7 (1)               ; 7 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 1.0 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 1.0 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:2:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:3:comparator_c|    ; 5.3 (0.8)            ; 5.3 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 7 (1)               ; 7 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:3:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:4:comparator_c|    ; 5.3 (0.8)            ; 5.5 (0.8)                        ; 0.3 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 7 (1)               ; 7 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:4:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:4:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:5:comparator_c| ; 0.8 (0.8)            ; 1.0 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:4:comparator_c|comparator:\g:recurse:5:comparator_c ; comparator    ; work         ;
-- ;       |comparator:\g:recurse:5:comparator_c|    ; 3.6 (0.7)            ; 3.8 (0.7)                        ; 0.3 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 5 (1)               ; 5 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c                                      ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:0:comparator_c| ; 0.8 (0.8)            ; 1.0 (1.0)                        ; 0.3 (0.3)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:0:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:1:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:1:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:2:comparator_c| ; 0.8 (0.8)            ; 0.8 (0.8)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:2:comparator_c ; comparator    ; work         ;
-- ;          |comparator:\g:recurse:3:comparator_c| ; 0.7 (0.7)            ; 0.7 (0.7)                        ; 0.0 (0.0)                                         ; 0.0 (0.0)                        ; 0.0 (0.0)            ; 1 (1)               ; 1 (1)                     ; 0 (0)         ; 0                 ; 0     ; 0          ; 0    ; 0            ; |comparator_io|comparator:comparator_c|comparator:\g:recurse:5:comparator_c|comparator:\g:recurse:3:comparator_c ; comparator    ; work         ;
-- +-------------------------------------------------+----------------------+----------------------------------+---------------------------------------------------+----------------------------------+----------------------+---------------------+---------------------------+---------------+-------------------+-------+------------+------+--------------+------------------------------------------------------------------------------------------------------------------+---------------+--------------+
-- Note: For table entries with two numbers listed, the numbers in parentheses indicate the number of resources of the given type used by the specific entity alone. The numbers listed outside of parentheses indicate the total resources of the given type used by the specific entity and all of its sub-entities in the hierarchy.


library ieee;
  use ieee.std_logic_1164.all;

entity comparator_io is
  port(
    clk    : in  std_ulogic;
    reset  : in  std_ulogic;
    data_a : in  std_ulogic_vector(100 downto 0);
    data_b : in  std_ulogic_vector(100 downto 0);
    equal  : out std_ulogic
  );
end entity;


architecture rtl of comparator_io is

  signal reset_reg : std_ulogic_vector(1 downto 0);

  type data_t is array(1 downto 0) of std_ulogic_vector(data_a'range);

  signal data_a_i : data_t;
  signal data_b_i : data_t;
  signal equal_i  : std_ulogic;

begin
  assert data_a'length = data_b'length
    report "Data input for comparison must be of equal length."
    severity failure;

  comparator_c : entity work.comparator
    generic map (
     depth_g      => 3,
     data_width_g => data_a'length,
     lutsize_g    => 6
    )
    port map (
     clk    => clk,
     reset  => reset_reg(1),
     data_a => data_a_i(1),
     data_b => data_b_i(1),
     equal  => equal_i
    );

  process(clk, reset)
  begin
    -- Asynchronous reset for synchronising the reset
    -- See articles at:
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-other-Design/bc-p/931744
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-and-other-Design/ba-p/887366
    if reset = '1' then
      reset_reg  <= "11";
    elsif rising_edge(clk) then
      reset_reg  <= reset_reg(0) & '0';
    end if;
  end process;

  -- Inputs
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        data_a_i <= (others => (others => '0'));
        data_b_i <= (others => (others => '0'));
      else
        -- double retime data
        data_a_i <= data_a_i(0) & data_a;
        data_b_i <= data_b_i(0) & data_b;
      end if;
    end if;
  end process;

  -- Outputs
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        equal <= '0';
      else
        equal <= equal_i;
      end if;
    end if;
  end process;

end architecture;
