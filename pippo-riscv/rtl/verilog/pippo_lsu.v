/*
 * File:        pippo_lsu.v
 * Project:     pippo
 * Designer:    fang@ali
 * Mainteiner:  fang@ali
 * Checker:
 * Description:
 *      һ����Ҫ����
                �ô棭���ݶ����ƴ��
                ʵ��ԭ�ӷô�ָ���
	            �����ô�����ж�����align, dbuserr
        ����Big-endian implementation notes
        1����С����ָ�����ֽڣ�byte������λ��bit���ڵ����֣�word����layout�ķ�ʽ��Ѱַ�淶��
                ����MSB/msb..LSB/lsb���֣�word���е����к�Ѱַ
                ��˸�ʽ���£�
                ������������int i = 0x12345678                
                ����洢���ֽڵ�ַ�������������У�
                    [2'b00][2'b01][2'b10][2'b11]
                    ���ֽ����ݷֲ�Ϊ��[0x12][0x34][0x56][0x78]
                    ע�⣺��ͬ���̿��ܴ洢�����ֽ�����˳������ͼ���෴
                    [2'b11][2'b10][2'b01][2'b00]
                    ���ֽ����ݷֲ�Ϊ��[0x78][0x56][0x34][0x12]                    
        2����С�˸��ô�ϵͳ�����ߺʹ洢����������CPU�ڲ���֯���
                �����CPU�ڲ���֯��ָ��Bit��CPU�ڲ��Ĵ���������ͨ·��layout
                ��ͳһ����CPU�ڲ�REG������ͨ·����Ϊ�����Ϊmsb���Ҷ�Ϊlsb
        3������CPU�ڲ��Ĵ��������λѰַ��RISCV����С��ģʽ��֯��
                ��msb��lsb��bit��ַ�ɸߵ��͵ĸ�ʽ��֯��
        4���Ĵ������λ��Ѱַ���ʣ���HDL���������أ�
            ����verilog�У�����bit����С������[3:0]�ʹ������[0:3]��0x1��Ϊ4'b0001��
        5��С��ϵͳ�����ݵ�ַ��ƴ�ӹ�������
            1��	Byte�ô棬��ַΪ2'b00
            �����REG������֯��	[31:8]-x; [7:0]-data
            MEM������������֯��	[31:8]-x; [7:0]-x
            2��	Byte�ô棬��ַΪ2'b01
            �����REG������֯��	[31:8]-x; [7:0]-data
            MEM������������֯��	[31:16]-x; [15:8]-data; [7:0]-x
            3��	Byte�ô棬��ַΪ2'b10
            �����REG������֯��	[31:8]-x; [7:0]-data
            MEM������������֯��	[31:24]-x; [23:16]-data; [15:0]-x
            4��	Byte�ô棬��ַΪ2'b11
            �����REG������֯��	[31:8]-x; [7:0]-data
            MEM������������֯��	[31:24]-x; [23:0]-data
            5��	Halfword�ô棬��ַΪ2'b00
            �����REG������֯��	[31:16]-x; [15:0]-data
            MEM������������֯��	[31:16]-x; [15:0]-data
            6��	Halfword�ô棬��ַΪ2'b10
            �����REG������֯��	[31:16]-x; [15:0]-data
            MEM������������֯��	[31:16]-data; [15:0]-x
            7��	Word�ô棬��ַΪ2'b00
            �����REG������֯��	[31:0]-data
            MEM������������֯��	[31:0]-data
            ���У�Haflword��word�ô�ʱ������������ַ����Ϊ�Ƕ�����ʡ�    
        ����ע������
            1���жϵĲ�����Ŀǰpippo����У����еķǶ�����ʶ�������жϣ����ο��ֲ�
            2����ַ���ɺʹ洢���ʵĶ�����ͨ��d-imxЭ��/multicycleʵ�֣�
                �����lsu����Ӧ��dmc֮��Ϊ����߼�������Ϊfalse/multi-cycle path
                d-imx: ͨ��imxЭ���address��data phaseʵ�ֶ����ڷֲ���
                multicycle/lsu_stall: ��core�ڲ�������ˮ�ȴ�����
 * Task.I:
 *      [TBD] �������IMXЭ�鴦��
 *          mem2reg���ȴ�ack��Ч�Ŵ���
 *          reg2mem���ȴ�addr_ack��Ч���ͳ�����
 *          dmc�����Ƿ���Ҫ���ص�ַ�ĵ�λ��
 *      [TBD] ��ַ���ɺʹ洢����
 *          d-imx��Ƶ�ע�������rqt���Ľ��е�ַ�����ܷ�֤ʱ��Ҫ��
 *          �޸�d-imxЭ�飬ȡ����ַ��Ӧ�źźͻ�·����ȥ��rty_i�źź�����߼�
 *          ��ˮ������������ˮ�Ĵ�������֧�������ķô�
 *      [TBD] ����ˮ�߿��ƹ�ϵ��ȥ��ID��multicycle���Ʒô�ָ��ִ��ʱ�Ķ����߼�������lsu_stall���ƶ����߼�      
 *      [TBD] ��dmcģ���������write-buffer������ˮ��Ӱ�죭store��ɵı�־��д��wb����, �����д��write-buffer���ݷ��������ж�?
 *      [TBD]����load����mem2reg��store����reg2mem���ܷ�������ܻ��ʡ�����
 *      [TBD]�ɷ�����ƴ�ӺͶ���ȹ����Ƶ�imx�д��� 
 */
 
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "def_pippo.v"

