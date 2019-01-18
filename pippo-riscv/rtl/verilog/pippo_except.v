/*
 * File:        pippo_except.v
 * Project:     pippo
 * Designer:    fang@ali
 * Mainteiner:  fang@ali
 * Checker:
 * Assigner:    
 * Description:
    һ��riscv�ܹ��ж϶��壬����������ʹ�������
            Normal program flow may be disrupted by two kinds of exceptions: interrupts (asynchronous
        external events) and traps (synchronous events caused by program execution). Upon an exception,
        the processor enters supervisor mode with exceptions disabled (status register bits PS, S, and ET
        are set to S, 1, and 0, respectively). Execution resumes at the virtual address specified by the evec
        register. The PC of the interrupted or trapping instruction is stored in the epc register.
            RISC-V implementations may s upp ort up to 8 interrupts. The timer uses interrupt 7. The possible
        interrupts in RISC-V are listed below in decreasing order of priority.
                Cause   IM index    Description
                0x10    0           Reserved.
                0x11    1           Reserved.
                0x12    2           Reserved.
                0x13    3           Reserved.
                0x14    4           Reserved.
                0x15    5           Reserved.
                0x16    6           Reserved.
                0x17    7           Timer interrup
            For each interrupt there is an IM flag in the status
        register that enables the interrupt when set. In addition, all interrupts will be masked off when
        the exception enable bit ET is cleared. A particular interrupt can occur only if the IM bit for that
        interrupt is set, ET is set, and there are no higher priority interrupts.
            Traps are listed below in order of decreasing priority.
                Cause       Description
                0x00        Instruction address misaligned.
                0x01        Instruction access fault.
                0x02        Illegal instruction.
                0x03        Privileged instruction.
                0x04        Floating-point disabled.
                0x05        System call.
                0x06        Breakpoint.
                0x07        Data address misaligned.
                0x08        Load access fault.
                0x09        Store access fault.
                0x0A        Reserved.
                0x0B        Reserved.
                0x0C        Reserved.
                0x0D        Reserved.
                0x0E        Reserved.
                0x0F        Reserved.
    ����pippoʵ��            
        Ŀǰpippo���жϴ����ϣ�trap���ȼ�����interrupts
        ע�⣺pippo��ȷ�жϵ�ʵ�֣������ж������ڽ���EXE/WB�κ�ʼ����
    ����ģ���߼���������
        a�����ʶ���жϣ����жϷ���ʱˢ����ˮ�ߣ����������ȼ���ת������жϴ��������ڵ�ַ
        b��ʵ���жϴ������SPRs���Լ���MSR�Ľӿ�:
            Exception Program Counter(EPC)
            Bad Virtual Address(BADVADDR)
            Exception Handler Address(EVEC)
            Cause of Exception(Cause)        
        c��ʵ��ͬ��ָ�
            context synchronization��"isync, rfi, rfci, sc"; 
                rfi/rfci: ���ж�FSM���ڿ���ʱ�����rfi/rfci������svm��飬������ˢ����ˮ��һ�ģ�����msr���ͳ�npc��
                isync: ����rfi/rfci��������������svm��npcΪsnia��
                sc: ���������жϴ��������жϴ���״̬����
            execution synchronization: "eieio, sync and mtmsr";
            storage synchronization: eieio, sync
    �ģ�FSM˵��
        ��Ҫ���ܣ�            
            ����жϣ�
            �����ж����ͣ����������ж���ؼĴ���������MSR������Ҳ����SPRs�����жϴ���Ĵ����߼�
            ˢ����ˮ�ߣ����жϼ�⵽���봦�����ʱ��Ϊ �ģ�
        RTL�淶
            ״̬EXP_Idle������״̬��ϵͳ��λ����ϸ��жϴ�����ɷ��ص�״̬��
	            ����жϣ�flag_except�źţ�����Ӧ���ָ���EXE�Σ��緢��
	                except_detect�źŽ���ʼˢ����ˮ�ߣ�
	                ��һ�Ľ���FLU1״̬��	            
	            �����жϣ�����Idle״̬��
	            ���extend_flushΪ��Ч��
	        ״̬EXP_PROCESSING���ж�ʶ��
	            ����ж����ͺ����ȼ�����ʼ�жϵ�Ӳ������
	                �����ֳ���д�ж����SPRs��������MSR��
	                �ͳ�npc_except����Ч�ź���ȡָ����
	            ���extend_flushΪ��Ч��
	            һ��֮�����FLU2״̬��
	        ״̬EXP_DONE���ж����״̬��
                ���extend_flushΪ��Ч������ˢ����ˮ��һ��֮�󷵻�Idle״̬��
                PC�ͳ��µ�ȡָ����
 * Task: 
        [TBV]ͬ��ָ��Ⱥ��ⲿ�ж�ͬʱ��Ч�����
        [TBV]�첽�ж�������ȴ���ǰָ�����
                ���첽������������stallסִ�жΣ��ȴ���ǰָ�����
                ������һ��ָ������exe�Σ������������ȼ��жϣ����첽�жϵò�������
        [TBD]�µ�ȡָ���������msr��ɸ��£������µ�context֮���ͳ�
        [TBD]Ƕ���жϺͶ���ж�ͬʱ��������������߼�   
            ����ж�����£������ȼ����ж���δ���Ӳ�����������ɣ��ڲ��߼������ⲿ�߼���
            CPU���ڲ���ͬʱ���������ж����������ߴ�������illegalָ��ȣ���ȷ��        
            to check if internal excepts are maskable.
            ��masked����£��ж�������һֱ���ֵ������ⲿ�߼����ֻ����ڲ��߼�����
        [TBD] 
            �ڵȴ�ISR���ص�һ��ָ��֮ʱ����������ⲿ�ж�����Ӧ����������ε���������ʱ��ˮ���е�ciaΪ��Чֵ
            ���ж��������
                ���ڴ����жϣ�EXP_Processing״̬ʱ�����ⲿ�����ȼ��������������Ϊ�������߼�����Ӧ�µĸ����ȼ��ж�
                ��EXE�δ��ڶ���ж�����ʱ��һ���ڲ���һ���ⲿ����α��������ȼ��������ź�
                Core�ڲ��п���ͬʱ����������Ҫ������ж�������sig_alian��sig_dbuserr
            ����pippo�ԷǶ�����ʵĴ���ALIGN����PRG��emulation�Ƕ������ָ�
            ��buserr����������machine check�ж�Դ��
            npc_except��npc_exp_validʱ��
            FSM��ˢ����ˮ���й�ǿԼ�������ɣ�����֤�Ľ�
            �Ƿ���ҪMSR����һ�����ݣ�
            Interrupt chaining�Ƿ���ҪӲ��֧�֣�
        [TBD] ��������д��ָ��Ĵ���������չwb�ķ����������д�����һ��ʱ�����жϣ���δ���ע�����������
        [TBV]�ж����SPRs��д������mtspr����FSM״̬û�й���
        [TBV]�ж���Ϊ������ppc4xxϵͳ����ļ�������һ���ܴ�����⣡�漰��������Ϊ��MSS��DSSϵͳ
            ��ϵͳ�жϷ���ʱ�����ֳ��������жϵ�ָ���ڽ����жϴ���ʱ��״̬�ʹ�����ɺ�ָ��ȣ���ʼִ�л��ǲ�����ɵȵȣ�
 */ 
 
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "def_pippo.v"

