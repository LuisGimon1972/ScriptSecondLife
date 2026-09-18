integer face_sorteada;

default
{
    state_entry()
    {
        llSetText("Clique para rolar o dado", <1,1,1>, 1.0);
    }

    touch_start(integer total_number)
    {
        // llFrand(6.0) gera um float de 0.0 a 5.999. 
        // Convertendo para integer (inteiro) temos 0 a 5. Somamos 1 para ter 1 a 6.
        face_sorteada = (integer)llFrand(6.0) + 1;
        
        string nome_jogador = llDetectedName(0);
        
        // Anuncia o resultado no chat local
        llSay(0, nome_jogador + " rolou um " + (string)face_sorteada + "!");
        
        // Envia o valor para a peça (Usando o canal 99 para comunicação entre objetos)
        // Em um jogo real, você enviaria para o controlador do tabuleiro para validar de quem é a vez.
        llRegionSay(99, (string)face_sorteada);
    }
}