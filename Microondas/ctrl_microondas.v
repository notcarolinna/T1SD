module ctrl_microondas
(
  // Declaração das portas
  input start,
  input stop,
  input pause,
  input porta,
  input mais,
  input menos,
  input potencia,
  input [1:0] min_mode,
  input sec_mode,
  input reset,
  input clock,

  output [7:0] an,
  output [7:0] dec_cat,
  output [2:0] potencia_rgb,
  output [1:0] EA_o


);
  //sinais
  wire start_ed;
  wire pause_ed;
  wire stop_ed;
  wire mais_ed;
  wire menos_ed;
  wire porta_ed;
  wire [7:0]an_s; // vai servir para a luz da potência
  wire [7:0]dec_cat_timer, dec_cat_pot;
  wire done_ed;

  reg [1:0] EA;
  reg [6:0] min, sec;
  reg [1:0] sel_potencia;

  // instanciação do timer
  timer timepp (.clock(clock), .stop(stop_ed), .pause(pause_ed),.start(start_ed), .reset(reset), .done(done_ed), .min(min), .sec(sec), .an(an_s), .dec_cat(dec_cat_timer)); // min daqui vira o do timer

  assign an = an_s;
  assign EA_o = ~EA;
  
  //EDGE DETECTOR INSTANCIAÇÃO 
  edge_detector startf (.clock(clock), .reset(reset), .din(start), .rising(start_ed)); // o sinal clock conectado ao pino de entrada clock que estão instanciados no aruqivo do edge detector
  edge_detector pausef (.clock(clock), .reset(reset), .din(pause), .rising(pause_ed));
  edge_detector stopf (.clock(clock), .reset(reset), .din(stop), .rising(stop_ed));
  edge_detector menosf (.clock(clock), .reset(reset), .din(menos), .rising(menos_ed));
  edge_detector maisf (.clock(clock), .reset(reset), .din(mais), .rising(mais_ed));

  // MÁQUINA DE estados
  always @(posedge clock or posedge reset)begin
  
  // EA = 2'd0 -> configuraçãp
  // EA = 2'd1 -> decrementa tempo
  // EA = 2'd2 -> pausa

  if(reset == 1)begin
   EA <= 2'd0;
  end

  else begin
    case(EA)
      2'd0:
        begin
          if(start_ed == 1)begin
            EA <= 2'd3;
          end
        end

      2'd1:
        begin
          if(pause_ed == 1 || porta_ed == 1)begin
            EA <= 2'd2;
          end
          else if(stop_ed == 1 || done_ed == 1 )begin 
              EA <= 2'd0;
          end
        end

      2'd2:
        begin
          if(start_ed == 1 || pause_ed == 1)begin
            EA <= 2'd1;
          end
        end
      
      2'd3: begin
          if(done_ed == 0)begin
            EA <= 2'd1;
          end 
          else begin
            EA <= 2'd3;
          end
       end
          
       default: begin
            EA <= 2'd0;
       end 
    endcase
    end
  end

//SOMA E SUB DE MIN E SEC
always@(posedge clock or posedge reset) begin
if(reset == 1)begin
     min <= 7'd0;
     sec <= 7'd0;
end

else if( EA == 2'd1)begin
    min <= 7'd0;
   sec <= 7'd0;
end

else begin
if(potencia == 0)begin

if(min_mode[1])begin
    if(mais_ed == 1)begin
        if(min >= 7'd90) begin
            min <= 7'd99;
            sec <= 7'd59;
        end
        else begin
        min <= min + 7'd10;
        end
    end
    else if(menos_ed == 1)begin  // a verificação precisa ser feita se o min for == 0?
      min <= min - 10;
    end
end 
else if(min_mode[0])begin
    if(mais_ed == 1)begin
      min <= min + 1;
    end
    else if(menos_ed == 1)begin  // a verificação precisa ser feita se o min for == 0?
        if(min == 7'd0)begin
        min <= 7'd0;
        end
      min <= min - 1;
    end
end
else if(sec_mode == 1)begin
  if(mais_ed == 1)begin
       if(sec >= 7'd59) begin
          sec <= 7'd59;
        end
      sec <= sec + 10;
    end
    else if(menos_ed == 1)begin  // a verificação precisa ser feita se o sec for == 0?
        if(sec == 7'd0)begin
        sec <= 7'd0;
        end
      sec <= sec - 10;
    end
  end
else if(sec_mode == 0)begin
   if(mais_ed == 1)begin
      sec <= sec + 1;
    end
    else if(menos_ed == 1)begin  // a verificação precisa ser feita se o sec for == 0?
      sec <= sec - 1;
    end
  end
end
end
end


// PORTA ABERTA OU FECHADA
// 1'b1 = true = está aberta
//1'b0 = false = porta está fechada
// isso aqui é feito na máquina de estados

// SELEÇÃO DAS POTÊNCIAS
assign dec_cat_pot = (sel_potencia == 2'd0) ?  8'b11101111:
                      (sel_potencia == 2'd1) ? 8'b11111101:
                      8'b01111111 ;


always @(posedge clock or posedge reset)begin
  if(reset == 1)begin
    sel_potencia <= 2'd0; // nível baixo
  end
  else begin
  if(potencia == 1 && EA == 2'd0)begin
    case(sel_potencia)
      2'd0:
        begin
          if(mais_ed == 1)begin
            sel_potencia <= 2'd1;
          end
          else if(menos_ed == 1)begin
            sel_potencia <= 2'd0; 
          end
         end
      2'd1:
        begin
          if(mais_ed == 1)begin
            sel_potencia <= 2'd2;
          end
          else if(menos_ed == 1)begin
            sel_potencia <= 2'd0;   
          end
        end

      2'd2:
        begin
          if(mais_ed == 1)begin
            sel_potencia <= 2'd2;
          end
          else if(menos_ed == 1)begin
            sel_potencia <= 2'd1; 
          end
        end
      endcase
  end
end 
end


assign dec_cat = (an_s[5] == 0) ? dec_cat_pot :
                  dec_cat_timer;

assign potencia_rgb = (EA == 2'd0 || EA == 2'd2) ? 3'b000: // esse fica desligado enquanto n ser start
                      (sel_potencia == 2'd0) ? 3'b001: // esse é o azul
                      (sel_potencia == 2'd1) ? 3'b010: // esse é o verde
                      3'b100; // esse é o vermelho



endmodule

