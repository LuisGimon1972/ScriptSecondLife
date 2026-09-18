// Digite aqui as coordenadas X, Y, Z do centro do seu tabuleiro:
vector POSICAO_CENTRO_TABULEIRO = <128.000, 130.000, 25.000>;

default
{
    touch_start(integer total_number)
    {
        // Obtém a posição atual do marcador amarelo no mundo
        vector minha_pos = llGetPos();
        
        // Subtrai a posição do tabuleiro para encontrar a distância relativa (Offset)
        vector offset = minha_pos - POSICAO_CENTRO_TABULEIRO;
        
        // Imprime no chat local o formato exato para copiar para a lista
        llOwnerSay((string)offset + ",");
    }
}