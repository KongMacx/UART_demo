module uart_loopback #(
    parameter UART_BPS = 115200,
    parameter CLK_FREQ = 50_000_000
) (
    input clk,
    input rst_n,

    input  uart_rxd,  // UART接收端口
    output uart_txd,  // UART发送端口

    output en_rs485,  // 485控制线：1=发送，0=接收
    output LED21,     // 显示接收到0x03
    output LED22      // 显示接收到0x04
);

    // wire define
    wire [7:0] uart_rx_data;   // 接收数据
    wire       uart_rx_done;   // 接收完成标志
    wire       frame_error;    // 帧错误信号

    wire       rs485_en_internal;
    wire       led1_internal;
    wire       led2_internal;

    wire       pll_locked;
    wire       clk_50M;

    wire       sys_rst_n = rst_n & pll_locked;

    wire       tx_busy;        // 发送忙
    wire       uart_tx_done;   // 发送完成信号

    wire       uart_tx_start;  // 控制模块输出的启动信号
    wire [7:0] uart_tx_data;   // 控制模块输出的数据

    //=============== PLL模块 ================//
    pll_clk u_pll_clk (
        .clkout0   ( clk_50M ),
        .lock      ( pll_locked ),
        .clkin1    ( clk )
    );

    //=============== 接收模块 ================//
    uart_rx #(
        .UART_BPS ( UART_BPS ),
        .CLK_FREQ ( CLK_FREQ )
    ) u_uart_rx (
        .clk         ( clk_50M ),
        .rst_n       ( sys_rst_n ),
        .uart_rxd    ( uart_rxd ),
        .done_flag   ( uart_rx_done ),
        .rx_data     ( uart_rx_data ),
        .frame_error ( frame_error )
    );

    //=============== 发送模块 ================//
    uart_tx #(
        .UART_BPS ( UART_BPS ),
        .CLK_FREQ ( CLK_FREQ )
    ) u_uart_tx (
        .clk            ( clk_50M ),
        .rst_n          ( sys_rst_n ),
        .uart_tx_start  ( uart_tx_start ),
        .uart_tx_data   ( uart_tx_data ),
        .uart_txd       ( uart_txd ),
        .uart_tx_busy   ( tx_busy ),
        .uart_tx_done   ( uart_tx_done )
    );

    //=============== 控制模块 ================//
    nRE_DE_LED u_nRE_DE_LED (
        .clk            ( clk_50M ),
        .rst_n          ( sys_rst_n ),
        .rx_data        ( uart_rx_data ),
        .rx_done        ( uart_rx_done ),
        .frame_error    ( frame_error ),

        .tx_busy        ( tx_busy ),
        .uart_tx_done   ( uart_tx_done ),

        .LED1           ( led1_internal ),
        .LED2           ( led2_internal ),
        .en_rs485       ( rs485_en_internal ),

        .uart_tx_start  ( uart_tx_start ),
        .uart_tx_data   ( uart_tx_data )
    );

    //=============== IO输出连接 ================//
    assign en_rs485 = rs485_en_internal;
    assign LED21    = led1_internal;
    assign LED22    = led2_internal;

endmodule