module pippo_lsu(

    clk, rst,
    
	lsu_uops, addrbase, addrofs, reg_zero, 
    lsu_datain, lsu_dataout, 
    lsu_stall, lsu_done,
    lsu_addr,
    
    set_atomic, clear_atomic,

    so, 
    cr0_lsu,
    cr0_lsu_we, 
    
    sig_align, sig_dbuserr,

	dimx_adr_o, dimx_rqt_o, dimx_we_o, dimx_sel_o, dimx_dat_o,
	dimx_dat_i, dimx_ack_i, dimx_err_i
);

parameter dw = `OPERAND_WIDTH;

//
// I/O
//
input       clk;
input       rst;

//
// Internal i/f
//
input	[31:0]		addrbase;
input	[31:0]		addrofs;
input	[dw-1:0]	lsu_datain;
input	[`LSUUOPS_WIDTH-1:0]	lsu_uops;

output	[dw-1:0]	lsu_dataout;
output  [31:0]      lsu_addr; 
output				lsu_stall;
output				lsu_done;
output				sig_align;
output				sig_dbuserr;

//
// External i/f to DC
//
output	[31:0]		dimx_adr_o;
output				dimx_rqt_o;
output				dimx_we_o;
output	[7:0]		dimx_sel_o;
output	[dw-1:0]		dimx_dat_o;
input	[dw-1:0]		dimx_dat_i;
input				dimx_ack_i;
input				dimx_err_i;

//
// Internal wires/regs
//
reg	[7:0]			dimx_sel_o;

wire [31:0]         lsu_addr; 
wire [3:0]          lsu_op; 

//
//
//
assign lsu_addr = addrbase + addrofs ;     // [TBD]to check address overflow?

//
// D-side IMX interface
//
// Note: the protocol is differnt than i-IMX
//  1, the request assert until the completion of data transaction
//  2, [TBD] eliminate address response(!rty_i)    
// Store Operation
//      cycle 1: 
//          master - send out rqt_valid(rqt_o)/addr_o/data_o/sel_o
//          slave - address decoding and if hit, give back addrack(!rty_i)
//                - slave can insert waiting cycles
//      cycle 2..:
//          slave - register data, and give dat_ack(ack_i), dictate transaction complete successfully
//          master - disassert rqt_valid
// Load Operation
//      cycle 1:
//          master - send out rqt_valid(rqt_o)/addr_o/sel_o
//          slave - address decoding and if hit, give back addrack(!rty_i)
//                - slave can insert waiting cycles
//      cycle 2..:
//          slave - send dat, and give dat_ack(ack_i), dictate transaction complete successfully
//          master - disassert rqt_valid, register dat_i, and diassert lsu_stall(advanced write-back)
//
assign dimx_rqt_o = (!dimx_ack_i) & (|lsu_op) & (!sig_align);
assign dimx_adr_o = lsu_addr; 

