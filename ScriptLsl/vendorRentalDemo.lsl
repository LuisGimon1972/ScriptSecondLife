// ==========================================
// VENDOR AUTOMÁTICO PRO - RENTAL MANAGER DEMO
// ✅ Com links formatados para o chat e avisos restritos ao dono
// ==========================================

// ------------------- CONFIGURAÇÃO -------------------
integer PRECIO = 1;                        // Preço da Demo em L$
string NOMBRE_PRODUTO = "Rental Manager DEMO"; // Nome exibido no texto flutuante
string NOME_ARQUIVO_ITEM = "Rental Manager DEMO"; // Nome EXATO do arquivo no inventário
key DONO;                              

// 🔗 LINKS FORMATADOS PARA O CHAT DO SECOND LIFE
string LINK_LOJA = "url:https://marketplace.secondlife.com/stores/273481 [Visite nossa Loja]"; 
string LINK_PRODUTO = "url:https://marketplace.secondlife.com/p/Rental-Manager-v100-DEMO/28656888 [Ver Página do Produto]"; 

string MENSAGEM_AGRADECIMENTO = "Obrigado por adquirir a Demo! 💙\nVisite nossa loja: ";
// -----------------------------------------------------

integer g_contador = 0;

AtualizarTexto()
{
    llSetText(
        NOMBRE_PRODUTO + "\n" +
        "Preco: L$ " + (string)PRECIO + "\n" +
        "Vendidos: " + (string)g_contador,
        <1,1,1>, 1);
}

default
{
    state_entry()
    {
        DONO = llGetOwner();
        AtualizarTexto();
        llRequestPermissions(DONO, PERMISSION_DEBIT);
        llSetPayPrice(PAY_HIDE, [PRECIO, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
        
        // 🔒 Aviso de segurança e status exibido EXCLUSIVAMENTE ao dono
        llOwnerSay("✅ Vendor Rental Manager Demo inicializado!\n- Produto: " + NOMBRE_PRODUTO + "\n- Preço: L$ " + (string)PRECIO);
    }

    touch_start(integer total)
    {
        key comprador = llDetectedKey(0);
        
        if (comprador == DONO)
        {
            llOwnerSay("⚙️ Menu do Dono | Total de demos vendidas: " + (string)g_contador);
            return;
        }

        // Instrução limpa para o cliente no chat privado
        llInstantMessage(comprador, "Para adquirir " + NOMBRE_PRODUTO + ", clique com o botão direito no vendor e escolha 'Pagar' (Pay) o valor de L$ " + (string)PRECIO + ".\n🔗 " + LINK_PRODUTO);
    }

    money(key pagador, integer valor)
    {
        // Valor incorreto -> devolve o dinheiro
        if (valor != PRECIO)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Valor incorreto!\nPreço da Demo: L$ " + (string)PRECIO + "\nDevolvido: L$ " + (string)valor);
            return;
        }

        // Verifica se o arquivo demo existe no inventário
        if (llGetInventoryType(NOME_ARQUIVO_ITEM) == INVENTORY_NONE)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Erro: O arquivo demo não está no inventário do vendor. Dinheiro devolvido!");
            llOwnerSay("⚠️ AVISO: O arquivo '" + NOME_ARQUIVO_ITEM + "' não foi encontrado no inventário!");
            return;
        }

        // Entrega o item demo e registra a venda
        llGiveInventory(pagador, NOME_ARQUIVO_ITEM);
        
        g_contador++;
        AtualizarTexto();
        
        llInstantMessage(pagador, "✅ " + MENSAGEM_AGRADECIMENTO + LINK_LOJA + "\n🔗 " + LINK_PRODUTO);
        llOwnerSay("💰 DEMO VENDIDA! → " + llKey2Name(pagador) + " comprou " + NOMBRE_PRODUTO + " | Total: " + (string)g_contador);
    }
}