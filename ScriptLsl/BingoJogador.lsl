integer canal_bingo = 7777;
integer listener_handle;
list numeros_da_cartela = [];
integer total_acertos = 0;
integer meta_vitoria = 5; // Quantidade de acertos necessários para vencer a rodada

// Função para gerar uma cartela exclusiva e aleatória para o jogador
list gerarCartelaAleatoria()
{
    list temporaria = [];
    list minha_cartela = [];
    integer i;
    
    // Preenche com os 75 números possíveis
    for (i = 1; i <= 75; i++)
    {
        temporaria = (list)i + temporaria;
    }
    
    // Seleciona 10 números aleatórios sem repetir
    for (i = 0; i < 10; i++)
    {
        integer indice = (integer)llFrand(llGetListLength(temporaria));
        integer numero_escolhido = llList2Integer(temporaria, indice);
        
        minha_cartela = (list)numero_escolhido + minha_cartela;
        temporaria = llDeleteSubList(temporaria, indice, indice);
    }
    
    return minha_cartela;
}

default
{
    state_entry()
    {
        // Gera os números únicos do jogador e zera o contador de pontos
        numeros_da_cartela = gerarCartelaAleatoria();
        total_acertos = 0;
        
        // Liga a escuta no canal de transmissão do bingo
        listener_handle = llListen(canal_bingo, "", NULL_KEY, "");
        
        // Informa discretamente ao dono da cartela quais são os números dele
        llOwnerSay("📋 [SUA CARTELA] Cartela gerada! Seus números da sorte são: " + (string)numeros_da_cartela);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canal_bingo)
        {
            integer numero_ouvido = (integer)message;
            
            // Verifica se o número chamado pelo globo está nesta cartela
            integer posicao = llListFindList(numeros_da_cartela, (list)numero_ouvido);
            
            if (posicao != -1)
            {
                total_acertos++;
                llOwnerSay("✨ [MARCADO!] O número " + message + " bateu na sua cartela! (Total de acertos: " + (string)total_acertos + "/" + (string)meta_vitoria + ")");
                
                // Se atingir a quantidade estipulada, canta BINGO para a região inteira
                if (total_acertos >= meta_vitoria)
                {
                    llSay(0, "🏆 BINGO! O jogador " + llGetDisplayName(llGetOwner()) + " completou a cartela e venceu a rodada!");
                }
            }
        }
    }
}