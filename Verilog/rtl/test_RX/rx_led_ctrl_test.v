module uart_rx_led_top #(
    parameter UART_BPS = 115200,
    parameter CLK_FREQ = 50_000_000
) (
    input wire clk,
    input wire rst_n,

    input wire uart_rxd,  // UART 接收引脚

    output wire led1,
    output wire led2,

    output reg en_rs485
);

    // === 内部信号定义 ===
    wire [7:0] rx_data;
    wire       rx_done;
    wire       frame_error;

    pll_clk u_pll_clk (
        .clkout0(clk_50M),
        .lock   (pll_locked),
        .clkin1 (clk)
    );

    // === 实例化 UART 接收模块 ===
    uart_rx #(
        .UART_BPS(UART_BPS),
        .CLK_FREQ(CLK_FREQ)
    ) u_uart_rx (
        .clk     (clk_50M),
        .rst_n   (rst_n),
        .uart_rxd(uart_rxd),

        .rx_data    (rx_data),
        .done_flag  (rx_done),
        .frame_error(frame_error)
    );

    // === 实例化 LED 控制模块 ===
    rx_led_ctrl u_rx_led_ctrl (
        .clk        (clk_50M),
        .rst_n      (rst_n),
        .rx_data    (rx_data),
        .rx_done    (rx_done),
        .frame_error(frame_error),
        .led1       (led1),
        .led2       (led2)
    );

endmodule
