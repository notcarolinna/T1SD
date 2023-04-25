`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module tb;
    reg clock, reset, start, stop, pause;
    reg [6:0] min, sec;
    wire done;
    wire [7:0] an, dec_cat;

    localparam PERIOD = 2;  

    timer DUT (.clock(clock), .reset(reset), .start(start), .pause(pause), .stop(stop), .min(min), .sec(sec), .done(done), .an(an), .dec_cat(dec_cat));

    initial begin
        clock <= 1'b0;
        forever #1 clock <= ~clock;
    end

    initial
    begin
        reset <= 1'b1;
        start <= 1'b0;
        stop <= 1'b0;
        pause <= 1'b0;
        min <= 7'd1;
        sec <= 7'd02;
        #127
        reset <= 0'b0;
        #184
        start <= 1'b1;
        #700
        start <= 1'b0;
        #3850
        start <= 1'b1;
        #700
        start <= 1'b0;
        #6850
        pause <= 1'b1;
        #850
        pause <= 1'b0;
        #1850
        pause <= 1'b1;
        #705
        pause <= 1'b0;
    end
endmodule