module pippo_except(

	clk, rst, 
	
	sig_dbuserr, sig_ibuserr, sig_ext_ci, sig_illegal, sig_emulate, sig_syscall, sig_align, sig_ext_i,
    sig_eieio, sig_isync, sig_sync,
    sig_svm_check, sig_trap, 
	sig_pit, sig_fit, sig_watchdog,
	
	npc_except, npc_exp_valid, 
	
    ex_cia, ex_snia, 
    
	wb_freeze, asyn_stall, 
	
	flush_except,
	
    msr,
	msr_except, msr_expwe,
	
    eir,
    eir_we, ex_inst, 
	dear, esr, evpr, mcsr, srr0, srr1, srr2, srr3, 
	dear_we, esr_we, evpr_we, mcsr_we, srr0_we, srr1_we, srr2_we, srr3_we,
    spr_dat_i, 
				
	lsu_addr
);

//
// I/O
//
input				clk;
input				rst;                

// interrupt request
input				sig_dbuserr;
input				sig_ibuserr;
input				sig_ext_ci;
input				sig_illegal;
input				sig_syscall;
input				sig_align;
input				sig_ext_i;
input               sig_svm_check;
input               sig_trap;
// timer
input               sig_fit;
input		        sig_pit;
input               sig_watchdog;