// (all store inst. 
assign dimx_we_o = (lsu_op[3];

// data selector for little-endian implementation: selector rule see specification
always @(lsu_op or dimx_adr_o)
	casex({lsu_op, dimx_adr_o[2:0]})
		{`LSUOP_SB, 3'b000} : dimx_sel_o = 8'b0000_0001;
		{`LSUOP_SB, 3'b001} : dimx_sel_o = 8'b0000_0010;
		{`LSUOP_SB, 3'b010} : dimx_sel_o = 8'b0000_0100;
		{`LSUOP_SB, 3'b011} : dimx_sel_o = 8'b0000_1000;
		{`LSUOP_SB, 3'b100} : dimx_sel_o = 8'b0001_0000;
		{`LSUOP_SB, 3'b101} : dimx_sel_o = 8'b0010_0000;
		{`LSUOP_SB, 3'b110} : dimx_sel_o = 8'b0100_0000;
		{`LSUOP_SB, 3'b111} : dimx_sel_o = 8'b1000_0000;
		{`LSUOP_SH, 3'b000} : dimx_sel_o = 8'b0000_0011;
		{`LSUOP_SH, 3'b010} : dimx_sel_o = 8'b0000_1100;
		{`LSUOP_SH, 3'b100} : dimx_sel_o = 8'b0011_0000;
		{`LSUOP_SH, 3'b110} : dimx_sel_o = 8'b1100_0000;
		{`LSUOP_SW, 3'b000} : dimx_sel_o = 8'b0000_1111;
		{`LSUOP_SW, 3'b100} : dimx_sel_o = 8'b1111_0000;
        {`LSUOP_SD, 3'b000} : dimx_sel_o = 8'b1111_1111;

		{`LSUOP_LB, 3'b000},
		{`LSUOP_LBU, 3'b000}: dimx_sel_o = 8'b0000_0001;
		{`LSUOP_LB, 3'b001},
		{`LSUOP_LBU, 3'b001}: dimx_sel_o = 8'b0000_0010;
		{`LSUOP_LB, 3'b010},
		{`LSUOP_LBU, 3'b010}: dimx_sel_o = 8'b0000_0100;
		{`LSUOP_LB, 3'b011},
		{`LSUOP_LBU, 3'b011}: dimx_sel_o = 8'b0000_1000;
		{`LSUOP_LB, 3'b100},
		{`LSUOP_LBU, 3'b100}: dimx_sel_o = 8'b0001_0000;
		{`LSUOP_LB, 3'b101},
		{`LSUOP_LBU, 3'b101}: dimx_sel_o = 8'b0010_0000;
		{`LSUOP_LB, 3'b110},
		{`LSUOP_LBU, 3'b110}: dimx_sel_o = 8'b0100_0000;
		{`LSUOP_LB, 3'b111},
		{`LSUOP_LBU, 3'b111}: dimx_sel_o = 8'b1000_0000;
		
		{`LSUOP_LH, 3'b000},
		{`LSUOP_LHU, 3'b000}: dimx_sel_o = 8'b0000_0011;
		{`LSUOP_LH, 3'b010},
		{`LSUOP_LHU, 3'b010}: dimx_sel_o = 8'b0000_1100;
		{`LSUOP_LH, 3'b100},
		{`LSUOP_LHU, 3'b100}: dimx_sel_o = 8'b0011_0000;
		{`LSUOP_LH, 3'b110},
		{`LSUOP_LHU, 3'b110}: dimx_sel_o = 8'b1100_0000;

		{`LSUOP_LW, 3'b000},
		{`LSUOP_LWU, 3'b000}: dimx_sel_o = 8'b0000_1111;
		{`LSUOP_LW, 3'b100},
		{`LSUOP_LWU, 3'b100}: dimx_sel_o = 8'b1111_0000;

		{`LSUOP_LD, 3'b000} : dimx_sel_o = 8'b1111_1111;

		default : dimx_sel_o = 8'b0000_0000;
	endcase

//
// Pipeline Control Signals
//

// lsu_stall assert until the completion of data transaction. 
assign lsu_stall = (|lsu_op) & !dimx_ack_i; 
assign lsu_done = (|lsu_op) & dimx_ack_i;     

//
// uops to op transfer
//
assign lsu_op = lsu_uops[3:0]; 

//
// memory-to-regfile aligner
//
lsu_mem2reg lsu_mem2reg(
	.addr(dimx_adr_o[2:0]),
	.lsu_op(lsu_op),
	.memdata(dimx_dat_i),
	.regdata(lsu_dataout)
);

//
// regfile-to-memory aligner
//
lsu_reg2mem lsu_reg2mem(
        .addr(dimx_adr_o[2:0]),
        .lsu_op(lsu_op),
        .regdata(lsu_datain),
        .memdata(dimx_dat_o)
);

//
// except request
//
assign sig_align = 
        ((lsu_op == `LSUOP_STH) | (lsu_op == `LSUOP_STHB) | (lsu_op == `LSUOP_LHZ) | 
            (lsu_op == `LSUOP_LHZB) | (lsu_op == `LSUOP_LHA)) & dimx_adr_o[0] | 
        ((lsu_op == `LSUOP_STW) | (lsu_op == `LSUOP_STWB) | (lsu_op == `LSUOP_LWZ) | 
            (lsu_op == `LSUOP_LWZB)) & |dimx_adr_o[1:0];
assign sig_dbuserr = dimx_ack_i & dimx_err_i;


endmodule

