//
// Copyright (c) 2019, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

`ifndef __OFS_PLAT_AVALON_MEM_RDWR_IF_VH__
`define __OFS_PLAT_AVALON_MEM_RDWR_IF_VH__

//
// Macros for replicating properties of an ofs_plat_avalon_mem_rdwr_if when
// defininig another instance of the interface.
//
`define OFS_PLAT_AVALON_MEM_RDWR_IF_REPLICATE_PARAMS(AVALON_IF) \
    .ADDR_WIDTH(AVALON_IF.ADDR_WIDTH_), \
    .DATA_WIDTH(AVALON_IF.DATA_WIDTH_), \
    .MASKED_SYMBOL_WIDTH(AVALON_IF.MASKED_SYMBOL_WIDTH_), \
    .BURST_CNT_WIDTH(AVALON_IF.BURST_CNT_WIDTH_)

`define OFS_PLAT_AVALON_MEM_RDWR_IF_REPLICATE_MEM_PARAMS(AVALON_IF) \
    .ADDR_WIDTH(AVALON_IF.ADDR_WIDTH_), \
    .DATA_WIDTH(AVALON_IF.DATA_WIDTH_), \
    .MASKED_SYMBOL_WIDTH(AVALON_IF.MASKED_SYMBOL_WIDTH_)


//
// Utilities for operating on interface ofs_plat_avalon_mem_rdwr_if.
//
// Ideally, the macros here would instead be tasks in the interface intself.
// Unfortunately, tasks within an interface can't use the interface as a
// parameter type. You can't build a task in an interface that operates on an
// instance of interface object. Instead, we resort to these ugly macros.
// Macros allow modules to operate without knowing some of the minor interface
// fields.
//
// General copy macros take OPER so the macro can be used in both combinational
// and registered contexts. Specify an operator: usually = or <=.
//

`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_MASTER_TO_SLAVE(MEM_SLAVE, OPER, MEM_MASTER) \
    MEM_SLAVE.rd_read OPER MEM_MASTER.rd_read; \
    MEM_SLAVE.rd_burstcount OPER MEM_MASTER.rd_burstcount; \
    MEM_SLAVE.rd_byteenable OPER MEM_MASTER.rd_byteenable; \
    MEM_SLAVE.rd_address OPER MEM_MASTER.rd_address; \
    MEM_SLAVE.rd_function OPER MEM_MASTER.rd_function; \
    MEM_SLAVE.rd_user OPER MEM_MASTER.rd_user; \
    MEM_SLAVE.wr_burstcount OPER MEM_MASTER.wr_burstcount; \
    MEM_SLAVE.wr_writedata OPER MEM_MASTER.wr_writedata; \
    MEM_SLAVE.wr_address OPER MEM_MASTER.wr_address; \
    MEM_SLAVE.wr_function OPER MEM_MASTER.wr_function; \
    MEM_SLAVE.wr_write OPER MEM_MASTER.wr_write; \
    MEM_SLAVE.wr_byteenable OPER MEM_MASTER.wr_byteenable; \
    MEM_SLAVE.wr_user OPER MEM_MASTER.wr_user

`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_MASTER_TO_SLAVE_COMB(MEM_SLAVE, MEM_MASTER) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_MASTER_TO_SLAVE(MEM_SLAVE, =, MEM_MASTER)

`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_MASTER_TO_SLAVE_FF(MEM_SLAVE, MEM_MASTER) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_MASTER_TO_SLAVE(MEM_SLAVE, <=, MEM_MASTER)


// Note these do not set clk, reset or instance_number since those
// fields may be handled specially.
`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_SLAVE_TO_MASTER(MEM_MASTER, OPER, MEM_SLAVE) \
    MEM_MASTER.rd_readdata OPER MEM_SLAVE.rd_readdata; \
    MEM_MASTER.rd_readdatavalid OPER MEM_SLAVE.rd_readdatavalid; \
    MEM_MASTER.rd_response OPER MEM_SLAVE.rd_response; \
    MEM_MASTER.rd_readresponseuser OPER MEM_SLAVE.rd_readresponseuser; \
    MEM_MASTER.wr_writeresponsevalid OPER MEM_SLAVE.wr_writeresponsevalid; \
    MEM_MASTER.wr_response OPER MEM_SLAVE.wr_response; \
    MEM_MASTER.wr_writeresponseuser OPER MEM_SLAVE.wr_writeresponseuser

`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_SLAVE_TO_MASTER_COMB(MEM_MASTER, MEM_SLAVE) \
    MEM_MASTER.rd_waitrequest = MEM_SLAVE.rd_waitrequest; \
    MEM_MASTER.wr_waitrequest = MEM_SLAVE.wr_waitrequest; \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_SLAVE_TO_MASTER(MEM_MASTER, =, MEM_SLAVE)

// Note the lack of waitrequest in the non-blocking assignment. The
// ready/enable protocol must be handled explicitly.
`define OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_SLAVE_TO_MASTER_FF(MEM_MASTER, MEM_SLAVE) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_FROM_SLAVE_TO_MASTER(MEM_MASTER, <=, MEM_SLAVE)


//
// Initialization macros ought to just be tasks in the interface, but QuestSim
// treats tasks as active even if they are never invoked, leading to errors
// about multiple drivers.
//
// User extension fields are not initialized, leaving them at 'x and making it
// obvious that these fields are not part of the protocol.
//

`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_MASTER(MEM_MASTER, OPER) \
    MEM_MASTER.rd_read OPER 1'b0; \
    MEM_MASTER.rd_burstcount OPER '0; \
    MEM_MASTER.rd_byteenable OPER '0; \
    MEM_MASTER.rd_address OPER '0; \
    MEM_MASTER.rd_function OPER '0; \
    MEM_MASTER.wr_burstcount OPER '0; \
    MEM_MASTER.wr_writedata OPER '0; \
    MEM_MASTER.wr_address OPER '0; \
    MEM_MASTER.wr_function OPER '0; \
    MEM_MASTER.wr_write OPER 1'b0; \
    MEM_MASTER.wr_byteenable OPER '0

`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_MASTER_COMB(MEM_MASTER) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_MASTER(MEM_MASTER, =)

`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_MASTER_FF(MEM_MASTER) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_MASTER(MEM_MASTER, <=)


`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_SLAVE(MEM_SLAVE, OPER) \
    MEM_SLAVE.rd_waitrequest OPER 1'b0; \
    MEM_SLAVE.rd_readdata OPER '0; \
    MEM_SLAVE.rd_readdatavalid OPER 1'b0; \
    MEM_SLAVE.rd_response OPER '0; \
    MEM_SLAVE.wr_waitrequest OPER 1'b0; \
    MEM_SLAVE.wr_writeresponsevalid OPER 1'b0; \
    MEM_SLAVE.wr_response OPER '0

`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_SLAVE_COMB(MEM_SLAVE) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_SLAVE(MEM_SLAVE, =)

`define OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_SLAVE_FF(MEM_SLAVE) \
    `OFS_PLAT_AVALON_MEM_RDWR_IF_INIT_SLAVE(MEM_SLAVE, <=)


`endif // __OFS_PLAT_AVALON_MEM_RDWR_IF_VH__