// synchronization instruction
input               sig_eieio;
input               sig_isync;
input               sig_sync;

// emualtion request
input               sig_emulate;
    
// instruction and data pointer
input	[31:0]		ex_cia; 
input	[31:0]		ex_snia; 
input	[31:0]		lsu_addr;   

// pipelining control
input				wb_freeze;       
output              asyn_stall; 
output				flush_except; 
	
// MSR interface
input	[width-1:0]	msr;  
output	[width-1:0]	msr_except;
output          msr_expwe; 

// SPRs interface for mtspr inst.
input   dear_we;
input   esr_we;
input   evpr_we;
input   mcsr_we;
input   srr0_we;
input   srr1_we;
input   srr2_we;
input   srr3_we;


input	[width-1:0]		spr_dat_i; 

// SPRs interface for mfspr inst.
output	[width-1:0]		dear;
output	[width-1:0]		esr;
output	[width-1:0]		evpr;
output	[width-1:0]		mcsr;
output	[width-1:0]		srr0;
output	[width-1:0]		srr1;
output	[width-1:0]		srr2;
output	[width-1:0]		srr3;

// emulation
input   eir_we;
input   [31:0]      ex_inst;
output  [width-1::0]      eir;

// inst. fetch for exception
output	[31:0]      npc_except; 
output              npc_exp_valid; 

//
// Internal regs and wires
//
reg	[width-1::0]		dear;
reg	[width-1::0]		esr;
reg	[width-1::0]		evpr;
reg	[width-1::0]		mcsr;
reg	[width-1::0]		srr0;
reg	[width-1::0]		srr1;
reg	[width-1::0]		srr2;
reg	[width-1::0]		srr3;
reg	[width-1::0]		eir;

// FSM
reg [1:0]   state; 
reg [1:0]   state_next; 
reg         extend_flush;
reg         npc_exp_valid;
reg [31:0]  npc_except;
reg [15:0]  except_type;
reg         msr_expwe; 
reg [width-1::0]  msr_except;

reg	[width-1::0]        dear_new;
reg	[width-1::0]        esr_new;
reg	[width-1::0]        mcsr_new;
reg	[width-1::0]        srr0_new;
reg	[width-1::0]        srr1_new;
reg	[width-1::0]        srr2_new;
reg	[width-1::0]        srr3_new;
reg [width-1::0]        eir_new;

//
// logic
//

// check svm for sret instruction.
assign sret_go = sig_sret & !msr[`pippo_MSR_S_BITS];        // S or PS?

// 
assign fence_go = sig_fence | sig_fencei;

// program interrupt
assign sig_prg = sig_illegal | sig_trap | sig_svm_check | 
                (sig_sret & msr[`pippo_MSR_S_BITS]); 

//
// delayed_et/delayed_im
//
// MSR[ET]/MSR[IM] should not enable interrupts right away when 
// it is restored with sret. Instead delayed_et/delayed_im
// together with MSR[ET]/[IM] enables interrupts once pipeline is 
// again ready.
//
reg     [2:0]       delayed_et;
reg     [2:0]       delayed_im0, delayed_im1, delayed_im2, delayed_im3;
reg     [2:0]       delayed_im4, delayed_im5, delayed_im6, delayed_im7; 

