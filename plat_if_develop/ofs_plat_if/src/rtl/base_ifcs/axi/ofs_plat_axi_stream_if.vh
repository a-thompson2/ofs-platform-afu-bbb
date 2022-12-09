// Copyright (C) 2022 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef __OFS_PLAT_AXI_STREAM_IF_VH__
`define __OFS_PLAT_AXI_STREAM_IF_VH__

//
// Macro for replicating properties of an ofs_plat_axi_stream_if when
// defining another instance of the interface. SystemVerilog doesn't
// allow querying a "type" parameter, so the only option is to
// generate an opaque instance of the same size, using the equivalent
// interface ofs_plat_axi_stream_opaque_if.
//
`define OFS_PLAT_AXI_STREAM_IF_REPLICATE_OPAQUE(AXI_IF) \
    .TDATA_WIDTH(AXI_IF.TDATA_WIDTH), \
    .TUSER_WIDTH(AXI_IF.TUSER_WIDTH_)

// Replicate AXI stream interface but don't set type data type so
// that other code can set it.
`define OFS_PLAT_AXI_STREAM_IF_REPLICATE_PARAMS(AXI_IF)


//
// General copy macros take OPER so the macro can be used in both combinational
// and registered contexts. Specify an operator: usually = or <=.
//

`define OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, OPER, STREAM_SOURCE) \
    STREAM_SINK.t OPER STREAM_SOURCE.t; \
    STREAM_SINK.tvalid OPER STREAM_SOURCE.tvalid

`define OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK_COMB(STREAM_SINK, STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, =, STREAM_SOURCE)

`define OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK_FF(STREAM_SINK, STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, <=, STREAM_SOURCE)

 // Old naming, maintained for compatibility
`define OFS_PLAT_AXI_STREAM_IF_FROM_MASTER_TO_SLAVE(STREAM_SINK, OPER, STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, OPER, STREAM_SOURCE)
`define OFS_PLAT_AXI_STREAM_IF_FROM_MASTER_TO_SLAVE_COMB(STREAM_SINK, STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, =, STREAM_SOURCE)
`define OFS_PLAT_AXI_STREAM_IF_FROM_MASTER_TO_SLAVE_FF(STREAM_SINK, STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SOURCE_TO_SINK(STREAM_SINK, <=, STREAM_SOURCE)


`define OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, OPER, STREAM_SINK) \
    STREAM_SOURCE.tready OPER STREAM_SINK.tready

`define OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE_COMB(STREAM_SOURCE, STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, =, STREAM_SINK)

`define OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE_FF(STREAM_SOURCE, STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, <=, STREAM_SINK)

 // Old naming, maintained for compatibility
`define OFS_PLAT_AXI_STREAM_IF_FROM_SLAVE_TO_MASTER(STREAM_SOURCE, OPER, STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, OPER, STREAM_SINK)
`define OFS_PLAT_AXI_STREAM_IF_FROM_SLAVE_TO_MASTER_COMB(STREAM_SOURCE, STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, =, STREAM_SINK)
`define OFS_PLAT_AXI_STREAM_IF_FROM_SLAVE_TO_MASTER_FF(STREAM_SOURCE, STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_FROM_SINK_TO_SOURCE(STREAM_SOURCE, <=, STREAM_SINK)


//
// Initialization macros.
//

`define OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, OPER) \
    STREAM_SOURCE.t OPER '0; \
    STREAM_SOURCE.valid OPER 1'b0

`define OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE_COMB(STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, =)

`define OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE_FF(STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, <=)

 // Old naming, maintained for compatibility
`define OFS_PLAT_AXI_STREAM_IF_INIT_MASTER(STREAM_SOURCE, OPER) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, OPER)
`define OFS_PLAT_AXI_STREAM_IF_INIT_MASTER_COMB(STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, =)
`define OFS_PLAT_AXI_STREAM_IF_INIT_MASTER_FF(STREAM_SOURCE) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SOURCE(STREAM_SOURCE, <=)


`define OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, OPER) \
    STREAM_SINK.tready OPER 1'b0

`define OFS_PLAT_AXI_STREAM_IF_INIT_SINK_COMB(STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, =)

`define OFS_PLAT_AXI_STREAM_IF_INIT_SINK_FF(STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, <=)

 // Old naming, maintained for compatibility
`define OFS_PLAT_AXI_STREAM_IF_INIT_SLAVE(STREAM_SINK, OPER) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, OPER)
`define OFS_PLAT_AXI_STREAM_IF_INIT_SLAVE_COMB(STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, =)
`define OFS_PLAT_AXI_STREAM_IF_INIT_SLAVE_FF(STREAM_SINK) \
    `OFS_PLAT_AXI_STREAM_IF_INIT_SINK(STREAM_SINK, <=)


//
// Field-by-field copies of structs, needed when source and sink have
// different field widths.
//

`define OFS_PLAT_AXI_STREAM_IF_COPY_T(STREAM_SINK_T, OPER, STREAM_SOURCE_T) \
    STREAM_SINK_T.last OPER STREAM_SOURCE_T.last; \
    STREAM_SINK_T.user OPER STREAM_SOURCE_T.user; \
    STREAM_SINK_T.data OPER STREAM_SOURCE_T.data


//
// Standard validation macros. Copying using structs maps data incorrectly
// if the parameters to a pair of interfaces are different. Standard checks
// for incompatibility raise simulation-time errors.
//

`define OFS_PLAT_AXI_STREAM_IF_CHECK_PARAMS_MATCH(STREAM_IFC0, STREAM_IFC1) \
    initial \
    begin \
        if (STREAM_IFC0.TUSER_WIDTH != STREAM_IFC1.TUSER_WIDTH) \
            $fatal(2, "** ERROR ** %m: AXI-S interface TUSER_WIDTH mismatch (%0d vs. %0d)!", \
                   STREAM_IFC0.TUSER_WIDTH, STREAM_IFC1.TUSER_WIDTH); \
        if (STREAM_IFC0.TDATA_WIDTH != STREAM_IFC1.TDATA_WIDTH) \
            $fatal(2, "** ERROR ** %m: AXI-S interface TDATA_WIDTH mismatch (%0d vs. %0d)!", \
                   STREAM_IFC0.TDATA_WIDTH, STREAM_IFC1.TDATA_WIDTH); \
    end

`endif // __OFS_PLAT_AXI_STREAM_IF_VH__
