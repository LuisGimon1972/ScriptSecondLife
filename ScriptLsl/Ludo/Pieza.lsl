// Exemplo de posições do tabuleiro (coordenadas da região onde cada "casa" fica)
// Em um jogo real, você teria cerca de 50+ vetores aqui mapeando o trajeto completo.
list caminho = [
    <128.0, 128.0, 25.0>, // Casa 1
    <129.0, 128.0, 25.0>, // Casa 2
    <130.0, 128.0, 25.0>, // Casa 3
    <130.0, 129.0, 25.0>  // Casa 4
];

integer casa_atual = -1; // -1 significa que está na base
integer valor_do_dado = 0;

default
{
    state_entry()
    {
        // Fica escutando o canal 99 (onde o dado fala)
        llListen(99, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        // Quando o dado é rolado, a peça "grava" o valor
        valor_do_dado = (integer)message;
    }

    touch_start(integer total_number)
    {
        if (valor_do_dado > 0)
        {
            // Lógica básica do Ludo: Só sai da base se tirar 6
            if (casa_atual == -1 && valor_do_dado != 6)
            {
                llSay(0, "Você precisa de um 6 para sair da base!");
                valor_do_dado = 0; // Reseta o dado
                return;
            }
            
            // Calcula a nova posição
            casa_atual = casa_atual + valor_do_dado;
            
            // Verifica se chegou ao fim do caminho
            integer tamanho_caminho = llGetListLength(caminho);
            if (casa_atual >= tamanho_caminho)
            {
                casa_atual = tamanho_caminho - 1; // Para na última casa
                llSay(0, "Peça chegou ao centro!");
            }

            // Pega a coordenada exata na lista e move a peça magicamente para lá
            vector nova_posicao = llList2Vector(caminho, casa_atual);
            llSetRegionPos(nova_posicao);
            
            // Zera o dado para a próxima rodada
            valor_do_dado = 0; 
        }
        else
        {
            llSay(0, "Role o dado primeiro!");
        }
    }
}