//====================================================
// uart_sys_pkg.sv : 公共包，包含类型定义
//====================================================
package uart_sys_pkg;

    //LED组合信号
    typedef struct packed {
        logic led21;
        logic led22;
    } led_pair_t;

    //帧错误信号
    typedef enum logic [0:0] {
        FRAME_OK  = 1'b0,
        FRAME_ERR = 1'b1
    } frame_err_e;

endpackage : uart_sys_pkg

//====================================================
// 接口定义：UART 数据通道
//====================================================
interface uart_stream_if #(
    parameter int WIDTH = 8
);

    logic [WIDTH-1:0] data;
    logic valid;  //接收完成信号
    logic error;  //帧错误

    //modport区分方向
    modport RX(output data, output valid, output error);
    modport CTRL(input data, input valid, input error);

endinterface : uart_stream_if

//====================================================
// 接口定义：UART TX 控制
//====================================================
interface uart_tx_ctrl_if #(
    parameter int WIDTH = 8
);

    logic start;
    logic [WIDTH-1:0] data;
    logic busy;
    logic done;

    modport TX(input start, input data, output busy, output done);
    modport CTRL(output start, output data, input busy, input done);

endinterface : uart_tx_ctrl_if

//====================================================
// 顶层模块 uart_loopback (SV重构版)
//====================================================
// `default_nettype none
import uart_sys_pkg::*;

module uart_loopback #(
    parameter int UART_BPS = 115200,
    parameter int CLK_FREQ = 50_000_000
) (
    input  logic clk,
    input  logic rst_n,

    input  logic uart_rxd,
    output logic uart_txd,

    output logic en_rs485,
    output logic LED21,
    output logic LED22
);

    //================= 内部信号 =================//
    logic        pll_locked;
    logic        clk_50M;
    logic        sys_rst_n;

    assign sys_rst_n = rst_n & pll_locked;

    //================= 接口实例化 =================//
    uart_stream_if #(8)      uart_rx_if();
    uart_tx_ctrl_if #(8)     uart_tx_if();

    led_pair_t leds;

    //================= PLL模块 =================//
    pll_clk u_pll_clk (
        .clkout0 ( clk_50M ),
        .lock    ( pll_locked ),
        .clkin1  ( clk )
    );

    //================= 接收模块 =================//
    uart_rx #(
        .UART_BPS ( UART_BPS ),
        .CLK_FREQ ( CLK_FREQ )
    ) u_uart_rx (
        .clk         ( clk_50M ),
        .rst_n       ( sys_rst_n ),
        .uart_rxd    ( uart_rxd ),
        .done_flag   ( uart_rx_if.valid ),
        .rx_data     ( uart_rx_if.data ),
        .frame_error ( uart_rx_if.error )
    );

    //================= 发送模块 =================//
    uart_tx #(
        .UART_BPS ( UART_BPS ),
        .CLK_FREQ ( CLK_FREQ )
    ) u_uart_tx (
        .clk            ( clk_50M ),
        .rst_n          ( sys_rst_n ),
        .uart_tx_start  ( uart_tx_if.start ),
        .uart_tx_data   ( uart_tx_if.data ),
        .uart_txd       ( uart_txd ),
        .uart_tx_busy   ( uart_tx_if.busy ),
        .uart_tx_done   ( uart_tx_if.done )
    );

    //================= 控制模块 =================//
    nRE_DE_LED u_nRE_DE_LED (
        .clk           ( clk_50M ),
        .rst_n         ( sys_rst_n ),
        .rx_data       ( uart_rx_if.data ),
        .rx_done       ( uart_rx_if.valid ),
        .frame_error   ( uart_rx_if.error ),
        .tx_busy       ( uart_tx_if.busy ),
        .uart_tx_done  ( uart_tx_if.done ),

        .LED1          ( leds.led21 ),
        .LED2          ( leds.led22 ),
        .en_rs485      ( en_rs485 ),

        .uart_tx_start ( uart_tx_if.start ),
        .uart_tx_data  ( uart_tx_if.data )
    );

    //================= LED输出 =================//
    assign LED21 = leds.led21;
    assign LED22 = leds.led22;

    //================= 简单断言示例 (SVA) =================//
    // 保证波特率参数合理
    initial begin
      assert (UART_BPS > 0 && CLK_FREQ > UART_BPS)
        else $error("UART 参数非法: UART_BPS=%0d, CLK_FREQ=%0d", UART_BPS, CLK_FREQ);
    end

endmodule : uart_loopback

// `default_nettype wire
