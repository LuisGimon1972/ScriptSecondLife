integer CANAL_JOGO = -987654; // O mesmo canal do Controlador Central
integer face_sorteada;

default
{
    state_entry()
    {
        llSetText("Clique para rolar o dado", <1,1,1>, 1.0);
    }

    touch_start(integer total_number)
    {
        // Pega a UUID (chave) de quem clicou no dado
        key id_jogador = llDetectedKey(0); 

        // Gera o número de 1 a 6
        face_sorteada = (integer)llFrand(6.0) + 1;
        
        // Envia o comando no formato exato que o Controlador espera:
        // Exemplo de saída: "DADO:66864f3c-e095-d9c8-058d-d6575e6ed1b8:4"
        llRegionSay(CANAL_JOGO, "DADO:" + (string)id_jogador + ":" + (string)face_sorteada);
        
        // Opcional: Uma pequena animação de texto no próprio dado para dar feedback visual
        llSetText("Rolando...", <1,1,0>, 1.0);
        llSleep(0.5);
        llSetText("Resultado: " + (string)face_sorteada + "\nClique para rolar", <1,1,1>, 1.0);
    }
}