always @(posedge rst or posedge clk)
	if (rst)
		delayed_et <= #1 3'b000;
	else if (!msr[`pippo_MSR_ET_BITS])
		delayed_et <= #1 3'b000;
	else
		delayed_et <= #1 {delayed_et[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im7 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM7_BITS])
		delayed_im7 <= #1 3'b000;
	else
		delayed_im7 <= #1 {delayed_im7[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im6 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM6_BITS])
		delayed_im6 <= #1 3'b000;
	else
		delayed_im6 <= #1 {delayed_im6[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im5 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM5_BITS])
		delayed_im5 <= #1 3'b000;
	else
		delayed_im5 <= #1 {delayed_im5[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im4 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM4_BITS])
		delayed_im4 <= #1 3'b000;
	else
		delayed_im4 <= #1 {delayed_im4[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im3 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM3_BITS])
		delayed_im3 <= #1 3'b000;
	else
		delayed_im3 <= #1 {delayed_im3[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im2 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM2_BITS])
		delayed_im2 <= #1 3'b000;
	else
		delayed_im2 <= #1 {delayed_im2[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im1 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM1_BITS])
		delayed_im1 <= #1 3'b000;
	else
		delayed_im1 <= #1 {delayed_im1[1:0], 1'b1};

always @(posedge rst or posedge clk)
	if (rst)
		delayed_im0 <= #1 3'b000;
	else if (!msr[`pippo_MSR_IM0_BITS])
		delayed_im0 <= #1 3'b000;
	else
		delayed_im0 <= #1 {delayed_im0[1:0], 1'b1};

//assign abort_ex = sig_dbuserr | sig_align | sig_prg;     // Abort write into RF by load & other instructions

//
// Spec: After detecting a critical interrupt, if no synchronous precise interrupts are outstanding, the 
//       PPC405-S immediately takes the critical interrupt and writes the address of the next instruction
//       to be executed in SRR2.
// Notes:
// 1. external non-critical and critical interrupt(asynchronous) must wait the completion of current instruction
// 2. delayed enable signals are for rfi/rfci processing
// [TBD] what about watchdog/fit/pit case, waiting the completion of current instruction?
//

// asyn_stall is forholding the execution stage, to prevent new instruction enter the execution stage
//      1, if wb_freeze assert, asyn_stall will asert for wb_freeze + 1 cycle
//      2, if wb_freeze disassert, it means current cycle is the write-back stage of current instructions
//         wb_done disassert, and will assert at next cycle if enable bit of msr is on
//         then, asycn_xxx_pending will assert
assign asyn_stall = (sig_ext_i0 & msr[`pippo_MSR_IM0_BITS] & delayed_im0[2]) |
                    (sig_ext_i1 & msr[`pippo_MSR_IM1_BITS] & delayed_im1[2]) |
                    (sig_ext_i2 & msr[`pippo_MSR_IM2_BITS] & delayed_im2[2]) |
                    (sig_ext_i3 & msr[`pippo_MSR_IM3_BITS] & delayed_im3[2]) |
                    (sig_ext_i4 & msr[`pippo_MSR_IM4_BITS] & delayed_im4[2]) |
                    (sig_ext_i5 & msr[`pippo_MSR_IM5_BITS] & delayed_im5[2]) |
                    (sig_ext_i6 & msr[`pippo_MSR_IM6_BITS] & delayed_im6[2]) |
                    (sig_ext_i7 & msr[`pippo_MSR_IM7_BITS] & delayed_im7[2]);

// when interrupt request assert, waiting the completion of current instruction
reg wb_done;          
always @(posedge rst or posedge clk) begin
	if (rst)
		wb_done <= #1 1'b0;
	else
		wb_done <= #1 !wb_freeze & ((msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM0_BITS] & sig_ext_i0) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM1_BITS] & sig_ext_i1) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM2_BITS] & sig_ext_i2) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM3_BITS] & sig_ext_i3) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM4_BITS] & sig_ext_i4) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM5_BITS] & sig_ext_i5) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM6_BITS] & sig_ext_i6) |
		                            (msr[`pippo_MSR_ET_BITS] & msr[`pippo_MSR_IM7_BITS] & sig_ext_i7) ); 
end

