`timescale 1ns / 1ns

module tb_top_auto_send_test;

    // Testbench 时钟参数
    parameter CLK_PERIOD = 20;  // 50MHz -> 20ns周期

    // DUT 接口信号
    reg clk;
    reg rst_n;
    wire uart_txd;

    // 实例化顶层模块
    top_auto_send_test uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_txd(uart_txd)
    );

    // 产生50MHz系统时钟
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 复位逻辑
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // // 仿真时间控制
    // initial begin
    //     $display("Start simulation...");
    //     #100;  // 仿真约1ms，可调节
    //     $display("End simulation.");
    //     $stop;
    // end

    // 监控输出（可选）
    initial begin
        $monitor("Time=%t | uart_txd=%b", $time, uart_txd);
    end

endmodule
