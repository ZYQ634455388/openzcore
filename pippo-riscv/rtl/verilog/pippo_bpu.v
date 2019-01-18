/*
 * File:        pippo_bpu.v
 * Project:     pippo
 * Designer:    fang@ali
 * Mainteiner:  fang@ali
 * Checker:
 * Description:
 *      һ����Ҫ���ܺ��߼�
 *          a���жϷ�֧������ʵ�ֱȽ��߼�
 *          b�������֧Ŀ���ַ           
 *          c��jump with link���ж���id����ɣ�����rfwb_uops��������߼�
 *      ������֧����ʱ��
 *          Cycle 1����Ӧ��ָ֧���EXE�Σ������֧����ת��һ�������������֧��ת����
 *              �ͳ�npc_branch����Ч�ź���PC��
 *              ��flush_branchΪ��Ч��ˢ����ˮ��
 *          Cycle 2��IF/ID/EXE���ˢ��    
 *              PC���µ�ȡָ�����͵�ָ�����߽ӿ�
 * Task.I
 *      [TBO]�߼��Ż�-�Ƚϴ�����alu�߼��������жϽ�����ɣ���ַ���ɸ���LSU�ĵ�ַ�ӷ�����
 *      [TBV]��֧Ŀ���ַ���ɣ�ƫ��Ϊ�������������Ĵ���-�����֤�������ɣ�
 */
 
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "def_pippo.v"

module pippo_bpu(

    clk, rst, 
    
    bpu_uops, 
    
    branch_immoffset, bus_a, bus_b,
    
    cia, snia, 
    
    npc_branch_valid, npc_branch, flush_branch
);

//
// Internal i/f
//

input           clk;
input           rst;

//uops and operands
input   [4:0]   bpu_uops;

// for target address generation and LR update
input   [31:0]  branch_immoffset; 
input   [31:0]  bus_a, bus_b;
input   [31:0]  cia; 
input   [31:0]  snia; 

// flush pipeline when branch is taken, at current implementation
output          flush_branch; 
output          npc_branch_valid;
output  [31:0]  npc_branch; 

//
// Internal wires/regs
//
reg     [31:0]  branch_target;
reg             condition_pass;

//
// logic
//

// bpu_uops[`BPUOP_SCMP_BIT] assertion(1'b1) means signed compare, diassertion(1'b0) means unsigned compare
assign cmp_a = {bus_a[width-1] ^ bpu_uops[`BPUOP_SCMP_BIT], bus_a[width-2:0]};
assign cmp_b = {bus_b[width-1] ^ bpu_uops[`BPUOP_SCMP_BIT], bus_b[width-2:0]};


always @(bpu_uops or bus_a or bus_b or cmp_a or cmp_b or cia) begin
    condition_pass = 1'b0;
    branch_target = 32'd0; 
    case (bpu_uops[2:0])
        
        `BPUOP_NOP: branch_target = 32'd0; 
        
        `BPUOP_REGIMM: begin
            branch_target = branch_immoffset + bus_a; 
        end

        `BPUOP_PCIMM: begin
            branch_target = branch_immoffset + cia; 
        end

        `BPUOP_CBEQ: begin
            condition_pass = (bus_a == bus_b); 
            branch_target = branch_immoffset + cia;         
        end
        
        `BPUOP_CBNE: begin
            condition_pass = (bus_a !== bus_b); 
            branch_target = branch_immoffset + cia;         
        end

        `BPUOP_CBLT: begin
            condition_pass = (cmp_a < cmp_b); 
            branch_target = branch_immoffset + cia;         
        end

        `BPUOP_CBGE: begin
            condition_pass = (cmp_a > cmp_b); 
            branch_target = branch_immoffset + cia;         
        end

        `BPUOP_CBLTU: begin
            condition_pass = (cmp_a < cmp_b); 
            branch_target = branch_immoffset + cia;         
        end

        `BPUOP_CGEU: begin
            condition_pass = (cmp_a > cmp_b); 
            branch_target = branch_immoffset + cia;         
        end

    endcase        
end

//
// output
//
// unconditional branch or taken conditional branch
assign flush_branch = (bpu_uops[`BPUOP_JUMP_BIT] | ( !bpu_uops[`BPUOP_JUMP_BIT] & condition_pass & |bpu_uops);   

// Output to pipeline control and fetch unit
assign npc_branch_valid = flush_branch; 
assign npc_branch = branch_target;

endmodule