assign exti0_pending = sig_ext_i0 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM0_BITS] & delayed_im0[2]) & wb_done;
assign exti1_pending = sig_ext_i1 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM1_BITS] & delayed_im1[2]) & wb_done;
assign exti2_pending = sig_ext_i2 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM2_BITS] & delayed_im2[2]) & wb_done;
assign exti3_pending = sig_ext_i3 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM3_BITS] & delayed_im3[2]) & wb_done;
assign exti4_pending = sig_ext_i4 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM4_BITS] & delayed_im4[2]) & wb_done;
assign exti5_pending = sig_ext_i5 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM5_BITS] & delayed_im5[2]) & wb_done;
assign exti6_pending = sig_ext_i6 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM6_BITS] & delayed_im6[2]) & wb_done;
assign exti7_pending = sig_ext_i7 & (msr[`pippo_MSR_ET_BITS] & delayed_et[2]) & (msr[`pippo_MSR_IM7_BITS] & delayed_im7[2]) & wb_done;

//
// Exception detection priority: msb > lsb
//
wire    [23:0]   except_trig; 
wire    [23:0]   except_rqt; 
reg     [23:0]   except_rqt_reg; 
assign except_rqt = {
            sig_align_inst,
            sig_ibuserr,
            sig_illegal, 
            sig_svm_check,
            sig_fp_disabled,
            1'b0, 
            sig_scall,
            sig_sbreak, 
            sig_align_load,
            sig_align_store,
            sig_dbuserr_load,
            sig_dbuserr_store,
            4'b0000,
            exti0_pending,
            exti1_pending,
            exti2_pending,
            exti3_pending,
            exti4_pending,
            exti5_pending,
            exti6_pending,
            exti7_pending,
		};

// keep for one cycle for fsm
always @(posedge clk or posedge rst) begin
	if (rst)
		except_rqt_reg <= #1 24'b0;
	else 
		except_rqt_reg <= #1 except_rqt;
end

assign except_trig = except_rqt | except_rqt_reg; 

//
// Exception SPRs
//  [TBV] no need for pipeling control logic-wb_freeze to stop update
//        exception happen at mtspr's exe/wb cycle, flush will disenable spr_we
//

// badvaddr is a XPRLEN-bit read only register. 
// When a load/store access exception or data address misaligned exception occurs, badvaddr is written with the faulting virtual address. 
always @(posedge clk or posedge rst) begin
	if (rst)
		badvaddr <= #1 64'b0;
    else 
        badvaddr <= #1 badvaddr_new;
end

// evec is a XPRLEN-bit register aligned to a 4-byte boundary. 
// When an exception occurs, the pc is set to evec.
always @(posedge clk or posedge rst) begin
	if (rst)
		evec <= #1 64'b0;
	else if(evec_we) 
		evec <= #1 spr_dat_i;
end

// epc is a XPRLEN-bit read only register. 
// When an exception occurs, epc is written with the virtual address of the instruction that caused the exception.
always @(posedge clk or posedge rst) begin
	if (rst) 
		epc <= #1 64'b0;
    else 
        epc <= #1 epc_new;
end

// cause register is a 32-bit register
// The cause register contains a code identifying the last exception. 
// Writes to cause are ignored
always @(posedge clk or posedge rst) begin
	if (rst) 
		cause <= #1 5'b0;
    else 
        cause <= #1 cause_new;
end

    
//
// FSM of flushing pipeline and switch to exception-handler
//
`define STATE_WIDTH     2
`define EXP_Idle	    `STATE_WIDTH'd0
`define EXP_Processing 	`STATE_WIDTH'd1
`define EXP_Done     	`STATE_WIDTH'd2

// assert for one cycle, at FSM state Idle            
assign flag_except = |except_trig & ~|state;       

// assert for two cycle for exception
// assert for one cycle for rfi/rfci/isync/emulate
assign flush_except = flag_except | extend_flush | sret_go | sig_fence;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= #1 `EXP_Idle;
	end
	else begin
        state <= #1 state_next;
    end
end
    
