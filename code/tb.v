module tb;
    reg clk, rst;
    wire [7:0] pc, acc, ir;
    wire [2:0] state;
    wire halt;
    
    risc_cpu cpu(clk, rst, pc, acc, ir, state, halt);
   
    always #0.5 clk = ~clk;
    
    always @(posedge clk) begin
        if (!rst)
            $display("Time=%0t | PC=%h | IR=%h | Opcode=%b | Acc=%h(%0d) | State=%d | Zero=%b | inA=%h | inB=%h | alu_out=%h | is_zero=%b | Data_Out=%h",
                     $time, pc, ir, ir[7:5], acc, acc, state, (acc==0),
                     cpu.alu_unit.inA, cpu.alu_unit.inB, 
                     cpu.alu_unit.result, cpu.alu_unit.is_zero,
                     cpu.mem_data_out);
    end
    
    initial begin
        clk = 0; rst = 1;
        $readmemb("init.mem", cpu.mem.mem);
        #20; rst = 0;
        wait(halt);
        $display("\n========================================");
        $display("  END PROGRAM");
        $display("  PC=%h  Acc=%h(%0d)  Zero=%b", pc, acc, acc, (acc==0));
        $display("========================================\n");
        $finish;
    end

    initial begin
        $recordfile ("waves");
        $recordvars ("depth=0", tb);
    end
endmodule