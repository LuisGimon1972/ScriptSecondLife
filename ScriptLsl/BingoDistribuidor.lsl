integer canal_dialog = -998877;
string cartela_ativa = "Cartela Linha"; // Padrão ao iniciar

default
{
    state_entry()
    {
        llSetObjectName("Distribudor do Bingo");
        llSetText("📦 DISTRIBUIDOR DE BINGO 📦\nModo Atual: LINHA\nClique para pegar sua cartela!", <0.0, 1.0, 1.0>, 1.0);
    }

    touch_start(integer total_number)
    {
        key clicou = llDetectedKey(0);

        // SE O DONO CLICAR: Abre o menu para trocar a modalidade do jogo
        if (clicou == llGetOwner())
        {
            llListen(canal_dialog, "", clicou, "");
            llDialog(clicou, "\n[ PAINEL DO ANFITRIÃO ]\nEscolha qual cartela este distribuidor vai entregar aos jogadores:\n\nModo Selecionado: " + cartela_ativa, ["Linha", "Cartela Cheia", "Fechar"], canal_dialog);
        }
        // SE UM JOGADOR CLICAR: Entrega a cartela que está ativa no momento
        else
        {
            if (llGetInventoryType(cartela_ativa) != INVENTORY_NONE)
            {
                llGiveInventory(clicou, cartela_ativa);
                llRegionSayTo(clicou, 0, "🎯 Você recebeu a " + cartela_ativa + "! Abra o seu inventário e selecione 'Anexar ao HUD'.");
            }
            else
            {
                llRegionSayTo(clicou, 0, "⚠️ Erro: Não foi encontrada a '" + cartela_ativa + "' no conteúdo do distribuidor!");
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == "Linha")
        {
            cartela_ativa = "Cartela Linha";
            llOwnerSay("✅ Distribuidor configurado para entregar: CARTELA LINHA");
            llSetText("📦 DISTRIBUIDOR DE BINGO 📦\nModo Atual: LINHA\nClique para pegar sua cartela!", <0.0, 1.0, 1.0>, 1.0);
        }
        else if (message == "Cartela Cheia")
        {
            cartela_ativa = "Cartela Cheia";
            llOwnerSay("✅ Distribuidor configurado para entregar: CARTELA CHEIA");
            llSetText("📦 DISTRIBUIDOR DE BINGO 📦\nModo Atual: CARTELA CHEIA\nClique para pegar sua cartela!", <0.0, 1.0, 0.0>, 1.0);
        }
    }
}