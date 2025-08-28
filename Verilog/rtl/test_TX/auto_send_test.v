module top_auto_send_test (
    input clk,   // 系统时钟，例如50MHz
    input rst_n, // 异步复位，低有效

    output uart_txd,  // 串口发送引脚，接到板子TXD或RS485发送
    output nRE_DE
);

    wire clk_50M;

    pll_clk u_pll_clk (
        .clkout0(clk_50M),
        .lock   (),
        .clkin1 (clk)
    );

    // 实例化 auto_send 模块
    auto_send u_auto_send (
        .clk     (clk_50M),
        .rst_n   (rst_n),
        .uart_txd(uart_txd)
    );

endmodule