always @(state or except_trig or flag_except or except_type or rfi_go or rfci_go or sig_isync or
         ex_snia or ex_cia or lsu_addr or sig_illegal or sig_svm_check or sig_trap or sig_emulate or
         msr or esr or mcsr or dear or evpr or srr0 or srr1 or srr2 or srr3 or ex_inst or eir) begin
    state_next = `EXP_Idle; 
    npc_exp_valid = 1'b0; 
    npc_except = 32'd0; 
    extend_flush = 1'b0;
    except_type = `pippo_EXCEPT_NONE;

    msr_expwe = 1'b0; 
    msr_except = msr;

    badvaddr_new = badvaddr;
    epc_new = epc;
    cause_new = cause;
    
    `ifdef pippo_CASE_DEFAULT
	case (state)	// synopsys parallel_case
    `else
	case (state)	// synopsys full_case parallel_case
    `endif

		`EXP_Idle: begin
		    extend_flush = 1'b0;
		    except_type = `pippo_EXCEPT_NONE;
		    case ({sret_go, fence_go, sig_emulate})		        

		        4'b1000: begin                  // rfi 
			        npc_exp_valid = 1'b1;  
			        npc_except = srr0;
			        msr_expwe = 1'b1; 
			        msr_except = srr1;
		        end

		        4'b0100: begin                  // rfci
			        npc_exp_valid = 1'b1;
			        npc_except = srr2; 			        			        
			        msr_expwe = 1'b1; 
			        msr_except = srr3;
		        end
		        
		        4'b0010: begin                  // isync
			        npc_exp_valid = 1'b1;  
			        npc_except = {ex_snia, 2'b00};
			        msr_expwe = 1'b1; 
			        msr_except = msr;			
		        end
		        
		        4'b0001: begin                  // emulation
			        npc_exp_valid = 1'b1;  
			        npc_except = `pippo_EMU_ROMADDR;
			        msr_expwe = 1'b1; 
                    msr_except = 32'd0;
                    srr0_new = {ex_snia, 2'b00};
                    srr1_new = msr;
                    eir_new = ex_inst; 
		        end

		        default: begin
			        npc_exp_valid = 1'b0;
			        npc_except = 32'd0;
			        msr_expwe = 1'b0; 
			        msr_except = msr;
                    srr0_new = srr0;
                    srr1_new = srr1;
                    eir_new = eir; 
		        end
            endcase
            			        			                                			
            // "~msr_expwe": for rfi/rfci/isync/emulate processing, delayed exception
			if (flag_except & ~msr_expwe) begin     
				state_next = `EXP_Processing;
			end	
			else begin
			    state_next = `EXP_Idle;
			end
        end
			
		`EXP_Processing: begin
			state_next = `EXP_Done;
			extend_flush = 1'b1;
			casex (except_trig)

                `ifdef pippo_EXCEPT_ALIGN_INST
				24'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx: begin
                    msr_expwe = 1'b0; 
                    msr_except = msr;
                    epc_new = ex_cia;
                    cause_new = 5'b0_0000;
				end
                `endif

                `ifdef pippo_EXCEPT_IBUSERR
				24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx: begin
				
				end
                `endif

                `ifdef pippo_EXCEPT_ILLEGAL
				24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_SVMCHECK
				24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_FPDISABLE
				24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_SCALL
				24'b0000_001x_xxxx_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_SBREAK
				24'b0000_0001_xxxx_xxxx_xxxx_xxxx: begin
				end
                `endif
   
                `ifdef pippo_EXCEPT_ALIGN_LOAD
				24'b0000_0000_1xxx_xxxx_xxxx_xxxx: begin
				end
                `endif
                `ifdef pippo_EXCEPT_CHK
                
                `ifdef pippo_EXCEPT_ALIGH_STORE
				24'b0000_0000_01xx_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_DBUSERR_LOAD
				24'b0000_0000_001x_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_DBUSERR_STORE
				24'b0000_0000_0001_xxxx_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI0
				24'b0000_0000_0000_0001_xxxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI1
				24'b0000_0000_0000_0000_1xxx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI2
				24'b0000_0000_0000_0000_01xx_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI3
				24'b0000_0000_0000_0000_001x_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI4
				24'b0000_0000_0000_0000_0001_xxxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI5
				24'b0000_0000_0000_0000_0000_1xxx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI5
				24'b0000_0000_0000_0000_0000_01xx: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI6
				24'b0000_0000_0000_0000_0000_001x: begin
				end
                `endif

                `ifdef pippo_EXCEPT_EXTI7
				24'b0000_0000_0000_0000_0000_0001: begin
				end
                `endif

				10'b01_xxxx_xxxx: begin
					except_type = `pippo_EXCEPT_CHK;
                    msr_expwe = 1'b1; 
                    msr_except = 32'd0;
                    esr_new = {1'b1, 31'd0};
                    srr2_new = {ex_cia, 2'b00};
                    srr3_new = msr;
				end
                `endif

                `ifdef pippo_EXCEPT_CI          // external critical interrupt
                10'b00_1xxx_xxxx: begin                    
					except_type = `pippo_EXCEPT_CI;
                    msr_expwe = 1'b1; 
                    msr_except = {19'd0, msr[`pippo_MSR_ME_BITS], 12'd0};
                    srr2_new = {ex_snia, 2'b00};      
                    srr3_new = msr;
                end
                `endif

                `ifdef pippo_EXCEPT_WATCHDOG    // watchdog interrupt
                10'b00_01xx_xxxx: begin          
                    except_type = `pippo_EXCEPT_WATCHDOG;
                    msr_expwe = 1'b1; 
                    msr_except = {19'd0, msr[12], 12'd0};   // ME unchanged
                    srr0_new = {ex_snia, 2'b00};     
                    srr1_new = msr;                                                   
                end
                `endif

                `ifdef pippo_EXCEPT_PRG         // program interrupt: illegal, svm, trap, unimpl...
                10'b00_001x_xxxx: begin                    
					except_type = `pippo_EXCEPT_PRG;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    srr0_new = {ex_cia, 2'b00};
                    srr1_new = msr;
                    esr_new = {4'd0, sig_illegal, sig_svm_check, sig_trap, 1'b0, 24'd0};    // apu/fpu is off currently
                end
                `endif
                
                `ifdef pippo_EXCEPT_SYSCALL     //syscall
                10'b00_0001_xxxx: begin                    
					except_type = `pippo_EXCEPT_SYSCALL;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    srr0_new = {ex_snia, 2'b00};
                    srr1_new = msr;
                end                    
                `endif
                
                `ifdef pippo_EXCEPT_ALIGN   // align interrupt - [TBD] move normal load/store align to another vector
                10'b00_0000_1xxx: begin                    
					except_type = `pippo_EXCEPT_ALIGN;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    dear_new = lsu_addr;
                    srr0_new = {ex_cia, 2'b00};
                    srr1_new = msr;
                end                    
                `endif

                `ifdef pippo_EXCEPT_EXT     // external non-critical interrupt
                10'b00_0001_01xx: begin                    
					except_type = `pippo_EXCEPT_EXT;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    srr0_new = {ex_snia, 2'b00}; 
                    srr1_new = msr;
                end                    
                `endif

                `ifdef pippo_EXCEPT_FIT    // fit interrupt
                10'b00_0000_001x: begin                    
                    except_type = `pippo_EXCEPT_FIT;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    srr0_new = {ex_snia, 2'b00};  
                    srr1_new = msr;                         
                end
                `endif

                `ifdef pippo_EXCEPT_PIT    // to ask software guy, why snia(PowerPC SPEC)?
                10'b00_0000_0001: begin           
                    except_type = `pippo_EXCEPT_PIT;
                    msr_expwe = 1'b1; 
                    msr_except = {14'd0, msr[17], 4'd0, msr[12], 2'd0, msr[9], 9'd0};   // CE, ME, DE unchanged
                    srr0_new = {ex_snia, 2'b00}; 
                    srr1_new = msr;                         
                end
                `endif

                default: begin
                    except_type = `pippo_EXCEPT_NONE;
                    msr_expwe = 1'b0; 
                    msr_except = msr;
                    dear_new = dear;
                    esr_new = esr;
                    mcsr_new = mcsr;
                    srr0_new = srr0;
                    srr1_new = srr1;
                    srr2_new = srr2;
                    srr3_new = srr3;
                end						                
			endcase

			npc_exp_valid = 1'b1; 
            npc_except = {evpr[31:16], except_type};    // notes: the order of assignmen-except must behind type.
                                                        // or wrong logic will be inferred by syn and sim tools
        end
					
		`EXP_Done: begin
            extend_flush = 1'b0;
            except_type = `pippo_EXCEPT_NONE;
            npc_exp_valid = 1'b0; 
            state_next = `EXP_Idle;
        end
    endcase
end

endmodule
