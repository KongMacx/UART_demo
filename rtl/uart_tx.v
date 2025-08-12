module uart_tx #(
    parameter CLK_FREQ = 50_000_000,  //系统时钟频率
    parameter UART_BPS = 115200  //串口波特率
)(
    input       clk,            //系统时钟
    input       rst_n,          //系统复位，低有效
    input       uart_tx_start,  //UART的发送使能
    input [7:0] uart_tx_data,   //UART要发送的数据

    output reg uart_txd,      //UART发送端口
    output reg uart_tx_busy,  //发送忙状态信号
    output reg uart_tx_done   //发送完成标志
);

    localparam BAUD_CNT_MAX = CLK_FREQ / UART_BPS;

    //reg define
    reg [ 7:0] tx_data_t;  //发送数据寄存器
    reg [ 3:0] tx_cnt;  //发送数据计数器
    reg [15:0] baud_cnt;  //波特率计数器

    //main code

    //当uart_tx_start为高时，寄存输入并行数据，并拉高BUSY
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_t    <= 8'b0;
            uart_tx_busy <= 1'b0;
        end  //发送使能时，寄存要发送的数据，并拉高BUSY
            else if (uart_tx_start && !uart_tx_busy) begin
            tx_data_t    <= uart_tx_data;
            uart_tx_busy <= 1'b1;
        end  //当计数到停止位结束时，停止发送过程
            else if (tx_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX - 1) begin
            tx_data_t    <= 8'b0;  //清空发送数据寄存器
            uart_tx_busy <= 1'b0;  //并拉低BUSY信号
        end
    end

    //波特率计数器赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 16'd0;
        end else if (uart_tx_start && !uart_tx_busy) begin
            baud_cnt <= 16'd0;  //发送使能计数器清零
        end else if (uart_tx_busy) begin  //当处于发送过程时，波特率计数器进行循环计数
            if (baud_cnt < BAUD_CNT_MAX - 1'b1) begin
                baud_cnt <= baud_cnt + 1'b1;
            end else begin
                baud_cnt <= 16'b0;  //计数器到达一个波特率周期后清零
            end
        end else begin
            baud_cnt <= 16'd0;  //发送过程结束时计数器清零
        end
    end

    //tx_cnt进行赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) tx_cnt <= 4'd0;
        else if (uart_tx_start) begin
            tx_cnt <= 4'd0;  //发送使能时计数器清零
        end else if (uart_tx_busy) begin  //处于发送过程时 tx_cnt 才进行计数
            if (baud_cnt == BAUD_CNT_MAX - 1'b1) begin  //当波特率计数器计数到一个波特率周期时
                tx_cnt <= tx_cnt + 1'b1;  //发送数据计数器加 1
            end else begin
                tx_cnt <= tx_cnt;
            end
        end else begin
            tx_cnt <= 4'd0;  //发送过程结束时计数器清零
        end
    end

    //根据 tx_cnt 来给 uart 发送端口赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) uart_txd <= 1'b1;
        else if (uart_tx_busy) begin
            case (tx_cnt)
                4'd0: uart_txd <= 1'b0;  //起始位
                4'd1: uart_txd <= tx_data_t[0];  //数据最低位
                4'd2: uart_txd <= tx_data_t[1];
                4'd3: uart_txd <= tx_data_t[2];
                4'd4: uart_txd <= tx_data_t[3];
                4'd5: uart_txd <= tx_data_t[4];
                4'd6: uart_txd <= tx_data_t[5];
                4'd7: uart_txd <= tx_data_t[6];
                4'd8: uart_txd <= tx_data_t[7];  //数据最高位
                4'd9: uart_txd <= 1'b1;
                default: uart_txd <= 1'b1;  //停止位
            endcase
        end else uart_txd <= 1'b1;  //空闲时发送端口为高电平
    end

    // 发送完成标志（持续1个时钟周期）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            uart_tx_done <= 1'b0;
        else if (tx_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX - 1)
            uart_tx_done <= 1'b1;
        else
            uart_tx_done <= 1'b0;
    end

endmodule  //uart_tx
